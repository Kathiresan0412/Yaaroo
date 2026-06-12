import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/discovery_filters.dart';

/// Available gender options for the discovery filter.
const List<String> kFilterGenderOptions = ['Male', 'Female', 'Other'];

/// Provider that loads the current user's saved discovery filters from Firestore.
///
/// Returns default [DiscoveryFilters] if no saved preferences exist in the
/// User_Document (Requirement 12.7).
///
/// Times out after 10 seconds with an error if Firestore does not respond
/// (Requirement 17.5).
final savedFiltersProvider = FutureProvider<DiscoveryFilters>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const DiscoveryFilters();

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get()
      .timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException(
          'Filters did not load within 10 seconds. Please check your connection.',
          const Duration(seconds: 10),
        ),
      );

  if (!doc.exists || doc.data() == null) return const DiscoveryFilters();

  final data = doc.data()!;

  // If no filter fields exist, return defaults (Requirement 12.7)
  if (data['ageMin'] == null &&
      data['ageMax'] == null &&
      data['maxDistance'] == null &&
      data['interestedInGenders'] == null) {
    return const DiscoveryFilters();
  }

  return DiscoveryFilters(
    ageMin: data['ageMin'] as int? ?? 18,
    ageMax: data['ageMax'] as int? ?? 99,
    maxDistance: data['maxDistance'] as int? ?? 50,
    interestedIn: data['interestedInGenders'] != null
        ? List<String>.from(data['interestedInGenders'] as List)
        : const ['Male', 'Female', 'Other'],
  );
});

/// Discovery filters screen allowing users to set age range, max distance,
/// and gender preferences.
///
/// Persists filter values to the User_Document on confirm (Requirement 12.4).
/// Applies default values when no saved filters exist (Requirement 12.7).
class FilterScreen extends ConsumerStatefulWidget {
  const FilterScreen({super.key});

  @override
  ConsumerState<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends ConsumerState<FilterScreen> {
  // Filter state
  RangeValues _ageRange = const RangeValues(18, 99);
  double _maxDistance = 50;
  Set<String> _selectedGenders = {'Male', 'Female', 'Other'};

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  /// Loads saved filters from Firestore or applies defaults.
  Future<void> _loadFilters() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _ageRange = RangeValues(
            (data['ageMin'] as int? ?? 18).toDouble(),
            (data['ageMax'] as int? ?? 99).toDouble(),
          );
          _maxDistance = (data['maxDistance'] as int? ?? 50).toDouble();
          _selectedGenders = data['interestedInGenders'] != null
              ? Set<String>.from(data['interestedInGenders'] as List)
              : {'Male', 'Female', 'Other'};
        });
      }
      // If no data, defaults are already set in field initializers.
    } catch (e) {
      // On error, use defaults — user can still adjust and save.
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Toggles a gender selection. Ensures at least one remains selected
  /// (Requirement 12.5).
  void _toggleGender(String gender) {
    setState(() {
      if (_selectedGenders.contains(gender)) {
        // Prevent deselecting the last gender
        if (_selectedGenders.length > 1) {
          _selectedGenders.remove(gender);
        }
      } else {
        _selectedGenders.add(gender);
      }
      _error = null;
    });
  }

  /// Saves filter preferences to the User_Document in Firestore
  /// (Requirement 12.4).
  Future<void> _saveFilters() async {
    // Validate at least one gender is selected (Requirement 12.5)
    if (_selectedGenders.isEmpty) {
      setState(() => _error = 'Please select at least one gender preference.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Not authenticated. Please sign in again.';
          _isSaving = false;
        });
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'ageMin': _ageRange.start.round(),
        'ageMax': _ageRange.end.round(),
        'maxDistance': _maxDistance.round(),
        'interestedInGenders': _selectedGenders.toList(),
      });

      // Invalidate the saved filters provider so other parts of the app
      // get the updated values.
      ref.invalidate(savedFiltersProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to save filters. Please try again.';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discovery Filters'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAgeRangeSection(),
                          const SizedBox(height: 32),
                          _buildDistanceSection(),
                          const SizedBox(height: 32),
                          _buildGenderSection(),
                          if (_error != null) ...[
                            const SizedBox(height: 24),
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  _buildConfirmButton(),
                ],
              ),
            ),
    );
  }

  /// Builds the age range slider section (Requirement 12.1).
  Widget _buildAgeRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Age Range',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              '${_ageRange.start.round()} - ${_ageRange.end.round()}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFFF4F6D),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: _ageRange,
          min: 18,
          max: 99,
          divisions: 81,
          activeColor: const Color(0xFFFF4F6D),
          inactiveColor: const Color(0xFFFF4F6D).withOpacity(0.2),
          labels: RangeLabels(
            _ageRange.start.round().toString(),
            _ageRange.end.round().toString(),
          ),
          onChanged: (values) {
            setState(() => _ageRange = values);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '18',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              '99',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the max distance slider section (Requirement 12.2).
  Widget _buildDistanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Maximum Distance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              '${_maxDistance.round()} km',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFFF4F6D),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _maxDistance,
          min: 1,
          max: 100,
          divisions: 99,
          activeColor: const Color(0xFFFF4F6D),
          inactiveColor: const Color(0xFFFF4F6D).withOpacity(0.2),
          label: '${_maxDistance.round()} km',
          onChanged: (value) {
            setState(() => _maxDistance = value);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1 km',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              '100 km',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the gender preference toggle section (Requirement 12.3).
  Widget _buildGenderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interested In',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select at least one',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: kFilterGenderOptions.map((gender) {
            final isSelected = _selectedGenders.contains(gender);
            return FilterChip(
              label: Text(gender),
              selected: isSelected,
              selectedColor: const Color(0xFFFF4F6D).withOpacity(0.2),
              checkmarkColor: const Color(0xFFFF4F6D),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFFFF4F6D) : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              onSelected: (_) => _toggleGender(gender),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Builds the confirm/save button at the bottom.
  Widget _buildConfirmButton() {
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveFilters,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF4F6D),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
              : const Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
