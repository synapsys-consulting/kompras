import 'package:flutter/foundation.dart';
import 'package:kompras/model/MultiPricesProductAvail.model.dart';

class Cart with ChangeNotifier {
  /// Internal, private state of the cart. Stores the ids of each item.
  final List<MultiPricesProductAvail> _items = [];
  double totalPrice= 0.0;
  double totalTax = 0.0;

  List<MultiPricesProductAvail> get items => _items;

  void add (MultiPricesProductAvail item) {
    bool founded = false;
    if (_items.isNotEmpty) {
      for (var element in items) {
        if (element.productId == item.productId) {
          element.purchased += element.minQuantitySell;   // Always purchase the minimum quantity sell
          element.totalAmountAccordingQuantity = element.getTotalAmountAccordingQuantity();   // Update the price according the quantity purchased
          founded = true;
        }
      }
    }
    if (!founded) {
      final itemCart = MultiPricesProductAvail (
          productId: item.productId,
          productCode: item.productCode,
          productName: item.productName,
          productNameLong: item.productNameLong,
          productDescription: item.productDescription,
          productType: item.productType,
          brand: item.brand,
          numImages: item.numImages,
          numVideos: item.numVideos,
          purchased: item.minQuantitySell,  // Always purchase the minimun quantity sell
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
          quantityMinPrice: item.quantityMinPrice,
          quantityMaxPrice: item.quantityMaxPrice,
          productCategoryId: item.productCategoryId,
          rn: item.rn
      );
      for (var element in item.items) {
        itemCart.items.add(element);
      }
      itemCart.totalAmountAccordingQuantity = itemCart.getTotalAmountAccordingQuantity();   // Update the price according the quantity purchased
      _items.add(itemCart);
    }
    totalPrice = _items.fold(0, (total, current) => total + (current.getTotalAmountAccordingQuantity() * current.purchased));
    totalTax = _items.fold(0, (total, current) => total + (((current.productPriceDiscountedAccordingQuantity() * current.taxApply)/100) * current.purchased));
    notifyListeners();
  }
  void remove (MultiPricesProductAvail item) {
    bool founded = false;
    MultiPricesProductAvail? tmpElement;
    if (_items.isNotEmpty) {
      for (var element in _items) {
        if (element.productId == item.productId) {
          if (element.purchased == element.minQuantitySell) {
            founded = true;
            tmpElement = element;
          } else {
            element.purchased -= element.minQuantitySell; // Always purchase the minimum quantity sell
            element.totalAmountAccordingQuantity = element.getTotalAmountAccordingQuantity(); // Update the price according the quantity purchased
          }
        }
      }
    }
    if (founded) {
      _items.remove(tmpElement);
    }
    totalPrice = _items.fold(0, (total, current) => total + (current.getTotalAmountAccordingQuantity() * current.purchased));
    totalTax = _items.fold(0, (total, current) => total + (((current.productPriceDiscountedAccordingQuantity() * current.taxApply)/100) * current.purchased));
    notifyListeners();
  }
  void incrementAvail (MultiPricesProductAvail item) {
    for (var element in items) {
      if (element.productId == item.productId) {
        element.purchased += element.minQuantitySell;
        element.totalAmountAccordingQuantity = element.getTotalAmountAccordingQuantity();   // Update the price according the quantity purchased
      }
    }  // Always purchase the minimum quantity sell
    totalPrice = _items.fold(0, (total, current) => total + (current.getTotalAmountAccordingQuantity() * current.purchased));
    totalTax = _items.fold(0, (total, current) => total + (((current.productPriceDiscountedAccordingQuantity() * current.taxApply)/100) * current.purchased));
    notifyListeners();
  }
  void decrementAvail (MultiPricesProductAvail item) {
    for (var element in items) {
      if (element.productId == item.productId) {
        element.purchased -= element.minQuantitySell;
        element.totalAmountAccordingQuantity = element.getTotalAmountAccordingQuantity();   // Update the price according the quantity purchased
      }
    }  // Always purchase the minimum quantity sell
    totalPrice = _items.fold(0, (total, current) => total + (current.getTotalAmountAccordingQuantity() * current.purchased));
    totalTax = _items.fold(0, (total, current) => total + (((current.productPriceDiscountedAccordingQuantity() * current.taxApply)/100) * current.purchased));
    notifyListeners();
  }

  MultiPricesProductAvail getItem (int index) {
    return _items[index];
  }

  void removeCart () {
    _items.clear();
    totalPrice = 0.0;
    totalTax = 0.0;
    notifyListeners();
  }

  int get numItems => _items.length;

}