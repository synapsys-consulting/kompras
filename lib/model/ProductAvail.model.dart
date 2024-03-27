class ProductAvail {
  ProductAvail({
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.productNameLong,
    required this.productDescription,
    required this.productType,
    required this.brand,
    required this.numImages,
    required this.numVideos,
    required this.purchased,
    required this.productPrice,
    required this.totalBeforeDiscount, // PRICE WITH TAX INCLUDED
    required this.taxAmount,
    required this.personeId,
    required this.personeName,
    required this.businessName,
    required this.email,
    required this.taxId,
    required this.taxApply,
    required this.productPriceDiscounted,
    required this.totalAmount,
    required this.discountAmount,
    required this.idUnit,
    required this.remark,
    required this.minQuantitySell,
    required this.partnerId,
    required this.partnerName,
    required this.quantityMinPrice,
    required this.quantityMaxPrice,
    required this.productCategoryId,
    required this.rn
  });
  final int productId;
  final int productCode;
  final String productName;
  final String productNameLong;
  final String productDescription;
  final String productType;
  final String brand;
  final int numImages;
  final int numVideos;
  double purchased;
  final double productPrice;
  final double totalBeforeDiscount;
  final double taxAmount;
  final int personeId;
  final String personeName;
  final String businessName;
  final String email;
  final int taxId;
  final double taxApply;
  final double productPriceDiscounted;   // FINAL PRICE DISCOUNT INCLUDED
  final double totalAmount;              // FINAL PRICE DISCOUNT AND TAXES INCLUDED
  final int discountAmount;           // PRODUCT_PRICE - PRODUCT_PRICE_DISCOUNTED
  final String idUnit;
  final String remark;
  final double minQuantitySell;
  final int partnerId;
  final String partnerName;
  final double quantityMinPrice;
  final double quantityMaxPrice;
  final int productCategoryId;
  final int rn;


  factory ProductAvail.fromJson (Map<String, dynamic> json) {
    //debugPrint('Entro en el FACTORY.');
    //debugPrint('El productId es: ' + json['PRODUCT_ID'].toString());
    //debugPrint('El productName es: ' + json['PRODUCT_NAME'].toString());
    //debugPrint('El productNameLong es: ' + json['PRODUCT_NAME_LONG'].toString());
    //debugPrint('El productDescription es: ' + json['PRODUCT_DESCRIPTION'].toString());
    //debugPrint('El productType es: ' + json['PRODUCT_TYPE'].toString());
    //debugPrint('El brand es: ' + json['BRAND'].toString());
    //debugPrint('El numImages es: ' + json['NUM_IMAGES'].toString());
    //debugPrint('El numVideos es: ' + json['NUM_VIDEOS'].toString());
    //debugPrint('El productPrice es: ' + json['PRODUCT_PRICE'].toString());
    //debugPrint('El totalBeforeDiscount es: ' + json['TOTAL_BEFORE_DISCOUNT'].toString());
    //debugPrint('El taxAmount es: ' + json['TAX_AMOUNT'].toString());
    return ProductAvail (
      productId: int.parse(json['PRODUCT_ID'].toString()),
      productCode: int.parse(json['PRODUCT_CODE'].toString()),
      productName: json['PRODUCT_NAME'] ?? '',
      productNameLong: json['PRODUCT_NAME_LONG'] ?? '',
      productDescription: json['PRODUCT_DESCRIPTION'] ?? 'NULL',
      productType: json['PRODUCT_TYPE'] ?? '',
      brand: json['BRAND'] ?? '',
      numImages: int.parse((json['NUM_IMAGES'] ?? '0').toString()),
      numVideos: int.parse((json['NUM_VIDEOS'] ?? '0').toString()),
      purchased: 0.0,
      productPrice: double.parse((json['PRODUCT_PRICE'] ?? '0').toString()),
      totalBeforeDiscount: double.parse((json['PRODUCT_PRICE'] ?? '0').toString()),
      taxAmount: double.parse((json['TAX_AMOUNT'] ?? '0').toString()),
      personeId: int.parse((json['PERSONE_ID'] ?? '0').toString()),
      personeName: json['PERSONE_NAME'] ?? '',
      businessName: json['BUSINESS_NAME'].toString(),
      email: json['EMAIL'] ?? '',
      taxId: int.parse((json['TAX_ID'] ?? '0').toString()),
      taxApply: double.parse((json['TAX_APPLY'] ?? '10').toString()),
      productPriceDiscounted: double.parse((json['PRODUCT_PRICE_DISCOUNTED'] ?? '0').toString()),
      totalAmount: double.parse((json['TOTAL_AMOUNT'] ?? '0').toString()),
      discountAmount: int.parse((json['DISCOUNT_AMOUNT'] ?? '0').toString()),
      idUnit: json['ID_UNIT'] ?? '',
      remark: json['REMARK'] ?? '',
      minQuantitySell: double.parse((json['MIN_QUANTITY_SELL'] ?? '0').toString()),
      partnerId: int.parse((json['PARTNER_ID'] ?? '1').toString()),
      partnerName: json['PARTNER_NAME'] ?? '',
      quantityMinPrice: double.parse((json['QUANTITY_MIN_PRICE'] ?? '0').toString()),
      quantityMaxPrice: double.parse((json['QUANTITY_MAX_PRICE'] ?? '99999').toString()),
      productCategoryId: int.parse((json['PRODUCT_CATEGORY_ID'] ?? '0').toString()),
      rn: int.parse((json['RN'] ?? '1').toString()),
    );
  }
}