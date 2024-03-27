import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kompras/View/AddAddressView.view.dart';
import 'package:kompras/View/ConfirmPurchase.view.dart';
import 'package:kompras/model/Address.model.dart';
import 'package:kompras/model/Cart.model.dart';
import 'package:kompras/model/Catalog.model.dart';
import 'package:kompras/model/MultiPricesProductAvail.model.dart';
import 'package:kompras/model/ProductAvail.model.dart';
import 'package:kompras/util/PleaseWaitWidget.util.dart';
import 'package:kompras/util/ResponsiveWidget.util.dart';
import 'package:kompras/util/ShowSnackBar.util.dart';
import 'package:kompras/util/color.util.dart';
import 'package:kompras/util/configuration.util.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SignUpView extends StatelessWidget {
  const SignUpView(this.email, this.reason, {super.key});
  final String email;
  final int reason;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        leading: IconButton (
          icon: Image.asset('assets/images/leftArrow.png'),
          onPressed: () {
            Navigator.pop (context);
          },
        ),
        actions: <Widget>[
          IconButton(
              icon: Image.asset ('assets/images/logoQuestion.png'),
              onPressed: null
          )
        ],
      ),
      body: ResponsiveWidget (
        smallScreen: _SmallScreenView (email, reason),
        mediumScreen: _MediumScreenView(email, reason),
        largeScreen: _LargeScreenView (email, reason),
      ),
    );
  }
}
class _SmallScreenView extends StatefulWidget {
  const _SmallScreenView (this.email, this.reason);
  final String email;
  final int reason;
  @override
  _SmallScreenViewState createState() {
    return _SmallScreenViewState();
  }
}
class _SmallScreenViewState extends State<_SmallScreenView> {
  bool _pleaseWait = false;
  bool _passwordNoVisible = true;
  final PleaseWaitWidget _pleaseWaitWidget = const PleaseWaitWidget(key: ObjectKey("pleaseWaitWidget"));
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _surname = TextEditingController();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }
  @override
  void initState() {
    super.initState();
    _passwordNoVisible = true;
    _pleaseWait = false;
  }
  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget tmpBuilder = Consumer<Cart>(
        builder: (context, cart, child) {
          return GestureDetector (
            onTap: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  debugPrint('El valor de user_name es: ${widget.email}');
                  _showPleaseWait (true);
                  final Uri url = Uri.parse('$SERVER_IP/register');
                  final http.Response res = await http.post (
                      url,
                      headers: <String, String>{
                        'Content-Type': 'application/json; charset=UTF-8',
                        //'Authorization': jwt
                      },
                      body: jsonEncode(<String, String>{
                        'user_name': widget.email,
                        'user_firstname': _name.text,
                        'user_lastname': _surname.text,
                        'password': _password.text,
                        'gethash': 'true'
                      })
                  );
                  if (res.statusCode == 200) {
                    // Sign up
                    final String token = json.decode(res.body)['token'].toString();
                    final SharedPreferences prefs = await _prefs;
                    prefs.setString('token', token);
                    // See if there is an address for this user
                    Map<String, dynamic> payload;
                    payload = json.decode(
                        utf8.decode(
                            base64.decode(base64.normalize(token.split(".")[1]))
                        )
                    );
                    if (payload['partner_id'] != DEFAULT_PARTNER_ID) {
                      // RELOAD THE PRODUCTS WHICH THE USER CAN BUY
                      final Uri url = Uri.parse('$SERVER_IP/getProductsAvailWithPartnerId/${payload['partner_id']}');
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
                        final List<ProductAvail> resultListProducts = resultListJson.map<ProductAvail>((json) => ProductAvail.fromJson(json)).toList();
                        final List<MultiPricesProductAvail> resultListMultiPriceProducts = [];
                        int tmpProductCategoryIdPrevious = -1;
                        String tmpPersonNamePrevious = "";
                        for (var element in resultListProducts) {
                          if (element.productCategoryId != tmpProductCategoryIdPrevious && element.personeName != tmpPersonNamePrevious && element.rn == 1) {
                            // Change the productCategoryId and the rn = 1, so start a new MultiPriceProductAvail
                            debugPrint ('El product_description retornado desde el API es: ${element.productName}');
                            tmpProductCategoryIdPrevious = element.productCategoryId;
                            tmpPersonNamePrevious = element.personeName;
                            final item = MultiPricesProductAvail (
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
                        debugPrint ('Entre medias de la api RESPONSE.');
                        cart.removeCart();
                        if (!context.mounted) return;
                        Provider.of<Catalog>(context, listen: false).removeCatalog();
                        for (var element in resultListMultiPriceProducts) {
                          Provider.of<Catalog>(context, listen: false).add(element);
                          //Provider.of<VisibleButtonToPurchase>(context, listen: false).add(true);
                        }
                        debugPrint ('Antes de terminar de responder la API.');
                        Navigator.popUntil(context, ModalRoute.withName('/'));
                      }
                    } else {
                      if (widget.reason == COME_FROM_ANOTHER) {
                        //  1 the call comes from the drawer. 2 the call comes from cart.view.dart
                        final Uri urlAddress = Uri.parse('$SERVER_IP/getDefaultLogisticAddress/${payload['user_id']}');
                        final http.Response resAddress = await http.get (
                            urlAddress,
                            headers: <String, String>{
                              'Content-Type': 'application/json; charset=UTF-8',
                              //'Authorization': jwt
                            }
                        );
                        if (resAddress.statusCode == 200) {
                          // exists an address for the user
                          final List<Map<String, dynamic>> resultListJson = json.decode(resAddress.body)['data'].cast<Map<String, dynamic>>();
                          final List<Address> resultListAddress = resultListJson.map<Address>((json) => Address.fromJson(json)).toList();
                          if (resultListAddress.isNotEmpty) {
                            // if exists address
                            _showPleaseWait(false);
                            if (!context.mounted) return;
                            Navigator.push (
                                context,
                                MaterialPageRoute (
                                    builder: (context) => (ConfirmPurchaseView(resultListAddress, payload['phone_number'].toString(), payload['user_id'].toString()))
                                )
                            );
                          } else {
                            // if not exists address
                            _showPleaseWait(false);
                            if (!context.mounted) return;
                            Navigator.push (
                                context,
                                MaterialPageRoute (
                                    builder: (context) => (AddAddressView(payload['persone_id'].toString(), payload['user_id'].toString()))
                                )
                            );
                          }
                        } else if (resAddress.statusCode == 404) {
                          // if not exists address
                          _showPleaseWait(false);
                          if (!context.mounted) return;
                          Navigator.push (
                              context,
                              MaterialPageRoute (
                                  builder: (context) => (AddAddressView(payload['persone_id'].toString(), payload['user_id'].toString()))
                              )
                          );
                        } else {
                          // Error
                          _showPleaseWait(false);
                          if (!context.mounted) return;
                          ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'].toString());
                        }
                      } else {
                        //  1 the call comes from the drawer. 2 the call comes from cart.view.dart
                        // The call comes from the drawer.
                        if (!context.mounted) return;
                        Navigator.popUntil(context, ModalRoute.withName('/'));
                      }
                    }
                  } else {
                    // Error
                    _showPleaseWait(false);
                    if (!context.mounted) return;
                    ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'].toString());
                  }
                } catch (e) {
                  _showPleaseWait(false);
                  if (!context.mounted) return;
                  ShowSnackBar.showSnackBar(context, e.toString(), error: true);
                }
              }
            },
            child: Container (
              height: 64.0,
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
                  ),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        offset: Offset (5,5),
                        blurRadius: 10
                    )
                  ]
              ),
              child: const Center (
                child: Text (
                  'Continuar',
                  style: TextStyle(
                      fontSize: 24.0,
                      color: tanteLadenBackgroundWhite
                  ),
                ),
              ),
            ),
          );
        }
    );
    return SafeArea(
        child: Center(
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text (
                      'Crear cuenta',
                      style: TextStyle (
                        fontWeight: FontWeight.w900,
                        fontSize: 36.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30.0,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text (
                      '¿Es tu primer pedido? Introduce tus datos',
                      style: TextStyle (
                        fontWeight: FontWeight.w500,
                        fontSize: 16.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  )
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text (
                      'para continuar.',
                      style: TextStyle (
                        fontWeight: FontWeight.w500,
                        fontSize: 16.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  )
                ],
              ),
              const SizedBox (height: 20.0,),
              Form (
                autovalidateMode: AutovalidateMode.always,
                key: _formKey,
                child: Column (
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration (
                        labelText: 'Nombre',
                        labelStyle: TextStyle (
                          color: tanteLadenIconBrown,
                        ),
                      ),
                      validator: (String? value) {
                        if (value == null) {
                          return 'Introduce tu nombre';
                        } else {
                          return null;
                        }
                      },
                    ),
                    const SizedBox(height: 20.0,),
                    TextFormField(
                      controller: _surname,
                      decoration: const InputDecoration (
                        labelText: 'Apellidos',
                        labelStyle: TextStyle (
                          color: tanteLadenIconBrown,
                        ),
                      ),
                      validator: (String? value) {
                        if (value == null) {
                          return 'Introduce tus apellidos';
                        } else {
                          return null;
                        }
                      },
                    ),
                    const SizedBox(height: 20.0,),
                    TextFormField(
                      controller: _password,
                      decoration: InputDecoration (
                        labelText: 'Contraseña',
                        labelStyle: const TextStyle (
                          color: tanteLadenIconBrown,
                        ),
                        suffixIcon: IconButton (
                            icon: Icon(_passwordNoVisible ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _passwordNoVisible = ! _passwordNoVisible;
                              });
                            }
                        ),
                      ),
                      validator: (String? value) {
                        if (value == null) {
                          return 'Introduce una password';
                        } else {
                          return null;
                        }
                      },
                      obscureText: _passwordNoVisible,
                    ),
                    const SizedBox(height: 50.0,),
                    _pleaseWait
                        ? Stack (
                      key:  const ObjectKey("stack"),
                      alignment: AlignmentDirectional.center,
                      children: [tmpBuilder, _pleaseWaitWidget],
                    )
                        : Stack (key:  const ObjectKey("stack"), children: [tmpBuilder],)
                  ],
                ),
              )
            ],
          ),
        )
    );
  }
}
class _MediumScreenView extends StatefulWidget {
  const _MediumScreenView (this.email, this.reason);
  final String email;
  final int reason;
  @override
  _MediumScreenViewState createState() {
    return _MediumScreenViewState();
  }
}
class _MediumScreenViewState extends State<_MediumScreenView> {
  bool _pleaseWait = false;
  bool _passwordNoVisible = true;
  final PleaseWaitWidget _pleaseWaitWidget = const PleaseWaitWidget(key: ObjectKey("pleaseWaitWidget"));
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _surname = TextEditingController();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }
  @override
  void initState() {
    super.initState();
    _passwordNoVisible = true;
    _pleaseWait = false;
  }
  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget tmpBuilder = Consumer<Cart>(
        builder: (context, cart, child) {
          return GestureDetector (
            onTap: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  debugPrint('El valor de user_name es: ${widget.email}');
                  _showPleaseWait (true);
                  final Uri url = Uri.parse('$SERVER_IP/register');
                  final http.Response res = await http.post (
                      url,
                      headers: <String, String>{
                        'Content-Type': 'application/json; charset=UTF-8',
                        //'Authorization': jwt
                      },
                      body: jsonEncode(<String, String>{
                        'user_name': widget.email,
                        'user_firstname': _name.text,
                        'user_lastname': _surname.text,
                        'password': _password.text,
                        'gethash': 'true'
                      })
                  );
                  if (res.statusCode == 200) {
                    // Sign up
                    final String token = json.decode(res.body)['token'].toString();
                    final SharedPreferences prefs = await _prefs;
                    prefs.setString('token', token);
                    // See if there is an address for this user
                    Map<String, dynamic> payload;
                    payload = json.decode(
                        utf8.decode(
                            base64.decode(base64.normalize(token.split(".")[1]))
                        )
                    );
                    if (payload['partner_id'] != DEFAULT_PARTNER_ID) {
                      // RELOAD THE PRODUCTS WHICH THE USER CAN BUY
                      final Uri url = Uri.parse('$SERVER_IP/getProductsAvailWithPartnerId/${payload['partner_id']}');
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
                        final List<ProductAvail> resultListProducts = resultListJson.map<ProductAvail>((json) => ProductAvail.fromJson(json)).toList();
                        final List<MultiPricesProductAvail> resultListMultiPriceProducts = [];
                        int tmpProductCategoryIdPrevious = -1;
                        String tmpPersonNamePrevious = "";
                        for (var element in resultListProducts) {
                          if (element.productCategoryId != tmpProductCategoryIdPrevious && element.personeName != tmpPersonNamePrevious && element.rn == 1) {
                            // Change the productCategoryId and the rn = 1, so start a new MultiPriceProductAvail
                            debugPrint ('El product_description retornado desde el API es: ${element.productName}');
                            tmpProductCategoryIdPrevious = element.productCategoryId;
                            tmpPersonNamePrevious = element.personeName;
                            final item = MultiPricesProductAvail (
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
                        debugPrint ('Entre medias de la api RESPONSE.');
                        cart.removeCart();
                        if (!context.mounted) return;
                        Provider.of<Catalog>(context, listen: false).removeCatalog();
                        for (var element in resultListMultiPriceProducts) {
                          Provider.of<Catalog>(context, listen: false).add(element);
                          //Provider.of<VisibleButtonToPurchase>(context, listen: false).add(true);
                        }
                        debugPrint ('Antes de terminar de responder la API.');
                        Navigator.popUntil(context, ModalRoute.withName('/'));
                      }
                    } else {
                      if (widget.reason == COME_FROM_ANOTHER) {
                        //  1 the call comes from the drawer. 2 the call comes from cart.view.dart
                        final Uri urlAddress = Uri.parse('$SERVER_IP/getDefaultLogisticAddress/${payload['user_id']}');
                        final http.Response resAddress = await http.get (
                            urlAddress,
                            headers: <String, String>{
                              'Content-Type': 'application/json; charset=UTF-8',
                              //'Authorization': jwt
                            }
                        );
                        if (resAddress.statusCode == 200) {
                          // exists an address for the user
                          final List<Map<String, dynamic>> resultListJson = json.decode(resAddress.body)['data'].cast<Map<String, dynamic>>();
                          final List<Address> resultListAddress = resultListJson.map<Address>((json) => Address.fromJson(json)).toList();
                          if (resultListAddress.isNotEmpty) {
                            // if exists address
                            _showPleaseWait(false);
                            if (!context.mounted) return;
                            Navigator.push (
                                context,
                                MaterialPageRoute (
                                    builder: (context) => (ConfirmPurchaseView(resultListAddress, payload['phone_number'].toString(), payload['user_id'].toString()))
                                )
                            );
                          } else {
                            // if not exists address
                            _showPleaseWait(false);
                            if (!context.mounted) return;
                            Navigator.push (
                                context,
                                MaterialPageRoute (
                                    builder: (context) => (AddAddressView(payload['persone_id'].toString(), payload['user_id'].toString()))
                                )
                            );
                          }
                        } else if (resAddress.statusCode == 404) {
                          // if not exists address
                          _showPleaseWait(false);
                          if (!context.mounted) return;
                          Navigator.push (
                              context,
                              MaterialPageRoute (
                                  builder: (context) => (AddAddressView(payload['persone_id'].toString(), payload['user_id'].toString()))
                              )
                          );
                        } else {
                          // Error
                          _showPleaseWait(false);
                          if (!context.mounted) return;
                          ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'].toString());
                        }
                      } else {
                        //  1 the call comes from the drawer. 2 the call comes from cart.view.dart
                        // The call comes from the drawer.
                        if (!context.mounted) return;
                        Navigator.popUntil(context, ModalRoute.withName('/'));
                      }
                    }
                  } else {
                    // Error
                    _showPleaseWait(false);
                    if (!context.mounted) return;
                    ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'].toString());
                  }
                } catch (e) {
                  _showPleaseWait(false);
                  if (!context.mounted) return;
                  ShowSnackBar.showSnackBar(context, e.toString(), error: true);
                }
              }
            },
            child: Container (
              height: 64.0,
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
                  ),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        offset: Offset (5,5),
                        blurRadius: 10
                    )
                  ]
              ),
              child: const Center (
                child: Text (
                  'Continuar',
                  style: TextStyle(
                      fontSize: 24.0,
                      color: tanteLadenBackgroundWhite
                  ),
                ),
              ),
            ),
          );
        }
    );
    return SafeArea(
        child: Center(
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text (
                      'Crear cuenta',
                      style: TextStyle (
                        fontWeight: FontWeight.w900,
                        fontSize: 36.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30.0,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text (
                      '¿Es tu primer pedido? Introduce tus datos',
                      style: TextStyle (
                        fontWeight: FontWeight.w500,
                        fontSize: 16.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  )
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text (
                      'para continuar.',
                      style: TextStyle (
                        fontWeight: FontWeight.w500,
                        fontSize: 16.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  )
                ],
              ),
              const SizedBox (height: 20.0,),
              Form (
                autovalidateMode: AutovalidateMode.always,
                key: _formKey,
                child: Column (
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration (
                        labelText: 'Nombre',
                        labelStyle: TextStyle (
                          color: tanteLadenIconBrown,
                        ),
                      ),
                      validator: (String? value) {
                        if (value == null) {
                          return 'Introduce tu nombre';
                        } else {
                          return null;
                        }
                      },
                    ),
                    const SizedBox(height: 20.0,),
                    TextFormField(
                      controller: _surname,
                      decoration: const InputDecoration (
                        labelText: 'Apellidos',
                        labelStyle: TextStyle (
                          color: tanteLadenIconBrown,
                        ),
                      ),
                      validator: (String? value) {
                        if (value == null) {
                          return 'Introduce tus apellidos';
                        } else {
                          return null;
                        }
                      },
                    ),
                    const SizedBox(height: 20.0,),
                    TextFormField(
                      controller: _password,
                      decoration: InputDecoration (
                        labelText: 'Contraseña',
                        labelStyle: const TextStyle (
                          color: tanteLadenIconBrown,
                        ),
                        suffixIcon: IconButton (
                            icon: Icon(_passwordNoVisible ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _passwordNoVisible = ! _passwordNoVisible;
                              });
                            }
                        ),
                      ),
                      validator: (String? value) {
                        if (value == null) {
                          return 'Introduce una password';
                        } else {
                          return null;
                        }
                      },
                      obscureText: _passwordNoVisible,
                    ),
                    const SizedBox(height: 50.0,),
                    _pleaseWait
                        ? Stack (
                      key:  const ObjectKey("stack"),
                      alignment: AlignmentDirectional.center,
                      children: [tmpBuilder, _pleaseWaitWidget],
                    )
                        : Stack (key:  const ObjectKey("stack"), children: [tmpBuilder],)
                  ],
                ),
              )
            ],
          ),
        )
    );
  }
}
class _LargeScreenView extends StatefulWidget {
  const _LargeScreenView (this.email, this.reason);
  final String email;
  final int reason;
  @override
  _LargeScreenViewState createState() {
    return _LargeScreenViewState();
  }
}
class _LargeScreenViewState extends State<_LargeScreenView> {
  bool _pleaseWait = false;
  bool _passwordNoVisible = true;
  final PleaseWaitWidget _pleaseWaitWidget = const PleaseWaitWidget(key: ObjectKey("pleaseWaitWidget"));
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _surname = TextEditingController();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }
  @override
  void initState() {
    super.initState();
    _passwordNoVisible = true;
    _pleaseWait = false;
  }
  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget tmpBuilder = Consumer<Cart>(
        builder: (context, cart, child) {
          return GestureDetector (
            onTap: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  debugPrint('El valor de user_name es: ${widget.email}');
                  _showPleaseWait (true);
                  final Uri url = Uri.parse('$SERVER_IP/register');
                  final http.Response res = await http.post (
                      url,
                      headers: <String, String>{
                        'Content-Type': 'application/json; charset=UTF-8',
                        //'Authorization': jwt
                      },
                      body: jsonEncode(<String, String>{
                        'user_name': widget.email,
                        'user_firstname': _name.text,
                        'user_lastname': _surname.text,
                        'password': _password.text,
                        'gethash': 'true'
                      })
                  );
                  if (res.statusCode == 200) {
                    // Sign up
                    final String token = json.decode(res.body)['token'].toString();
                    final SharedPreferences prefs = await _prefs;
                    prefs.setString('token', token);
                    // See if there is an address for this user
                    Map<String, dynamic> payload;
                    payload = json.decode(
                        utf8.decode(
                            base64.decode(base64.normalize(token.split(".")[1]))
                        )
                    );
                    if (payload['partner_id'] != DEFAULT_PARTNER_ID) {
                      // RELOAD THE PRODUCTS WHICH THE USER CAN BUY
                      final Uri url = Uri.parse('$SERVER_IP/getProductsAvailWithPartnerId/${payload['partner_id']}');
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
                        final List<ProductAvail> resultListProducts = resultListJson.map<ProductAvail>((json) => ProductAvail.fromJson(json)).toList();
                        final List<MultiPricesProductAvail> resultListMultiPriceProducts = [];
                        int tmpProductCategoryIdPrevious = -1;
                        String tmpPersonNamePrevious = "";
                        for (var element in resultListProducts) {
                          if (element.productCategoryId != tmpProductCategoryIdPrevious && element.personeName != tmpPersonNamePrevious && element.rn == 1) {
                            // Change the productCategoryId and the rn = 1, so start a new MultiPriceProductAvail
                            debugPrint ('El product_description retornado desde el API es: ${element.productName}');
                            tmpProductCategoryIdPrevious = element.productCategoryId;
                            tmpPersonNamePrevious = element.personeName;
                            final item = MultiPricesProductAvail (
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
                        debugPrint ('Entre medias de la api RESPONSE.');
                        cart.removeCart();
                        if (!context.mounted) return;
                        Provider.of<Catalog>(context, listen: false).removeCatalog();
                        for (var element in resultListMultiPriceProducts) {
                          Provider.of<Catalog>(context, listen: false).add(element);
                          //Provider.of<VisibleButtonToPurchase>(context, listen: false).add(true);
                        }
                        debugPrint ('Antes de terminar de responder la API.');
                        Navigator.popUntil(context, ModalRoute.withName('/'));
                      }
                    } else {
                      if (widget.reason == COME_FROM_ANOTHER) {
                        //  1 the call comes from the drawer. 2 the call comes from cart.view.dart
                        final Uri urlAddress = Uri.parse('$SERVER_IP/getDefaultLogisticAddress/${payload['user_id']}');
                        final http.Response resAddress = await http.get (
                            urlAddress,
                            headers: <String, String>{
                              'Content-Type': 'application/json; charset=UTF-8',
                              //'Authorization': jwt
                            }
                        );
                        if (resAddress.statusCode == 200) {
                          // exists an address for the user
                          final List<Map<String, dynamic>> resultListJson = json.decode(resAddress.body)['data'].cast<Map<String, dynamic>>();
                          final List<Address> resultListAddress = resultListJson.map<Address>((json) => Address.fromJson(json)).toList();
                          if (resultListAddress.isNotEmpty) {
                            // if exists address
                            _showPleaseWait(false);
                            if (!context.mounted) return;
                            Navigator.push (
                                context,
                                MaterialPageRoute (
                                    builder: (context) => (ConfirmPurchaseView(resultListAddress, payload['phone_number'].toString(), payload['user_id'].toString()))
                                )
                            );
                          } else {
                            // if not exists address
                            _showPleaseWait(false);
                            if (!context.mounted) return;
                            Navigator.push (
                                context,
                                MaterialPageRoute (
                                    builder: (context) => (AddAddressView(payload['persone_id'].toString(), payload['user_id'].toString()))
                                )
                            );
                          }
                        } else if (resAddress.statusCode == 404) {
                          // if not exists address
                          _showPleaseWait(false);
                          if (!context.mounted) return;
                          Navigator.push (
                              context,
                              MaterialPageRoute (
                                  builder: (context) => (AddAddressView(payload['persone_id'].toString(), payload['user_id'].toString()))
                              )
                          );
                        } else {
                          // Error
                          _showPleaseWait(false);
                          if (!context.mounted) return;
                          ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'].toString());
                        }
                      } else {
                        //  1 the call comes from the drawer. 2 the call comes from cart.view.dart
                        // The call comes from the drawer.
                        if (!context.mounted) return;
                        Navigator.popUntil(context, ModalRoute.withName('/'));
                      }
                    }
                  } else {
                    // Error
                    _showPleaseWait(false);
                    if (!context.mounted) return;
                    ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'].toString());
                  }
                } catch (e) {
                  _showPleaseWait(false);
                  if (!context.mounted) return;
                  ShowSnackBar.showSnackBar(context, e.toString(), error: true);
                }
              }
            },
            child: Container (
              height: 64.0,
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
                  ),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        offset: Offset (5,5),
                        blurRadius: 10
                    )
                  ]
              ),
              child: const Center (
                child: Text (
                  'Continuar',
                  style: TextStyle(
                      fontSize: 24.0,
                      color: tanteLadenBackgroundWhite
                  ),
                ),
              ),
            ),
          );
        }
    );
    return SafeArea(
        child: Center(
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text (
                      'Crear cuenta',
                      style: TextStyle (
                        fontWeight: FontWeight.w900,
                        fontSize: 36.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30.0,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text (
                      '¿Es tu primer pedido? Introduce tus datos',
                      style: TextStyle (
                        fontWeight: FontWeight.w500,
                        fontSize: 16.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  )
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text (
                      'para continuar.',
                      style: TextStyle (
                        fontWeight: FontWeight.w500,
                        fontSize: 16.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  )
                ],
              ),
              const SizedBox (height: 20.0,),
              Form (
                autovalidateMode: AutovalidateMode.always,
                key: _formKey,
                child: Column (
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration (
                        labelText: 'Nombre',
                        labelStyle: TextStyle (
                          color: tanteLadenIconBrown,
                        ),
                      ),
                      validator: (String? value) {
                        if (value == null) {
                          return 'Introduce tu nombre';
                        } else {
                          return null;
                        }
                      },
                    ),
                    const SizedBox(height: 20.0,),
                    TextFormField(
                      controller: _surname,
                      decoration: const InputDecoration (
                        labelText: 'Apellidos',
                        labelStyle: TextStyle (
                          color: tanteLadenIconBrown,
                        ),
                      ),
                      validator: (String? value) {
                        if (value == null) {
                          return 'Introduce tus apellidos';
                        } else {
                          return null;
                        }
                      },
                    ),
                    const SizedBox(height: 20.0,),
                    TextFormField(
                      controller: _password,
                      decoration: InputDecoration (
                        labelText: 'Contraseña',
                        labelStyle: const TextStyle (
                          color: tanteLadenIconBrown,
                        ),
                        suffixIcon: IconButton (
                            icon: Icon(_passwordNoVisible ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _passwordNoVisible = ! _passwordNoVisible;
                              });
                            }
                        ),
                      ),
                      validator: (String? value) {
                        if (value == null) {
                          return 'Introduce una password';
                        } else {
                          return null;
                        }
                      },
                      obscureText: _passwordNoVisible,
                    ),
                    const SizedBox(height: 50.0,),
                    _pleaseWait
                        ? Stack (
                      key:  const ObjectKey("stack"),
                      alignment: AlignmentDirectional.center,
                      children: [tmpBuilder, _pleaseWaitWidget],
                    )
                        : Stack (key:  const ObjectKey("stack"), children: [tmpBuilder],)
                  ],
                ),
              )
            ],
          ),
        )
    );
  }
}
