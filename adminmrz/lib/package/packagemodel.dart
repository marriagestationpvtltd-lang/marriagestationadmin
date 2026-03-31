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
    // api9 returns: { success, count, data: [...] }
    final success = json['success'] == true;
    final count = json['count'] is int ? json['count'] : int.tryParse(json['count']?.toString() ?? '') ?? 0;
    return PackageListResponse(
      success: success,
      totalRecords: count,
      data: List<Package>.from((json['data'] ?? []).map((x) => Package.fromJson(x))),
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
  final String description;
  final String price;

  Package({
    required this.id,
    required this.name,
    this.isActive = 1,
    this.createdDate,
    this.baseAmount,
    this.facility,
    this.duration,
    this.description = '',
    this.price = '',
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
      description: json['description']?.toString() ?? '',
      price: json['price']?.toString() ?? json['baseAmount']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive,
      'description': description,
      if (price.isNotEmpty) 'price': price,
      if (baseAmount != null) 'baseAmount': baseAmount,
      if (facility != null) 'facility': facility,
      if (duration != null) 'duration': duration,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'description': description,
      if (price.isNotEmpty) 'price': price,
      if (baseAmount != null) 'baseAmount': baseAmount,
      if (facility != null) 'facility': facility,
      if (duration != null) 'duration': duration,
    };
  }

  /// Numeric price parsed from [price] or [baseAmount].
  double get numericPrice {
    final raw = price.isNotEmpty ? price : (baseAmount ?? '');
    try {
      return double.parse(raw.replaceAll('Rs ', '').replaceAll(',', '').trim());
    } catch (e) {
      return 0.0;
    }
  }

  static final _durationRegExp = RegExp(r'(\d+)');

  /// Duration in months parsed from the [duration] string (e.g. '3 Month' → 3).
  int get durationInMonths {
    if (duration == null) return 0;
    final match = _durationRegExp.firstMatch(duration.toString());
    return match != null ? int.tryParse(match.group(1) ?? '') ?? 0 : 0;
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
    // api9 returns: { success, message, data: { id: ... } }
    return CreatePackageResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      packageId: json['data'] is Map
          ? (json['data']['id'] is int
              ? json['data']['id'] as int
              : int.tryParse(json['data']['id']?.toString() ?? '') ?? 0)
          : 0,
    );
  }
}
