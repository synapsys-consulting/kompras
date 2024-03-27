import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:kompras/model/NewProductData.model.dart';
import 'package:kompras/model/PriceChangeType.model.dart';
import 'package:kompras/model/ProductType.model.dart';
import 'package:kompras/model/ProviderProduct.model.dart';
import 'package:kompras/model/TaxType.model.dart';
import 'package:kompras/model/UnitType.model.dart';
import 'package:kompras/util/configuration.util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewProductService {

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Future<NewProductData> getNewProductData () async {
    NewProductData temp = NewProductData();

    final SharedPreferences prefs = await _prefs;
    final String token = prefs.getString ('token') ?? '';
    Map<String, dynamic> payload;
    payload = json.decode(
        utf8.decode(
            base64.decode (base64.normalize(token.split(".")[1]))
        )
    );
    final String partnerId = payload['partner_id'].toString();
    debugPrint ("Estoy en el getNewProductData");

    // getTaxType
    final Uri urlGetTaxType = Uri.parse ('$SERVER_IP/getTaxType');
    final http.Response resGetTaxType = await http.get (
        urlGetTaxType,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          //'Authorization': jwt
        }
    );
    debugPrint ('After the http call getTaxType.');
    if (resGetTaxType.statusCode == 200) {
      debugPrint ('The Rest API has responsed.');
      final List<Map<String, dynamic>> resultListJson = json.decode(resGetTaxType.body)['data'].cast<Map<String, dynamic>>();
      debugPrint ('Entre medias de la api RESPONSE.');
      final List<TaxType> resultListTaxTypes = resultListJson.map<TaxType>((json) => TaxType.fromJson(json)).toList();
      temp.taxTypeItems = resultListTaxTypes;
    } else {
      final List<TaxType> resultListTaxTypes = [];
      temp.taxTypeItems = resultListTaxTypes;
    }

    // getUnitType
    final Uri urlGetUnitType = Uri.parse ('$SERVER_IP/getUnitType');
    final http.Response resGetUnitType = await http.get (
        urlGetUnitType,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          //'Authorization': jwt
        }
    );
    debugPrint ('After the http call getUnitType.');
    if (resGetUnitType.statusCode == 200) {
      debugPrint ('The Rest API has responsed.');
      final List<Map<String, dynamic>> resultListJson = json.decode(resGetUnitType.body)['data'].cast<Map<String, dynamic>>();
      debugPrint ('Entre medias de la api RESPONSE.');
      final List<UnitType> resultListUnitTypes = resultListJson.map<UnitType>((json) => UnitType.fromJson(json)).toList();
      temp.unitTypeItems = resultListUnitTypes;
    } else {
      final List<UnitType> resultListUnitTypes = [];
      temp.unitTypeItems = resultListUnitTypes;
    }

    // getProviders
    final Uri urlProviders = Uri.parse ('$SERVER_IP/getProviders');
    final http.Response resProviders = await http.get (
        urlProviders,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          //'Authorization': jwt
        }
    );
    debugPrint ('After the http call getProviders.');
    if (resProviders.statusCode == 200) {
      debugPrint ('The Rest API has responsed.');
      final List<Map<String, dynamic>> resultListJson = json.decode(resProviders.body)['data'].cast<Map<String, dynamic>>();
      debugPrint ('Entre medias de la api RESPONSE.');
      final List<ProviderProduct> resultListProviders = resultListJson.map<ProviderProduct>((json) => ProviderProduct.fromJson(json)).toList();
      temp.providerItems = resultListProviders;
    } else {
      final List<ProviderProduct> resultListProviders = [];
      temp.providerItems = resultListProviders;
    }

    // getProductTypes
    final Uri urlProductTypes = Uri.parse ('$SERVER_IP/getProductTypes/$partnerId');
    final http.Response resProductTypes = await http.get (
        urlProductTypes,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          //'Authorization': jwt
        }
    );
    debugPrint ('After the http call getProductTypes.');
    if (resProductTypes.statusCode == 200) {
      debugPrint ('The Rest API has responsed.');
      final List<Map<String, dynamic>> resultListJson = json.decode(resProductTypes.body)['data'].cast<Map<String, dynamic>>();
      debugPrint ('Entre medias de la api RESPONSE.');
      final List<ProductType> resultListProductTypes = resultListJson.map<ProductType>((json) => ProductType.fromJson(json)).toList();
      temp.productTypeItems = resultListProductTypes;
    } else {
      final List<ProductType> resultListProductTypes = [];
      temp.productTypeItems = resultListProductTypes;
    }
    return temp;
  }
  void saveProduct({
    required int categoryId,
    required String productName,
    required int minQuantitySell,
    required double productPrice,
    required PriceChangeType discountType,
    required double discountValue,
    required String taxType,
    required String idUnit,
    required int weeksWarning,
    required double quantityMinPrice,
    required double quantityMaxPrice,
    required String productType,
    required String personeName,
    required int partnerId,
    required String partnerName,
    required int userCreateId
  }) async {
    final Uri url = Uri.parse('$SERVER_IP/saveNewProduct');
    await http.post (
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          //'Authorization': jwt
        },
        body: jsonEncode(<String, String>{
          'PRODUCT_CATEGORY_ID': categoryId.toString(),
          'PRODUCT_NAME': productName,
          'MIN_QUANTITY_SELL': minQuantitySell.toString(),
          'PRODUCT_PRICE': productPrice.toString(),
          'DISCOUNT_TYPE': discountType.toString(),
          'DISCOUNT_VALUE': discountValue.toString(),
          'TAX_TYPE': taxType.toString(),
          'ID_UNIT': idUnit.toString(),
          'WEEKS_WARNING': weeksWarning.toString(),
          'QUANTITY_MIN_PRICE': quantityMinPrice.toString(),
          'QUANTITY_MAX_PRICE': quantityMaxPrice.toString(),
          'PRODUCT_TYPE': productType,
          'PERSONE_NAME': personeName,
          'PARTNER_ID': partnerId.toString(),
          'PARTNER_NAME': partnerName,
          'USER_CREATE_ID': userCreateId.toString()
        })
    ).timeout(TIMEOUT);
  }
}