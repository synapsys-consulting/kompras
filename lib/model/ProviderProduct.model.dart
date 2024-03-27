class ProviderProduct {
  ProviderProduct({
    required this.personeName
  });
  final String personeName;
  factory ProviderProduct.fromJson (Map<String, dynamic> json) {
    return ProviderProduct (
      personeName: json['PERSONE_NAME']
    );

  }
}