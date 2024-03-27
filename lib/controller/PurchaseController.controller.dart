import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kompras/model/Purchase.model.dart';
import 'package:kompras/util/configuration.util.dart';
import 'package:http/http.dart' as http;

class PurchaseController {
  Future<List<Purchase>> getPurchasesByUserId (int userId) async {
    final Uri url = Uri.parse('$SERVER_IP/getPurchaseByUserId/$userId');
    final http.Response res = await http.get(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          //'Authorization': jwt
        }
    );
    debugPrint('After the http call.');
    if (res.statusCode == 200) {
      debugPrint('The Rest API has responsed.');
      final List<Map<String, dynamic>> resultListJson = json.decode(
          res.body)['result'].cast<Map<String, dynamic>>();
      debugPrint('Entre medias de la api RESPONSE.');
      final List<Purchase> resultListPurchase = resultListJson.map<Purchase>((
          json) => Purchase.fromJson(json)).toList();
      debugPrint('Justo antes de retornar de getPurchasesByUserId.');
      return resultListPurchase;
    } else {
      final List<Purchase> resultListPurchase = [];
      return resultListPurchase;
    }
  }
}