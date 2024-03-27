import 'package:flutter/material.dart';
import 'package:kompras/model/Address.model.dart';

class AddressesList extends ChangeNotifier {
  /// Internal, private state of the Warehouse. Stores the ids of each item.
  final List<Address> _items = [];

  List<Address> get items => _items;

  void add (Address item) {
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
  void remove (Address item) {
    bool founded = false;
    int indexTmp = 0;
    if (_items.isNotEmpty) {
      for (int j = 0; j < _items.length; j++) {
        if (_items[j].addrId == item.addrId) {
          founded = true;
          indexTmp = j;
        }
      }
      if (founded) {
        items.removeAt(indexTmp);
      }
    }
    notifyListeners();
  }
  Address getItem (int index) {
    return _items[index];
  }
  void clearAddressList () {
    _items.clear();
    notifyListeners();
  }
  int get numItems => _items.length;
}