import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  final String brandName;
  final String phone;
  final String address;
  final int vatPercent;
  final String language; // 'AR' or 'EN'
  final String printingLanguage; // 'AR' or 'EN'
  final String? logoPath;
  final String currency;
  final bool isOnboarded;

  const AppSettings({
    required this.brandName,
    required this.phone,
    required this.address,
    required this.vatPercent,
    required this.language,
    required this.printingLanguage,
    this.logoPath,
    required this.currency,
    this.isOnboarded = false,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      brandName: json['brandName'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      vatPercent: json['vatPercent'] ?? 15,
      language: json['language'] ?? 'EN',
      printingLanguage: json['printingLanguage'] ?? 'EN',
      logoPath: json['logoPath'],
      currency: json['currency'] ?? 'USD',
      isOnboarded: json['isOnboarded'] == 1 || json['isOnboarded'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': 1, // Always 1 for singleton
      'brandName': brandName,
      'phone': phone,
      'address': address,
      'vatPercent': vatPercent,
      'language': language,
      'printingLanguage': printingLanguage,
      'logoPath': logoPath,
      'currency': currency,
      'isOnboarded': isOnboarded ? 1 : 0,
    };
  }

  AppSettings copyWith({
    String? brandName,
    String? phone,
    String? address,
    int? vatPercent,
    String? language,
    String? printingLanguage,
    String? logoPath,
    String? currency,
    bool? isOnboarded,
  }) {
    return AppSettings(
      brandName: brandName ?? this.brandName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      vatPercent: vatPercent ?? this.vatPercent,
      language: language ?? this.language,
      printingLanguage: printingLanguage ?? this.printingLanguage,
      logoPath: logoPath ?? this.logoPath,
      currency: currency ?? this.currency,
      isOnboarded: isOnboarded ?? this.isOnboarded,
    );
  }

  @override
  List<Object?> get props => [
        brandName,
        phone,
        address,
        vatPercent,
        language,
        printingLanguage,
        logoPath,
        currency,
        isOnboarded,
      ];
}
