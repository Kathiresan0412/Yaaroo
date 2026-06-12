import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/storage_service.dart';

/// Preset interest options available for user selection (22 items).
const List<String> kPresetInterests = [
  'Travel',
  'Music',
  'Movies',
  'Sports',
  'Cooking',
  'Reading',
  'Photography',
  'Fitness',
  'Gaming',
  'Art',
  'Dancing',
  'Hiking',
  'Yoga',
  'Technology',
  'Fashion',
  'Food',
  'Pets',
  'Nature',
  'Comedy',
  'Coffee',
  'Writing',
  'Volunteering',
];

/// Gender options for profile selection.
const List<String> kGenderOptions = ['Male', 'Female', 'Other'];

/// SharedPreferences key prefix for profile setup persistence.
const String _prefKeyPrefix = 'profile_setup_';

/// Multi-step profile setup flow with 5 steps:
/// 1. Name, Age, Gender
/// 2. Photos (min 1, max 6)
/// 3. Bio (0-500 chars)
/// 4. Interests (3-10 from preset list)
/// 5. Location permission
///
/// Validates each step before allowing progression.
/// Persists completed step data locally via SharedPreferences.
/// Saves the complete UserProfile to Firestore on final step completion.
class ProfileSetupFlow extends ConsumerStatefulWidget {
  const ProfileSetupFlow({super.key});

  @override
  ConsumerState<ProfileSetupFlow> createState() => _ProfileSetupFlowState();
}

class _ProfileSetupFlowState extends ConsumerState<ProfileSetupFlow> {
  int _currentStep = 0;
  bool _isSaving = false;

  // Step 1: Name, Age, Gender
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender;
  String? _step1Error;

  // Step 2: Photos
  final List<String> _photoUrls = [];
  String? _step2Error;

  // Step 3: Bio
  final _bioController = TextEditingController();
  String? _step3Error;

  // Step 4: Interests
  final Set<String> _selectedInterests = {};
  String? _step4Error;

  // Step 5: Location
  Position? _currentPosition;
  String? _step5Error;
  bool _locationGranted = false;

  @override
  void initState() {
    super.initState();
    _loadPersistedData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  /// Loads any previously saved step data from SharedPreferences.
  Future<void> _loadPersistedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('${_prefKeyPrefix}data');
    if (savedData != null) {
      try {
        final map = jsonDecode(savedData) as Map<String, dynamic>;
        setState(() {
          _nameController.text = map['name'] as String? ?? '';
          _ageController.text = map['age'] != null ? map['age'].toString() : '';
          _selectedGender = map['gender'] as String?;
          if (map['photos'] != null) {
            _photoUrls
              ..clear()
              ..addAll(List<String>.from(map['photos'] as List));
          }
          _bioController.text = map['bio'] as String? ?? '';
          if (map['interests'] != null) {
            _selectedInterests
              ..clear()
              ..addAll(Set<String>.from(map['interests'] as List));
          }
          _currentStep = (map['currentStep'] as int?) ?? 0;
        });
      } catch (_) {
        // Corrupted data — start fresh.
      }
    }
  }

