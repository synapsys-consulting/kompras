import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kompras/model/PurchaseLine.model.dart';
import 'package:kompras/util/configuration.util.dart';
import 'package:http/http.dart' as http;

class PurchaseDetailController {
  Future<List<PurchaseLine>> getPurchaseLinesByOrderId (int userId, int orderId, String providerName) async {
    final Uri url = Uri.parse('$SERVER_IP/getPurchaseLinesByOrderId/$userId/$orderId/$providerName');
    debugPrint ('La URI a la que llamamos es: $SERVER_IP/getPurchaseLinesByOrderId/$userId/$orderId/$providerName');
    final http.Response res = await http.get (
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          //'Authorization': jwt
        }
    );
    debugPrint('After the http call.');
    if (res.statusCode == 200) {
      debugPrint ('The Rest API has responsed.');
      final List<Map<String, dynamic>> resultListJson = json.decode(res.body)['result'].cast<Map<String, dynamic>>();
      debugPrint ('Entre medias de la api RESPONSE.');
      final List<PurchaseLine> resultListPurchase = resultListJson.map<PurchaseLine>((json) => PurchaseLine.fromJson(json)).toList();
      debugPrint ('Justo antes de retornar del getPurchaseLinesByOrderId.');
      return resultListPurchase;
    } else {
      final List<PurchaseLine> resultListPurchase = [];
      return resultListPurchase;
    }
  }
}