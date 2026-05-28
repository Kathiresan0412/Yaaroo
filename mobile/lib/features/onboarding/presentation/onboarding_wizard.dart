import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../core/api_client.dart' show ApiException;
import '../../../main.dart' show YaaroScope, YaaroColors, AppTextField;

class _ValidationResult {
  _ValidationResult({
    required this.isValid,
    this.step = 0,
    this.fieldName = '',
    this.message = '',
  });

  final bool isValid;
  final int step;
  final String fieldName;
  final String message;
}

class OnboardingWizard extends StatefulWidget {
  const OnboardingWizard({
    required this.onComplete,
    required this.onLogout,
    this.mode = 'onboarding',
    super.key,
  });

  final VoidCallback onComplete;
  final VoidCallback onLogout;
  final String mode;

  @override
  State<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends State<OnboardingWizard> {
  int _currentStep = 0;
  bool _loading = true;
  bool _saving = false;
  bool _locating = false;
  String? _message;
  final _imagePicker = ImagePicker();
  double? _latitude;
  double? _longitude;

  // Validation focus nodes & error highlight flags
  final FocusNode _displayNameFocus = FocusNode();
  final FocusNode _bioFocus = FocusNode();
  final FocusNode _cityFocus = FocusNode();
  bool _displayNameHasError = false;
  bool _bioHasError = false;
  bool _cityHasError = false;
  bool _photosHasError = false;

  // Multi-step profile state data models
  final _displayName = TextEditingController();
  final _pronouns = TextEditingController();
  final _headline = TextEditingController();
  final _bio = TextEditingController();
  final _jobTitle = TextEditingController();
  final _company = TextEditingController();
  final _nationality = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();

  List<String> _photos = [];
  List<String> _sexualOrientation = [];
  double? _heightCm;
  String? _bodyType;
  List<String> _ethnicity = [];
  String? _hairColour;
  String? _eyeColour;
  String? _education;
  String? _industry;
  String? _religion;
  List<String> _languages = [];
  String? _smoking;
  String? _drinking;
  String? _exercise;
  String? _diet;
  String? _sleepSchedule;
  String? _livingSituation;
  String? _hasChildren;
  String? _wantsChildren;
  List<String> _hasPets = [];
  String? _wantsPets;
  String? _favPet;
  String? _favColour;
  List<String> _favFood = [];
  List<String> _favMusic = [];
  List<String> _favMovieGenre = [];
  List<String> _hobbies = [];
  String? _loveLanguage;
  String? _relationshipGoal;
  String _showGender = 'everyone';
  double _minAge = 18.0;
  double _maxAge = 35.0;
  double _maxDistanceKm = 50.0;

  // Options matching the Web UI
  final _options = {
    'orientation': ['Straight', 'Gay', 'Lesbian', 'Bisexual', 'Asexual', 'Queer', 'Questioning'],
    'body': ['Slim', 'Athletic', 'Average', 'Curvy', 'Muscular', 'Prefer not to say'],
    'ethnicity': ['Tamil', 'Sinhalese', 'Muslim', 'Burgher', 'Indian Tamil', 'South Asian', 'Mixed'],
    'hair': ['Black', 'Brown', 'Blonde', 'Grey', 'Red', 'Other'],
    'eyes': ['Brown', 'Black', 'Hazel', 'Blue', 'Green', 'Other'],
    'education': ['High school', 'Diploma', 'Bachelors', 'Masters', 'PhD', 'Other'],
    'industries': ['Technology', 'Healthcare', 'Education', 'Finance', 'Arts', 'Hospitality', 'Public sector'],
    'religion': ['Hindu', 'Christian', 'Muslim', 'Buddhist', 'Spiritual', 'Agnostic', 'Other'],
    'nationality': ['Sri Lankan', 'Indian', 'American', 'British', 'Canadian', 'Australian', 'German', 'French', 'Singaporean', 'Malaysian', 'Other'],
    'languages': ['Tamil', 'English', 'Sinhala', 'Hindi', 'Malayalam', 'French', 'German'],
    'habits': ['No', 'Occasionally', 'Socially', 'Yes'],
    'exercise': ['Daily', 'Often', 'Sometimes', 'Rarely'],
    'diet': ['Vegetarian', 'Vegan', 'Non vegetarian', 'Eggetarian', 'Halal', 'Other'],
    'sleep': ['Early bird', 'Night owl', 'Flexible'],
    'living': ['Alone', 'With family', 'With roommates', 'With pets'],
    'children': ['No', 'Yes', 'Prefer not to say'],
    'wantsChildren': ['Want someday', 'Open to it', 'Do not want', 'Not sure'],
    'pets': ['Dog', 'Cat', 'Bird', 'Fish', 'Rabbit', 'None'],
    'colours': ['Pink', 'Red', 'Blue', 'Green', 'Black', 'White', 'Gold', 'Purple'],
    'foods': ['Kottu', 'Dosa', 'Biryani', 'Rice & curry', 'Sushi', 'Pasta', 'Street food'],
    'music': ['Tamil pop', 'Kollywood', 'Hip hop', 'R&B', 'EDM', 'Classical', 'Indie'],
    'movies': ['Romance', 'Comedy', 'Thriller', 'Action', 'Drama', 'Sci-fi', 'Documentary'],
    'hobbies': ['Travel', 'Cooking', 'Cricket', 'Gym', 'Reading', 'Dancing', 'Gaming', 'Photography', 'Hiking', 'Volunteering'],
    'love': ['Words of affirmation', 'Quality time', 'Acts of service', 'Gifts', 'Physical touch'],
    'goals': ['Life partner', 'Long-term relationship', 'New friends', 'Still figuring it out'],
    'genders': ['everyone', 'women', 'men', 'non_binary'],
    'countries': [
      'Sri Lanka',
      'India',
      'United States',
      'United Kingdom',
      'Canada',
      'Australia',
      'Germany',
      'France',
      'Italy',
      'Spain',
      'Netherlands',
      'Norway',
      'Sweden',
      'Denmark',
      'Switzerland',
      'United Arab Emirates',
      'Qatar',
      'Saudi Arabia',
      'Singapore',
      'Malaysia',
      'Thailand',
      'Japan',
      'South Korea',
      'New Zealand',
    ],
  };

  final List<String> _steps = [
    'Photos',
    'About You',
    'Physical',
    'Background',
    'Lifestyle',
    'Favourites',
    'Preferences',
    'Location'
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _loadProfileData);
  }

