class DashboardResponse {
  final bool success;
  final DashboardData data;

  DashboardResponse({required this.success, required this.data});

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    final success = json['success'] == true;
    // api9 returns: { success, dashboard: { users: {...}, payments: {...} } }
    final dashboard = json['dashboard'] as Map<String, dynamic>? ?? {};
    return DashboardResponse(
      success: success,
      data: DashboardData.fromJson(dashboard),
    );
  }
}

class DashboardData {
  final int todayRegistration;
  final int monthlyRegistration;
  final int todayProposal;
  final int monthlyProposal;
  final List<RecentUser> recentUsers;

  DashboardData({
    required this.todayRegistration,
    required this.monthlyRegistration,
    required this.todayProposal,
    required this.monthlyProposal,
    required this.recentUsers,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final users = json['users'] as Map<String, dynamic>? ?? {};
    return DashboardData(
      todayRegistration: _parseInt(users['todayRegistered']),
      monthlyRegistration: _parseInt(users['thisMonthRegistered']),
      todayProposal: _parseInt(json['todayProposal']),
      monthlyProposal: _parseInt(json['monthlyProposal']),
      recentUsers: ((users['recentUsers'] ?? json['recentUserResult'] ?? []) as List)
          .map((u) => RecentUser.fromJson(u as Map<String, dynamic>))
          .toList(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class RecentUser {
  final int id;
  final String firstName;
  final String? middleName;
  final String? lastName;
  final String? email;
  final String? gender;
  final int isActive;
  final String? createdDate;

  RecentUser({
    required this.id,
    required this.firstName,
    this.middleName,
    this.lastName,
    this.email,
    this.gender,
    required this.isActive,
    this.createdDate,
  });

  factory RecentUser.fromJson(Map<String, dynamic> json) {
    return RecentUser(
      id: DashboardData._parseInt(json['id']),
      firstName: json['firstName']?.toString() ?? '',
      middleName: json['middleName']?.toString(),
      lastName: json['lastName']?.toString(),
      email: json['email']?.toString(),
      gender: json['gender']?.toString(),
      isActive: DashboardData._parseInt(json['isActive']),
      createdDate: json['createdDate']?.toString(),
    );
  }

  String get fullName {
    final parts = [firstName, middleName, lastName]
        .where((p) => p?.isNotEmpty ?? false)
        .toList();
    return parts.join(' ');
  }
}
