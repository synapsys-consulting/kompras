import 'dart:convert';
import 'package:intl/intl.dart' show NumberFormat hide TextDirection;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kompras/view/Cart.view.dart';
import 'package:kompras/view/CatalogManagement.view.dart';
import 'package:kompras/view/LoginView.view.dart';
import 'package:kompras/view/LookingForProducts.view.dart';
import 'package:kompras/view/ManageAddresses.view.dart';
import 'package:kompras/view/Menu.view.dart';
import 'package:kompras/view/PersonalData.view.dart';
import 'package:kompras/view/ProductView.view.dart';
import 'package:kompras/view/PurchaseView.view.dart';
import 'package:kompras/model/Cart.model.dart';
import 'package:kompras/model/Catalog.model.dart';
import 'package:kompras/model/ProductAvail.model.dart';
import 'package:kompras/util/DisplayDialog.util.dart';
import 'package:kompras/util/MultiPriceListElement.util.dart';
import 'package:kompras/util/ResponsiveWidget.util.dart';
import 'package:kompras/util/ShowSnackBar.util.dart';
import 'package:kompras/util/color.util.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:kompras/model/MultiPricesProductAvail.model.dart';
import 'package:kompras/util/PleaseWaitWidget.util.dart';
import 'package:kompras/util/configuration.util.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
class _MyHomePageState extends State<MyHomePage> {
  late Future<List<MultiPricesProductAvail>> itemsProductsAvailable;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final PleaseWaitWidget _pleaseWaitWidget = const PleaseWaitWidget(key: ObjectKey("pleaseWaitWidget"));
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late bool _isUserLogged;
  late String _name;
  bool _pleaseWait = false;
  late String _token;
  late String _roleId;
  String _role = '';

