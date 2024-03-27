import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' show NumberFormat hide TextDirection;
import 'package:kompras/View/AddPhone.view.dart';
import 'package:kompras/model/Address.model.dart';
import 'package:kompras/model/Cart.model.dart';
import 'package:kompras/model/Catalog.model.dart';
import 'package:kompras/model/ProductAvail.model.dart';
import 'package:kompras/util/DisplayDialog.util.dart';
import 'package:kompras/util/PleaseWaitWidget.util.dart';
import 'package:kompras/util/ResponsiveWidget.util.dart';
import 'package:kompras/util/ShowSnackBar.util.dart';
import 'package:kompras/util/color.util.dart';
import 'package:kompras/util/configuration.util.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfirmPurchaseView extends StatelessWidget {
  const ConfirmPurchaseView(this.resultListAddress, this.phoneNumber, this.userId, {super.key});
  final List<Address> resultListAddress;
  final String phoneNumber;
  final String userId;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar (
        elevation: 0.0,
        leading: IconButton (
            icon: Image.asset('assets/images/leftArrow.png'),
            onPressed: () {
              Navigator.pop(context);
            }
        ),
        title: const Text (
          'Confirmar pedido',
          style: TextStyle (
              fontFamily: 'SF Pro Display',
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: tanteLadenIconBrown
          ),
          textAlign: TextAlign.center,
        ),
      ),
      body: ResponsiveWidget(
        smallScreen: _SmallScreenView (resultListAddress, phoneNumber, userId),
        mediumScreen: _MediumScreenView(resultListAddress, phoneNumber, userId),
        largeScreen: _LargeScreenView (resultListAddress, phoneNumber, userId),
      ),
    );
  }
}
class _SmallScreenView extends StatefulWidget {
  const _SmallScreenView(this.resultListAddress, this.phoneNumber, this.userId);
  final List<Address> resultListAddress;
  final String phoneNumber;
  final String userId;
  @override
  _SmallScreenViewState createState() => _SmallScreenViewState();
}
class _SmallScreenViewState extends State<_SmallScreenView> {
  final PleaseWaitWidget _pleaseWaitWidget = const PleaseWaitWidget(key: ObjectKey("pleaseWaitWidget"));
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  bool _pleaseWait = false;
  late String _phoneNumber;

