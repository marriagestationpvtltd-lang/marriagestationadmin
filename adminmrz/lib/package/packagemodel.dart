class PackageListResponse {
  final bool success;
  final int totalRecords;
  final List<Package> data;

  PackageListResponse({
    required this.success,
    required this.totalRecords,
    required this.data,
  });

  factory PackageListResponse.fromJson(Map<String, dynamic> json) {
    final status = json['status'];
    final success = status == 200 || status?.toString() == '200';
    return PackageListResponse(
      success: success,
      totalRecords: json['totalRecords'] is int ? json['totalRecords'] : int.tryParse(json['totalRecords']?.toString() ?? '') ?? 0,
      data: List<Package>.from((json['recordList'] ?? []).map((x) => Package.fromJson(x))),
    );
  }
}

class Package {
  final int id;
  final String name;
  final int isActive;
  final String? createdDate;
  final String? baseAmount;
  final dynamic facility;
  final dynamic duration;

  Package({
    required this.id,
    required this.name,
    required this.isActive,
    this.createdDate,
    this.baseAmount,
    this.facility,
    this.duration,
  });

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      isActive: json['isActive'] is int ? json['isActive'] : int.tryParse(json['isActive']?.toString() ?? '') ?? 1,
      createdDate: json['createdDate']?.toString(),
      baseAmount: json['baseAmount']?.toString(),
      facility: json['facility'],
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive,
      if (baseAmount != null) 'baseAmount': baseAmount,
      if (facility != null) 'facility': facility,
      if (duration != null) 'duration': duration,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      if (baseAmount != null) 'baseAmount': baseAmount,
      if (facility != null) 'facility': facility,
      if (duration != null) 'duration': duration,
    };
  }

  double get numericPrice {
    try {
      return double.parse(baseAmount?.replaceAll('Rs ', '').replaceAll(',', '').trim() ?? '0');
    } catch (e) {
      return 0.0;
    }
  }
}

class CreatePackageResponse {
  final bool success;
  final String message;
  final int packageId;

  CreatePackageResponse({
    required this.success,
    required this.message,
    required this.packageId,
  });

  factory CreatePackageResponse.fromJson(Map<String, dynamic> json) {
    final status = json['status'];
    return CreatePackageResponse(
      success: status == 200 || status?.toString() == '200',
      message: json['message']?.toString() ?? '',
      packageId: json['recordList'] is List && (json['recordList'] as List).isNotEmpty
          ? (json['recordList'][0]['id'] is int
              ? json['recordList'][0]['id'] as int
              : int.tryParse(json['recordList'][0]['id']?.toString() ?? '') ?? 0)
          : 0,
    );
  }
}