  _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _isUserLogged = false;
    _name = '';
    _token = '';
    _roleId = '';
    _role = '';
    itemsProductsAvailable = _getProductsAvailable();
  }

  // Private method which get the available products from the database
  Future<List<MultiPricesProductAvail>> _getProductsAvailable () async {
    final SharedPreferences prefs = await _prefs;
    String? token = prefs.get ('token')?.toString() ?? '';
    debugPrint ('El valor de token es: @@$token@@@@');
    debugPrint ('Antes del if del token == ');
    if (token == '') {
      final Uri url = Uri.parse('$SERVER_IP/getProductsAvailWithOutPartnerId');
      debugPrint('La URL con la que llamo al inicio de todo es: $SERVER_IP/getProductsAvailWithOutPartnerId');
      debugPrint('La URL con la que llamo al inicio de todo es: ${url.host}${url.path}');
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
        final List<Map<String, dynamic>> resultListJson = json.decode(res.body)['products'].cast<Map<String, dynamic>>();
        debugPrint ('Entre medias de la api RESPONSE.');
        final List<ProductAvail> resultListProducts = resultListJson.map<ProductAvail>((json) => ProductAvail.fromJson(json)).toList();
        final List<MultiPricesProductAvail> resultListMultiPriceProducts = [];
        int tmpProductCategoryIdPrevious = -20; // -20 is a negative value to initialize this var
        String tmpPersonNamePrevious = "";
        for (var element in resultListProducts) {
          //debugPrint ('El producto que cargo es: ' + element.productName);
          //debugPrint ('El producto_code que cargo es: ' + element.productCode.toString());
          if (element.productCategoryId != tmpProductCategoryIdPrevious && element.personeName != tmpPersonNamePrevious && element.rn == 1) {
            // Change the productCategoryId and the rn = 1, so start a new MultiPriceProductAvail
            tmpProductCategoryIdPrevious = element.productCategoryId;
            tmpPersonNamePrevious = element.personeName;
            final item = MultiPricesProductAvail(
                productId: element.productId,
                productCode: element.productCode,
                productName: element.productName,
                productNameLong: element.productNameLong,
                productDescription: element.productDescription,
                productType: element.productType,
                brand: element.brand,
                numImages: element.numImages,
                numVideos: element.numVideos,
                purchased: element.purchased,
                productPrice: element.productPrice,
                totalBeforeDiscount: element.totalBeforeDiscount,
                taxAmount: element.taxAmount,
                personeId: element.personeId,
                personeName: element.personeName,
                businessName: element.businessName,
                email: element.email,
                taxId: element.taxId,
                taxApply: element.taxApply,
                productPriceDiscounted: element.productPriceDiscounted,
                totalAmount: element.totalAmount,
                discountAmount: element.discountAmount,
                idUnit: element.idUnit,
                remark: element.remark,
                minQuantitySell: element.minQuantitySell,
                partnerId: element.partnerId,
                partnerName: element.partnerName,
                quantityMinPrice: element.quantityMinPrice,
                quantityMaxPrice: element.quantityMaxPrice,
                productCategoryId: element.productCategoryId,
                rn: element.rn
            );
            resultListMultiPriceProducts.add(item);
            //Provider.of<Catalog>(context, listen: false).add(element);
          } else if (element.productCategoryId == tmpProductCategoryIdPrevious && element.personeName == tmpPersonNamePrevious && element.rn > 1) {
            // The same ProductCategoryId and the same PersoneName, so it is another price of the same MultiPriceProductAvail
            tmpProductCategoryIdPrevious = element.productCategoryId;
            tmpPersonNamePrevious = element.personeName;
            resultListMultiPriceProducts.last.add(element);
            //Provider.of<Catalog>(context, listen: false).addChildrenToFatherElement(tmpProductIdFather, element);
          } else {
            // We consider this case imposible, but if it is, we consider it as a new MultiPriceProductAvail
            tmpProductCategoryIdPrevious = element.productCategoryId;
            tmpPersonNamePrevious = element.personeName;
            final item = MultiPricesProductAvail(
                productId: element.productId,
                productCode: element.productCode,
                productName: element.productName,
                productNameLong: element.productNameLong,
                productDescription: element.productDescription,
                productType: element.productType,
                brand: element.brand,
                numImages: element.numImages,
                numVideos: element.numVideos,
                purchased: element.purchased,
                productPrice: element.productPrice,
                totalBeforeDiscount: element.totalBeforeDiscount,
                taxAmount: element.taxAmount,
                personeId: element.personeId,
                personeName: element.personeName,
                businessName: element.businessName,
                email: element.email,
                taxId: element.taxId,
                taxApply: element.taxApply,
                productPriceDiscounted: element.productPriceDiscounted,
                totalAmount: element.totalAmount,
                discountAmount: element.discountAmount,
                idUnit: element.idUnit,
                remark: element.remark,
                minQuantitySell: element.minQuantitySell,
                partnerId: element.partnerId,
                partnerName: element.partnerName,
                quantityMinPrice: element.quantityMinPrice,
                quantityMaxPrice: element.quantityMaxPrice,
                productCategoryId: element.productCategoryId,
                rn: element.rn
            );
            resultListMultiPriceProducts.add(item);
            //Provider.of<Catalog>(context, listen: false).add(element);
          }
        }
        for (var element in resultListMultiPriceProducts) {
          Provider.of<Catalog>(context, listen: false).add(element);
        }
        debugPrint ('Antes de terminar de responder la API.');
        return resultListMultiPriceProducts;
      } else {
        final List<MultiPricesProductAvail> resultListProducts = [];
        return resultListProducts;
      }
    } else {
      Map<String, dynamic> payload;
      payload = json.decode(
          utf8.decode(
              base64.decode (base64.normalize(token.split(".")[1]))
          )
      );
      debugPrint('El partner_id es: ${payload['partner_id']}');
      debugPrint('La URL con la que llamo al inicio de todo es: $SERVER_IP/getProductsAvailWithPartnerId/${payload['partner_id']}');

      final Uri url = Uri.parse('$SERVER_IP/getProductsAvailWithPartnerId/${payload['partner_id']}');
      debugPrint('La URL con la que llamo al inicio de todo es: ${url.host}${url.path}');

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
        final List<Map<String, dynamic>> resultListJson = json.decode(res.body)['products'].cast<Map<String, dynamic>>();
        debugPrint ('Entre medias de la api RESPONSE.');
        debugPrint ('Aquí estoy yo');
        final List<ProductAvail> resultListProducts = resultListJson.map<ProductAvail>((json) => ProductAvail.fromJson(json)).toList();
        final List<MultiPricesProductAvail> resultListMultiPriceProducts = [];
        int tmpProductCategoryIdPrevious = -20; // -20 is a negative value to initialize this var
        String tmpPersonNamePrevious = "";
        for (var element in resultListProducts) {
          //debugPrint ('El producto que cargo es: ' + element.productName);
          //debugPrint ('El producto_code que cargo es: ' + element.productCode.toString());
          if (element.productCategoryId != tmpProductCategoryIdPrevious && element.personeName != tmpPersonNamePrevious && element.rn == 1) {
            // Change the productCategoryId and the rn = 1, so start a new MultiPriceProductAvail
            tmpProductCategoryIdPrevious = element.productCategoryId;
            tmpPersonNamePrevious = element.personeName;
            final item = MultiPricesProductAvail(
                productId: element.productId,
                productCode: element.productCode,
                productName: element.productName,
                productNameLong: element.productNameLong,
                productDescription: element.productDescription,
                productType: element.productType,
                brand: element.brand,
                numImages: element.numImages,
                numVideos: element.numVideos,
                purchased: element.purchased,
                productPrice: element.productPrice,
                totalBeforeDiscount: element.totalBeforeDiscount,
                taxAmount: element.taxAmount,
                personeId: element.personeId,
                personeName: element.personeName,
                businessName: element.businessName,
                email: element.email,
                taxId: element.taxId,
                taxApply: element.taxApply,
                productPriceDiscounted: element.productPriceDiscounted,
                totalAmount: element.totalAmount,
                discountAmount: element.discountAmount,
                idUnit: element.idUnit,
                remark: element.remark,
                minQuantitySell: element.minQuantitySell,
                partnerId: element.partnerId,
                partnerName: element.partnerName,
                quantityMinPrice: element.quantityMinPrice,
                quantityMaxPrice: element.quantityMaxPrice,
                productCategoryId: element.productCategoryId,
                rn: element.rn
            );
            resultListMultiPriceProducts.add(item);
          } else if (element.productCategoryId == tmpProductCategoryIdPrevious && element.personeName == tmpPersonNamePrevious && element.rn > 1) {
            // The same ProductCategoryId and the same PersoneName, so it is another price of the same MultiPriceProductAvail
            tmpProductCategoryIdPrevious = element.productCategoryId;
            tmpPersonNamePrevious = element.personeName;
            resultListMultiPriceProducts.last.add(element);
          } else {
            // We consider tis case imposible, but if it is, we consider it as a new MultiPriceProductAvail
            tmpProductCategoryIdPrevious = element.productCategoryId;
            tmpPersonNamePrevious = element.personeName;
            final item = MultiPricesProductAvail(
                productId: element.productId,
                productCode: element.productCode,
                productName: element.productName,
                productNameLong: element.productNameLong,
                productDescription: element.productDescription,
                productType: element.productType,
                brand: element.brand,
                numImages: element.numImages,
                numVideos: element.numVideos,
                purchased: element.purchased,
                productPrice: element.productPrice,
                totalBeforeDiscount: element.totalBeforeDiscount,
                taxAmount: element.taxAmount,
                personeId: element.personeId,
                personeName: element.personeName,
                businessName: element.businessName,
                email: element.email,
                taxId: element.taxId,
                taxApply: element.taxApply,
                productPriceDiscounted: element.productPriceDiscounted,
                totalAmount: element.totalAmount,
                discountAmount: element.discountAmount,
                idUnit: element.idUnit,
                remark: element.remark,
                minQuantitySell: element.minQuantitySell,
                partnerId: element.partnerId,
                partnerName: element.partnerName,
                quantityMinPrice: element.quantityMinPrice,
                quantityMaxPrice: element.quantityMaxPrice,
                productCategoryId: element.productCategoryId,
                rn: element.rn
            );
            resultListMultiPriceProducts.add(item);
          }
        }
        debugPrint ('Después del estoy aquí');
        for (var element in resultListMultiPriceProducts) {
          Provider.of<Catalog>(context, listen: false).add(element);
        }
        debugPrint ('Antes de terminar de responder la API.');
        //return resultListProducts;
        return resultListMultiPriceProducts;
      } else {
        final List<MultiPricesProductAvail> resultListProducts = [];
        return resultListProducts;
      }
    }
  }

  Drawer _createEndDrawer (BuildContext context, bool isUserLogged, String name) {
    var catalog = context.watch<Catalog>();
    var cart = context.read<Cart>();

    if (isUserLogged) {
      if (_role == "SELLER") {
        // The user role lets change the product catalog
        // There is another one menu option
        return MenuView (
          child: ListView (
            padding: EdgeInsets.zero,
            children: [
              ListTile (
                title: SafeArea (
                  child: Text (
                      name,
                      style: const TextStyle (
                          fontSize: 24.0,
                          color: tanteLadenIconBrown,
                          fontFamily: 'SF Pro Display',
                          fontWeight: FontWeight.bold
                      )
                  ),
                ),
              ),
              const Divider(),
              ListTile (
                leading: IconButton(
                  icon: Image.asset ('assets/images/logoPersonalData.png'),
                  onPressed: null,
                ),
                title: const Text(
                  'Datos personales',
                  style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.normal
                  ),
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => PersonalData(_token)
                  ));
                },
              ),
              const Divider(),
              ListTile (
                leading: IconButton (
                    icon: Image.asset ('assets/images/logoDirections.png'),
                    onPressed: null
                ),
                title: const Text (
                  'Direcciones',
                  style: TextStyle (
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.normal
                  ),
                ),
                onTap: () {
                  Map<String, dynamic> payload;
                  payload = json.decode(
                      utf8.decode(
                          base64.decode (base64.normalize(_token.split(".")[1]))
                      )
                  );
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => ManageAddresses(payload['persone_id'].toString(), payload['user_id'].toString())
                  ));
                },
              ),
              const Divider(),
              ListTile (
                leading: IconButton (
                  icon: Image.asset ('assets/images/logoPaymentMethod1.png'),
                  onPressed: null,
                ),
                title: const Text(
                  'Métodos de pago',
                  style: TextStyle (
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.normal
                  ),
                ),
              ),
              const Divider(),
              ListTile (
                leading: IconButton (
                  icon: Image.asset ('assets/images/logoMyPurchases.png'),
                  onPressed: null,
                ),
                title: const Text(
                  'Mis pedidos',
                  style: TextStyle (
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.normal
                  ),
                ),
                onTap: () {
                  Map<String, dynamic> payload;
                  payload = json.decode(
                      utf8.decode(
                          base64.decode (base64.normalize(_token.split(".")[1]))
                      )
                  );
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => PurchaseView(userId: payload['user_id'], partnerId: payload['partner_id'], userRole: payload['role'])
                  ));
                },
              ),
              const Divider(),
              ListTile (
                leading: IconButton (
                  icon: Image.asset('assets/images/logoHelp.png'),
                  onPressed: null,
                ),
                title: const Text (
                  'Catálogo',
                  style: TextStyle (
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.normal
                  ),
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const CatalogManagement()
                  ));
                },
              ),
              const Divider(),
              ListTile (
                leading: IconButton (
                  icon: Image.asset ('assets/images/logoHelp.png'),
                  onPressed: null,
                ),
                title: const Text(
                  'Ayuda',
                  style: TextStyle (
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.normal
                  ),
                ),
              ),
              const Divider(),
              ListTile (
                leading: IconButton (
                  icon: Image.asset ('assets/images/logoInformation.png'),
                  onPressed: null,
                ),
                title: const Text (
                  'Información',
                  style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.normal
                  ),
                ),
              ),
              const Divider(),
              ListTile (
                leading: IconButton (
                  icon: Image.asset ('assets/images/logoExit.png'),
                  onPressed: null,
                ),
                title: const Text (
                  'Salir',
                  style: TextStyle (
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.normal
                  ),
                ),
                onTap: () async {
                  try {
                    debugPrint('Estoy en el salir.');
                    //debugPrint('Después de watch y read.');
                    final SharedPreferences prefs = await _prefs;
                    prefs.setString ('token', '');
                    final Uri url = Uri.parse('$SERVER_IP/getProductsAvailWithOutPartnerId');
                    final http.Response resProducts = await http.get (
                        url,
                        headers: <String, String>{
                          'Content-Type': 'application/json; charset=UTF-8',
                          //'Authorization': jwt
                        }
                    );
                    debugPrint('After the http call.');
                    if (resProducts.statusCode == 200) {
                      debugPrint ('The Rest API has responsed.');
                      final List<Map<String, dynamic>> resultListJson = json.decode(resProducts.body)['products'].cast<Map<String, dynamic>>();
                      debugPrint ('Entre medias de la api RESPONSE.');
                      final List<ProductAvail> resultListProducts = resultListJson.map<ProductAvail>((json) => ProductAvail.fromJson(json)).toList();
                      final List<MultiPricesProductAvail> resultListMultiPriceProducts = [];
                      int tmpProductCategoryIdPrevious = -20;   // -20 is a negative value to initialize this var
                      String tmpPersonNamePrevious = "";
                      debugPrint ('Entre medias de la api RESPONSE.');
                      //Provider.of<Catalog>(context, listen: false).clearCatalog();
                      catalog.removeCatalog();
                      for (var element in resultListProducts) {
                        //debugPrint ('El producto que cargo es: ' + element.productName);
                        //debugPrint ('El producto_code que cargo es: ' + element.productCode.toString());
                        if (element.productCategoryId != tmpProductCategoryIdPrevious && element.personeName != tmpPersonNamePrevious && element.rn == 1) {
                          // Change the productCategoryId and the rn = 1, so start a new MultiPriceProductAvail
                          tmpProductCategoryIdPrevious = element.productCategoryId;
                          tmpPersonNamePrevious = element.personeName;
                          final item = MultiPricesProductAvail(
                              productId: element.productId,
                              productCode: element.productCode,
                              productName: element.productName,
                              productNameLong: element.productNameLong,
                              productDescription: element.productDescription,
                              productType: element.productType,
                              brand: element.brand,
                              numImages: element.numImages,
                              numVideos: element.numVideos,
                              purchased: element.purchased,
                              productPrice: element.productPrice,
                              totalBeforeDiscount: element.totalBeforeDiscount,
                              taxAmount: element.taxAmount,
                              personeId: element.personeId,
                              personeName: element.personeName,
                              businessName: element.businessName,
                              email: element.email,
                              taxId: element.taxId,
                              taxApply: element.taxApply,
                              productPriceDiscounted: element.productPriceDiscounted,
                              totalAmount: element.totalAmount,
                              discountAmount: element.discountAmount,
                              idUnit: element.idUnit,
                              remark: element.remark,
                              minQuantitySell: element.minQuantitySell,
                              partnerId: element.partnerId,
                              partnerName: element.partnerName,
                              quantityMinPrice: element.quantityMinPrice,
                              quantityMaxPrice: element.quantityMaxPrice,
                              productCategoryId: element.productCategoryId,
                              rn: element.rn
                          );
                          resultListMultiPriceProducts.add(item);
                          //Provider.of<Catalog>(context, listen: false).add(element);
                        } else if (element.productCategoryId == tmpProductCategoryIdPrevious && element.personeName == tmpPersonNamePrevious && element.rn > 1) {
                          // The same ProductCategoryId and the same PersoneName, so it is another price of the same MultiPriceProductAvail
                          tmpProductCategoryIdPrevious = element.productCategoryId;
                          tmpPersonNamePrevious = element.personeName;
                          resultListMultiPriceProducts.last.add(element);
                          //Provider.of<Catalog>(context, listen: false).addChildrenToFatherElement(tmpProductIdFather, element);
                        } else {
                          // We consider tis case imposible, but if it is, we consider it as a new MultiPriceProductAvail
                          tmpProductCategoryIdPrevious = element.productCategoryId;
                          tmpPersonNamePrevious = element.personeName;
                          final item = MultiPricesProductAvail(
                              productId: element.productId,
                              productCode: element.productCode,
                              productName: element.productName,
                              productNameLong: element.productNameLong,
                              productDescription: element.productDescription,
                              productType: element.productType,
                              brand: element.brand,
                              numImages: element.numImages,
                              numVideos: element.numVideos,
                              purchased: element.purchased,
                              productPrice: element.productPrice,
                              totalBeforeDiscount: element.totalBeforeDiscount,
                              taxAmount: element.taxAmount,
                              personeId: element.personeId,
                              personeName: element.personeName,
                              businessName: element.businessName,
                              email: element.email,
                              taxId: element.taxId,
                              taxApply: element.taxApply,
                              productPriceDiscounted: element.productPriceDiscounted,
                              totalAmount: element.totalAmount,
                              discountAmount: element.discountAmount,
                              idUnit: element.idUnit,
                              remark: element.remark,
                              minQuantitySell: element.minQuantitySell,
                              partnerId: element.partnerId,
                              partnerName: element.partnerName,
                              quantityMinPrice: element.quantityMinPrice,
                              quantityMaxPrice: element.quantityMaxPrice,
                              productCategoryId: element.productCategoryId,
                              rn: element.rn
                          );
                          resultListMultiPriceProducts.add(item);
                          //Provider.of<Catalog>(context, listen: false).add(element);
                        }
                      }
                      for (var element in resultListMultiPriceProducts) {
                        Provider.of<Catalog>(context, listen: false).add(element);
                      }
                      debugPrint ('Antes de terminar de responder la API.');
                      if (cart.numItems > 0) {
                        //Add the elements which are in the cart to the catalog
                        debugPrint('El número de items es:${cart.numItems}');
                        for (var element in cart.items) {
                          debugPrint('El valor de product_name es: ${element.productName}');
                          if (element.partnerId != DEFAULT_PARTNER_ID) {
                            cart.remove(element);
                          }
                        }
                      }
                      debugPrint ('Despues de terminar de responder la API.');
                    }
                    Navigator.pop(context);
                  } catch (err) {
                    Navigator.pop(context);
                  }
                },
              ),
              const Divider(),
            ],
          ),
        );
      } else {
        // BUYER, PRO_DELIBERY, KRR_DELIBERY
        return MenuView (
          child: ListView (
            padding: EdgeInsets.zero,
            children: [
              ListTile (
                title: SafeArea (
                  child: Text (
                      name,
                      style: const TextStyle (
                          fontSize: 24.0,
                          color: tanteLadenIconBrown,
                          fontFamily: 'SF Pro Display',
                          fontWeight: FontWeight.bold
                      )
                  ),
                ),
              ),
              const Divider(),
              ListTile (
                leading: IconButton(
                  icon: Image.asset ('assets/images/logoPersonalData.png'),
                  onPressed: null,
                ),
                title: const Text(
                  'Datos personales',
                  style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.normal
                  ),
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => PersonalData(_token)
                  ));
                },
              ),
              const Divider(),
              ListTile (
                leading: IconButton (
                    icon: Image.asset ('assets/images/logoDirections.png'),
                    onPressed: null
                ),
                title: const Text (
                  'Direcciones',
                  style: TextStyle (
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.normal
                  ),
                ),
                onTap: () {
                  Map<String, dynamic> payload;
                  payload = json.decode(
                      utf8.decode(
                          base64.decode (base64.normalize(_token.split(".")[1]))
                      )
                  );
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => ManageAddresses(payload['persone_id'].toString(), payload['user_id'].toString())
                  ));
                },
              ),
              const Divider(),
              ListTile (
                leading: IconButton (
                  icon: Image.asset ('assets/images/logoPaymentMethod1.png'),
                  onPressed: null,
                ),
                title: const Text(
                  'Métodos de pago',
                  style: TextStyle (
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.normal
                  ),
                ),
              ),
              const Divider(),
              ListTile (
                leading: IconButton (
                  icon: Image.asset ('assets/images/logoMyPurchases.png'),
                  onPressed: null,
                ),
                title: const Text(
                  'Mis pedidos',
                  style: TextStyle (
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.normal
                  ),
                ),
                onTap: () {
                  Map<String, dynamic> payload;
                  payload = json.decode(
                      utf8.decode(
                          base64.decode (base64.normalize(_token.split(".")[1]))
                      )
                  );
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => PurchaseView(userId: payload['user_id'], partnerId: payload['partner_id'], userRole: payload['role'])
                  ));
                },
              ),
              const Divider(),
              ListTile (
                leading: IconButton (
                  icon: Image.asset('assets/images/logoUpCatalog.png'),
                  onPressed: null,
                ),
                title: const Text (
                  'Catálogo',
                  style: TextStyle (
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.normal
                  ),
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const CatalogManagement()
                  ));
                },
              ),
              const Divider(),
              ListTile (
                leading: IconButton (
                  icon: Image.asset ('assets/images/logoHelp.png'),
                  onPressed: null,
                ),
                title: const Text(
                  'Ayuda',
                  style: TextStyle (
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.normal
                  ),
                ),
              ),
              const Divider(),
              ListTile (
                leading: IconButton (
                  icon: Image.asset ('assets/images/logoInformation.png'),
                  onPressed: null,
                ),
                title: const Text (
                  'Información',
                  style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.normal
                  ),
                ),
              ),
              const Divider(),
              ListTile (
                leading: IconButton (
                  icon: Image.asset ('assets/images/logoExit.png'),
                  onPressed: null,
                ),
                title: const Text (
                  'Salir',
                  style: TextStyle (
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.normal
                  ),
                ),
                onTap: () async {
                  try {
                    debugPrint('Estoy en el salir.');
                    //debugPrint('Después de watch y read.');
                    final SharedPreferences prefs = await _prefs;
                    prefs.setString ('token', '');
                    final Uri url = Uri.parse('$SERVER_IP/getProductsAvailWithOutPartnerId');
                    final http.Response resProducts = await http.get (
                        url,
                        headers: <String, String>{
                          'Content-Type': 'application/json; charset=UTF-8',
                          //'Authorization': jwt
                        }
                    );
                    debugPrint('After the http call.');
                    if (resProducts.statusCode == 200) {
                      debugPrint ('The Rest API has responsed.');
                      final List<Map<String, dynamic>> resultListJson = json.decode(resProducts.body)['products'].cast<Map<String, dynamic>>();
                      debugPrint ('Entre medias de la api RESPONSE.');
                      final List<ProductAvail> resultListProducts = resultListJson.map<ProductAvail>((json) => ProductAvail.fromJson(json)).toList();
                      final List<MultiPricesProductAvail> resultListMultiPriceProducts = [];
                      int tmpProductCategoryIdPrevious = -20; // -20 is a negative value to initialize this var
                      String tmpPersonNamePrevious = "";
                      debugPrint ('Entre medias de la api RESPONSE.');
                      //Provider.of<Catalog>(context, listen: false).clearCatalog();
                      catalog.removeCatalog();
                      for (var element in resultListProducts) {
                        //debugPrint ('El producto que cargo es: ' + element.productName);
                        //debugPrint ('El producto_code que cargo es: ' + element.productCode.toString());
                        if (element.productCategoryId != tmpProductCategoryIdPrevious && element.personeName != tmpPersonNamePrevious && element.rn == 1) {
                          // Change the productCategoryId and the rn = 1, so start a new MultiPriceProductAvail
                          tmpProductCategoryIdPrevious = element.productCategoryId;
                          tmpPersonNamePrevious = element.personeName;
                          final item = MultiPricesProductAvail(
                              productId: element.productId,
                              productCode: element.productCode,
                              productName: element.productName,
                              productNameLong: element.productNameLong,
                              productDescription: element.productDescription,
                              productType: element.productType,
                              brand: element.brand,
                              numImages: element.numImages,
                              numVideos: element.numVideos,
                              purchased: element.purchased,
                              productPrice: element.productPrice,
                              totalBeforeDiscount: element.totalBeforeDiscount,
                              taxAmount: element.taxAmount,
                              personeId: element.personeId,
                              personeName: element.personeName,
                              businessName: element.businessName,
                              email: element.email,
                              taxId: element.taxId,
                              taxApply: element.taxApply,
                              productPriceDiscounted: element.productPriceDiscounted,
                              totalAmount: element.totalAmount,
                              discountAmount: element.discountAmount,
                              idUnit: element.idUnit,
                              remark: element.remark,
                              minQuantitySell: element.minQuantitySell,
                              partnerId: element.partnerId,
                              partnerName: element.partnerName,
                              quantityMinPrice: element.quantityMinPrice,
                              quantityMaxPrice: element.quantityMaxPrice,
                              productCategoryId: element.productCategoryId,
                              rn: element.rn
                          );
                          resultListMultiPriceProducts.add(item);
                          //Provider.of<Catalog>(context, listen: false).add(element);
                        } else if (element.productCategoryId == tmpProductCategoryIdPrevious && element.personeName == tmpPersonNamePrevious && element.rn > 1) {
                          // The same ProductCategoryId and the same PersoneName, so it is another price of the same MultiPriceProductAvail
                          tmpProductCategoryIdPrevious = element.productCategoryId;
                          tmpPersonNamePrevious = element.personeName;
                          resultListMultiPriceProducts.last.add(element);
                          //Provider.of<Catalog>(context, listen: false).addChildrenToFatherElement(tmpProductIdFather, element);
                        } else {
                          // We consider tis case imposible, but if it is, we consider it as a new MultiPriceProductAvail
                          tmpProductCategoryIdPrevious = element.productCategoryId;
                          tmpPersonNamePrevious = element.personeName;
                          final item = MultiPricesProductAvail(
                              productId: element.productId,
                              productCode: element.productCode,
                              productName: element.productName,
                              productNameLong: element.productNameLong,
                              productDescription: element.productDescription,
                              productType: element.productType,
                              brand: element.brand,
                              numImages: element.numImages,
                              numVideos: element.numVideos,
                              purchased: element.purchased,
                              productPrice: element.productPrice,
                              totalBeforeDiscount: element.totalBeforeDiscount,
                              taxAmount: element.taxAmount,
                              personeId: element.personeId,
                              personeName: element.personeName,
                              businessName: element.businessName,
                              email: element.email,
                              taxId: element.taxId,
                              taxApply: element.taxApply,
                              productPriceDiscounted: element.productPriceDiscounted,
                              totalAmount: element.totalAmount,
                              discountAmount: element.discountAmount,
                              idUnit: element.idUnit,
                              remark: element.remark,
                              minQuantitySell: element.minQuantitySell,
                              partnerId: element.partnerId,
                              partnerName: element.partnerName,
                              quantityMinPrice: element.quantityMinPrice,
                              quantityMaxPrice: element.quantityMaxPrice,
                              productCategoryId: element.productCategoryId,
                              rn: element.rn
                          );
                          resultListMultiPriceProducts.add(item);
                          //Provider.of<Catalog>(context, listen: false).add(element);
                        }
                      }
                      for (var element in resultListMultiPriceProducts) {
                        Provider.of<Catalog>(context, listen: false).add(element);
                      }
                      debugPrint ('Antes de terminar de responder la API.');
                      if (cart.numItems > 0) {
                        //Add the elements which are in the cart to the catalog
                        debugPrint('El número de items es:${cart.numItems}');
                        for (var element in cart.items) {
                          debugPrint('El valor de product_name es: ${element.productName}');
                          if (element.partnerId != DEFAULT_PARTNER_ID) {
                            cart.remove(element);
                          }
                        }
                      }
                      debugPrint ('Despues de terminar de responder la API.');
                    }
                    Navigator.pop(context);
                  } catch (err) {
                    Navigator.pop(context);
                  }
                },
              ),
              const Divider(),
            ],
          ),
        );
      }
    } else {
      return MenuView (
        child: ListView (
          padding: EdgeInsets.zero,
          children: [
            const ListTile (
                title: SafeArea (
                  child: Text('Invitado',
                    style: TextStyle (
                        fontSize: 24.0,
                        color: tanteLadenIconBrown,
                        fontFamily: 'SF Pro Display',
                        fontWeight: FontWeight.bold
                    ),
                  ),
                )
            ),
            const Divider(),
            const SizedBox(height: 50.0),
            const Padding (
              padding: EdgeInsets.symmetric (horizontal: 15.0),
              child: Center(
                child: Text (
                  'Identifícate',
                  style: TextStyle (
                      fontSize: 20.0,
                      color: tanteLadenOnPrimary,
                      fontFamily: 'SF Pro Display',
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ),
            const SizedBox (height: 10.0,),
            const Padding (
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: Center (
                child: Text (
                  'Para poder comprar, necesitas una cuenta, así podrás comprar más rápido y también te podremos dar un mejor servicio.',
                  style: TextStyle (
                    fontSize: 16.0,
                    fontFamily: 'SF Pro Display',
                    fontWeight: FontWeight.normal,
                    color: tanteLadenOnPrimary,
                  ),
                  textAlign: TextAlign.justify,
                  maxLines: 4,
                  softWrap: true,
                ),
              ),
            ),
            const SizedBox (height: 20.0,),
            Padding (
              padding: const EdgeInsets.all(15.0),
              child: GestureDetector (
                child: Container (
                  padding: const EdgeInsets.symmetric(horizontal: 80.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration (
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(8.0),
                      gradient: const LinearGradient(
                          colors: <Color>[
                            Color (0xFF833C26),
                            //Color (0XFF863F25),
                            //Color (0xFF8E4723),
                            Color (0xFF9A541F),
                            //Color (0xFFB16D1A),
                            //Color (0xFFDE9C0D),
                            Color (0xFFF9B806),
                            Color (0XFFFFC107),
                          ]
                      )
                  ),
                  height: 64.0,
                  child: const Text(
                    'Identifícate',
                    style: TextStyle(
                        fontSize: 18.0,
                        color: tanteLadenBackgroundWhite
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.push (
                      context,
                      MaterialPageRoute (
                          builder: (context) => (const LoginView(reason: COME_FROM_DRAWER))   //  1 the call comes from the drawer. 2 the call comes from cart.view.dart
                      )
                  );
                },
              ),
            ),
            const SizedBox (height: 20.0,),
            const Divider(),
            ListTile (
              leading: IconButton (
                icon: Image.asset ('assets/images/logoHelp.png'),
                onPressed: null,
              ),
              title: const Text(
                'Ayuda',
                style: TextStyle (
                    fontFamily: 'SF Pro Display',
                    fontSize: 20,
                    fontWeight: FontWeight.normal
                ),
              ),
            ),
            const Divider(),
            ListTile (
              leading: IconButton (
                icon: Image.asset ('assets/images/logoInformation.png'),
                onPressed: null,
              ),
              title: const Text (
                'Información',
                style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 20,
                    fontWeight: FontWeight.normal
                ),
              ),
            ),
            const Divider(),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    Widget tmpBuilder = IconButton (
        icon: Image.asset ('assets/images/profile.png'),
        tooltip: 'Perfil',
        onPressed: () async {
          try {
            _showPleaseWait(true);
            final SharedPreferences prefs = await _prefs;
            String? token = prefs.get ('token')?.toString() ?? '';
            debugPrint ('El token es: $token');
            debugPrint ('El token es #######: $token');
            if (token == '') {
              debugPrint ('Me he metido en la parte del If. Por lo que NO hay token.');
              _isUserLogged = false;
              _name = '';
              _token = '';
            } else {
              debugPrint ('Me he metido en la parte del else. Por lo que hay token.');
              debugPrint ('El token es: $token');
              debugPrint ('JUSTO ANTES DE PARTIR EL TOKEN.');
              Map<String, dynamic> payload;
              payload = json.decode(
                  utf8.decode(
                      base64.decode (base64.normalize(token.split(".")[1]))
                  )
              );
              debugPrint ('JUSTO DESPUES DE PARTIR EL TOKEN.');
              _token = token;
              _isUserLogged = true;
              debugPrint('Antes de sacar el payload el nombre y el apellido');
              _name = payload['user_firstname'] + ' ' + payload['user_lastname'];
              debugPrint('Antes de sacar el rid');
              //_roleId = payload['rid'];
              debugPrint('Antes de sacar el role');
              _role = payload['role'];
              debugPrint('Después de sacar el role y por lo tanto terminar');
            }
            _showPleaseWait(false);

            _scaffoldKey.currentState?.openEndDrawer();
          } catch (e) {
            if (!context.mounted) return;
            debugPrint ('ME VOY POR EL ERROR AL PARTIR EL TOKEN.');
            ShowSnackBar.showSnackBar(context, e.toString(), error: true);
          }
        }
    );
    return Scaffold (
      key: _scaffoldKey,
      appBar: AppBar (
        //backgroundColor: Theme.of(context).primaryColor,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        leading: Builder (
            builder: (BuildContext context) {
              return Container (
                alignment: Alignment.centerRight,
                child: IconButton(
                  //icon: Image.asset('assets/images/cart_fill_round.png'),
                  icon: Image.asset('assets/images/logoPantallaInicioAmber.png'),
                  onPressed: null,
                ),
              );
            }
        ),
        title: SizedBox (
          height: kToolbarHeight,
          child: Row (
            children: [
              Flexible(
                flex: 1,
                child: IconButton(
                    icon: Image.asset('assets/images/search_left.png'),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => const LookingForProducts()
                      ));
                    }
                ),
              ),
              const Spacer(),
              Flexible(
                flex: 1,
                child: IconButton(
                    icon: Image.asset('assets/images/love.png'),
                    onPressed: null
                ),
              ),
              Flexible(
                flex: 1,
                child: Consumer <Cart>(
                  builder: (context, cart, child) => cart.numItems > 0 ?
                  Stack (
                    alignment: AlignmentDirectional.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                        alignment: AlignmentDirectional.center,
                        child: Text(
                          cart.numItems.toString(),
                          style: const TextStyle (
                              fontWeight: FontWeight.bold,
                              backgroundColor: Colors.white,
                              fontSize: 10.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black
                          ),
                        ),
                      ),
                      IconButton(
                          icon: Image.asset('assets/images/shopping_cart.png'),
                          onPressed: () async {
                            Navigator.push(context, MaterialPageRoute(
                                builder: (context) => const CartView()
                            ));
                          }
                      )
                    ],
                  ):
                  Stack (
                    alignment: AlignmentDirectional.center,
                    children: [
                      Container(
                        alignment: AlignmentDirectional.center,
                        child: IconButton(
                            icon: Image.asset('assets/images/shopping_cart.png'),
                            onPressed: (){
                              Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => const CartView()
                              ));
                            }
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
        actions: <Widget>[
          _pleaseWait
              ? Stack (key:  const ObjectKey("stack"), alignment: AlignmentDirectional.center, children: [tmpBuilder, _pleaseWaitWidget],)
              : Stack (key:  const ObjectKey("stack"), children: [tmpBuilder])
        ],
        elevation: 0.0,
      ),
      endDrawer: _createEndDrawer (context, _isUserLogged,_name),
      body: FutureBuilder <List<MultiPricesProductAvail>> (
          future: itemsProductsAvailable,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              //final List<ProductAvail>listProductsAvail = snapshot.data;
              return ResponsiveWidget (
                largeScreen: _LargeScreen(),
                mediumScreen: _MediumScreen(),
                smallScreen: _SmallScreen(),
              );
            } else if (snapshot.hasError) {
              return Center (
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error. ${snapshot.error}')
                    ]
                ),
              );
            } else {
              return const Center (
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(),
                ),
              );
            }
          }
      ),
    );
  }
}
class _SmallScreen extends StatefulWidget {
  @override
  _SmallScreenState createState() => _SmallScreenState();
}
class _SmallScreenState extends State<_SmallScreen>{
  @override
  void initState() {
    super.initState();
  }
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var catalog = context.watch<Catalog>();
    var cart = context.read<Cart>();
    return SafeArea (
      child: Padding (
          padding: const EdgeInsets.only(top: 5.0),
          child: GridView.builder (
              itemCount: catalog.numItems,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 200.0 / 303.0
              ),
              itemBuilder: (BuildContext context, int index) {
                return Card (
                  clipBehavior: Clip.antiAlias,
                  elevation: 0,
                  shape: ContinuousRectangleBorder(
                      borderRadius: BorderRadius.circular(0.0)
                  ),
                  child: LayoutBuilder (
                    builder: (context, constraints) {
                      return Column (
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row (
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector (
                                onTap: () {
                                  Navigator.push (
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ProductView(catalog.items[index])
                                      )
                                  );
                                },
                                child: Container(
                                  //padding: EdgeInsets.fromLTRB(15.0, 5.0, 15.0, 0.0),
                                  alignment: Alignment.center,
                                  width: constraints.maxWidth,
                                  child: AspectRatio(
                                    aspectRatio: 3.0 / 2.0,
                                    child: CachedNetworkImage(
                                      placeholder: (context, url) => const CircularProgressIndicator(),
                                      imageUrl: '$SERVER_IP$IMAGES_DIRECTORY${catalog.items[index].productCode}_0.gif',
                                      fit: BoxFit.scaleDown,
                                      errorWidget: (context, url, error) => const Icon(Icons.error),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                          Container (
                            padding: const EdgeInsets.fromLTRB (15.0, 0.0, 0.0, 0.0),
                            child: Row (
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container (
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Image.asset('assets/images/00001.png'),
                                ),
                                Container (
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text.rich (
                                    TextSpan (
                                        text: NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((catalog.items[index].totalAmountAccordingQuantity/MULTIPLYING_FACTOR).toString())),
                                        style: const TextStyle (
                                          fontWeight: FontWeight.w500,
                                          fontSize: 24.0,
                                          fontFamily: 'SF Pro Display',
                                        ),
                                        //textAlign: TextAlign.start
                                        children: <TextSpan>[
                                          TextSpan (
                                            text: catalog.items[index].totalAmountAccordingQuantity == catalog.items[index].totalAmount
                                                ? ''
                                                : ' (${NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((catalog.items[index].totalAmount/MULTIPLYING_FACTOR).toString()))})',
                                            style: const TextStyle (
                                              fontWeight: FontWeight.w300,
                                              fontSize: 11.0,
                                              fontFamily: 'SF Pro Display',
                                              color: Color(0xFF6C6D77),
                                            ),
                                          )
                                        ]
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                                catalog.items[index].quantityMaxPrice != QUANTITY_MAX_PRICE ? Container (
                                  padding: EdgeInsets.zero,
                                  width: 20.0,
                                  height: 20.0,
                                  child: IconButton (
                                    alignment: Alignment.centerRight,
                                    padding: EdgeInsets.zero,
                                    icon: Image.asset (
                                      'assets/images/logoInfo.png',
                                      //fit: BoxFit.fill,
                                      width: 20.0,
                                      height: 20.0,
                                    ),
                                    iconSize: 20.0,
                                    onPressed: () {
                                      final List<MultiPriceListElement> listMultiPriceListElement = [];
                                      if (catalog.items[index].quantityMaxPrice != QUANTITY_MAX_PRICE) {
                                        // There is multiprice for this product
                                        final item = MultiPriceListElement(catalog.items[index].quantityMinPrice, catalog.items[index].quantityMaxPrice, catalog.items[index].totalAmount);
                                        listMultiPriceListElement.add(item);
                                        catalog.items[index].items.where((element) => element.partnerId != 1)
                                            .forEach((element) {
                                          final item = MultiPriceListElement(element.quantityMinPrice, element.quantityMaxPrice, element.totalAmount);
                                          listMultiPriceListElement.add(item);
                                        });
                                      }
                                      DisplayDialog.displayInformationAsATable (context, 'Descuentos por cantidad comprada:', listMultiPriceListElement);
                                    },
                                  ),
                                ) : Container()
                              ],
                            ),
                          ),
                          Row (
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container (
                                padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                                width: constraints.maxWidth,
                                child: Text (
                                  catalog.items[index].productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.start,
                                  overflow: TextOverflow.fade,
                                  maxLines: 1,
                                  softWrap: false,
                                ),
                              )
                            ],
                          ),
                          Row (
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container (
                                padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                                child: Text (
                                  catalog.items[index].businessName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w300,
                                    fontSize: 12.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Color(0xFF6C6D77),
                                  ),
                                  textAlign: TextAlign.start,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              )
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 0.0),
                            child: Visibility(
                              visible : catalog.items[index].purchased == 0,
                              replacement: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    (catalog.items[index].purchased > 1) ? '${catalog.items[index].purchased} ${catalog.items[index].idUnit}s.' : '${catalog.items[index].purchased} ${catalog.items[index].idUnit}.',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 24.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: tanteLadenIconBrown,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  Row (
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Visibility(
                                          visible: (catalog.items[index].purchased > 1) ? true : false,
                                          replacement: TextButton(
                                            child: Container (
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.rectangle,
                                                borderRadius: BorderRadius.circular(18.0),
                                                color: tanteLadenAmber500,
                                              ),
                                              padding: EdgeInsets.zero,
                                              child: IconButton(
                                                onPressed: null,
                                                icon: Image.asset(
                                                  'assets/images/logoDeleteKlein.png',
                                                  fit: BoxFit.fill,
                                                ),
                                                iconSize: 20.0,
                                                padding: const EdgeInsets.all(8.0),
                                              ),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                cart.remove(catalog.items[index]);
                                                catalog.remove(catalog.items[index]);
                                              });
                                            },
                                          ),
                                          child: TextButton(
                                            child: Container (
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.rectangle,
                                                  borderRadius: BorderRadius.circular(18.0),
                                                  color: tanteLadenAmber500,
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                                child: const Text(
                                                  '-',
                                                  style: TextStyle(
                                                      fontFamily: 'SF Pro Display',
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.w900,
                                                      color: tanteLadenIconBrown
                                                  ),
                                                )
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                if (catalog.items[index].purchased > 1) {
                                                  cart.remove(catalog.items[index]);
                                                  catalog.remove(catalog.items[index]);
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      const Expanded(
                                        flex: 1,
                                        child: SizedBox(
                                          width: 10.0,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: TextButton(
                                          child: Container (
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.rectangle,
                                              borderRadius: BorderRadius.circular(18.0),
                                              //color: colorFondo,
                                              color: tanteLadenAmber500,
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                                            child: const Text (
                                              '+',
                                              style: TextStyle (
                                                fontFamily: 'SF Pro Display',
                                                fontSize: 24,
                                                fontWeight: FontWeight.w900,
                                                color: tanteLadenIconBrown,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              cart.add(catalog.items[index]);
                                              catalog.add(catalog.items[index]);
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text (
                                          'Unids. mín. venta: ${catalog.items[index].minQuantitySell} ${(catalog.items[index].minQuantitySell > 1) ? '${catalog.items[index].idUnit}s.' : '${catalog.items[index].idUnit}.'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w300,
                                            fontSize: 11.0,
                                            fontFamily: 'SF Pro Display',
                                            fontStyle: FontStyle.normal,
                                            color: Color(0xFF6C6D77),
                                          ),
                                          textAlign: TextAlign.start
                                      )
                                    ],
                                  ),
                                  TextButton (
                                      onPressed: () {
                                        setState(() {
                                          catalog.add(catalog.getItem(index));
                                          cart.add(catalog.getItem(index));
                                        });
                                      },
                                      child: Container(
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.all(2.0),
                                        decoration: BoxDecoration (
                                            shape: BoxShape.rectangle,
                                            borderRadius: BorderRadius.circular(4.0),
                                            color: tanteLadenBrown500,
                                            gradient: const LinearGradient(
                                              colors: <Color>[
                                                Color (0xFF833C26),
                                                Color (0xFF9A541F),
                                                Color (0xFFF9B806),
                                                Color (0XFFFFC107),
                                              ],
                                            )
                                        ),
                                        height: 40,
                                        child: Container(
                                          //padding: EdgeInsets.all(3.0),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.rectangle,
                                              borderRadius: BorderRadius.circular(4.0),
                                              //color: colorFondo,
                                              color: tanteLadenBackgroundWhite
                                          ),
                                          child: const Text (
                                            'Añadir',
                                            style: TextStyle (
                                              fontFamily: 'SF Pro Display',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          //height: 38,
                                        ),
                                      )
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              }
          )
      ),
    );
  }
  
}
class _MediumScreen extends StatefulWidget {
  @override
  _MediumScreenState createState() => _MediumScreenState();
}
class _MediumScreenState extends State<_MediumScreen>{
  @override
  void initState() {
    super.initState();
  }
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var catalog = context.watch<Catalog>();
    var cart = context.read<Cart>();
    return SafeArea (
      child: Padding (
          padding: const EdgeInsets.only(top: 5.0),
          child: GridView.builder (
              itemCount: catalog.numItems,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 200.0 / 303.0
              ),
              itemBuilder: (BuildContext context, int index) {
                return Card (
                  clipBehavior: Clip.antiAlias,
                  elevation: 0,
                  shape: ContinuousRectangleBorder(
                      borderRadius: BorderRadius.circular(0.0)
                  ),
                  child: LayoutBuilder (
                    builder: (context, constraints) {
                      return Column (
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row (
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector (
                                onTap: () {
                                  Navigator.push (
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ProductView(catalog.items[index])
                                      )
                                  );
                                },
                                child: Container(
                                  //padding: EdgeInsets.fromLTRB(15.0, 5.0, 15.0, 0.0),
                                  alignment: Alignment.center,
                                  width: constraints.maxWidth,
                                  child: AspectRatio(
                                    aspectRatio: 3.0 / 2.0,
                                    child: CachedNetworkImage(
                                      placeholder: (context, url) => const CircularProgressIndicator(),
                                      imageUrl: '$SERVER_IP$IMAGES_DIRECTORY${catalog.items[index].productCode}_0.gif',
                                      fit: BoxFit.scaleDown,
                                      errorWidget: (context, url, error) => const Icon(Icons.error),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                          Container (
                            padding: const EdgeInsets.fromLTRB (15.0, 0.0, 0.0, 0.0),
                            child: Row (
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container (
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Image.asset('assets/images/00001.png'),
                                ),
                                Container (
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text.rich (
                                    TextSpan (
                                        text: NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((catalog.items[index].totalAmountAccordingQuantity/MULTIPLYING_FACTOR).toString())),
                                        style: const TextStyle (
                                          fontWeight: FontWeight.w500,
                                          fontSize: 24.0,
                                          fontFamily: 'SF Pro Display',
                                        ),
                                        //textAlign: TextAlign.start
                                        children: <TextSpan>[
                                          TextSpan (
                                            text: catalog.items[index].totalAmountAccordingQuantity == catalog.items[index].totalAmount
                                                ? ''
                                                : ' (${NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((catalog.items[index].totalAmount/MULTIPLYING_FACTOR).toString()))})',
                                            style: const TextStyle (
                                              fontWeight: FontWeight.w300,
                                              fontSize: 11.0,
                                              fontFamily: 'SF Pro Display',
                                              color: Color(0xFF6C6D77),
                                            ),
                                          )
                                        ]
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                                catalog.items[index].quantityMaxPrice != QUANTITY_MAX_PRICE ? Container (
                                  padding: EdgeInsets.zero,
                                  width: 20.0,
                                  height: 20.0,
                                  child: IconButton (
                                    alignment: Alignment.centerRight,
                                    padding: EdgeInsets.zero,
                                    icon: Image.asset (
                                      'assets/images/logoInfo.png',
                                      //fit: BoxFit.fill,
                                      width: 20.0,
                                      height: 20.0,
                                    ),
                                    iconSize: 20.0,
                                    onPressed: () {
                                      final List<MultiPriceListElement> listMultiPriceListElement = [];
                                      if (catalog.items[index].quantityMaxPrice != QUANTITY_MAX_PRICE) {
                                        // There is multiprice for this product
                                        final item = MultiPriceListElement(catalog.items[index].quantityMinPrice, catalog.items[index].quantityMaxPrice, catalog.items[index].totalAmount);
                                        listMultiPriceListElement.add(item);
                                        catalog.items[index].items.where((element) => element.partnerId != 1)
                                            .forEach((element) {
                                          final item = MultiPriceListElement(element.quantityMinPrice, element.quantityMaxPrice, element.totalAmount);
                                          listMultiPriceListElement.add(item);
                                        });
                                      }
                                      DisplayDialog.displayInformationAsATable (context, 'Descuentos por cantidad comprada:', listMultiPriceListElement);
                                    },
                                  ),
                                ) : Container()
                              ],
                            ),
                          ),
                          Row (
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container (
                                padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                                width: constraints.maxWidth,
                                child: Text (
                                  catalog.items[index].productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.start,
                                  overflow: TextOverflow.fade,
                                  maxLines: 1,
                                  softWrap: false,
                                ),
                              )
                            ],
                          ),
                          Row (
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container (
                                padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                                child: Text (
                                  catalog.items[index].businessName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w300,
                                    fontSize: 12.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Color(0xFF6C6D77),
                                  ),
                                  textAlign: TextAlign.start,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              )
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 0.0),
                            child: Visibility(
                              visible : catalog.items[index].purchased == 0,
                              replacement: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    (catalog.items[index].purchased > 1) ? '${catalog.items[index].purchased} ${catalog.items[index].idUnit}s.' : '${catalog.items[index].purchased} ${catalog.items[index].idUnit}.',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 24.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: tanteLadenIconBrown,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  Row (
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Visibility(
                                          visible: (catalog.items[index].purchased > 1) ? true : false,
                                          replacement: TextButton(
                                            child: Container (
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.rectangle,
                                                borderRadius: BorderRadius.circular(18.0),
                                                color: tanteLadenAmber500,
                                              ),
                                              padding: EdgeInsets.zero,
                                              child: IconButton(
                                                onPressed: null,
                                                icon: Image.asset(
                                                  'assets/images/logoDeleteKlein.png',
                                                  fit: BoxFit.fill,
                                                ),
                                                iconSize: 20.0,
                                                padding: const EdgeInsets.all(8.0),
                                              ),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                cart.remove(catalog.items[index]);
                                                catalog.remove(catalog.items[index]);
                                              });
                                            },
                                          ),
                                          child: TextButton(
                                            child: Container (
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.rectangle,
                                                  borderRadius: BorderRadius.circular(18.0),
                                                  color: tanteLadenAmber500,
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                                child: const Text(
                                                  '-',
                                                  style: TextStyle(
                                                      fontFamily: 'SF Pro Display',
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.w900,
                                                      color: tanteLadenIconBrown
                                                  ),
                                                )
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                if (catalog.items[index].purchased > 1) {
                                                  cart.remove(catalog.items[index]);
                                                  catalog.remove(catalog.items[index]);
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      const Expanded(
                                        flex: 1,
                                        child: SizedBox(
                                          width: 10.0,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: TextButton(
                                          child: Container (
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.rectangle,
                                              borderRadius: BorderRadius.circular(18.0),
                                              //color: colorFondo,
                                              color: tanteLadenAmber500,
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                                            child: const Text (
                                              '+',
                                              style: TextStyle (
                                                fontFamily: 'SF Pro Display',
                                                fontSize: 24,
                                                fontWeight: FontWeight.w900,
                                                color: tanteLadenIconBrown,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              cart.add(catalog.items[index]);
                                              catalog.add(catalog.items[index]);
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text (
                                          'Unids. mín. venta: ${catalog.items[index].minQuantitySell} ${(catalog.items[index].minQuantitySell > 1) ? '${catalog.items[index].idUnit}s.' : '${catalog.items[index].idUnit}.'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w300,
                                            fontSize: 11.0,
                                            fontFamily: 'SF Pro Display',
                                            fontStyle: FontStyle.normal,
                                            color: Color(0xFF6C6D77),
                                          ),
                                          textAlign: TextAlign.start
                                      )
                                    ],
                                  ),
                                  TextButton (
                                      onPressed: () {
                                        setState(() {
                                          catalog.add(catalog.getItem(index));
                                          cart.add(catalog.getItem(index));
                                        });
                                      },
                                      child: Container(
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.all(2.0),
                                        decoration: BoxDecoration (
                                            shape: BoxShape.rectangle,
                                            borderRadius: BorderRadius.circular(4.0),
                                            color: tanteLadenBrown500,
                                            gradient: const LinearGradient(
                                              colors: <Color>[
                                                Color (0xFF833C26),
                                                Color (0xFF9A541F),
                                                Color (0xFFF9B806),
                                                Color (0XFFFFC107),
                                              ],
                                            )
                                        ),
                                        height: 40,
                                        child: Container(
                                          //padding: EdgeInsets.all(3.0),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.rectangle,
                                              borderRadius: BorderRadius.circular(4.0),
                                              //color: colorFondo,
                                              color: tanteLadenBackgroundWhite
                                          ),
                                          child: const Text (
                                            'Añadir',
                                            style: TextStyle (
                                              fontFamily: 'SF Pro Display',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          //height: 38,
                                        ),
                                      )
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              }
          )
      ),
    );
  }

}
class _LargeScreen extends StatefulWidget {
  @override
  _LargeScreenState createState() => _LargeScreenState();
}
class _LargeScreenState extends State<_LargeScreen>{
  @override
  void initState() {
    super.initState();
  }
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var catalog = context.watch<Catalog>();
    var cart = context.read<Cart>();
    return SafeArea (
      child: Padding (
          padding: const EdgeInsets.only(top: 5.0),
          child: GridView.builder (
              itemCount: catalog.numItems,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 200.0 / 303.0
              ),
              itemBuilder: (BuildContext context, int index) {
                return Card (
                  clipBehavior: Clip.antiAlias,
                  elevation: 0,
                  shape: ContinuousRectangleBorder(
                      borderRadius: BorderRadius.circular(0.0)
                  ),
                  child: LayoutBuilder (
                    builder: (context, constraints) {
                      return Column (
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row (
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector (
                                onTap: () {
                                  Navigator.push (
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ProductView(catalog.items[index])
                                      )
                                  );
                                },
                                child: Container(
                                  //padding: EdgeInsets.fromLTRB(15.0, 5.0, 15.0, 0.0),
                                  alignment: Alignment.center,
                                  width: constraints.maxWidth,
                                  child: AspectRatio(
                                    aspectRatio: 3.0 / 2.0,
                                    child: CachedNetworkImage(
                                      placeholder: (context, url) => const CircularProgressIndicator(),
                                      imageUrl: '$SERVER_IP$IMAGES_DIRECTORY${catalog.items[index].productCode}_0.gif',
                                      fit: BoxFit.scaleDown,
                                      errorWidget: (context, url, error) => const Icon(Icons.error),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                          Container (
                            padding: const EdgeInsets.fromLTRB (15.0, 0.0, 0.0, 0.0),
                            child: Row (
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container (
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Image.asset('assets/images/00001.png'),
                                ),
                                Container (
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text.rich (
                                    TextSpan (
                                        text: NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((catalog.items[index].totalAmountAccordingQuantity/MULTIPLYING_FACTOR).toString())),
                                        style: const TextStyle (
                                          fontWeight: FontWeight.w500,
                                          fontSize: 24.0,
                                          fontFamily: 'SF Pro Display',
                                        ),
                                        //textAlign: TextAlign.start
                                        children: <TextSpan>[
                                          TextSpan (
                                            text: catalog.items[index].totalAmountAccordingQuantity == catalog.items[index].totalAmount
                                                ? ''
                                                : ' (${NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((catalog.items[index].totalAmount/MULTIPLYING_FACTOR).toString()))})',
                                            style: const TextStyle (
                                              fontWeight: FontWeight.w300,
                                              fontSize: 11.0,
                                              fontFamily: 'SF Pro Display',
                                              color: Color(0xFF6C6D77),
                                            ),
                                          )
                                        ]
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                                catalog.items[index].quantityMaxPrice != QUANTITY_MAX_PRICE ? Container (
                                  padding: EdgeInsets.zero,
                                  width: 20.0,
                                  height: 20.0,
                                  child: IconButton (
                                    alignment: Alignment.centerRight,
                                    padding: EdgeInsets.zero,
                                    icon: Image.asset (
                                      'assets/images/logoInfo.png',
                                      //fit: BoxFit.fill,
                                      width: 20.0,
                                      height: 20.0,
                                    ),
                                    iconSize: 20.0,
                                    onPressed: () {
                                      final List<MultiPriceListElement> listMultiPriceListElement = [];
                                      if (catalog.items[index].quantityMaxPrice != QUANTITY_MAX_PRICE) {
                                        // There is multiprice for this product
                                        final item = MultiPriceListElement(catalog.items[index].quantityMinPrice, catalog.items[index].quantityMaxPrice, catalog.items[index].totalAmount);
                                        listMultiPriceListElement.add(item);
                                        catalog.items[index].items.where((element) => element.partnerId != 1)
                                            .forEach((element) {
                                          final item = MultiPriceListElement(element.quantityMinPrice, element.quantityMaxPrice, element.totalAmount);
                                          listMultiPriceListElement.add(item);
                                        });
                                      }
                                      DisplayDialog.displayInformationAsATable (context, 'Descuentos por cantidad comprada:', listMultiPriceListElement);
                                    },
                                  ),
                                ) : Container()
                              ],
                            ),
                          ),
                          Row (
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container (
                                padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                                width: constraints.maxWidth,
                                child: Text (
                                  catalog.items[index].productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.start,
                                  overflow: TextOverflow.fade,
                                  maxLines: 1,
                                  softWrap: false,
                                ),
                              )
                            ],
                          ),
                          Row (
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container (
                                padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                                child: Text (
                                  catalog.items[index].businessName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w300,
                                    fontSize: 12.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Color(0xFF6C6D77),
                                  ),
                                  textAlign: TextAlign.start,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              )
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 0.0),
                            child: Visibility(
                              visible : catalog.items[index].purchased == 0,
                              replacement: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    (catalog.items[index].purchased > 1) ? '${catalog.items[index].purchased} ${catalog.items[index].idUnit}s.' : '${catalog.items[index].purchased} ${catalog.items[index].idUnit}.',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 24.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: tanteLadenIconBrown,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  Row (
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Visibility(
                                          visible: (catalog.items[index].purchased > 1) ? true : false,
                                          replacement: TextButton(
                                            child: Container (
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.rectangle,
                                                borderRadius: BorderRadius.circular(18.0),
                                                color: tanteLadenAmber500,
                                              ),
                                              padding: EdgeInsets.zero,
                                              child: IconButton(
                                                onPressed: null,
                                                icon: Image.asset(
                                                  'assets/images/logoDeleteKlein.png',
                                                  fit: BoxFit.fill,
                                                ),
                                                iconSize: 20.0,
                                                padding: const EdgeInsets.all(8.0),
                                              ),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                cart.remove(catalog.items[index]);
                                                catalog.remove(catalog.items[index]);
                                              });
                                            },
                                          ),
                                          child: TextButton(
                                            child: Container (
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.rectangle,
                                                  borderRadius: BorderRadius.circular(18.0),
                                                  color: tanteLadenAmber500,
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                                child: const Text(
                                                  '-',
                                                  style: TextStyle(
                                                      fontFamily: 'SF Pro Display',
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.w900,
                                                      color: tanteLadenIconBrown
                                                  ),
                                                )
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                if (catalog.items[index].purchased > 1) {
                                                  cart.remove(catalog.items[index]);
                                                  catalog.remove(catalog.items[index]);
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      const Expanded(
                                        flex: 1,
                                        child: SizedBox(
                                          width: 10.0,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: TextButton(
                                          child: Container (
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.rectangle,
                                              borderRadius: BorderRadius.circular(18.0),
                                              //color: colorFondo,
                                              color: tanteLadenAmber500,
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                                            child: const Text (
                                              '+',
                                              style: TextStyle (
                                                fontFamily: 'SF Pro Display',
                                                fontSize: 24,
                                                fontWeight: FontWeight.w900,
                                                color: tanteLadenIconBrown,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              cart.add(catalog.items[index]);
                                              catalog.add(catalog.items[index]);
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text (
                                          'Unids. mín. venta: ${catalog.items[index].minQuantitySell} ${(catalog.items[index].minQuantitySell > 1) ? '${catalog.items[index].idUnit}s.' : '${catalog.items[index].idUnit}.'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w300,
                                            fontSize: 11.0,
                                            fontFamily: 'SF Pro Display',
                                            fontStyle: FontStyle.normal,
                                            color: Color(0xFF6C6D77),
                                          ),
                                          textAlign: TextAlign.start
                                      )
                                    ],
                                  ),
                                  TextButton (
                                      onPressed: () {
                                        setState(() {
                                          catalog.add(catalog.getItem(index));
                                          cart.add(catalog.getItem(index));
                                        });
                                      },
                                      child: Container(
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.all(2.0),
                                        decoration: BoxDecoration (
                                            shape: BoxShape.rectangle,
                                            borderRadius: BorderRadius.circular(4.0),
                                            color: tanteLadenBrown500,
                                            gradient: const LinearGradient(
                                              colors: <Color>[
                                                Color (0xFF833C26),
                                                Color (0xFF9A541F),
                                                Color (0xFFF9B806),
                                                Color (0XFFFFC107),
                                              ],
                                            )
                                        ),
                                        height: 40,
                                        child: Container(
                                          //padding: EdgeInsets.all(3.0),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.rectangle,
                                              borderRadius: BorderRadius.circular(4.0),
                                              //color: colorFondo,
                                              color: tanteLadenBackgroundWhite
                                          ),
                                          child: const Text (
                                            'Añadir',
                                            style: TextStyle (
                                              fontFamily: 'SF Pro Display',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          //height: 38,
                                        ),
                                      )
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              }
          )
      ),
    );
  }

}