  @override
  void dispose() {
    _displayNameFocus.dispose();
    _bioFocus.dispose();
    _cityFocus.dispose();
    _displayName.dispose();
    _pronouns.dispose();
    _headline.dispose();
    _bio.dispose();
    _jobTitle.dispose();
    _company.dispose();
    _nationality.dispose();
    _city.dispose();
    _country.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final api = YaaroScope.of(context);
    try {
      final payload = await api.getProfileMe();
      final profile = payload['profile'] as Map<String, dynamic>? ?? {};
      final prefs = payload['preferences'] as Map<String, dynamic>? ?? {};
      final location = payload['location'] as Map<String, dynamic>? ?? {};
      final photosList = payload['photos'] as List? ?? [];

      setState(() {
        _photos = photosList.map((p) => p['url']?.toString() ?? '').toList();

        final existingDisplayName = profile['displayName']?.toString() ?? '';
        _displayName.text = existingDisplayName;
        _pronouns.text = profile['pronouns']?.toString() ?? '';
        _headline.text = profile['headline']?.toString() ?? '';
        _bio.text = profile['bio']?.toString() ?? '';

        _sexualOrientation = _parseStringList(profile['sexualOrientation']);
        _heightCm = double.tryParse(profile['heightCm']?.toString() ?? '');
        _bodyType = _nonEmptyString(profile['bodyType']);
        _ethnicity = _parseStringList(profile['ethnicity']);
        _hairColour = _nonEmptyString(profile['hairColour']);
        _eyeColour = _nonEmptyString(profile['eyeColour']);

        _education = _nonEmptyString(profile['education']);
        _jobTitle.text = profile['jobTitle']?.toString() ?? '';
        _company.text = profile['company']?.toString() ?? '';
        _industry = _nonEmptyString(profile['industry']);
        _religion = _nonEmptyString(profile['religion']);
        _nationality.text = profile['nationality']?.toString() ?? '';
        _languages = _parseStringList(profile['languages']);

        _smoking = _nonEmptyString(profile['smoking']);
        _drinking = _nonEmptyString(profile['drinking']);
        _exercise = _nonEmptyString(profile['exercise']);
        _diet = _nonEmptyString(profile['diet']);
        _sleepSchedule = _nonEmptyString(profile['sleepSchedule']);
        _livingSituation = _nonEmptyString(profile['livingSituation']);
        _hasChildren = _nonEmptyString(profile['hasChildren']);
        _wantsChildren = _nonEmptyString(profile['wantsChildren']);
        _hasPets = _parseStringList(profile['hasPets']);
        _wantsPets = _nonEmptyString(profile['wantsPets']);

        _favPet = _nonEmptyString(profile['favPet']);
        _favColour = _nonEmptyString(profile['favColour']);
        _favFood = _parseStringList(profile['favFood']);
        _favMusic = _parseStringList(profile['favMusic']);
        _favMovieGenre = _parseStringList(profile['favMovieGenre']);
        _hobbies = _parseStringList(payload['hobbies']);
        _loveLanguage = _nonEmptyString(profile['loveLanguage']);
        _relationshipGoal = _nonEmptyString(profile['relationshipGoal']);

        _showGender = prefs['showGender']?.toString() ?? 'everyone';
        _minAge = double.tryParse(prefs['minAge']?.toString() ?? '') ?? 18.0;
        _maxAge = double.tryParse(prefs['maxAge']?.toString() ?? '') ?? 35.0;
        _maxDistanceKm = double.tryParse(prefs['maxDistanceKm']?.toString() ?? '') ?? 50.0;

        _city.text = location['city']?.toString() ?? '';
        _country.text = location['country']?.toString() ?? '';
        _latitude = double.tryParse(location['latitude']?.toString() ?? '');
        _longitude = double.tryParse(location['longitude']?.toString() ?? '');

        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _message = 'Failed to load profile. Please try again.';
      });
    }
  }

