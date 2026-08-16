class Deposit {
  final String id;
  final String? batchNo;
  final String? name;
  final String? phone;
  final String dateOfDeposit;
  final num totalAmount;
  final num? shareAmount;

  const Deposit({
    required this.id,
    this.batchNo,
    this.name,
    this.phone,
    required this.dateOfDeposit,
    required this.totalAmount,
    this.shareAmount,
  });

  factory Deposit.fromJson(Map<String, dynamic> json) => Deposit(
        id: json['id'] as String,
        batchNo: json['batchNo'] as String?,
        name: json['name'] as String?,
        phone: json['phone'] as String?,
        dateOfDeposit: (json['dateOfDeposit'] ?? '').toString(),
        totalAmount: (json['totalAmount'] as num?) ?? 0,
        shareAmount: json['shareAmount'] as num?,
      );
}
