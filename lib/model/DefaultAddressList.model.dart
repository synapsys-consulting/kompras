import 'package:flutter/material.dart';
import 'package:kompras/model/Address.model.dart';

class DefaultAddressList extends ChangeNotifier {
  /// Internal, private state of the Warehouse. Stores the ids of each item.
  final List<Address> _items = [];

  List<Address> get items => _items;

  void add (Address item) {
    _items.clear();
    final itemAddress = Address (
        addrId: item.addrId,
        streetName: item.streetName,
        streetNumber: item.streetNumber,
        flatDoor: item.flatDoor,
        postalCode: item.postalCode,
        locality: item.locality,
        province: item.province,
        country: item.country,
        state: item.state,
        optional: item.optional,
        district: item.district,
        suburb: item.suburb,
        statusId: item.statusId
    );
    _items.add(itemAddress);
    notifyListeners();
  }
  Address  getItem (int index) {
    return _items[index];
  }
  int get numItems => _items.length;

  void clearDefaultAddressList () {
    _items.clear();
    notifyListeners();
  }
}