  List<String> _parseStringList(dynamic input) {
    if (input is List) {
      return input.map((item) => item.toString()).toList();
    }
    return [];
  }

  String? _nonEmptyString(dynamic input) {
    final value = input?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  List<String> get _countryOptions {
    final countries = _options['countries']!;
    final current = _country.text.trim();
    if (current.isNotEmpty && !countries.contains(current)) {
      return [current, ...countries];
    }
    return countries;
  }

  Future<Map<String, String>> _cityFromCoordinates(double latitude, double longitude) async {
    final uri = Uri.https(
      'api.bigdatacloud.net',
      '/data/reverse-geocode-client',
      {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'localityLanguage': 'en',
      },
    );
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Unable to find your city from device location.');
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw ApiException('Unable to find your city from device location.');
    }

    final city = payload['city']?.toString().trim().isNotEmpty == true
        ? payload['city'].toString().trim()
        : payload['locality']?.toString().trim().isNotEmpty == true
            ? payload['locality'].toString().trim()
            : payload['principalSubdivision']?.toString().trim() ?? '';
    final country = payload['countryName']?.toString().trim() ?? '';

    if (city.isEmpty || country.isEmpty) {
      throw ApiException('Unable to find your city from device location.');
    }

    return {'city': city, 'country': country};
  }

