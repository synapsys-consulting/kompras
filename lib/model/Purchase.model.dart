import 'package:kompras/model/PurchaseStatus.model.dart';

class Purchase {
  Purchase ({
    required this.orderId,
    required this.providerName,
    required this.buyerName,
    required this.showName,
    required this.allStatus,
    required this.statusId,
    required this.numStatus,
    required this.items,
    required this.situation,
    required this.totalAmount,
    required this.taxAmount,
    required this.discountAmount,
    required this.productPriceFinal,
    required this.productPrice,
    required this.totalBeforeDiscountWithoutTax,
    required this.totalAfterDiscountWithoutTax,
    required this.orderDate,
    required this.possibleStatusToTransitionTo
  });
  final int orderId;
  final String providerName;
  final String buyerName;
  final String showName;
  String allStatus;
  String statusId;
  int numStatus;
  final double items;
  final String situation;
  final double totalAmount;
  final double taxAmount;
  final double discountAmount;
  final double productPriceFinal;
  final double productPrice;
  final double totalBeforeDiscountWithoutTax;
  final double totalAfterDiscountWithoutTax;
  final DateTime orderDate;
  List<PurchaseStatus> possibleStatusToTransitionTo;
  factory Purchase.fromJson (Map<String, dynamic> json) {
    final List<Map<String, dynamic>> resultListJson = json['STATUS_TO_TRANSITION_TO'].cast<Map<String, dynamic>>();
    return Purchase (
        orderId: int.parse(json['ORDER_ID'].toString()),
        providerName: json['PROVIDER_NAME'],
        buyerName:  json['BUYER_NAME'],
        showName: json['SHOW_NAME'],
        allStatus: json['ALL_STATUS'],
        statusId: json['STATUS_ID'],
        numStatus: int.parse(json['NUM_STATUS'].toString()),
        items: double.parse(json['ITEMS'].toString()),
        situation: json['SITUACION'],
        totalAmount: double.parse(json['TOTAL_AMOUNT'].toString()),
        taxAmount: double.parse(json['TAX_AMOUNT'].toString()),
        discountAmount: double.parse(json['DISCOUNT_AMOUNT'].toString()),
        productPriceFinal: double.parse(json['PRODUCT_PRICE_FINAL'].toString()),
        productPrice: double.parse(json['PRODUCT_PRICE'].toString()),
        totalBeforeDiscountWithoutTax: double.parse(json['TOTAL_BEFORE_DISCOUNT_WITHOUT_TAX'].toString()),
        totalAfterDiscountWithoutTax: double.parse(json['TOTAL_AFTER_DISCOUNT_WITHOUT_TAX'].toString()),
        orderDate: DateTime.parse(json['ORDER_DATE']),
        possibleStatusToTransitionTo: resultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList()
    );
  }
}