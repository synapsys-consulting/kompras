import 'package:kompras/model/PurchaseStatus.model.dart';

class PurchaseLine {
  PurchaseLine ({
    required this.orderId,
    required this.providerName,
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.allStatus,
    required this.statusId,
    required this.numStatus,
    required this.banPrice,
    required this.banQuantity,
    required this.items,
    required this.idUnit,
    required this.newQuantity,
    required this.newProductPrice,
    required this.banOfficialPrice,
    required this.situation,
    required this.totalAmount,
    required this.taxAmount,
    required this.discountAmount,
    required this.productPriceFinal,
    required this.productPrice,
    required this.totalBeforeDiscountWithoutTax,
    required this.totalAfterDiscountWithoutTax,
    required this.orderDate,
    required this.remarkSeller,
    required this.remarkBuyer,
    required this.possibleStatusToTransitionTo
  });
  final int orderId;
  final String providerName;
  final int productId;
  final int productCode;
  final String productName;
  String allStatus;
  String statusId;
  final int numStatus;
  String banPrice;
  String banQuantity;
  double items;
  String idUnit;
  double newQuantity;
  double newProductPrice;
  String banOfficialPrice;
  final String situation;
  double totalAmount;
  double taxAmount;
  double discountAmount;
  final double productPriceFinal;
  final double productPrice;
  double totalBeforeDiscountWithoutTax;
  double totalAfterDiscountWithoutTax;
  final DateTime orderDate;
  String remarkSeller;
  String remarkBuyer;
  List<PurchaseStatus> possibleStatusToTransitionTo;
  factory PurchaseLine.fromJson (Map<String, dynamic> json) {
    final List<Map<String, dynamic>> resultListJson = json['STATUS_TO_TRANSITION_TO'].cast<Map<String, dynamic>>();
    return PurchaseLine (
        orderId: int.parse(json['ORDER_ID'].toString()),
        providerName: json['PROVIDER_NAME'],
        productId: int.parse(json['PRODUCT_ID'].toString()),
        productCode: int.parse(json['PRODUCT_CODE'].toString()),
        productName: json['PRODUCT_NAME'],
        allStatus: json['ALL_STATUS'],
        statusId: json['STATUS_ID'],
        numStatus: int.parse(json['NUM_STATUS'].toString()),
        banPrice: json['BAN_PRICE'],
        banQuantity: json['BAN_QUANTITY'],
        items: double.parse(json['ITEMS'].toString()),
        idUnit: json['ID_UNIT'],
        newQuantity: double.parse(json['NEW_QUANTITY'].toString()),
        newProductPrice: double.parse(json['NEW_PRODUCT_PRICE_FINAL'].toString()),
        banOfficialPrice: json['BAN_OFICIAL_PRICE'],
        situation: json['SITUACION'],
        totalAmount: double.parse(json['TOTAL_AMOUNT'].toString()),
        taxAmount: double.parse(json['TAX_AMOUNT'].toString()),
        discountAmount: double.parse(json['DISCOUNT_AMOUNT'].toString()),
        productPriceFinal: double.parse(json['PRODUCT_PRICE_FINAL'].toString()),
        productPrice: double.parse(json['PRODUCT_PRICE'].toString()),
        totalBeforeDiscountWithoutTax: double.parse(json['TOTAL_BEFORE_DISCOUNT_WITHOUT_TAX'].toString()),
        totalAfterDiscountWithoutTax: double.parse(json['TOTAL_AFTER_DISCOUNT_WITHOUT_TAX'].toString()),
        orderDate: DateTime.parse(json['ORDER_DATE']),
        remarkSeller: json['REMARK_SELLER'],
        remarkBuyer: json['REMARK_BUYER'],
        possibleStatusToTransitionTo: resultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList()
    );
  }
}