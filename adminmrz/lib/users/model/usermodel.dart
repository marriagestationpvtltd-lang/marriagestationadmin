import 'package:flutter/material.dart';

class UserListResponse {
  final bool success;
  final int totalRecords;
  final List<User> data;

  UserListResponse({
    required this.success,
    required this.totalRecords,
    required this.data,
  });

  factory UserListResponse.fromJson(Map<String, dynamic> json) {
    final status = json['status'];
    final success = status == 200 || status?.toString() == '200';
    return UserListResponse(
      success: success,
      totalRecords: json['totalRecords'] is int ? json['totalRecords'] : int.tryParse(json['totalRecords']?.toString() ?? '') ?? 0,
      data: List<User>.from((json['recordList'] ?? []).map((x) => User.fromJson(x))),
    );
  }
}

class User {
  int id;
  String firstName;
  String? middleName;
  String lastName;
  String email;
  String? contactNo;
  String gender;
  int isDisable;
  int? isVerified;
  int isActive;
  int isDelete;
  String? createdDate;
  int? roleId;
  String usertype;
  int isOnline;
  String? profilePicture;
  String? lastLogin;
  String privacy;

  User({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    this.contactNo,
    required this.gender,
    required this.isDisable,
    this.isVerified,
    required this.isActive,
    required this.isDelete,
    this.createdDate,
    this.roleId,
    this.usertype = 'free',
    this.isOnline = 0,
    this.profilePicture,
    this.lastLogin,
    this.privacy = 'public',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      firstName: json['firstName']?.toString() ?? '',
      middleName: json['middleName']?.toString(),
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      contactNo: json['contactNo']?.toString(),
      gender: json['gender']?.toString() ?? '',
      isDisable: json['isDisable'] is int ? json['isDisable'] : int.tryParse(json['isDisable']?.toString() ?? '') ?? 0,
      isVerified: json['isVerified'] is int ? json['isVerified'] : int.tryParse(json['isVerified']?.toString() ?? ''),
      isActive: json['isActive'] is int ? json['isActive'] : int.tryParse(json['isActive']?.toString() ?? '') ?? 1,
      isDelete: json['isDelete'] is int ? json['isDelete'] : int.tryParse(json['isDelete']?.toString() ?? '') ?? 0,
      createdDate: json['createdDate']?.toString(),
      roleId: json['roleId'] is int ? json['roleId'] : int.tryParse(json['roleId']?.toString() ?? ''),
      usertype: json['usertype']?.toString() ?? json['userType']?.toString() ?? 'free',
      isOnline: json['isOnline'] is int ? json['isOnline'] : int.tryParse(json['isOnline']?.toString() ?? '') ?? 0,
      profilePicture: json['profilePicture']?.toString() ?? json['profile_picture']?.toString(),
      lastLogin: json['lastLogin']?.toString() ?? json['last_login']?.toString(),
      privacy: json['privacy']?.toString() ?? 'public',
    );
  }

  String get fullName {
    final parts = [firstName, middleName, lastName]
        .where((p) => p?.isNotEmpty ?? false)
        .toList();
    return parts.join(' ');
  }

  bool get hasProfilePicture => profilePicture != null && profilePicture!.isNotEmpty;

  bool get isPending => isVerified == null;

  /// Lowercase status key used for filtering ('pending', 'approved', 'rejected', 'not_uploaded').
  String get status {
    if (isActive == 0) return 'rejected';
    if (isVerified == null) return 'pending';
    if (isVerified == 1) return 'approved';
    return 'not_uploaded';
  }

  String get formattedStatus {
    if (isActive == 0) return 'INACTIVE';
    if (isVerified == null) return 'PENDING';
    if (isVerified == 1) return 'VERIFIED';
    return 'ACTIVE';
  }

  Color get statusColor {
    if (isActive == 0) return Colors.red;
    if (isVerified == null) return Colors.orange;
    if (isVerified == 1) return Colors.green;
    return Colors.blue;
  }
}
