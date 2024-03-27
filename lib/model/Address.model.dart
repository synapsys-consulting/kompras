class Address {
  Address ({
    required this.addrId,
    required this.streetName,
    required this.streetNumber,
    required this.flatDoor,
    required this.postalCode,
    required this.locality,
    required this.province,
    required this.country,
    required this.state,
    required this.optional,
    required this.district,
    required this.suburb,
    required this.statusId
  });
  int addrId;
  String streetName;
  String streetNumber;
  String flatDoor;
  String postalCode;
  String locality;
  String province;
  String country;
  String state;
  String optional;
  String district;
  String suburb;
  String statusId;
  factory Address.fromJson (Map<String, dynamic> json) {
    return Address (
        addrId: int.parse(json['ADDR_ID'].toString()),
        streetName: json['ADDR_STREET'],
        streetNumber: json['ADDR_NUMBER'] ?? '',
        flatDoor: json['ADDR_COMPLEMENT'] ?? '',
        postalCode: json['ADDR_ZIP_CODE'] ?? '',
        locality: json['CITY'] ?? '',
        province: json['PROVINCE'] ?? '',
        country: json['COUNTRY'] ?? '',
        state: json['STATE'] ?? '',
        optional: json['INDICATION'] ?? '',
        district: json['DISTRICT'] ?? '',
        suburb: json['SUBURB'] ?? '',
        statusId: json['STATUS_ID'] ?? ''
    );
  }
}