  _badStatusCode(http.Response response) {
    debugPrint("Bad status code ${response.statusCode} returned from server.");
    debugPrint("Response body ${response.body} returned from server.");
    throw Exception(
        'Bad status code ${response.statusCode} returned from server.');
  }
  _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }
  Future<String> _processPurchase (Cart cartPurchased) async {
    int userId;
    String message = '';
    try {
      final SharedPreferences prefs = await _prefs;
      final String token = prefs.get ('token').toString();
      if (token == '') {
        userId = 1;
      } else {
        Map<String, dynamic> payload;
        payload = json.decode(
            utf8.decode(
                base64.decode (base64.normalize(token.split(".")[1]))
            )
        );
        userId = payload['user_id'];
      }
      final List<ProductAvail> productAvailListToSave = [];
      for (var element in cartPurchased.items) {
        if (element.getIndexElementAmongQuantity() == -1) {
          final item = ProductAvail (
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
              discountAmount: (element.discountAmount * -1),  // Save a negative amount because it is a discount
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
          productAvailListToSave.add(item);
        } else {
          var index = element.getIndexElementAmongQuantity();
          final item = ProductAvail (
              productId: element.items[index].productId,
              productCode: element.items[index].productCode,
              productName: element.items[index].productName,
              productNameLong: element.items[index].productNameLong,
              productDescription: element.items[index].productDescription,
              productType: element.items[index].productType,
              brand: element.items[index].brand,
              numImages: element.items[index].numImages,
              numVideos: element.items[index].numVideos,
              purchased: element.purchased,   // The quantity purchased is in the father product field
              productPrice: element.items[index].productPrice,
              totalBeforeDiscount: element.items[index].totalBeforeDiscount,
              taxAmount: element.items[index].taxAmount,
              personeId: element.items[index].personeId,
              personeName: element.items[index].personeName,
              businessName: element.items[index].businessName,
              email: element.items[index].email,
              taxId: element.items[index].taxId,
              taxApply: element.items[index].taxApply,
              productPriceDiscounted: element.items[index].productPriceDiscounted,
              totalAmount: element.items[index].totalAmount,
              discountAmount: (element.items[index].discountAmount * -1), // Save a negative amount because it is a discount
              idUnit: element.items[index].idUnit,
              remark: element.items[index].remark,
              minQuantitySell: element.items[index].minQuantitySell,
              partnerId: element.items[index].partnerId,
              partnerName: element.items[index].partnerName,
              quantityMinPrice: element.items[index].quantityMinPrice,
              quantityMaxPrice: element.items[index].quantityMaxPrice,
              productCategoryId: element.items[index].productCategoryId,
              rn: element.items[index].rn
          );
          productAvailListToSave.add(item);
        }
      }
      final Uri url = Uri.parse('$SERVER_IP/savePurchasedProducts');
      final http.Response res = await http.post(url,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'purchased_products': productAvailListToSave.map<Map<String, dynamic>>((e) {
              return {
                'product_id': e.productId,
                'product_name': e.productName,
                'product_name_long': e.productNameLong,
                'product_description': e.productDescription,
                'product_type': e.productType,
                'brand': e.brand,
                'num_images': e.numImages,
                'num_videos': e.numVideos,
                'purchased': e.purchased,
                'product_price': e.productPriceDiscounted,
                'total_before_discount': e.totalAmount,
                'total_amount': e.totalAmount,
                'discount_amount': 0,
                'tax_amount': e.taxAmount,
                'persone_id': e.personeId,
                'persone_name': e.personeName,
                'email': e.email,
                'tax_id': e.taxId,
                'tax_apply': e.taxApply,
                'partner_id': e.partnerId,
                'partner_name': e.partnerName,
                'user_id': userId
              };
            }).toList()
          })
      ).timeout(TIMEOUT);
      if (res.statusCode == 200) {
        message = json.decode(res.body)['data'];
        debugPrint('After returning.');
        debugPrint('The message is: $message');
      } else {
        // If that response was not OK, throw an error.
        debugPrint('There is an error.');
        _badStatusCode(res);
      }
      return message;
    } catch (e) {
      throw Exception(e);
    }
  }
  @override
  void initState() {
    super.initState();
    _pleaseWait = false;
    _phoneNumber = widget.phoneNumber;
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build (BuildContext context) {
    var cart = context.read<Cart>();
    final Widget tmpBuilder = GestureDetector (
      child: Container(
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
          'Tramitar pedido',
          style: TextStyle(
              fontSize: 24.0,
              color: tanteLadenBackgroundWhite
          ),
        ),
      ),
      onTap: () async {
        try {
          debugPrint ('Comienzo el tramitar pedido');
          _showPleaseWait(true);
          final String message = await _processPurchase(cart);
          _showPleaseWait(false);
          if (!context.mounted) return;
          var widgetImage = Image.asset ('assets/images/infoMessage.png');
          await DisplayDialog.displayDialog (context, widgetImage, 'Compra realizada', message);
          cart.removeCart();
          if (!context.mounted) return;
          var catalog = context.read<Catalog>();
          catalog.clearCatalog();
          if (!context.mounted) return;
          Navigator.popUntil(context, ModalRoute.withName('/'));
        } catch (e) {
          debugPrint ('Me he ido por el error en el Tramitar pedido');
          _showPleaseWait(false);
          ShowSnackBar.showSnackBar(context, e.toString(), error: true);
        }
      },
    );
    return SafeArea (
        child: ListView (
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
          children: <Widget> [
            const SizedBox(height: 10.0),
            Card(
              elevation: 8.0,
              child: ListTile (
                  leading: IconButton(
                    icon: Image.asset('assets/images/logoDelibery.png'),
                    onPressed: null,
                  ),
                  title: const Text (
                    'Entrega',
                    style: TextStyle (
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0,
                      fontFamily: 'SF Pro Display',
                      fontStyle: FontStyle.normal,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Container(
                    padding: const EdgeInsets.all(0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.resultListAddress[0].streetName}, ${widget.resultListAddress[0].streetNumber}',
                          style: const TextStyle (
                            fontWeight: FontWeight.w300,
                            fontSize: 16.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          widget.resultListAddress[0].flatDoor,
                          style: const TextStyle (
                            fontWeight: FontWeight.w300,
                            fontSize: 16.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '${widget.resultListAddress[0].postalCode} ${widget.resultListAddress[0].locality}',
                          style: const TextStyle (
                            fontWeight: FontWeight.w300,
                            fontSize: 16.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          widget.resultListAddress[0].optional,
                          style: const TextStyle (
                            fontWeight: FontWeight.w300,
                            fontSize: 16.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  )
              ),
            ),
            const SizedBox(height: 5.0,),
            Card(
              elevation: 8.0,
              child: ListTile (
                leading: IconButton(
                  icon: Image.asset('assets/images/logoPhone.png'),
                  onPressed: null,
                ),
                title: (widget.phoneNumber == "null") ?   // Come "null" from shared_preferences and from backend if there no is a value
                const Text(
                  'Añadir teléfono',
                  style: TextStyle (
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                    fontFamily: 'SF Pro Display',
                    fontStyle: FontStyle.normal,
                    color: Colors.black,
                  ),
                ) :
                const Text(
                  'Teléfono',
                  style: TextStyle (
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                    fontFamily: 'SF Pro Display',
                    fontStyle: FontStyle.normal,
                    color: Colors.black,
                  ),
                ),
                subtitle: (_phoneNumber  == "null") ?  // Come "null" from shared_preferences and from backend if there no is a value
                const Text(
                  '',
                  style: TextStyle (
                    fontWeight: FontWeight.w300,
                    fontSize: 16.0,
                    fontFamily: 'SF Pro Display',
                    fontStyle: FontStyle.normal,
                    color: Colors.black,
                  ),
                ):
                Text(
                  _phoneNumber,
                  style: const TextStyle (
                    fontWeight: FontWeight.w300,
                    fontSize: 16.0,
                    fontFamily: 'SF Pro Display',
                    fontStyle: FontStyle.normal,
                    color: Colors.black,
                  ),
                ),
                trailing: (_phoneNumber == "null") ?  // Come "null" from shared_preferences and from backend if there no is a value
                IconButton (
                  icon: Image.asset('assets/images/logoPlus.png'),
                  onPressed: () async {
                    var retorno = await Navigator.push (
                        context,
                        MaterialPageRoute (
                            builder: (context) => (AddPhone(_phoneNumber, widget.userId))
                        )
                    );
                    setState(() {
                      _phoneNumber = retorno;
                    });
                  },
                ) :
                TextButton(
                  child: const Text(
                    'Editar',
                    style: TextStyle (
                      fontWeight: FontWeight.w500,
                      fontSize: 20.0,
                      fontFamily: 'SF Pro Display',
                      fontStyle: FontStyle.normal,
                      color: Colors.brown,
                    ),
                  ),
                  onPressed: () async {
                    var retorno = await Navigator.push (
                        context,
                        MaterialPageRoute (
                            builder: (context) => (AddPhone(widget.phoneNumber, widget.userId))
                        )
                    );
                    setState(() {
                      _phoneNumber = retorno;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 5.0,),
            Card(
              elevation: 8.0,
              child: ListTile(
                leading: IconButton(
                  icon: Image.asset('assets/images/logoPaymentMethod.png'),
                  onPressed: null,
                ),
                title: const Text(
                  'Forma de pago',
                  style: TextStyle (
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                    fontFamily: 'SF Pro Display',
                    fontStyle: FontStyle.normal,
                    color: Colors.black,
                  ),
                ),
                subtitle: const Text(
                  'Diferido',
                  style: TextStyle (
                    fontWeight: FontWeight.w300,
                    fontSize: 16.0,
                    fontFamily: 'SF Pro Display',
                    fontStyle: FontStyle.normal,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60.0,),
            Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        const Text (
                          'Total aproximado ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: tanteLadenOnPrimary,
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: IconButton(
                            icon: Image.asset('assets/images/logoInfo.png'),
                            iconSize: 6.0,
                            onPressed: () {
                              var widgetImage = Image.asset('assets/images/weightMessage.png');
                              var message = 'En los productos al peso, el importe se ajustará a la cantidad servida. El cobro del importe final se realizará tras la presentación de tu pedido.';
                              DisplayDialog.displayDialog (context, widgetImage, 'Total aproximado', message);
                            },
                          ),
                        )
                      ],
                    )
                ),
                Expanded(
                    flex: 1,
                    child: Text(
                      NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format((cart.totalPrice/MULTIPLYING_FACTOR)),
                      style: const TextStyle (
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: tanteLadenOnPrimary,
                      ),
                      textAlign: TextAlign.right,
                    )
                )

              ],
            ),
            const SizedBox(height: 5.0,),
            Row(
              children: [
                const Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Text(
                          'IVA incluido ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    )
                ),
                Expanded(
                    flex: 1,
                    child: Text(
                      NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format((cart.totalTax/MULTIPLYING_FACTOR)),
                      style: const TextStyle (
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black45,
                      ),
                      textAlign: TextAlign.right,
                    )
                )
              ],
            ),
            const SizedBox(height: 60.0,),
            _pleaseWait ?
            Stack (
              key:  const ObjectKey("stack"),
              alignment: AlignmentDirectional.center,
              children: [tmpBuilder, _pleaseWaitWidget],
            ) :
            Stack (key:  const ObjectKey("stack"), children: [tmpBuilder],)
          ],
        )
    );
  }
}
class _MediumScreenView extends StatefulWidget {
  const _MediumScreenView(this.resultListAddress, this.phoneNumber, this.userId);
  final List<Address> resultListAddress;
  final String phoneNumber;
  final String userId;
  @override
  _MediumScreenViewState createState() => _MediumScreenViewState();
}
class _MediumScreenViewState extends State<_MediumScreenView> {
  final PleaseWaitWidget _pleaseWaitWidget = const PleaseWaitWidget(key: ObjectKey("pleaseWaitWidget"));
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  bool _pleaseWait = false;
  late String _phoneNumber;

  _badStatusCode(http.Response response) {
    debugPrint("Bad status code ${response.statusCode} returned from server.");
    debugPrint("Response body ${response.body} returned from server.");
    throw Exception(
        'Bad status code ${response.statusCode} returned from server.');
  }
  _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }
  Future<String> _processPurchase (Cart cartPurchased) async {
    int userId;
    String message = '';
    try {
      final SharedPreferences prefs = await _prefs;
      final String token = prefs.get ('token').toString();
      if (token == '') {
        userId = 1;
      } else {
        Map<String, dynamic> payload;
        payload = json.decode(
            utf8.decode(
                base64.decode (base64.normalize(token.split(".")[1]))
            )
        );
        userId = payload['user_id'];
      }
      final List<ProductAvail> productAvailListToSave = [];
      for (var element in cartPurchased.items) {
        if (element.getIndexElementAmongQuantity() == -1) {
          final item = ProductAvail (
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
              discountAmount: (element.discountAmount * -1),  // Save a negative amount because it is a discount
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
          productAvailListToSave.add(item);
        } else {
          var index = element.getIndexElementAmongQuantity();
          final item = ProductAvail (
              productId: element.items[index].productId,
              productCode: element.items[index].productCode,
              productName: element.items[index].productName,
              productNameLong: element.items[index].productNameLong,
              productDescription: element.items[index].productDescription,
              productType: element.items[index].productType,
              brand: element.items[index].brand,
              numImages: element.items[index].numImages,
              numVideos: element.items[index].numVideos,
              purchased: element.purchased,   // The quantity purchased is in the father product field
              productPrice: element.items[index].productPrice,
              totalBeforeDiscount: element.items[index].totalBeforeDiscount,
              taxAmount: element.items[index].taxAmount,
              personeId: element.items[index].personeId,
              personeName: element.items[index].personeName,
              businessName: element.items[index].businessName,
              email: element.items[index].email,
              taxId: element.items[index].taxId,
              taxApply: element.items[index].taxApply,
              productPriceDiscounted: element.items[index].productPriceDiscounted,
              totalAmount: element.items[index].totalAmount,
              discountAmount: (element.items[index].discountAmount * -1), // Save a negative amount because it is a discount
              idUnit: element.items[index].idUnit,
              remark: element.items[index].remark,
              minQuantitySell: element.items[index].minQuantitySell,
              partnerId: element.items[index].partnerId,
              partnerName: element.items[index].partnerName,
              quantityMinPrice: element.items[index].quantityMinPrice,
              quantityMaxPrice: element.items[index].quantityMaxPrice,
              productCategoryId: element.items[index].productCategoryId,
              rn: element.items[index].rn
          );
          productAvailListToSave.add(item);
        }
      }
      final Uri url = Uri.parse('$SERVER_IP/savePurchasedProducts');
      final http.Response res = await http.post(url,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'purchased_products': productAvailListToSave.map<Map<String, dynamic>>((e) {
              return {
                'product_id': e.productId,
                'product_name': e.productName,
                'product_name_long': e.productNameLong,
                'product_description': e.productDescription,
                'product_type': e.productType,
                'brand': e.brand,
                'num_images': e.numImages,
                'num_videos': e.numVideos,
                'purchased': e.purchased,
                'product_price': e.productPriceDiscounted,
                'total_before_discount': e.totalAmount,
                'total_amount': e.totalAmount,
                'discount_amount': 0,
                'tax_amount': e.taxAmount,
                'persone_id': e.personeId,
                'persone_name': e.personeName,
                'email': e.email,
                'tax_id': e.taxId,
                'tax_apply': e.taxApply,
                'partner_id': e.partnerId,
                'partner_name': e.partnerName,
                'user_id': userId
              };
            }).toList()
          })
      ).timeout(TIMEOUT);
      if (res.statusCode == 200) {
        message = json.decode(res.body)['data'];
        debugPrint('After returning.');
        debugPrint('The message is: $message');
      } else {
        // If that response was not OK, throw an error.
        debugPrint('There is an error.');
        _badStatusCode(res);
      }
      return message;
    } catch (e) {
      throw Exception(e);
    }
  }
  @override
  void initState() {
    super.initState();
    _pleaseWait = false;
    _phoneNumber = widget.phoneNumber;
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build (BuildContext context) {
    var cart = context.read<Cart>();
    final Widget tmpBuilder = GestureDetector (
      child: Container(
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
          'Tramitar pedido',
          style: TextStyle(
              fontSize: 24.0,
              color: tanteLadenBackgroundWhite
          ),
        ),
      ),
      onTap: () async {
        try {
          debugPrint ('Comienzo el tramitar pedido');
          _showPleaseWait(true);
          final String message = await _processPurchase(cart);
          _showPleaseWait(false);
          if (!context.mounted) return;
          var widgetImage = Image.asset ('assets/images/infoMessage.png');
          await DisplayDialog.displayDialog (context, widgetImage, 'Compra realizada', message);
          cart.removeCart();
          if (!context.mounted) return;
          var catalog = context.read<Catalog>();
          catalog.clearCatalog();
          if (!context.mounted) return;
          Navigator.popUntil(context, ModalRoute.withName('/'));
        } catch (e) {
          debugPrint ('Me he ido por el error en el Tramitar pedido');
          _showPleaseWait(false);
          ShowSnackBar.showSnackBar(context, e.toString(), error: true);
        }
      },
    );
    return SafeArea (
        child: ListView (
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
          children: <Widget> [
            const SizedBox(height: 10.0),
            Card(
              elevation: 8.0,
              child: ListTile (
                  leading: IconButton(
                    icon: Image.asset('assets/images/logoDelibery.png'),
                    onPressed: null,
                  ),
                  title: const Text (
                    'Entrega',
                    style: TextStyle (
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0,
                      fontFamily: 'SF Pro Display',
                      fontStyle: FontStyle.normal,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Container(
                    padding: const EdgeInsets.all(0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.resultListAddress[0].streetName}, ${widget.resultListAddress[0].streetNumber}',
                          style: const TextStyle (
                            fontWeight: FontWeight.w300,
                            fontSize: 16.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          widget.resultListAddress[0].flatDoor,
                          style: const TextStyle (
                            fontWeight: FontWeight.w300,
                            fontSize: 16.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '${widget.resultListAddress[0].postalCode} ${widget.resultListAddress[0].locality}',
                          style: const TextStyle (
                            fontWeight: FontWeight.w300,
                            fontSize: 16.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          widget.resultListAddress[0].optional,
                          style: const TextStyle (
                            fontWeight: FontWeight.w300,
                            fontSize: 16.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  )
              ),
            ),
            const SizedBox(height: 5.0,),
            Card(
              elevation: 8.0,
              child: ListTile (
                leading: IconButton(
                  icon: Image.asset('assets/images/logoPhone.png'),
                  onPressed: null,
                ),
                title: (widget.phoneNumber == "null") ?   // Come "null" from shared_preferences and from backend if there no is a value
                const Text(
                  'Añadir teléfono',
                  style: TextStyle (
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                    fontFamily: 'SF Pro Display',
                    fontStyle: FontStyle.normal,
                    color: Colors.black,
                  ),
                ) :
                const Text(
                  'Teléfono',
                  style: TextStyle (
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                    fontFamily: 'SF Pro Display',
                    fontStyle: FontStyle.normal,
                    color: Colors.black,
                  ),
                ),
                subtitle: (_phoneNumber  == "null") ?  // Come "null" from shared_preferences and from backend if there no is a value
                const Text(
                  '',
                  style: TextStyle (
                    fontWeight: FontWeight.w300,
                    fontSize: 16.0,
                    fontFamily: 'SF Pro Display',
                    fontStyle: FontStyle.normal,
                    color: Colors.black,
                  ),
                ):
                Text(
                  _phoneNumber,
                  style: const TextStyle (
                    fontWeight: FontWeight.w300,
                    fontSize: 16.0,
                    fontFamily: 'SF Pro Display',
                    fontStyle: FontStyle.normal,
                    color: Colors.black,
                  ),
                ),
                trailing: (_phoneNumber == "null") ?  // Come "null" from shared_preferences and from backend if there no is a value
                IconButton (
                  icon: Image.asset('assets/images/logoPlus.png'),
                  onPressed: () async {
                    var retorno = await Navigator.push (
                        context,
                        MaterialPageRoute (
                            builder: (context) => (AddPhone(_phoneNumber, widget.userId))
                        )
                    );
                    setState(() {
                      _phoneNumber = retorno;
                    });
                  },
                ) :
                TextButton(
                  child: const Text(
                    'Editar',
                    style: TextStyle (
                      fontWeight: FontWeight.w500,
                      fontSize: 20.0,
                      fontFamily: 'SF Pro Display',
                      fontStyle: FontStyle.normal,
                      color: Colors.brown,
                    ),
                  ),
                  onPressed: () async {
                    var retorno = await Navigator.push (
                        context,
                        MaterialPageRoute (
                            builder: (context) => (AddPhone(widget.phoneNumber, widget.userId))
                        )
                    );
                    setState(() {
                      _phoneNumber = retorno;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 5.0,),
            Card(
              elevation: 8.0,
              child: ListTile(
                leading: IconButton(
                  icon: Image.asset('assets/images/logoPaymentMethod.png'),
                  onPressed: null,
                ),
                title: const Text(
                  'Forma de pago',
                  style: TextStyle (
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                    fontFamily: 'SF Pro Display',
                    fontStyle: FontStyle.normal,
                    color: Colors.black,
                  ),
                ),
                subtitle: const Text(
                  'Diferido',
                  style: TextStyle (
                    fontWeight: FontWeight.w300,
                    fontSize: 16.0,
                    fontFamily: 'SF Pro Display',
                    fontStyle: FontStyle.normal,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20.0,),
            Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        const Text (
                          'Total aproximado ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: tanteLadenOnPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Image.asset('assets/images/logoInfo.png'),
                          iconSize: 6.0,
                          onPressed: () {
                            var widgetImage = Image.asset('assets/images/weightMessage.png');
                            var message = 'En los productos al peso, el importe se ajustará a la cantidad servida. El cobro del importe final se realizará tras la presentación de tu pedido.';
                            DisplayDialog.displayDialog (context, widgetImage, 'Total aproximado', message);
                          },
                        )
                      ],
                    )
                ),
                Expanded(
                    flex: 1,
                    child: Text(
                      NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format((cart.totalPrice/MULTIPLYING_FACTOR)),
                      style: const TextStyle (
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: tanteLadenOnPrimary,
                      ),
                      textAlign: TextAlign.right,
                    )
                )
              ],
            ),
            const SizedBox(height: 5.0,),
            Row(
              children: [
                const Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Text(
                          'IVA incluido ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    )
                ),
                Expanded(
                    flex: 1,
                    child: Text(
                      NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format((cart.totalTax/MULTIPLYING_FACTOR)),
                      style: const TextStyle (
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black45,
                      ),
                      textAlign: TextAlign.right,
                    )
                )
              ],
            ),
            const SizedBox(height: 60.0,),
            _pleaseWait ?
            Stack (
              key:  const ObjectKey("stack"),
              alignment: AlignmentDirectional.center,
              children: [tmpBuilder, _pleaseWaitWidget],
            ) :
            Stack (key:  const ObjectKey("stack"), children: [tmpBuilder],)
          ],
        )
    );
  }
}
class _LargeScreenView extends StatefulWidget {
  const _LargeScreenView(this.resultListAddress, this.phoneNumber, this.userId);
  final List<Address> resultListAddress;
  final String phoneNumber;
  final String userId;
  @override
  _LargeScreenViewState createState() => _LargeScreenViewState();
}
class _LargeScreenViewState extends State<_LargeScreenView> {
  final PleaseWaitWidget _pleaseWaitWidget = const PleaseWaitWidget(key: ObjectKey("pleaseWaitWidget"));
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  bool _pleaseWait = false;
  late String _phoneNumber;

  _badStatusCode(http.Response response) {
    debugPrint("Bad status code ${response.statusCode} returned from server.");
    debugPrint("Response body ${response.body} returned from server.");
    throw Exception(
        'Bad status code ${response.statusCode} returned from server.');
  }
  _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }
  Future<String> _processPurchase (Cart cartPurchased) async {
    int userId;
    String message = '';
    try {
      final SharedPreferences prefs = await _prefs;
      final String token = prefs.get ('token').toString();
      if (token == '') {
        userId = 1;
      } else {
        Map<String, dynamic> payload;
        payload = json.decode(
            utf8.decode(
                base64.decode (base64.normalize(token.split(".")[1]))
            )
        );
        userId = payload['user_id'];
      }
      final List<ProductAvail> productAvailListToSave = [];
      for (var element in cartPurchased.items) {
        if (element.getIndexElementAmongQuantity() == -1) {
          final item = ProductAvail (
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
              discountAmount: (element.discountAmount * -1),  // Save a negative amount because it is a discount
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
          productAvailListToSave.add(item);
        } else {
          var index = element.getIndexElementAmongQuantity();
          final item = ProductAvail (
              productId: element.items[index].productId,
              productCode: element.items[index].productCode,
              productName: element.items[index].productName,
              productNameLong: element.items[index].productNameLong,
              productDescription: element.items[index].productDescription,
              productType: element.items[index].productType,
              brand: element.items[index].brand,
              numImages: element.items[index].numImages,
              numVideos: element.items[index].numVideos,
              purchased: element.purchased,   // The quantity purchased is in the father product field
              productPrice: element.items[index].productPrice,
              totalBeforeDiscount: element.items[index].totalBeforeDiscount,
              taxAmount: element.items[index].taxAmount,
              personeId: element.items[index].personeId,
              personeName: element.items[index].personeName,
              businessName: element.items[index].businessName,
              email: element.items[index].email,
              taxId: element.items[index].taxId,
              taxApply: element.items[index].taxApply,
              productPriceDiscounted: element.items[index].productPriceDiscounted,
              totalAmount: element.items[index].totalAmount,
              discountAmount: (element.items[index].discountAmount * -1), // Save a negative amount because it is a discount
              idUnit: element.items[index].idUnit,
              remark: element.items[index].remark,
              minQuantitySell: element.items[index].minQuantitySell,
              partnerId: element.items[index].partnerId,
              partnerName: element.items[index].partnerName,
              quantityMinPrice: element.items[index].quantityMinPrice,
              quantityMaxPrice: element.items[index].quantityMaxPrice,
              productCategoryId: element.items[index].productCategoryId,
              rn: element.items[index].rn
          );
          productAvailListToSave.add(item);
        }
      }
      final Uri url = Uri.parse('$SERVER_IP/savePurchasedProducts');
      final http.Response res = await http.post(url,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'purchased_products': productAvailListToSave.map<Map<String, dynamic>>((e) {
              return {
                'product_id': e.productId,
                'product_name': e.productName,
                'product_name_long': e.productNameLong,
                'product_description': e.productDescription,
                'product_type': e.productType,
                'brand': e.brand,
                'num_images': e.numImages,
                'num_videos': e.numVideos,
                'purchased': e.purchased,
                'product_price': e.productPriceDiscounted,
                'total_before_discount': e.totalAmount,
                'total_amount': e.totalAmount,
                'discount_amount': 0,
                'tax_amount': e.taxAmount,
                'persone_id': e.personeId,
                'persone_name': e.personeName,
                'email': e.email,
                'tax_id': e.taxId,
                'tax_apply': e.taxApply,
                'partner_id': e.partnerId,
                'partner_name': e.partnerName,
                'user_id': userId
              };
            }).toList()
          })
      ).timeout(TIMEOUT);
      if (res.statusCode == 200) {
        message = json.decode(res.body)['data'];
        debugPrint('After returning.');
        debugPrint('The message is: $message');
      } else {
        // If that response was not OK, throw an error.
        debugPrint('There is an error.');
        _badStatusCode(res);
      }
      return message;
    } catch (e) {
      throw Exception(e);
    }
  }
  @override
  void initState() {
    super.initState();
    _pleaseWait = false;
    _phoneNumber = widget.phoneNumber;
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build (BuildContext context) {
    var cart = context.read<Cart>();
    final Widget tmpBuilder = GestureDetector (
      child: Container(
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
          'Tramitar pedido',
          style: TextStyle(
              fontSize: 24.0,
              color: tanteLadenBackgroundWhite
          ),
        ),
      ),
      onTap: () async {
        try {
          debugPrint ('Comienzo el tramitar pedido');
          _showPleaseWait(true);
          final String message = await _processPurchase(cart);
          _showPleaseWait(false);
          if (!context.mounted) return;
          var widgetImage = Image.asset ('assets/images/infoMessage.png');
          await DisplayDialog.displayDialog (context, widgetImage, 'Compra realizada', message);
          cart.removeCart();
          if (!context.mounted) return;
          var catalog = context.read<Catalog>();
          catalog.clearCatalog();
          if (!context.mounted) return;
          Navigator.popUntil(context, ModalRoute.withName('/'));
        } catch (e) {
          debugPrint ('Me he ido por el error en el Tramitar pedido');
          _showPleaseWait(false);
          ShowSnackBar.showSnackBar(context, e.toString(), error: true);
        }
      },
    );
    return SafeArea (
        child: ListView (
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
          children: <Widget> [
            const SizedBox(height: 10.0),
            Card(
              elevation: 8.0,
              child: ListTile (
                  leading: IconButton(
                    icon: Image.asset('assets/images/logoDelibery.png'),
                    onPressed: null,
                  ),
                  title: const Text (
                    'Entrega',
                    style: TextStyle (
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0,
                      fontFamily: 'SF Pro Display',
                      fontStyle: FontStyle.normal,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Container(
                    padding: const EdgeInsets.all(0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.resultListAddress[0].streetName}, ${widget.resultListAddress[0].streetNumber}',
                          style: const TextStyle (
                            fontWeight: FontWeight.w300,
                            fontSize: 16.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          widget.resultListAddress[0].flatDoor,
                          style: const TextStyle (
                            fontWeight: FontWeight.w300,
                            fontSize: 16.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '${widget.resultListAddress[0].postalCode} ${widget.resultListAddress[0].locality}',
                          style: const TextStyle (
                            fontWeight: FontWeight.w300,
                            fontSize: 16.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          widget.resultListAddress[0].optional,
                          style: const TextStyle (
                            fontWeight: FontWeight.w300,
                            fontSize: 16.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  )
              ),
            ),
            const SizedBox(height: 5.0,),
            Card(
              elevation: 8.0,
              child: ListTile (
                leading: IconButton(
                  icon: Image.asset('assets/images/logoPhone.png'),
                  onPressed: null,
                ),
                title: (widget.phoneNumber == "null") ?   // Come "null" from shared_preferences and from backend if there no is a value
                const Text(
                  'Añadir teléfono',
                  style: TextStyle (
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                    fontFamily: 'SF Pro Display',
                    fontStyle: FontStyle.normal,
                    color: Colors.black,
                  ),
                ) :
                const Text(
                  'Teléfono',
                  style: TextStyle (
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                    fontFamily: 'SF Pro Display',
                    fontStyle: FontStyle.normal,
                    color: Colors.black,
                  ),
                ),
                subtitle: (_phoneNumber  == "null") ?  // Come "null" from shared_preferences and from backend if there no is a value
                const Text(
                  '',
                  style: TextStyle (
                    fontWeight: FontWeight.w300,
                    fontSize: 16.0,
                    fontFamily: 'SF Pro Display',
                    fontStyle: FontStyle.normal,
                    color: Colors.black,
                  ),
                ):
                Text(
                  _phoneNumber,
                  style: const TextStyle (
                    fontWeight: FontWeight.w300,
                    fontSize: 16.0,
                    fontFamily: 'SF Pro Display',
                    fontStyle: FontStyle.normal,
                    color: Colors.black,
                  ),
                ),
                trailing: (_phoneNumber == "null") ?  // Come "null" from shared_preferences and from backend if there no is a value
                IconButton (
                  icon: Image.asset('assets/images/logoPlus.png'),
                  onPressed: () async {
                    var retorno = await Navigator.push (
                        context,
                        MaterialPageRoute (
                            builder: (context) => (AddPhone(_phoneNumber, widget.userId))
                        )
                    );
                    setState(() {
                      _phoneNumber = retorno;
                    });
                  },
                ) :
                TextButton(
                  child: const Text(
                    'Editar',
                    style: TextStyle (
                      fontWeight: FontWeight.w500,
                      fontSize: 20.0,
                      fontFamily: 'SF Pro Display',
                      fontStyle: FontStyle.normal,
                      color: Colors.brown,
                    ),
                  ),
                  onPressed: () async {
                    var retorno = await Navigator.push (
                        context,
                        MaterialPageRoute (
                            builder: (context) => (AddPhone(widget.phoneNumber, widget.userId))
                        )
                    );
                    setState(() {
                      _phoneNumber = retorno;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 5.0,),
            Card(
              elevation: 8.0,
              child: ListTile(
                leading: IconButton(
                  icon: Image.asset('assets/images/logoPaymentMethod.png'),
                  onPressed: null,
                ),
                title: const Text(
                  'Forma de pago',
                  style: TextStyle (
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                    fontFamily: 'SF Pro Display',
                    fontStyle: FontStyle.normal,
                    color: Colors.black,
                  ),
                ),
                subtitle: const Text(
                  'Diferido',
                  style: TextStyle (
                    fontWeight: FontWeight.w300,
                    fontSize: 16.0,
                    fontFamily: 'SF Pro Display',
                    fontStyle: FontStyle.normal,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20.0,),
            Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        const Text (
                          'Total aproximado ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: tanteLadenOnPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Image.asset('assets/images/logoInfo.png'),
                          iconSize: 6.0,
                          onPressed: () {
                            var widgetImage = Image.asset('assets/images/weightMessage.png');
                            var message = 'En los productos al peso, el importe se ajustará a la cantidad servida. El cobro del importe final se realizará tras la presentación de tu pedido.';
                            DisplayDialog.displayDialog (context, widgetImage, 'Total aproximado', message);
                          },
                        )
                      ],
                    )
                ),
                Expanded(
                    flex: 1,
                    child: Text(
                      NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format((cart.totalPrice/MULTIPLYING_FACTOR)),
                      style: const TextStyle (
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: tanteLadenOnPrimary,
                      ),
                      textAlign: TextAlign.right,
                    )
                )
              ],
            ),
            const SizedBox(height: 5.0,),
            Row(
              children: [
                const Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Text(
                          'IVA incluido ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    )
                ),
                Expanded(
                    flex: 1,
                    child: Text(
                      NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format((cart.totalTax/MULTIPLYING_FACTOR)),
                      style: const TextStyle (
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black45,
                      ),
                      textAlign: TextAlign.right,
                    )
                )
              ],
            ),
            const SizedBox(height: 60.0,),
            _pleaseWait ?
            Stack (
              key:  const ObjectKey("stack"),
              alignment: AlignmentDirectional.center,
              children: [tmpBuilder, _pleaseWaitWidget],
            ) :
            Stack (key:  const ObjectKey("stack"), children: [tmpBuilder],)
          ],
        )
    );
  }
}