class ProductType {
  ProductType ({
    required this.productType
  });
  final String productType;
  factory ProductType.fromJson (Map<String, dynamic> json) {
    return ProductType (
        productType: json['PRODUCT_TYPE']
    );
  }
}