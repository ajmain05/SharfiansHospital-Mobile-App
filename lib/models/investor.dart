import 'deposit.dart';

/// Mirrors the backend's `Investor` Prisma model (backend/prisma/schema.prisma).
/// `POST /investors/auth-phone` returns each matched account with its
/// `deposits` embedded, so this model carries them directly rather than
/// fetching deposits separately.
class Investor {
  final String id;
  final String investorId;
  final String investorType; // 'Individual' | 'Organization'
  final String? organizationName;
  final String name;
  final String fatherName;
  final String motherName;
  final String address;
  final String phone;
  final String? educationLevel;
  final int? passingYear;
  final num shareAmount;
  final int numberOfPersons;
  final num monthlyPayment;
  final int totalMonths;
  final String status; // 'REGULAR' | 'DIRECTOR'
  final String? nomineeName;
  final String? nomineePhone;
  final String? nomineeAddress;
  final String? nomineeRelation;
  final String? nomineeNid;
  final num? charityPercentage;
  final List<Deposit> deposits;

  const Investor({
    required this.id,
    required this.investorId,
    required this.investorType,
    this.organizationName,
    required this.name,
    required this.fatherName,
    required this.motherName,
    required this.address,
    required this.phone,
    this.educationLevel,
    this.passingYear,
    required this.shareAmount,
    required this.numberOfPersons,
    required this.monthlyPayment,
    required this.totalMonths,
    required this.status,
    this.nomineeName,
    this.nomineePhone,
    this.nomineeAddress,
    this.nomineeRelation,
    this.nomineeNid,
    this.charityPercentage,
    this.deposits = const [],
  });

  String get displayName => investorType == 'Organization' ? (organizationName ?? name) : name;

  bool get isDirector => status == 'DIRECTOR';

  factory Investor.fromJson(Map<String, dynamic> json) => Investor(
        id: json['id'] as String,
        investorId: (json['investor_id'] ?? '').toString(),
        investorType: (json['investor_type'] ?? 'Individual').toString(),
        organizationName: json['organization_name'] as String?,
        name: (json['name'] ?? '').toString(),
        fatherName: (json['father_name'] ?? '').toString(),
        motherName: (json['mother_name'] ?? '').toString(),
        address: (json['address'] ?? '').toString(),
        phone: (json['phone'] ?? '').toString(),
        educationLevel: json['education_level'] as String?,
        passingYear: (json['passing_year'] as num?)?.toInt(),
        shareAmount: (json['share_amount'] as num?) ?? 0,
        numberOfPersons: (json['number_of_persons'] as num?)?.toInt() ?? 1,
        monthlyPayment: (json['monthly_payment'] as num?) ?? 0,
        totalMonths: (json['total_months'] as num?)?.toInt() ?? 12,
        status: (json['status'] ?? 'REGULAR').toString(),
        nomineeName: json['nominee_name'] as String?,
        nomineePhone: json['nominee_phone'] as String?,
        nomineeAddress: json['nominee_address'] as String?,
        nomineeRelation: json['nominee_relation'] as String?,
        nomineeNid: json['nominee_nid'] as String?,
        charityPercentage: json['charity_percentage'] as num?,
        deposits: (json['deposits'] as List?)?.map((d) => Deposit.fromJson(d as Map<String, dynamic>)).toList() ?? const [],
      );
}
