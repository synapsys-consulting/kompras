import 'ProductAvail.model.dart';

class MultiPricesProductAvail extends ProductAvail {
  MultiPricesProductAvail({
    required super.productId,
    required super.productCode,
    required super.productName,
    required super.productNameLong,
    required super.productDescription,
    required super.productType,
    required super.brand,
    required super.numImages,
    required super.numVideos,
    required super.purchased,
    required super.productPrice,
    required super.totalBeforeDiscount, // PRICE WITH TAX INCLUDED
    required super.taxAmount,
    required super.personeId,
    required super.personeName,
    required super.businessName,
    required super.email,
    required super.taxId,
    required super.taxApply,
    required super.productPriceDiscounted,
    required super.totalAmount,
    required super.discountAmount,
    required super.idUnit,
    required super.remark,
    required super.minQuantitySell,
    required super.partnerId,
    required super.partnerName,
    required super.quantityMinPrice,
    required super.quantityMaxPrice,
    required super.productCategoryId,
    required super.rn
  }){
    totalAmountAccordingQuantity = totalAmount;
  }

  factory MultiPricesProductAvail.fromJson (Map<String, dynamic> json) {
    return MultiPricesProductAvail (
      productId: int.parse(json['PRODUCT_ID'].toString()),
      productCode: int.parse(json['PRODUCT_CODE'].toString()),
      productName: json['PRODUCT_NAME'],
      productNameLong: json['PRODUCT_NAME_LONG'],
      productDescription: json['PRODUCT_DESCRIPTION'] ?? '',
      productType: json['PRODUCT_TYPE'] ?? '',
      brand: json['BRAND'] ?? '',
      numImages: int.parse((json['NUM_IMAGES'] ?? '0').toString()),
      numVideos: int.parse((json['NUM_VIDEOS'] ?? '0').toString()),
      purchased: 0,
      productPrice: double.parse(json['PRODUCT_PRICE'].toString()),
      totalBeforeDiscount: double.parse(json['TOTAL_BEFORE_DISCOUNT'].toString()),
      taxAmount: double.parse(json['TAX_AMOUNT'].toString()),
      personeId: int.parse((json['PERSONE_ID'] ?? '0').toString()),
      personeName: json['PERSONE_NAME'] ?? '',
      businessName: json['BUSINESS_NAME'].toString() ,
      email: json['EMAIL'] ?? '',
      taxId: int.parse(json['TAX_ID'].toString()),
      taxApply: double.parse(json['TAX_APPLY'].toString()),
      productPriceDiscounted: double.parse(json['PRODUCT_PRICE_DISCOUNTED'].toString()),
      totalAmount: double.parse(json['TOTAL_AMOUNT'].toString()),
      discountAmount: int.parse(json['DISCOUNT_AMOUNT'].toString()),
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

  final List<ProductAvail> _items = [];   // Save the registers which have the different prices depending the amount
  int _indexElementAmongQuantity = -1;    // Save the element according quantity. Default = -1. It is the father element
  double totalAmountAccordingQuantity = 0;    // Save the field totalAmount according the quantity of the product purchased

  List<ProductAvail> get items => _items;

  void add (ProductAvail item) {
    bool founded = false;
    if (_items.isNotEmpty) {
      for (var element in items) {
        if (element.productId == item.productId) {
          founded = true;
        }
      }
    }
    if (!founded) {
      final itemCatalog = ProductAvail(
          productId: item.productId,
          productCode: item.productCode,
          productName: item.productName,
          productNameLong: item.productNameLong,
          productDescription: item.productDescription,
          productType: item.productType,
          brand: item.brand,
          numImages: item.numImages,
          numVideos: item.numVideos,
          purchased: 0,
          productPrice: item.productPrice,
          totalBeforeDiscount: item.totalBeforeDiscount,
          taxAmount: item.taxAmount,
          personeId: item.productId,
          personeName: item.personeName,
          businessName: item.businessName,
          email: item.email,
          taxId: item.taxId,
          taxApply: item.taxApply,
          productPriceDiscounted: item.productPriceDiscounted,
          totalAmount: item.totalAmount,
          discountAmount: item.discountAmount,
          idUnit: item.idUnit,
          remark: item.remark,
          minQuantitySell: item.minQuantitySell,
          partnerId: item.partnerId,
          partnerName: item.partnerName,
          quantityMaxPrice: item.quantityMaxPrice,
          quantityMinPrice: item.quantityMinPrice,
          productCategoryId: item.productCategoryId,
          rn: item.rn
      );
      _items.add(itemCatalog);
    }
  }
  ProductAvail getItem (int index) {
    return _items[index];
  }
  void clear () {
    _items.clear();
  }
  int get numItems => _items.length;

  int getIndexElementAmongQuantity () {
    return _indexElementAmongQuantity;
  }
  double getTotalAmountAccordingQuantity () {
    double totalAmountAccordingQuantity = 0;
    if (_items.isNotEmpty) {
      // The product hast multi-prices according quantity
      //debugPrint ('Estoy en el totalAmountAccordingQuantity. Dentro de _items > 0');
      if (purchased <= quantityMaxPrice) {
        // See the first element, the father element
        totalAmountAccordingQuantity = totalAmount;
        _indexElementAmongQuantity = -1;  // Save the element according quantity
        //debugPrint ('Estoy en el totalAmountAccordingQuantity. Father element.');
      } else {
        // See the rest of the elements, children elements
        for (var j = 0; j < _items.length; j++) {
          //debugPrint ('Estoy en el totalAmountAccordingQuantity. Children element.');
          if (purchased <= _items[j].quantityMaxPrice) {
            totalAmountAccordingQuantity = _items[j].totalAmount;
            _indexElementAmongQuantity = j;  // Save the element according quantity
            //debugPrint ('Estoy en el totalAmountAccordingQuantity. El indice que marca el totalAmountAccordingQuantity es: ' + this._indexElementAmongQuantity.toString());
            break;
          }
        }
      }
    } else {
      //debugPrint ('Estoy en el totalAmountAccordingQuantity. Dentro de _items = 0');
      totalAmountAccordingQuantity = totalAmount;
      _indexElementAmongQuantity = -1;  // Save the element according quantity
    }
    //debugPrint ('Estoy en el totalAmountAccordingQuantity. Retorno: ' + totalAmountAccordingQuantity.toString());
    return totalAmountAccordingQuantity;
  }
  double productPriceDiscountedAccordingQuantity () {
    double productPriceDiscountedAccordingQuantity = 0;
    if (_items.isNotEmpty) {
      // The product hast multi-prices according quantity
      if (purchased < quantityMaxPrice) {
        // See the first element, the father element
        productPriceDiscountedAccordingQuantity = productPriceDiscounted;
      } else {
        // See the rest the elements
        for (var j = 0; j < _items.length; j++) {
          if (purchased < _items[j].quantityMaxPrice) {
            productPriceDiscountedAccordingQuantity = _items[j].productPriceDiscounted;
            break;
          }
        }
      }
    } else {
      productPriceDiscountedAccordingQuantity = productPriceDiscounted;
    }
    return productPriceDiscountedAccordingQuantity;
  }
}