class Product {
  const Product({
    required this.productId,
    required this.productCode,
    required this.productCategoryId,
    required this.productCategory,
    required this.productName,
    required this.productNameInternal,
    required this.productDescription,
    required this.brandId,
    required this.brand,
    required this.minQuantitySell,
    required this.languageCode,
    required this.productPrice,
    required this.productPriceFinal,
    required this.taxId,
    required this.currencyId,
    required this.unitId,
    required this.desUnit,
    required this.weeksWarning,
    required this.quantityMinPrice,
    required this.quantityMaxPrice,
    required this.typeDayDelivery,
    required this.desDeliveryType,
    required this.minDaysDelivery,
    required this.maxDaysDelivery,
    required this.remark,
    required this.daysDelivery,
    required this.productTypeId,
    required this.providerId,
    required this.personeName,
    required this.partnerId,
    required this.partnerName,
    required this.effDate,
    required this.expDate,
    required this.daysExp,
    required this.expoiledFlag,
    required this.countableFlag,
    required this.sourceId,
    required this.numImages,
    required this.numVideos
  });
  final int productId;
  final String productCode;
  final int productCategoryId;
  final String productCategory;
  final String productName;
  final String productNameInternal;
  final String productDescription;
  final int brandId;
  final String brand;
  final double minQuantitySell;
  final String languageCode;
  final double productPrice;
  final double productPriceFinal;
  final int taxId;
  final String currencyId;
  final String unitId;
  final String desUnit;
  final double weeksWarning;
  final double quantityMinPrice;
  final double quantityMaxPrice;
  final String typeDayDelivery;
  final String desDeliveryType;
  final double minDaysDelivery;
  final double maxDaysDelivery;
  final String remark;
  final String daysDelivery;
  final int productTypeId;
  final int providerId;
  final String personeName;
  final String partnerId;
  final String partnerName;
  final String effDate;
  final String expDate;
  final int daysExp;
  final String expoiledFlag;
  final String countableFlag;
  final String sourceId;
  final int numImages;
  final int numVideos;

  factory Product.fromJson (Map<String, dynamic> json) {
    return Product (
        productId: int.parse(json['PRODUCT_ID'].toString()),
        productCode: json['PRODUCT_CODE'] ?? '',
        productCategoryId: int.parse(json['PRODUCT_CATEGORY_ID'].toString()),
        productCategory: json['PRODUCT_CATEGORY'],
        productName: json['PRODUCT_NAME'],
        productNameInternal: json['PRODUCT_NAME_INTERNAL'],
        productDescription: json['PRODUCT_DESCRIPTION'] ?? '',
        brandId: int.parse((json['BRAND_ID'] ?? '-3').toString()),
        brand: json['BRAND'] ?? '',
        minQuantitySell: double.parse(json['MIN_QUANTITY_SELL'].toString()),
        languageCode: json['LANGUAGE_CODE'],
        productPrice: double.parse(json['PRODUCT_PRICE'].toString()),
        productPriceFinal: double.parse(json['PRODUCT_PRICE_FINAL'].toString()),
        taxId: int.parse(json['TAX_ID'].toString()),
        currencyId: json['CURRENCY_ID'],
        unitId: json['UNIT_ID'],
        desUnit: json['DES_UNIT'],
        weeksWarning: double.parse(json['WEEKS_WARNING'].toString()),
        quantityMinPrice: double.parse(json['QUANTITY_MIN_PRICE'].toString()),
        quantityMaxPrice: double.parse(json['QUANTITY_MAX_PRICE'].toString()),
        typeDayDelivery: json['TYPE_DAY_DELIVERY'] ?? '',
        desDeliveryType: json['DES_DELIVERY_TYPE'] ?? '',
        minDaysDelivery: double.parse((json['MIN_DAYS_DELIVERY'] ?? '-3').toString()),
        maxDaysDelivery: double.parse((json['MAX_DAYS_DELIVERY'] ?? '-3').toString()),
        remark: json['REMARK'] ?? '',
        daysDelivery: json['DAYS_DELIVERY'] ?? '',
        productTypeId: int.parse((json['PRODUCT_TYPE_ID'] ?? '-3').toString()),
        providerId: int.parse(json['PROVIDER_ID'].toString()),
        personeName: json['PERSONE_NAME'],
        partnerId: json['PARTNER_ID'],
        partnerName: json['PARTNER_NAME'],
        effDate: json['EFF_DATE'],
        expDate: json['EXP_DATE'] ?? '',
        daysExp: int.parse((json['DAYS_EXP'] ?? '-3').toString()),
        expoiledFlag: json['EXPOILED_FLAG'] ?? '',
        countableFlag: json['COUNTABLE_FLAG'] ?? '',
        sourceId: json['SOURCE_ID'],
        numImages: int.parse((json['NUM_IMAGES'] ?? '0').toString()),
        numVideos: int.parse((json['NUM_VIDEOS'] ?? '0').toString())
    );
  }
}