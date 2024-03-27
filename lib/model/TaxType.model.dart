class TaxType {
  TaxType({
    required this.taxType
  });
  final String taxType;
  factory TaxType.fromJson (Map<String, dynamic> json) {
    return TaxType (
        taxType: json['TAX_TYPE']
    );
  }
}