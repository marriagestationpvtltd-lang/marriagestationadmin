class DashboardResponse {
  final bool success;
  final DashboardData dashboard;

  DashboardResponse({
    required this.success,
    required this.dashboard,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    final rawSuccess = json['success'];
    final rawString = rawSuccess?.toString().toLowerCase();
    final success = rawSuccess == true ||
        rawSuccess == 1 ||
        rawString == '1' ||
        rawString == 'true';
    return DashboardResponse(
      success: success,
      dashboard: DashboardData.fromJson(json['dashboard'] ?? {}),
    );
  }
}

class DashboardData {
  final UserStats users;
  final AddressStats permanentAddress;
  final PaymentStats payments;

  DashboardData({
    required this.users,
    required this.permanentAddress,
    required this.payments,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      users: UserStats.fromJson(json['users'] ?? {}),
      permanentAddress: AddressStats.fromJson(json['permanent_address'] ?? {}),
      payments: PaymentStats.fromJson(json['payments'] ?? {}),
    );
  }
}

class UserStats {
  final int total;
  final int todayRegistered;
  final int thisMonthRegistered;
  final int verified;
  final int unverified;
  final int active;
  final int online;
  final List<TypeCount> byType;
  final List<GenderCount> byGender;
  final List<PageCount> byPageno;

  UserStats({
    required this.total,
    required this.todayRegistered,
    required this.thisMonthRegistered,
    required this.verified,
    required this.unverified,
    required this.active,
    required this.online,
    required this.byType,
    required this.byGender,
    required this.byPageno,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      total: _parseInt(json['total']),
      todayRegistered: _parseInt(json['today_registered']),
      thisMonthRegistered: _parseInt(json['this_month_registered']),
      verified: _parseInt(json['verified']),
      unverified: _parseInt(json['unverified']),
      active: _parseInt(json['active']),
      online: _parseInt(json['online']),
      byType: List<TypeCount>.from(
        (json['by_type'] ?? []).map((x) => TypeCount.fromJson(x)),
      ),
      byGender: List<GenderCount>.from(
        (json['by_gender'] ?? []).map((x) => GenderCount.fromJson(x)),
      ),
      byPageno: List<PageCount>.from(
        (json['by_pageno'] ?? []).map((x) => PageCount.fromJson(x)),
      ),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class TypeCount {
  final String usertype;
  final int total;

  TypeCount({
    required this.usertype,
    required this.total,
  });

  factory TypeCount.fromJson(Map<String, dynamic> json) {
    return TypeCount(
      usertype: json['usertype']?.toString() ?? '',
      total: UserStats._parseInt(json['total']),
    );
  }
}

class GenderCount {
  final String gender;
  final int total;

  GenderCount({
    required this.gender,
    required this.total,
  });

  factory GenderCount.fromJson(Map<String, dynamic> json) {
    return GenderCount(
      gender: json['gender']?.toString() ?? '',
      total: UserStats._parseInt(json['total']),
    );
  }
}

class PageCount {
  final int pageno;
  final int total;

  PageCount({
    required this.pageno,
    required this.total,
  });

  factory PageCount.fromJson(Map<String, dynamic> json) {
    return PageCount(
      pageno: UserStats._parseInt(json['pageno']),
      total: UserStats._parseInt(json['total']),
    );
  }
}

class AddressStats {
  final int totalWithAddress;
  final List<CountryCount> byCountry;
  final List<StateCount> byState;
  final List<CityCount> byCity;
  final List<ResidentialStatusCount> byResidentialStatus;

  AddressStats({
    required this.totalWithAddress,
    required this.byCountry,
    required this.byState,
    required this.byCity,
    required this.byResidentialStatus,
  });

  factory AddressStats.fromJson(Map<String, dynamic> json) {
    return AddressStats(
      totalWithAddress: UserStats._parseInt(json['total_with_address']),
      byCountry: List<CountryCount>.from(
        (json['by_country'] ?? []).map((x) => CountryCount.fromJson(x)),
      ),
      byState: List<StateCount>.from(
        (json['by_state'] ?? []).map((x) => StateCount.fromJson(x)),
      ),
      byCity: List<CityCount>.from(
        (json['by_city'] ?? []).map((x) => CityCount.fromJson(x)),
      ),
      byResidentialStatus: List<ResidentialStatusCount>.from(
        (json['by_residential_status'] ?? []).map((x) => ResidentialStatusCount.fromJson(x)),
      ),
    );
  }
}

class CountryCount {
  final String country;
  final int total;

  CountryCount({
    required this.country,
    required this.total,
  });

  factory CountryCount.fromJson(Map<String, dynamic> json) {
    return CountryCount(
      country: json['country']?.toString() ?? '',
      total: UserStats._parseInt(json['total']),
    );
  }
}

class StateCount {
  final String state;
  final int total;

  StateCount({
    required this.state,
    required this.total,
  });

  factory StateCount.fromJson(Map<String, dynamic> json) {
    return StateCount(
      state: json['state']?.toString() ?? '',
      total: UserStats._parseInt(json['total']),
    );
  }
}

class CityCount {
  final String city;
  final int total;

  CityCount({
    required this.city,
    required this.total,
  });

  factory CityCount.fromJson(Map<String, dynamic> json) {
    return CityCount(
      city: json['city']?.toString() ?? '',
      total: UserStats._parseInt(json['total']),
    );
  }
}

class ResidentialStatusCount {
  final String residentialStatus;
  final int total;

  ResidentialStatusCount({
    required this.residentialStatus,
    required this.total,
  });

  factory ResidentialStatusCount.fromJson(Map<String, dynamic> json) {
    return ResidentialStatusCount(
      residentialStatus: json['residential_status']?.toString() ??
          json['residentalstatus']?.toString() ?? '',
      total: UserStats._parseInt(json['total']),
    );
  }
}

class PaymentStats {
  final int totalSold;
  final int activePackages;
  final int expiredPackages;
  final String totalEarning;
  final String todayEarning;
  final String thisMonthEarning;
  final List<PaymentMethodCount> byMethod;
  final BestSellingPackage bestSellingPackage;

  PaymentStats({
    required this.totalSold,
    required this.activePackages,
    required this.expiredPackages,
    required this.totalEarning,
    required this.todayEarning,
    required this.thisMonthEarning,
    required this.byMethod,
    required this.bestSellingPackage,
  });

  factory PaymentStats.fromJson(Map<String, dynamic> json) {
    // Handle best_selling_package which might be false (bool) instead of a map
    dynamic bestPackageData = json['best_selling_package'];
    BestSellingPackage bestPackage;

    if (bestPackageData is Map<String, dynamic>) {
      bestPackage = BestSellingPackage.fromJson(bestPackageData);
    } else {
      // Return a default/empty package when it's false or any other type
      bestPackage = BestSellingPackage(
        name: 'No package data',
        total: 0,
      );
    }

    return PaymentStats(
      totalSold: UserStats._parseInt(json['total_sold']),
      activePackages: UserStats._parseInt(json['active_packages']),
      expiredPackages: UserStats._parseInt(json['expired_packages']),
      totalEarning: json['total_earning']?.toString() ?? 'Rs 0.00',
      todayEarning: json['today_earning']?.toString() ?? 'Rs 0.00',
      thisMonthEarning: json['this_month_earning']?.toString() ?? 'Rs 0.00',
      byMethod: List<PaymentMethodCount>.from(
        (json['by_method'] ?? []).map((x) => PaymentMethodCount.fromJson(x)),
      ),
      bestSellingPackage: bestPackage,
    );
  }

  double get numericTotalEarning {
    try {
      return double.parse(totalEarning.replaceAll('Rs ', '').replaceAll(',', '').trim());
    } catch (e) {
      return 0.0;
    }
  }
}

class PaymentMethodCount {
  final String paidby;
  final int total;

  PaymentMethodCount({
    required this.paidby,
    required this.total,
  });

  factory PaymentMethodCount.fromJson(Map<String, dynamic> json) {
    return PaymentMethodCount(
      paidby: json['paidby']?.toString() ?? '',
      total: UserStats._parseInt(json['total']),
    );
  }
}

class BestSellingPackage {
  final String name;
  final int total;

  BestSellingPackage({
    required this.name,
    required this.total,
  });

  factory BestSellingPackage.fromJson(Map<String, dynamic> json) {
    return BestSellingPackage(
      name: json['name']?.toString() ?? '',
      total: UserStats._parseInt(json['total']),
    );
  }
}