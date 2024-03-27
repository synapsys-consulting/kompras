import 'package:flutter/material.dart';

class VisibleButtonToPurchase with ChangeNotifier {
  final List<bool> _items = [];

  List<bool> get items => _items;

  void add (bool item) {
    _items.add(item);
    notifyListeners();
  }
  void remove (bool item){
    _items.remove(item);
    notifyListeners();
  }
  bool getItem (int index) {
    return _items[index];
  }
  void clearVisibleButtonToPurchase () {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = true;
      notifyListeners();
    }
  }
  int get numItems => _items.length;
  void setItem (int index, bool value) {
    _items[index] = value;
    notifyListeners();
  }
}