  /// Persists current form data to SharedPreferences.
  Future<void> _persistData() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'name': _nameController.text,
      'age': int.tryParse(_ageController.text),
      'gender': _selectedGender,
      'photos': _photoUrls,
      'bio': _bioController.text,
      'interests': _selectedInterests.toList(),
      'currentStep': _currentStep,
    };
    await prefs.setString('${_prefKeyPrefix}data', jsonEncode(map));
  }

  /// Clears persisted setup data after successful completion.
  Future<void> _clearPersistedData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_prefKeyPrefix}data');
  }

  // ──────────────────────────────────────────────
  // Validation
  // ──────────────────────────────────────────────

  bool _validateStep1() {
    final name = _nameController.text.trim();
    final ageText = _ageController.text.trim();
    final age = int.tryParse(ageText);

    if (name.isEmpty || name.length > 50) {
      setState(() => _step1Error = 'Name must be between 1 and 50 characters.');
      return false;
    }
    if (age == null || age < 18 || age > 99) {
      setState(() => _step1Error = 'Age must be between 18 and 99.');
      return false;
    }
    if (_selectedGender == null) {
      setState(() => _step1Error = 'Please select a gender.');
      return false;
    }
    setState(() => _step1Error = null);
    return true;
  }

  bool _validateStep2() {
    if (_photoUrls.isEmpty) {
      setState(() => _step2Error = 'Please add at least 1 photo.');
      return false;
    }
    if (_photoUrls.length > 6) {
      setState(() => _step2Error = 'Maximum 6 photos allowed.');
      return false;
    }
    setState(() => _step2Error = null);
    return true;
  }

  bool _validateStep3() {
    final bio = _bioController.text;
    if (bio.length > 500) {
      setState(() => _step3Error = 'Bio must be 500 characters or less.');
      return false;
    }
    setState(() => _step3Error = null);
    return true;
  }

  bool _validateStep4() {
    if (_selectedInterests.length < 3) {
      setState(() => _step4Error = 'Please select at least 3 interests.');
      return false;
    }
    if (_selectedInterests.length > 10) {
      setState(() => _step4Error = 'Maximum 10 interests allowed.');
      return false;
    }
    setState(() => _step4Error = null);
    return true;
  }

  bool _validateStep5() {
    if (!_locationGranted || _currentPosition == null) {
      setState(
          () => _step5Error = 'Location permission is required for discovery.');
      return false;
    }
    setState(() => _step5Error = null);
    return true;
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _validateStep1();
      case 1:
        return _validateStep2();
      case 2:
        return _validateStep3();
      case 3:
        return _validateStep4();
      case 4:
        return _validateStep5();
      default:
        return false;
    }
  }

  // ──────────────────────────────────────────────
  // Actions
  // ──────────────────────────────────────────────

  void _onNext() {
    if (!_validateCurrentStep()) return;
    setState(() => _currentStep++);
    _persistData();
  }

  void _onBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _requestLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _step5Error =
            'Location services are disabled. Please enable them in settings.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() => _step5Error =
            'Location permission denied. Location is required for discovery.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _step5Error =
            'Location permission permanently denied. Please enable it in app settings.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _currentPosition = position;
        _locationGranted = true;
        _step5Error = null;
      });
    } catch (e) {
      setState(() => _step5Error = 'Failed to get location. Please try again.');
    }
  }

  Future<void> _onComplete() async {
    if (!_validateStep5()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _step5Error = 'Not authenticated. Please sign in again.';
          _isSaving = false;
        });
        return;
      }

      final now = DateTime.now();
      final location =
          GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude);

      // Compute a simple geohash placeholder — in production Geoflutterfire2
      // handles proper geohash encoding. For now, store lat/lon based hash.
      final geohash =
          '${_currentPosition!.latitude.toStringAsFixed(3)}_${_currentPosition!.longitude.toStringAsFixed(3)}';

      final profileData = {
        'uid': user.uid,
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'bio': _bioController.text,
        'gender': _selectedGender,
        'interestedIn': _selectedGender == 'Male'
            ? 'Female'
            : _selectedGender == 'Female'
                ? 'Male'
                : 'Male,Female,Other',
        'photos': _photoUrls,
        'interests': _selectedInterests.toList(),
        'location': location,
        'geohash': geohash,
        'createdAt': Timestamp.fromDate(now),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(profileData, SetOptions(merge: true));

      await _clearPersistedData();

      // The auth gate will automatically route to HomeScreen once the
      // profile provider detects the complete profile.
    } catch (e) {
      setState(() {
        _step5Error = 'Failed to save profile: ${e.toString()}';
        _isSaving = false;
      });
    }
  }

  // ──────────────────────────────────────────────
  // Photo management — wired to StorageService and image_picker
  // ──────────────────────────────────────────────

  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingPhoto = false;

  void _addPhotoUrl() async {
    // In full implementation, this opens image_picker and uploads via
    // StorageService.
    if (_photoUrls.length >= 6) {
      setState(() => _step2Error = 'Maximum 6 photos reached.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (pickedFile == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final storageService = FirebasePhotoStorageService(
        storage: FirebaseStorage.instance,
      );
      final downloadUrl = await storageService.uploadPhoto(
        user.uid,
        File(pickedFile.path),
      );

      setState(() {
        _photoUrls.add(downloadUrl);
        _step2Error = null;
        _isUploadingPhoto = false;
      });
      _persistData();
    } on PhotoValidationException catch (e) {
      setState(() {
        _step2Error = e.message;
        _isUploadingPhoto = false;
      });
    } on PhotoUploadException catch (e) {
      setState(() {
        _step2Error = e.message;
        _isUploadingPhoto = false;
      });
    } catch (e) {
      setState(() {
        _step2Error = 'Upload failed. Please try again.';
        _isUploadingPhoto = false;
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photoUrls.removeAt(index);
    });
    _persistData();
  }

  // ──────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(signOutProvider)(),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildCurrentStep(),
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    const stepLabels = ['Info', 'Photos', 'Bio', 'Interests', 'Location'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(5, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Column(
              children: [
                Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFFFF4F6D)
                        : isActive
                            ? const Color(0xFFFF4F6D).withOpacity(0.5)
                            : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stepLabels[index],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive || isCompleted
                        ? const Color(0xFFFF4F6D)
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      case 4:
        return _buildStep5();
      default:
        return const SizedBox.shrink();
    }
  }

  // ──────────────────────────────────────────────
  // Step 1: Name, Age, Gender
  // ──────────────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About You',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tell us a bit about yourself.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          maxLength: 50,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Enter your name',
            border: OutlineInputBorder(),
            counterText: '',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Age',
            hintText: '18 - 99',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Gender',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: kGenderOptions.map((gender) {
            final isSelected = _selectedGender == gender;
            return ChoiceChip(
              label: Text(gender),
              selected: isSelected,
              selectedColor: const Color(0xFFFF4F6D).withOpacity(0.2),
              onSelected: (selected) {
                setState(() => _selectedGender = selected ? gender : null);
              },
            );
          }).toList(),
        ),
        if (_step1Error != null) ...[
          const SizedBox(height: 12),
          Text(
            _step1Error!,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ],
      ],
    );
  }

  // ──────────────────────────────────────────────
  // Step 2: Photos
  // ──────────────────────────────────────────────

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Photos',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add at least 1 photo (max 6).',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _photoUrls.length + (_photoUrls.length < 6 ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _photoUrls.length) {
              // Add button (or upload indicator)
              return GestureDetector(
                onTap: _isUploadingPhoto ? null : _addPhotoUrl,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isUploadingPhoto
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : const Icon(Icons.add_a_photo, color: Colors.grey),
                  ),
                ),
              );
            }
            // Photo tile
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey.shade200,
                    child: _photoUrls[index].startsWith('http')
                        ? Image.network(
                            _photoUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image, color: Colors.grey),
                          ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removePhoto(index),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        if (_step2Error != null) ...[
          const SizedBox(height: 12),
          Text(
            _step2Error!,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ],
      ],
    );
  }

  // ──────────────────────────────────────────────
  // Step 3: Bio
  // ──────────────────────────────────────────────

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Bio',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Write a short bio about yourself (optional, max 500 characters).',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _bioController,
          maxLength: 500,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Tell others about yourself...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        if (_step3Error != null) ...[
          const SizedBox(height: 12),
          Text(
            _step3Error!,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ],
      ],
    );
  }

  // ──────────────────────────────────────────────
  // Step 4: Interests
  // ──────────────────────────────────────────────

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Interests',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select 3 to 10 interests.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_selectedInterests.length} selected',
          style: TextStyle(
            fontSize: 13,
            color: _selectedInterests.length >= 3 &&
                    _selectedInterests.length <= 10
                ? const Color(0xFFFF4F6D)
                : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kPresetInterests.map((interest) {
            final isSelected = _selectedInterests.contains(interest);
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              selectedColor: const Color(0xFFFF4F6D).withOpacity(0.2),
              checkmarkColor: const Color(0xFFFF4F6D),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (_selectedInterests.length < 10) {
                      _selectedInterests.add(interest);
                      _step4Error = null;
                    }
                  } else {
                    _selectedInterests.remove(interest);
                  }
                });
              },
            );
          }).toList(),
        ),
        if (_step4Error != null) ...[
          const SizedBox(height: 12),
          Text(
            _step4Error!,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ],
      ],
    );
  }

  // ──────────────────────────────────────────────
  // Step 5: Location Permission
  // ──────────────────────────────────────────────

  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enable Location',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'We need your location to show you people nearby. '
          'This is required to use the app.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              Icon(
                _locationGranted
                    ? Icons.location_on
                    : Icons.location_off_outlined,
                size: 64,
                color: _locationGranted ? const Color(0xFFFF4F6D) : Colors.grey,
              ),
              const SizedBox(height: 16),
              if (_locationGranted)
                Text(
                  'Location enabled ✓',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFFFF4F6D),
                        fontWeight: FontWeight.w600,
                      ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _requestLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Grant Location Permission'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4F6D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
            ],
          ),
        ),
        if (_step5Error != null) ...[
          const SizedBox(height: 16),
          Center(
            child: Text(
              _step5Error!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  // ──────────────────────────────────────────────
  // Navigation Buttons
  // ──────────────────────────────────────────────

  Widget _buildNavigationButtons() {
    final isLastStep = _currentStep == 4;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _onBack,
              child: const Text('Back'),
            ),
          const Spacer(),
          if (isLastStep)
            ElevatedButton(
              onPressed: _isSaving ? null : _onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4F6D),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Complete'),
            )
          else
            ElevatedButton(
              onPressed: _onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4F6D),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Next'),
            ),
        ],
      ),
    );
  }
}
