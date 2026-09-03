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
  final String? photoUrl;
  // These 4 (plus photo_url and nominee info) are what
  // profileCompletion.js's checklist counts toward profileCompletionPercent —
  // self-editable via PUT /investors/public-update/:id so an investor can
  // actually reach 100% themselves, not just an admin.
  final String? email;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? etinNo;
  final DateTime? profileUpdatedAt;
  // Derived server-side (backend/utils/profileCompletion.js), never stored —
  // always fresh, drives the completion ring around the avatar.
  final int profileCompletionPercent;
  // Superadmin-only prestige override for the DISPLAY tier — see
  // core/utils/investor_category.dart's `InvestorCategory.of`. Never affects
  // shareAmount, but the backend does recompute status/monthlyPayment/
  // totalMonths from it (a Director-tier override means the 12-month plan,
  // an explicit 'regular' override means 36 months) — this model just
  // reflects whatever the server already applied, no client-side logic.
  final String? tierOverride;
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
    this.photoUrl,
    this.email,
    this.gender,
    this.dateOfBirth,
    this.etinNo,
    this.profileUpdatedAt,
    this.profileCompletionPercent = 0,
    this.tierOverride,
    this.deposits = const [],
  });

  String get displayName =>
      investorType == 'Organization' ? (organizationName ?? name) : name;

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
    photoUrl: json['photo_url'] as String?,
    email: json['email'] as String?,
    gender: json['gender'] as String?,
    dateOfBirth: json['date_of_birth'] != null
        ? DateTime.tryParse(json['date_of_birth'].toString())
        : null,
    etinNo: json['etin_no'] as String?,
    profileUpdatedAt: json['profileUpdatedAt'] != null
        ? DateTime.tryParse(json['profileUpdatedAt'].toString())
        : null,
    profileCompletionPercent:
        (json['profileCompletionPercent'] as num?)?.toInt() ?? 0,
    tierOverride: json['tierOverride'] as String?,
    deposits:
        (json['deposits'] as List?)
            ?.map((d) => Deposit.fromJson(d as Map<String, dynamic>))
            .toList() ??
        const [],
  );
}