  Future<void> _useDeviceLocation() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _message = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw ApiException('Turn on location services or enter your city manually.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw ApiException('Location permission was not granted. Enter your city manually.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw ApiException('Location permission is blocked. Enable it in settings or enter your city manually.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final latitude = double.parse(position.latitude.toStringAsFixed(7));
      final longitude = double.parse(position.longitude.toStringAsFixed(7));
      final location = await _cityFromCoordinates(latitude, longitude);

      if (!mounted) return;
      setState(() {
        _latitude = latitude;
        _longitude = longitude;
        _city.text = location['city']!;
        _country.text = location['country']!;
        _message = 'Location selected.';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      _showValidationErrorDialog(
        title: 'Location Error',
        message: e.message,
        onConfirm: () {
          if (e.message.contains('blocked')) {
            Geolocator.openAppSettings();
          } else if (e.message.contains('services')) {
            Geolocator.openLocationSettings();
          }
        },
      );
    } catch (_) {
      if (!mounted) return;
      _showValidationErrorDialog(
        title: 'Location Error',
        message: 'Unable to find your city from device location. Please make sure location is enabled.',
        onConfirm: () {},
      );
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  String _mimeTypeForImage(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String get _heightFtLabel {
    final totalInches = ((_heightCm ?? 170.0) / 2.54).round();
    final ft = totalInches ~/ 12;
    final inches = totalInches % 12;
    return "$ft'$inches\"";
  }

  Future<void> _pickAndUploadPhoto() async {
    final api = YaaroScope.of(context);
    try {
      final images = await _imagePicker.pickMultiImage(
        imageQuality: 68,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (images.isEmpty) return;

      setState(() {
        _saving = true;
        _message = null;
      });

      int uploadCount = 0;
      for (final image in images) {
        final bytes = await image.readAsBytes();
        final mimeType = _mimeTypeForImage(image.name);
        final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';
        await api.uploadPhoto(dataUrl);
        uploadCount++;
      }

      final photosPayload = await api.getProfilePhotos();
      if (!mounted) return;
      setState(() {
        _photos = photosPayload.map((p) => p['url']?.toString() ?? '').toList();
        _message = uploadCount > 1
            ? 'Successfully uploaded $uploadCount photos.'
            : 'Photo uploaded.';
        if (_photos.length >= 2) {
          _photosHasError = false;
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _message = e.message);
    } on PlatformException catch (e) {
      if (!mounted) return;
      final isMissingPlugin = e.code == 'channel-error' ||
          e.message?.contains('Unable to establish connection') == true;
      setState(() {
        _message = isMissingPlugin
            ? 'Photo picker is not ready yet. Fully stop and rebuild the app, then try again.'
            : 'Photo picker failed. Please allow photo access and try again.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = 'Photo upload failed: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deletePhoto(int index) async {
    if (_photos.length <= index) return;
    setState(() => _saving = true);
    try {
      setState(() {
        _photos.removeAt(index);
        _message = 'Photo removed.';
        _photosHasError = _photos.length < 2;
      });
    } catch (_) {
      setState(() => _message = 'Failed to delete photo.');
    } finally {
      setState(() => _saving = false);
    }
  }

  Map<String, dynamic> _buildProfileBody() {
    final body = <String, dynamic>{};

    void addText(String key, TextEditingController controller) {
      final value = controller.text.trim();
      if (value.isNotEmpty) body[key] = value;
    }

    void addString(String key, String? value) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) body[key] = trimmed;
    }

    void addList(String key, List<String> value) {
      if (value.isNotEmpty) body[key] = value;
    }

    addText('displayName', _displayName);
    addText('pronouns', _pronouns);
    addList('sexualOrientation', _sexualOrientation);
    addText('headline', _headline);
    addText('bio', _bio);
    if (_heightCm != null) body['heightCm'] = _heightCm!.toInt();
    addString('bodyType', _bodyType);
    addList('ethnicity', _ethnicity);
    addString('hairColour', _hairColour);
    addString('eyeColour', _eyeColour);
    addString('education', _education);
    addText('jobTitle', _jobTitle);
    addText('company', _company);
    addString('industry', _industry);
    addString('religion', _religion);
    addText('nationality', _nationality);
    addList('languages', _languages);
    addString('smoking', _smoking);
    addString('drinking', _drinking);
    addString('exercise', _exercise);
    addString('diet', _diet);
    addString('sleepSchedule', _sleepSchedule);
    addString('livingSituation', _livingSituation);
    addString('hasChildren', _hasChildren);
    addString('wantsChildren', _wantsChildren);
    addList('hasPets', _hasPets);
    addString('wantsPets', _wantsPets);
    addString('favPet', _favPet);
    addString('favColour', _favColour);
    addList('favFood', _favFood);
    addList('favMusic', _favMusic);
    addList('favMovieGenre', _favMovieGenre);
    addList('hobbies', _hobbies);
    if (_hobbies.isNotEmpty) body['interests'] = {'hobbies': _hobbies};
    addString('loveLanguage', _loveLanguage);
    addString('relationshipGoal', _relationshipGoal);

    return body;
  }

  Future<void> _showValidationErrorDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Validation Error',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: YaaroColors.surface,
                  border: Border.all(color: YaaroColors.line),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: YaaroColors.rose.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: YaaroColors.rose,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: const TextStyle(
                        color: YaaroColors.muted,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onConfirm();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: YaaroColors.rose,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          "Let's fix it",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  _ValidationResult _validateAllRequiredFields() {
    return _ValidationResult(isValid: true, step: 0, fieldName: '', message: '');
  }

  void _handleValidationError(_ValidationResult result) {
    _showValidationErrorDialog(
      title: 'Missing Required Info',
      message: result.message,
      onConfirm: () {
        setState(() {
          _currentStep = result.step;
          if (result.step == 0) {
            _photosHasError = true;
          } else if (result.step == 1) {
            if (result.fieldName == 'Display Name') {
              _displayNameHasError = true;
              _displayNameFocus.requestFocus();
            } else if (result.fieldName == 'Bio') {
              _bioHasError = true;
              _bioFocus.requestFocus();
            }
          } else if (result.step == 7) {
            _cityHasError = true;
            _cityFocus.requestFocus();
          }
        });
      },
    );
  }

  void _handleBackendValidationErrors(Map<String, dynamic> errors) {
    String errorMsg = "Please fix the following issues to continue:\n\n";
    int? targetStep;
    String? targetField;

    errors.forEach((key, val) {
      errorMsg += "• $val\n";
      
      if (targetStep == null) {
        if (key == 'photos') {
          targetStep = 0;
          targetField = 'photos';
        } else if (key == 'displayName') {
          targetStep = 1;
          targetField = 'displayName';
        } else if (key == 'bio') {
          targetStep = 1;
          targetField = 'bio';
        } else if (key == 'location') {
          targetStep = 7;
          targetField = 'location';
        }
      }
    });

    _showValidationErrorDialog(
      title: 'Required Info Missing',
      message: errorMsg.trim(),
      onConfirm: () {
        if (targetStep != null) {
          setState(() {
            _currentStep = targetStep!;
            if (targetField == 'photos') {
              _photosHasError = true;
            } else if (targetField == 'displayName') {
              _displayNameHasError = true;
              _displayNameFocus.requestFocus();
            } else if (targetField == 'bio') {
              _bioHasError = true;
              _bioFocus.requestFocus();
            } else if (targetField == 'location') {
              _cityHasError = true;
              _cityFocus.requestFocus();
            }
          });
        }
      },
    );
  }

  Future<void> _saveStep() async {
    if (_currentStep == 7) {
      final validation = _validateAllRequiredFields();
      if (!validation.isValid) {
        _handleValidationError(validation);
        return;
      }
    }

    setState(() {
      _saving = true;
      _message = null;
    });

    final api = YaaroScope.of(context);
    try {
      switch (_currentStep) {
        case 0:
          break;

        case 1: // About You
          break;

        case 2: // Physical
          break;

        case 3: // Background
          break;

        case 4: // Lifestyle
          break;

        case 5: // Favourites & Hobbies
          break;

        case 6: // Preferences
          await api.updatePreferences({
            'showGender': _showGender,
            'minAge': _minAge.toInt(),
            'maxAge': _maxAge.toInt(),
            'maxDistanceKm': _maxDistanceKm.toInt(),
          });
          break;

        case 7: // Location
          final profileBody = _buildProfileBody();
          if (profileBody.isNotEmpty) {
            await api.updateProfileMe(profileBody);
          }

          if (_city.text.trim().isNotEmpty && _country.text.trim().isNotEmpty) {
            await api.updateLocation(_latitude, _longitude, _city.text.trim(), _country.text.trim());
          }
          if (widget.mode == 'onboarding') {
            await api.onboardingComplete();
          }
          widget.onComplete();
          return;
      }

      // If we are on steps 1 through 5, send the ENTIRE profileBody (all attributes matching web exactly)!
      if (_currentStep >= 1 && _currentStep <= 5) {
        final profileBody = _buildProfileBody();
        if (profileBody.isNotEmpty) {
          await api.updateProfileMe(profileBody);
        }
      }

      // Progress step or show success message in edit mode
      if (widget.mode == 'edit') {
        if (!mounted) return;
        if (_currentStep < _steps.length - 1) {
          setState(() {
            _message = 'Section updated successfully.';
            _currentStep++;
          });
        } else {
          widget.onComplete();
        }
      } else {
        if (!mounted) return;
        setState(() {
          _currentStep++;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.errors != null && e.errors!.isNotEmpty) {
        _handleBackendValidationErrors(e.errors!);
      } else {
        _showValidationErrorDialog(
          title: 'Validation Error',
          message: e.toString(),
          onConfirm: () {},
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showValidationErrorDialog(
        title: 'Validation Error',
        message: e.toString(),
        onConfirm: () {},
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _skipOnboarding() async {
    setState(() {
      _saving = true;
      _message = null;
    });

    final api = YaaroScope.of(context);
    try {
      if (widget.mode == 'onboarding') {
        await api.updatePreferences({
          'showGender': _showGender,
          'minAge': _minAge.toInt(),
          'maxAge': _maxAge.toInt(),
          'maxDistanceKm': 20000,
          'globalMode': true,
          'showPhotosOnly': true,
        });
        await api.onboardingComplete();
      }
      widget.onComplete();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showValidationErrorDialog(
        title: 'Error Completing Onboarding',
        message: e.toString(),
        onConfirm: () {},
      );
    } catch (e) {
      if (!mounted) return;
      _showValidationErrorDialog(
        title: 'Error Completing Onboarding',
        message: e.toString(),
        onConfirm: () {},
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: YaaroColors.black,
        body: Center(child: CircularProgressIndicator(color: YaaroColors.rose)),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: YaaroColors.black,
          appBar: AppBar(
            backgroundColor: YaaroColors.surface,
            elevation: 0,
            leading: widget.mode == 'edit'
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: widget.onComplete,
                  )
                : null,
            title: Text(
              widget.mode == 'edit' ? 'Edit Profile' : 'Onboarding: Step ${_currentStep + 1}/${_steps.length}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              if (widget.mode == 'onboarding') ...[
                TextButton(
                  onPressed: _saving ? null : _skipOnboarding,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: YaaroColors.rose,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: widget.onLogout,
                ),
              ],
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (_currentStep + 1) / _steps.length,
                  color: YaaroColors.rose,
                  backgroundColor: Colors.white10,
                  minHeight: 4,
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    children: List.generate(_steps.length, (index) {
                      final bool isCurrent = index == _currentStep;
                      final bool isEnabled = widget.mode == 'edit' || index <= _currentStep;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(_steps[index]),
                          selected: isCurrent,
                          onSelected: isEnabled
                              ? (selected) {
                                  if (selected) {
                                    setState(() {
                                      _currentStep = index;
                                      _message = null;
                                    });
                                  }
                                }
                              : null,
                          backgroundColor: YaaroColors.surfaceAlt,
                          selectedColor: YaaroColors.rose,
                          labelStyle: TextStyle(
                            color: isCurrent
                                ? Colors.white
                                : (isEnabled ? Colors.white70 : Colors.white24),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                if (_message != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: YaaroColors.saffron.withOpacity(0.15),
                    child: Text(
                      _message!,
                      style: const TextStyle(color: YaaroColors.saffron, fontWeight: FontWeight.bold),
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _steps[_currentStep].toUpperCase(),
                          style: const TextStyle(
                            color: YaaroColors.teal,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStepContent(),
                      ],
                    ),
                  ),
                ),
                _buildNavigationRow(),
              ],
            ),
          ),
        ),
        if (_saving) _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: AbsorbPointer(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: Colors.black.withOpacity(0.34),
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.94, end: 1),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: YaaroColors.surface.withOpacity(0.92),
                    border: Border.all(color: YaaroColors.line),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: YaaroColors.rose.withOpacity(0.22),
                        blurRadius: 28,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(
                        color: YaaroColors.rose,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPhotosStep();
      case 1:
        return _buildAboutStep();
      case 2:
        return _buildPhysicalStep();
      case 3:
        return _buildBackgroundStep();
      case 4:
        return _buildLifestyleStep();
      case 5:
        return _buildFavouritesStep();
      case 6:
        return _buildPreferencesStep();
      case 7:
        return _buildLocationStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPhotosStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Show your best self',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Upload at least 2 photos to activate your profile. The first photo will be your primary card cover.',
          style: TextStyle(color: YaaroColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 18),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: _photosHasError ? const EdgeInsets.all(10) : EdgeInsets.zero,
          decoration: BoxDecoration(
            border: Border.all(
              color: _photosHasError ? YaaroColors.rose : Colors.transparent,
              width: _photosHasError ? 2.0 : 0.0,
            ),
            borderRadius: BorderRadius.circular(12),
            color: _photosHasError ? Colors.red.withOpacity(0.06) : Colors.transparent,
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              if (index < _photos.length) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(_photos[index], fit: BoxFit.cover),
                    ),
                    if (index == 0)
                      Positioned(
                        left: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: YaaroColors.teal,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('PRIMARY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        style: IconButton.styleFrom(backgroundColor: Colors.black54),
                        onPressed: () => _deletePhoto(index),
                      ),
                    ),
                  ],
                );
              } else {
                return InkWell(
                  onTap: _saving ? null : _pickAndUploadPhoto,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      border: Border.all(color: Colors.white10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.add_a_photo, color: YaaroColors.muted, size: 28),
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAboutStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Introduce yourself', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        AppTextField(
          controller: _displayName,
          label: 'Display Name',
          focusNode: _displayNameFocus,
          hasError: _displayNameHasError,
          onChanged: (val) {
            if (_displayNameHasError && val.trim().isNotEmpty) {
              setState(() => _displayNameHasError = false);
            }
          },
        ),
        const SizedBox(height: 12),
        AppTextField(controller: _pronouns, label: 'Pronouns (e.g. He/Him, She/Her)'),
        const SizedBox(height: 16),
        const Text('Sexual Orientation', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        _buildChipsSelection('orientation', _sexualOrientation, (list) => setState(() => _sexualOrientation = list)),
        const SizedBox(height: 16),
        AppTextField(controller: _headline, label: 'Headline (e.g. Dosa loyalist, curious traveler)'),
        const SizedBox(height: 12),
        TextField(
          controller: _bio,
          focusNode: _bioFocus,
          maxLines: 4,
          onChanged: (val) {
            if (_bioHasError && val.trim().isNotEmpty) {
              setState(() => _bioHasError = false);
            }
          },
          decoration: InputDecoration(
            labelText: 'About You (Bio)',
            filled: true,
            fillColor: _bioHasError ? Colors.red.withOpacity(0.08) : Colors.white.withOpacity(0.06),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _bioHasError ? YaaroColors.rose : Colors.white24,
                width: _bioHasError ? 2.0 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _bioHasError ? YaaroColors.rose : YaaroColors.rose.withOpacity(0.8),
                width: 2.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhysicalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Physical Attributes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Height: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(_heightCm == null ? 'Not set' : '${_heightCm!.toInt()} cm ($_heightFtLabel)', style: const TextStyle(color: YaaroColors.rose, fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
        Slider(
          value: (_heightCm ?? 170.0).clamp(140.0, 220.0),
          min: 140.0,
          max: 220.0,
          activeColor: YaaroColors.rose,
          onChanged: (val) => setState(() => _heightCm = val),
        ),
        const SizedBox(height: 12),
        _buildDropdown('Body Type', _bodyType, _options['body']!, (val) => setState(() => _bodyType = val!)),
        const SizedBox(height: 16),
        const Text('Ethnicity', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        _buildChipsSelection('ethnicity', _ethnicity, (list) => setState(() => _ethnicity = list)),
        const SizedBox(height: 16),
        _buildDropdown('Hair Colour', _hairColour, _options['hair']!, (val) => setState(() => _hairColour = val!)),
        const SizedBox(height: 12),
        _buildDropdown('Eye Colour', _eyeColour, _options['eyes']!, (val) => setState(() => _eyeColour = val!)),
      ],
    );
  }

  Widget _buildBackgroundStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Background', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        _buildDropdown('Education Level', _education, _options['education']!, (val) => setState(() => _education = val!)),
        const SizedBox(height: 12),
        AppTextField(controller: _jobTitle, label: 'Job Title'),
        const SizedBox(height: 12),
        AppTextField(controller: _company, label: 'Company Name'),
        const SizedBox(height: 12),
        _buildDropdown('Industry', _industry, _options['industries']!, (val) => setState(() => _industry = val!)),
        const SizedBox(height: 12),
        _buildDropdown('Religion', _religion, _options['religion']!, (val) => setState(() => _religion = val!)),
        const SizedBox(height: 12),
        _buildDropdown('Nationality', _nationality.text.trim().isEmpty ? 'Select nationality' : _nationality.text.trim(), _options['nationality']!, (val) => setState(() => _nationality.text = val!)),
        const SizedBox(height: 16),
        const Text('Languages Spoken', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        _buildChipsSelection('languages', _languages, (list) => setState(() => _languages = list)),
      ],
    );
  }

  Widget _buildLifestyleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lifestyle & Habits', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        _buildDropdown('Do you smoke?', _smoking, _options['habits']!, (val) => setState(() => _smoking = val!)),
        const SizedBox(height: 12),
        _buildDropdown('Do you drink?', _drinking, _options['habits']!, (val) => setState(() => _drinking = val!)),
        const SizedBox(height: 12),
        _buildDropdown('Exercise habits', _exercise, _options['exercise']!, (val) => setState(() => _exercise = val!)),
        const SizedBox(height: 12),
        _buildDropdown('Diet preference', _diet, _options['diet']!, (val) => setState(() => _diet = val!)),
        const SizedBox(height: 12),
        _buildDropdown('Sleep schedule', _sleepSchedule, _options['sleep']!, (val) => setState(() => _sleepSchedule = val!)),
        const SizedBox(height: 12),
        _buildDropdown('Living situation', _livingSituation, _options['living']!, (val) => setState(() => _livingSituation = val!)),
        const SizedBox(height: 12),
        _buildDropdown('Do you have kids?', _hasChildren, _options['children']!, (val) => setState(() => _hasChildren = val!)),
        const SizedBox(height: 12),
        _buildDropdown('Do you want kids?', _wantsChildren, _options['wantsChildren']!, (val) => setState(() => _wantsChildren = val!)),
        const SizedBox(height: 16),
        const Text('Pets you have', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        _buildChipsSelection('pets', _hasPets, (list) => setState(() => _hasPets = list)),
        const SizedBox(height: 12),
        _buildDropdown('Do you want pets?', _wantsPets, _options['wantsChildren']!, (val) => setState(() => _wantsPets = val!)),
      ],
    );
  }

  Widget _buildFavouritesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Favourites & Hobbies', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        const Text('Favourite Food (Select multiple)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        _buildChipsSelection('foods', _favFood, (list) => setState(() => _favFood = list)),
        const SizedBox(height: 16),
        const Text('Music Preference', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        _buildChipsSelection('music', _favMusic, (list) => setState(() => _favMusic = list)),
        const SizedBox(height: 16),
        const Text('Movie Genres', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        _buildChipsSelection('movies', _favMovieGenre, (list) => setState(() => _favMovieGenre = list)),
        const SizedBox(height: 16),
        const Text('Your Hobbies', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        _buildChipsSelection('hobbies', _hobbies, (list) => setState(() => _hobbies = list)),
        const SizedBox(height: 16),
        _buildDropdown('Love Language', _loveLanguage, _options['love']!, (val) => setState(() => _loveLanguage = val!)),
        const SizedBox(height: 12),
        _buildDropdown('Relationship Goal', _relationshipGoal, _options['goals']!, (val) => setState(() => _relationshipGoal = val!)),
      ],
    );
  }

  Widget _buildPreferencesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dating Preferences', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        _buildDropdown('Show me', _showGender, _options['genders']!, (val) => setState(() => _showGender = val!)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Age Range Filter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${_minAge.clamp(18.0, 60.0).toInt()} - ${_maxAge.clamp(18.0, 60.0).toInt()} years old', style: const TextStyle(color: YaaroColors.rose, fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
        RangeSlider(
          values: RangeValues(
            _minAge.clamp(18.0, 60.0),
            _maxAge.clamp(18.0, 60.0),
          ),
          min: 18.0,
          max: 60.0,
          activeColor: YaaroColors.rose,
          onChanged: (val) => setState(() {
            _minAge = val.start;
            _maxAge = val.end;
          }),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Maximum Distance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              _maxDistanceKm >= 20000 || _maxDistanceKm > 150
                  ? 'Unlimited (Global)'
                  : '${_maxDistanceKm.toInt()} km',
              style: const TextStyle(color: YaaroColors.rose, fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        Slider(
          value: _maxDistanceKm.clamp(1.0, 150.0),
          min: 1.0,
          max: 150.0,
          activeColor: YaaroColors.rose,
          onChanged: (val) => setState(() => _maxDistanceKm = val),
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Where are you based?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Select your current city and country to see matches near you.', style: TextStyle(color: YaaroColors.muted, fontSize: 13)),
        const SizedBox(height: 18),
        _buildDropdown('Country', _country.text.trim().isEmpty ? 'Select country' : _country.text.trim(), _countryOptions, (val) {
          if (val == null) return;
          setState(() {
            _country.text = val;
            _latitude = null;
            _longitude = null;
          });
        }),
        const SizedBox(height: 12),
        AppTextField(
          controller: _city,
          label: 'City',
          focusNode: _cityFocus,
          hasError: _cityHasError,
          onChanged: (val) {
            if (_cityHasError && val.trim().isNotEmpty) {
              setState(() => _cityHasError = false);
            }
          },
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _locating ? null : _useDeviceLocation,
          icon: _locating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: YaaroColors.teal,
                  ),
                )
              : const Icon(Icons.my_location, color: YaaroColors.teal),
          label: Text(
            _locating ? 'Detecting location...' : 'Use my current location',
            style: const TextStyle(color: Colors.white),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            side: const BorderSide(color: YaaroColors.line),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    final displayValue = value?.trim().isNotEmpty == true ? value!.trim() : 'Not set';
    return InkWell(
      onTap: () async {
        final selected = await _selectDropdownOption(
          label: label,
          value: value ?? '',
          items: items,
        );
        if (selected != null) {
          onChanged(selected);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: YaaroColors.muted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayValue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Future<String?> _selectDropdownOption({
    required String label,
    required String value,
    required List<String> items,
  }) {
    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: label,
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: const SizedBox.expand(),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxHeight: 420),
                    decoration: BoxDecoration(
                      color: YaaroColors.surface,
                      border: Border.all(color: YaaroColors.line),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.only(bottom: 8),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              color: Colors.white10,
                            ),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final selected = item == value;

                              return ListTile(
                                title: Text(
                                  item,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                trailing: selected
                                    ? const Icon(Icons.check, color: YaaroColors.rose)
                                    : null,
                                onTap: () => Navigator.pop(context, item),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChipsSelection(String optionKey, List<String> selectedList, ValueChanged<List<String>> onChanged) {
    final list = _options[optionKey]!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: list.map((item) {
        final isSelected = selectedList.contains(item);
        return ChoiceChip(
          label: Text(item),
          selected: isSelected,
          selectedColor: YaaroColors.rose.withOpacity(0.24),
          onSelected: (_) {
            final next = List<String>.from(selectedList);
            if (isSelected) {
              next.remove(item);
            } else {
              next.add(item);
            }
            onChanged(next);
          },
        );
      }).toList(),
    );
  }

  Widget _buildNavigationRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: YaaroColors.surface,
        border: Border(top: BorderSide(color: YaaroColors.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: _saving ? null : () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(100, 48),
                side: const BorderSide(color: YaaroColors.line),
                foregroundColor: Colors.white,
              ),
              child: const Text('Back'),
            )
          else
            const SizedBox(width: 100),
          FilledButton(
            onPressed: _saving ? null : _saveStep,
            style: FilledButton.styleFrom(
              backgroundColor: YaaroColors.rose,
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 48),
            ),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(_currentStep == _steps.length - 1 ? 'Finish' : 'Next'),
          ),
        ],
      ),
    );
  }
}
