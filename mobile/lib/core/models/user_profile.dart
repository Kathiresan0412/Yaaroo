import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user profile document stored at `users/{uid}` in Firestore.
class UserProfile {
  final String uid;
  final String name;
  final int age;
  final String bio;
  final String gender;
  final String interestedIn;
  final List<String> photos;
  final List<String> interests;
  final GeoPoint location;
  final String geohash;
  final DateTime createdAt;

  // Optional filter fields
  final int? ageMin;
  final int? ageMax;
  final int? maxDistance;
  final List<String>? interestedInGenders;

  // Internal fields (not exposed to other users)
  final String? fcmToken;
  final String? email;
  final String? phoneNumber;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.age,
    required this.bio,
    required this.gender,
    required this.interestedIn,
    required this.photos,
    required this.interests,
    required this.location,
    required this.geohash,
    required this.createdAt,
    this.ageMin,
    this.ageMax,
    this.maxDistance,
    this.interestedInGenders,
    this.fcmToken,
    this.email,
    this.phoneNumber,
  });

  /// Converts this [UserProfile] to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'age': age,
      'bio': bio,
      'gender': gender,
      'interestedIn': interestedIn,
      'photos': photos,
      'interests': interests,
      'location': location,
      'geohash': geohash,
      'createdAt': Timestamp.fromDate(createdAt),
      if (ageMin != null) 'ageMin': ageMin,
      if (ageMax != null) 'ageMax': ageMax,
      if (maxDistance != null) 'maxDistance': maxDistance,
      if (interestedInGenders != null)
        'interestedInGenders': interestedInGenders,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    };
  }

  /// Creates a [UserProfile] from a Firestore document snapshot.
  factory UserProfile.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserProfile(
      uid: data['uid'] as String,
      name: data['name'] as String,
      age: data['age'] as int,
      bio: data['bio'] as String,
      gender: data['gender'] as String,
      interestedIn: data['interestedIn'] as String,
      photos: List<String>.from(data['photos'] as List),
      interests: List<String>.from(data['interests'] as List),
      location: data['location'] as GeoPoint,
      geohash: data['geohash'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      ageMin: data['ageMin'] as int?,
      ageMax: data['ageMax'] as int?,
      maxDistance: data['maxDistance'] as int?,
      interestedInGenders: data['interestedInGenders'] != null
          ? List<String>.from(data['interestedInGenders'] as List)
          : null,
      fcmToken: data['fcmToken'] as String?,
      email: data['email'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
    );
  }

  /// Creates a [UserProfile] from a raw map (useful for queries returning data directly).
  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'] as String,
      name: data['name'] as String,
      age: data['age'] as int,
      bio: data['bio'] as String,
      gender: data['gender'] as String,
      interestedIn: data['interestedIn'] as String,
      photos: List<String>.from(data['photos'] as List),
      interests: List<String>.from(data['interests'] as List),
      location: data['location'] as GeoPoint,
      geohash: data['geohash'] as String,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : data['createdAt'] as DateTime,
      ageMin: data['ageMin'] as int?,
      ageMax: data['ageMax'] as int?,
      maxDistance: data['maxDistance'] as int?,
      interestedInGenders: data['interestedInGenders'] != null
          ? List<String>.from(data['interestedInGenders'] as List)
          : null,
      fcmToken: data['fcmToken'] as String?,
      email: data['email'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
    );
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    int? age,
    String? bio,
    String? gender,
    String? interestedIn,
    List<String>? photos,
    List<String>? interests,
    GeoPoint? location,
    String? geohash,
    DateTime? createdAt,
    int? ageMin,
    int? ageMax,
    int? maxDistance,
    List<String>? interestedInGenders,
    String? fcmToken,
    String? email,
    String? phoneNumber,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      interestedIn: interestedIn ?? this.interestedIn,
      photos: photos ?? this.photos,
      interests: interests ?? this.interests,
      location: location ?? this.location,
      geohash: geohash ?? this.geohash,
      createdAt: createdAt ?? this.createdAt,
      ageMin: ageMin ?? this.ageMin,
      ageMax: ageMax ?? this.ageMax,
      maxDistance: maxDistance ?? this.maxDistance,
      interestedInGenders: interestedInGenders ?? this.interestedInGenders,
      fcmToken: fcmToken ?? this.fcmToken,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}
