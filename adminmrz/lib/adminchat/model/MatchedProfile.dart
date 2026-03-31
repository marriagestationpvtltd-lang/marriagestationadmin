class MatchedProfile {
  final int id;
  final String firstName;
  final String lastName;
  final String memberid;
  final double matchingPercentage;
  final bool isPaid;
  final bool isOnline;
  final String occupation;
  final String education;
  final String country;
  final String marit;
  final String gender;
  final int age;
  final String profilePicture; // Add this field

  MatchedProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.memberid,
    required this.matchingPercentage,
    required this.isPaid,
    required this.isOnline,
    required this.occupation,
    required this.education,
    required this.country,
    required this.marit,
    required this.gender,
    required this.age,
    required this.profilePicture, // Add this
  });

  factory MatchedProfile.fromJson(Map<String, dynamic> json) {
    return MatchedProfile(
      id: json['id'] ?? 0,
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      memberid: json['member_id']?.toString() ?? '',
      matchingPercentage: (json['matching_percentage'] ?? 0).toDouble(),
      isPaid: json['is_paid'] ?? false,
      isOnline: json['is_online'] ?? false,
      occupation: json['occupation']?.toString() ?? '',
      education: json['education']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      marit: json['marital_status']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      age: json['age'] ?? 0,
      profilePicture: json['profile_picture']?.toString() ?? '', // Add this
    );
  }
}