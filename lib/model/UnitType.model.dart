class UnitType {
  final String idUnit;
  UnitType ({
    required this.idUnit
  });
  factory UnitType.fromJson (Map<String, dynamic> json) {
    return UnitType(
        idUnit: json['ID_UNIT']
    );
  }
}