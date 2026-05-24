import 'package:flutter/material.dart';
import '../../../main.dart' show YaaroScope, YaaroColors, AppTextField;

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
  String? _message;

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
  double _heightCm = 170.0;
  String _bodyType = 'Average';
  List<String> _ethnicity = [];
  String _hairColour = 'Black';
  String _eyeColour = 'Brown';
  String _education = 'Bachelors';
  String _industry = 'Technology';
  String _religion = 'Hindu';
  List<String> _languages = [];
  String _smoking = 'No';
  String _drinking = 'Socially';
  String _exercise = 'Sometimes';
  String _diet = 'Vegetarian';
  String _sleepSchedule = 'Flexible';
  String _livingSituation = 'Alone';
  String _hasChildren = 'No';
  String _wantsChildren = 'Open to it';
  List<String> _hasPets = [];
  String _wantsPets = 'Yes';
  String _favPet = 'Dog';
  String _favColour = 'Blue';
  List<String> _favFood = [];
  List<String> _favMusic = [];
  List<String> _favMovieGenre = [];
  List<String> _hobbies = [];
  String _loveLanguage = 'Quality time';
  String _relationshipGoal = 'Life partner';
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
    'genders': ['everyone', 'women', 'men', 'non_binary']
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
      final userMap = payload['user'] as Map<String, dynamic>? ?? {};
      final firstName = userMap['firstName']?.toString() ?? '';
      final registeredName = userMap['registeredProfile']?['name']?.toString() ?? '';
      final defaultDisplayName = firstName.isNotEmpty ? firstName : (registeredName.isNotEmpty ? registeredName : '');

      setState(() {
        _photos = photosList.map((p) => p['url']?.toString() ?? '').toList();

        final existingDisplayName = profile['displayName']?.toString() ?? '';
        _displayName.text = existingDisplayName.isNotEmpty ? existingDisplayName : defaultDisplayName;
        _pronouns.text = profile['pronouns']?.toString() ?? '';
        _headline.text = profile['headline']?.toString() ?? '';
        _bio.text = profile['bio']?.toString() ?? '';

        _sexualOrientation = _parseStringList(profile['sexualOrientation']);
        _heightCm = double.tryParse(profile['heightCm']?.toString() ?? '') ?? 170.0;
        _bodyType = profile['bodyType']?.toString() ?? 'Average';
        _ethnicity = _parseStringList(profile['ethnicity']);
        _hairColour = profile['hairColour']?.toString() ?? 'Black';
        _eyeColour = profile['eyeColour']?.toString() ?? 'Brown';

        _education = profile['education']?.toString() ?? 'Bachelors';
        _jobTitle.text = profile['jobTitle']?.toString() ?? '';
        _company.text = profile['company']?.toString() ?? '';
        _industry = profile['industry']?.toString() ?? 'Technology';
        _religion = profile['religion']?.toString() ?? 'Hindu';
        _nationality.text = profile['nationality']?.toString() ?? '';
        _languages = _parseStringList(profile['languages']);

        _smoking = profile['smoking']?.toString() ?? 'No';
        _drinking = profile['drinking']?.toString() ?? 'Socially';
        _exercise = profile['exercise']?.toString() ?? 'Sometimes';
        _diet = profile['diet']?.toString() ?? 'Vegetarian';
        _sleepSchedule = profile['sleepSchedule']?.toString() ?? 'Flexible';
        _livingSituation = profile['livingSituation']?.toString() ?? 'Alone';
        _hasChildren = profile['hasChildren']?.toString() ?? 'No';
        _wantsChildren = profile['wantsChildren']?.toString() ?? 'Open to it';
        _hasPets = _parseStringList(profile['hasPets']);
        _wantsPets = profile['wantsPets']?.toString() ?? 'Yes';

        _favPet = profile['favPet']?.toString() ?? 'Dog';
        _favColour = profile['favColour']?.toString() ?? 'Blue';
        _favFood = _parseStringList(profile['favFood']);
        _favMusic = _parseStringList(profile['favMusic']);
        _favMovieGenre = _parseStringList(profile['favMovieGenre']);
        _hobbies = _parseStringList(payload['hobbies']);
        _loveLanguage = profile['loveLanguage']?.toString() ?? 'Quality time';
        _relationshipGoal = profile['relationshipGoal']?.toString() ?? 'Life partner';

        _showGender = prefs['showGender']?.toString() ?? 'everyone';
        _minAge = double.tryParse(prefs['minAge']?.toString() ?? '') ?? 18.0;
        _maxAge = double.tryParse(prefs['maxAge']?.toString() ?? '') ?? 35.0;
        _maxDistanceKm = double.tryParse(prefs['maxDistanceKm']?.toString() ?? '') ?? 50.0;

        _city.text = location['city']?.toString() ?? '';
        _country.text = location['country']?.toString() ?? '';

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

  String get _heightFtLabel {
    final totalInches = (_heightCm / 2.54).round();
    final ft = totalInches ~/ 12;
    final inches = totalInches % 12;
    return "$ft'$inches\"";
  }

  Future<void> _showPhotoUploadUnavailable() async {
    setState(() {
      _message = 'Photo upload from device is not available in this build yet.';
    });
  }

  Future<void> _deletePhoto(int index) async {
    if (_photos.length <= index) return;
    setState(() => _saving = true);
    try {
      setState(() {
        _photos.removeAt(index);
        _message = 'Photo removed.';
      });
    } catch (_) {
      setState(() => _message = 'Failed to delete photo.');
    } finally {
      setState(() => _saving = false);
    }
  }

  Map<String, dynamic> _buildProfileBody() {
    return {
      'displayName': _displayName.text.trim(),
      'pronouns': _pronouns.text.trim(),
      'sexualOrientation': _sexualOrientation,
      'headline': _headline.text.trim(),
      'bio': _bio.text.trim(),
      'heightCm': _heightCm.toInt(),
      'bodyType': _bodyType,
      'ethnicity': _ethnicity,
      'hairColour': _hairColour,
      'eyeColour': _eyeColour,
      'education': _education,
      'jobTitle': _jobTitle.text.trim(),
      'company': _company.text.trim(),
      'industry': _industry,
      'religion': _religion,
      'nationality': _nationality.text.trim(),
      'languages': _languages,
      'smoking': _smoking,
      'drinking': _drinking,
      'exercise': _exercise,
      'diet': _diet,
      'sleepSchedule': _sleepSchedule,
      'livingSituation': _livingSituation,
      'hasChildren': _hasChildren,
      'wantsChildren': _wantsChildren,
      'hasPets': _hasPets,
      'wantsPets': _wantsPets,
      'favPet': _favPet,
      'favColour': _favColour,
      'favFood': _favFood,
      'favMusic': _favMusic,
      'favMovieGenre': _favMovieGenre,
      'hobbies': _hobbies,
      'interests': {'hobbies': _hobbies},
      'loveLanguage': _loveLanguage,
      'relationshipGoal': _relationshipGoal,
    };
  }

  Future<void> _saveStep() async {
    setState(() {
      _saving = true;
      _message = null;
    });

    final api = YaaroScope.of(context);
    try {
      switch (_currentStep) {
        case 0:
          if (_photos.length < 2) {
            throw 'Please upload at least 2 photos to continue.';
          }
          break;

        case 1: // About You
          if (_displayName.text.trim().isEmpty ||
              _sexualOrientation.isEmpty ||
              _headline.text.trim().isEmpty ||
              _bio.text.trim().isEmpty) {
            throw 'Display Name, Orientation, Headline and Bio are required.';
          }
          break;

        case 2: // Physical
          break;

        case 3: // Background
          if (_jobTitle.text.trim().isEmpty || _nationality.text.trim().isEmpty || _languages.isEmpty) {
            throw 'Job Title, Nationality and Languages are required.';
          }
          break;

        case 4: // Lifestyle
          break;

        case 5: // Favourites & Hobbies
          if (_favFood.isEmpty || _favMusic.isEmpty || _hobbies.isEmpty) {
            throw 'Please select at least one Favourite Food, Music and Hobby.';
          }
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
          if (_city.text.trim().isEmpty || _country.text.trim().isEmpty) {
            throw 'City and Country are required to complete onboarding.';
          }
          await api.updateLocation(7.8731, 80.7718, _city.text.trim(), _country.text.trim());
          if (widget.mode == 'onboarding') {
            await api.onboardingComplete();
          }
          widget.onComplete();
          return;
      }

      // If we are on steps 1 through 5, send the ENTIRE profileBody (all attributes matching web exactly)!
      if (_currentStep >= 1 && _currentStep <= 5) {
        final profileBody = _buildProfileBody();
        await api.updateProfileMe(profileBody);
      }

      // Progress step or show success message in edit mode
      if (widget.mode == 'edit') {
        setState(() {
          _message = 'Section updated successfully.';
        });
      } else {
        setState(() {
          _currentStep++;
        });
      }
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _skipOnboarding() async {
    setState(() {
      _saving = true;
      _message = null;
    });

    final api = YaaroScope.of(context);
    try {
      // 1. Prefill display name from first name or default
      final defaultDisplayName = _displayName.text.trim().isNotEmpty
          ? _displayName.text.trim()
          : (api.user?.firstName ?? 'User');
      final defaultBio = _bio.text.trim().isNotEmpty ? _bio.text.trim() : 'Hey! I am using Yaaro0.';

      // 2. We need location
      final defaultCity = _city.text.trim().isNotEmpty ? _city.text.trim() : 'Colombo';
      final defaultCountry = _country.text.trim().isNotEmpty ? _country.text.trim() : 'Sri Lanka';

      // 3. Make sure we have at least 2 photos in the DB.
      if (_photos.length < 2) {
        final needed = 2 - _photos.length;
        const pinkPlaceholder = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAAANElEQVR42u3PMQEAAADCoPdPbQ43oAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAO4GT0wAAQsmc94AAAAASUVORK5CYII=';
        const bluePlaceholder = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAQAAAAD/E/3AAAAJElEQVR42mN8/58BCwYeDTxGCUYJRglGCUYJRglGCUYJRglG/wAArV8Q1fep2gAAAABJRU5ErkJggg==';

        if (needed >= 1) {
          await api.uploadPhoto(pinkPlaceholder);
        }
        if (needed >= 2) {
          await api.uploadPhoto(bluePlaceholder);
        }

        final photosPayload = await api.getProfilePhotos();
        _photos = photosPayload.map((p) => p['url']?.toString() ?? '').toList();
      }

      // 4. Save profile fields
      final profileBody = {
        'displayName': defaultDisplayName,
        'pronouns': _pronouns.text.trim(),
        'sexualOrientation': _sexualOrientation.isNotEmpty ? _sexualOrientation : ['Straight'],
        'headline': _headline.text.trim().isNotEmpty ? _headline.text.trim() : 'Hello Yaaro0!',
        'bio': defaultBio,
        'heightCm': _heightCm.toInt(),
        'bodyType': _bodyType,
        'ethnicity': _ethnicity.isNotEmpty ? _ethnicity : ['Mixed'],
        'hairColour': _hairColour,
        'eyeColour': _eyeColour,
        'education': _education,
        'jobTitle': _jobTitle.text.trim().isNotEmpty ? _jobTitle.text.trim() : 'Member',
        'company': _company.text.trim(),
        'industry': _industry,
        'religion': _religion,
        'nationality': _nationality.text.trim().isNotEmpty ? _nationality.text.trim() : 'Global citizen',
        'languages': _languages.isNotEmpty ? _languages : ['English'],
        'smoking': _smoking,
        'drinking': _drinking,
        'exercise': _exercise,
        'diet': _diet,
        'sleepSchedule': _sleepSchedule,
        'livingSituation': _livingSituation,
        'hasChildren': _hasChildren,
        'wantsChildren': _wantsChildren,
        'hasPets': _hasPets,
        'wantsPets': _wantsPets,
        'favPet': _favPet,
        'favColour': _favColour,
        'favFood': _favFood.isNotEmpty ? _favFood : ['Rice & curry'],
        'favMusic': _favMusic.isNotEmpty ? _favMusic : ['Indie'],
        'favMovieGenre': _favMovieGenre.isNotEmpty ? _favMovieGenre : ['Comedy'],
        'hobbies': _hobbies.isNotEmpty ? _hobbies : ['Travel'],
        'interests': {'hobbies': _hobbies.isNotEmpty ? _hobbies : ['Travel']},
        'loveLanguage': _loveLanguage,
        'relationshipGoal': _relationshipGoal,
      };

      await api.updateProfileMe(profileBody);

      // 5. Save location
      await api.updateLocation(6.9271, 79.8612, defaultCity, defaultCountry);

      // 6. Save preferences
      await api.updatePreferences({
        'showGender': _showGender,
        'minAge': _minAge.toInt(),
        'maxAge': _maxAge.toInt(),
        'maxDistanceKm': _maxDistanceKm.toInt(),
      });

      // 7. Complete onboarding
      await api.onboardingComplete();
      await api.refreshSession();
      if (!mounted) return;
      widget.onComplete();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'Failed to skip onboarding: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
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

    return Scaffold(
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
        GridView.builder(
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
                onTap: _saving ? null : _showPhotoUploadUnavailable,
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
      ],
    );
  }

  Widget _buildAboutStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Introduce yourself', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        AppTextField(controller: _displayName, label: 'Display Name'),
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
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'About You (Bio)',
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
            Text('${_heightCm.toInt()} cm ($_heightFtLabel)', style: const TextStyle(color: YaaroColors.rose, fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
        Slider(
          value: _heightCm,
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
        AppTextField(controller: _nationality, label: 'Nationality'),
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
            Text('${_minAge.toInt()} - ${_maxAge.toInt()} years old', style: const TextStyle(color: YaaroColors.rose, fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
        RangeSlider(
          values: RangeValues(_minAge, _maxAge),
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
            Text('${_maxDistanceKm.toInt()} km', style: const TextStyle(color: YaaroColors.rose, fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
        Slider(
          value: _maxDistanceKm,
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
        AppTextField(controller: _city, label: 'City'),
        const SizedBox(height: 12),
        AppTextField(controller: _country, label: 'Country'),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _city.text = 'Colombo';
              _country.text = 'Sri Lanka';
              _message = 'Simulated location successfully retrieved!';
            });
          },
          icon: const Icon(Icons.my_location, color: YaaroColors.teal),
          label: const Text('Retrieve Current Location', style: TextStyle(color: Colors.white)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            side: const BorderSide(color: YaaroColors.line),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: YaaroColors.surface,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
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
