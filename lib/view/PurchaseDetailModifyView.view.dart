import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kompras/controller/PurchaseDetailModifyController.controller.dart';
import 'package:kompras/model/PriceChangeType.model.dart';
import 'package:kompras/model/ProductAvail.model.dart';
import 'package:kompras/model/Purchase.model.dart';
import 'package:kompras/model/PurchaseLine.model.dart';
import 'package:kompras/model/PurchaseStatus.model.dart';
import 'package:kompras/util/PleaseWaitWidget.util.dart';
import 'package:kompras/util/ResponsiveWidget.util.dart';
import 'package:kompras/util/ShowSnackBar.util.dart';
import 'package:kompras/util/color.util.dart';
import 'package:kompras/util/configuration.util.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show NumberFormat hide TextDirection;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:kompras/util/sizes.util.dart';
import 'package:kompras/view/AddComment.view.dart';



class _StateChanged {
  bool changed;
  _StateChanged(this.changed);
}
class PurchaseDetailModifyView extends StatefulWidget {
  final int userId;
  final Purchase grandFather;
  final int partnerId;
  final PurchaseLine father;
  final String userRole;

  const PurchaseDetailModifyView (this.userId, this.grandFather, this.partnerId, this.father, this.userRole, {super.key});
  @override
  PurchaseDetailModifyViewState createState() {
    return PurchaseDetailModifyViewState();
  }
}
class PurchaseDetailModifyViewState extends State<PurchaseDetailModifyView> {
  final PurchaseDetailModifyController _controller = PurchaseDetailModifyController();
  final _StateChanged _stateChangedAttr = _StateChanged(false);

  @override
  void initState() {
    super.initState();
    _stateChangedAttr.changed = false;
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold (
      appBar: AppBar (
        elevation: 0.0,
        leading: IconButton(
            icon: Image.asset('assets/images/leftArrow.png'),
            onPressed: (){
              Navigator.pop(context, false);
            }
        ),
        title: Text(
          widget.father.productName,
          style: const TextStyle (
              fontFamily: 'SF Pro Display',
              fontSize: 16.0,
              fontWeight: FontWeight.w500
          ),
          textAlign: TextAlign.left,
        ),
      ),
      body: FutureBuilder <ProductAvail>(
        future: _controller.getProductAvailable(widget.father.productId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ResponsiveWidget (
              smallScreen: _SmallScreen (widget.father, snapshot.data!, widget.userId, _stateChangedAttr, widget.partnerId, widget.userRole),
              mediumScreen: _MediumScreen(widget.father, snapshot.data!, widget.userId, _stateChangedAttr, widget.partnerId, widget.userRole),
              largeScreen: _LargeScreen (widget.father, snapshot.data!, widget.userId, _stateChangedAttr, widget.partnerId, widget.userRole),
            );
          } else if (snapshot.hasError) {
            return Center (
              child: Column (
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error. ${snapshot.error}')
                  ]
              ),
            );
          } else {
            return const Center (
              child: SizedBox (
                width: 60,
                height: 60,
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }
}
class _SmallScreen extends StatefulWidget {
  final PurchaseLine father;
  final ProductAvail productItem;
  final int userId;
  final _StateChanged stateChanged;
  final int partnerId;
  final String userRole;
  const _SmallScreen (this.father, this.productItem, this.userId, this.stateChanged, this.partnerId, this.userRole);
  @override
  _SmallScreenState createState() => _SmallScreenState();
}
class _SmallScreenState extends State<_SmallScreen> {
  // private variables
  int _current = 0; // Var to save the current carousel image
  bool _pleaseWait = false;
  final PleaseWaitWidget _pleaseWaitWidget = const PleaseWaitWidget(key: ObjectKey("pleaseWaitWidget"));
  final TextEditingController _valueDiscountTextField = TextEditingController();
  final TextEditingController _percentDiscountTextField = TextEditingController();
  final TextEditingController _valueDiscountTextFieldOnlyForCaseOne = TextEditingController();  // Use a new text controller only for modifying the price text field of the case 1
  final TextEditingController _percentDiscountTextFieldOnlyForCaseOne = TextEditingController();  // Use a new text controller only for modifying the price text field of the case 1
  final _formPercentKey = GlobalKey<FormState>();
  final _formNewPricekey = GlobalKey<FormState>();
  // fields to save temporal values
  double _valueDiscount = 0.0;
  double _percentDiscount = 0.0;
  double _totalBeforeDiscount = 0.0;
  double _totalBeforeDiscountWithoutTax = 0.0;
  double _discountAmount = 0.0;
  double _totalAfterDiscountWithoutTax = 0.0;
  double _taxAmount = 0.0;
  double _totalAmount = 0.0;
  double _newNumItemsPurchased = 0;  // save the value of the field NEW_QUANTITY of the KRC_PURCHASE table.
  late double _newNewProductPriceFinal;  // save the value of the field NEW_PRODUCT_PRICE_FINAL of the KRC_PURCHASE table.
  late double _newPrice; // save the value of the field PRODUCT_PRICE of the KRC_PURCHASE table.
  PriceChangeType _changeType = PriceChangeType.priceValue;
  bool _isOfficial = false;
  late String _comment;

  _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }
  Color getColor(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
    };
    if (states.any(interactiveStates.contains)) {
      return Colors.blue;
    }
    return Colors.red;
  }
  void _valueDiscountTextFieldProcessor () {
    debugPrint ('Estoy en el listener _valueDiscountTextFieldProcessor');
    if (widget.father.newProductPrice != -1) {
      debugPrint ('Estoy en el _newNewProductPriceFinal != -1');
      // the price has been previously modified
      if (widget.father.newQuantity != -1) {
        _valueDiscount = double.tryParse (_valueDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Estoy en el listener. El valor de _valueDiscount es: $_valueDiscount');
        //_valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('Valor de _valueDiscountTextField.text: ${_valueDiscountTextField.text}');
        _totalBeforeDiscountWithoutTax = widget.father.newQuantity * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.father.newQuantity * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.newProductPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = widget.father.newQuantity * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.father.newQuantity * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.father.newQuantity * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        _valueDiscount = double.tryParse (_valueDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Estoy en el listener. El valor de _valueDiscount es: $_valueDiscount');
        //_valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('Valor de _valueDiscountTextField.text: ${_valueDiscountTextField.text}');
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.newProductPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    } else {
      // the price has not yet modified
      debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
      if (widget.father.newQuantity != -1) {
        _valueDiscount = double.tryParse (_valueDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        //_valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
        _totalBeforeDiscountWithoutTax = widget.father.newQuantity * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.father.newQuantity * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_valueDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = widget.father.newQuantity * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.father.newQuantity * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.father.newQuantity * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        _valueDiscount = double.tryParse (_valueDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        //_valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_valueDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    }
  }
  void _percentDiscountTextFieldProcessor() {
    debugPrint ('Estoy en el listener _percentDiscountTextFieldProcessor');
    if (widget.father.newProductPrice != -1) {
      debugPrint ('Estoy en el _newNewProductPriceFinal != -1');
      if (widget.father.newQuantity != -1) {
        debugPrint ('Valor de _percentDiscountTextField.text: ${_percentDiscountTextField.text}');
        // the price has been previously modified
        _percentDiscount = double.tryParse (_percentDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('El valor de _percentDiscount es: $_valueDiscount');
        _totalBeforeDiscountWithoutTax = widget.father.newQuantity * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.father.newQuantity * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.newProductPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = widget.father.newQuantity * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.father.newQuantity * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.father.newQuantity * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        debugPrint ('Valor de _percentDiscountTextField.text: ${_percentDiscountTextField.text}');
        // the price has been previously modified
        _percentDiscount = double.tryParse (_percentDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('El valor de _percentDiscount es: $_valueDiscount');
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.newProductPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    } else {
      // the price has not yet modified
      debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
      if (widget.father.newQuantity != -1) {
        _percentDiscount = double.tryParse (_percentDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Valor de _percentDiscountTextField.text: ${_percentDiscountTextField.text}');
        _totalBeforeDiscountWithoutTax = widget.father.newQuantity * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.father.newQuantity * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.productPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_percentDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = widget.father.newQuantity * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.father.newQuantity * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.father.newQuantity * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        _percentDiscount = double.tryParse (_percentDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Valor de _percentDiscountTextField.text: ${_percentDiscountTextField.text}');
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.productPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_percentDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    }
  }
  void _valueDiscountTextFieldForCaseOneProcessor() {
    // Use a new and different listener for the case 1 (Price and Amount modified)
    debugPrint ('Estoy en el listener _valueDiscountTextFieldForCaseOneProcessor');
    if (widget.father.newProductPrice != -1) {
      if (widget.father.newQuantity != -1) {
        debugPrint ('Estoy en el _newNewProductPriceFinal != -1');
        // the price has been previously modified
        _valueDiscount = double.tryParse (_valueDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Estoy en el listener. El valor de _valueDiscount es: $_valueDiscount');
        //_valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('Valor de _valueDiscountTextFieldOnlyForCaseOne.text: ${_valueDiscountTextFieldOnlyForCaseOne.text}');
        _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.newProductPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        debugPrint ('Estoy en el _newNewProductPriceFinal != -1');
        // the price has been previously modified
        _valueDiscount = double.tryParse (_valueDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Estoy en el listener. El valor de _valueDiscount es: $_valueDiscount');
        //_valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('Valor de _valueDiscountTextFieldOnlyForCaseOne.text: ${_valueDiscountTextFieldOnlyForCaseOne.text}');
        //_totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.newProductPrice;
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.newProductPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    } else {
      // the price has not yet modified
      debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
      if (widget.father.newQuantity != -1) {
        _valueDiscount = double.tryParse (_valueDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        //_valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
        _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice*(1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_valueDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        _valueDiscount = double.tryParse (_valueDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        //_valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_valueDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    }
  }
  void _percentDiscountTextFieldForCaseOneProcessor() {
    // Use a new and different listener for the case 1 (Price and Amount modified)
    debugPrint ('Estoy en el listener _percentDiscountTextFieldForCaseOneProcessor.');
    if (widget.father.newProductPrice != -1) {
      if (widget.father.newQuantity != -1) {
        debugPrint ('Estoy en el _newNewProductPriceFinal != -1');
        debugPrint ('Valor de _percentDiscountTextFieldOnlyForCaseOne.text: ${_percentDiscountTextFieldOnlyForCaseOne.text}');
        // the price has been previously modified
        _percentDiscount = double.tryParse (_percentDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('El valor de _percentDiscount es: $_valueDiscount');
        _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        //_totalBeforeDiscount = _newNumItemsPurchased * (widget.father.newProductPrice * (1+widget.productItem.taxApply/100));
        _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.newProductPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        //_discountAmount = _newNumItemsPurchased * (_newNewProductPriceFinal * (_percentDiscount/100));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        //_totalAfterDiscountWithoutTax = _totalBeforeDiscountWithoutTax + _discountAmount;
        _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        debugPrint ('Estoy en el _newNewProductPriceFinal != -1');
        debugPrint ('Valor de _percentDiscountTextFieldOnlyForCaseOne.text: ${_percentDiscountTextFieldOnlyForCaseOne.text}');
        // the price has been previously modified
        _percentDiscount = double.tryParse (_percentDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('El valor de _percentDiscount es: $_percentDiscount');
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.newProductPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    } else {
      // the price has not yet modified
      if (widget.father.newQuantity != -1) {
        debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
        _percentDiscount = double.tryParse (_percentDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Valor de _percentDiscountTextField.text: ${_percentDiscountTextFieldOnlyForCaseOne.text}');
        _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.productPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_percentDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
        _percentDiscount = double.tryParse (_percentDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Valor de _percentDiscountTextFieldOnlyForCaseOne.text: ${_percentDiscountTextFieldOnlyForCaseOne.text}');
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.productPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_percentDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    }
  }
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES');
    _current = 0;
    _changeType = PriceChangeType.priceValue;
    _isOfficial = false;
    // fields to save temporal values
    widget.productItem.purchased = widget.father.items;
    _newNumItemsPurchased = widget.father.newQuantity;
    _totalBeforeDiscountWithoutTax = widget.father.totalBeforeDiscountWithoutTax;
    _valueDiscount = 0.0;
    _valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
    _valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
    _percentDiscount = 0.0;
    _newNewProductPriceFinal = widget.father.newProductPrice;
    _newPrice = widget.father.productPrice;
    debugPrint ('El valor de _newNewProductPriceFinal es: $_newNewProductPriceFinal');
    _percentDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
    _percentDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
    _totalBeforeDiscountWithoutTax = widget.father.totalBeforeDiscountWithoutTax;
    _totalBeforeDiscount = widget.productItem.totalBeforeDiscount;
    _discountAmount = widget.father.discountAmount;
    _totalAfterDiscountWithoutTax = widget.father.totalAfterDiscountWithoutTax;
    _taxAmount = widget.father.taxAmount;
    _totalAmount = widget.father.totalAmount;
    if (widget.userRole == 'BUYER') {
      _comment = widget.father.remarkBuyer;
    } else {
      _comment = widget.father.remarkSeller;
    }
    _valueDiscountTextField.addListener (_valueDiscountTextFieldProcessor);
    _percentDiscountTextField.addListener (_percentDiscountTextFieldProcessor);
    _valueDiscountTextFieldOnlyForCaseOne.addListener(_valueDiscountTextFieldForCaseOneProcessor);  // Use a new and different listener for the case 1 (Price and Amount modified)
    _percentDiscountTextFieldOnlyForCaseOne.addListener(_percentDiscountTextFieldForCaseOneProcessor);  // Use a new and different listener for the case 1 (Price and Amount modified)
  }
  @override
  void dispose() {
    _valueDiscountTextField.dispose();
    _percentDiscountTextField.dispose();
    _valueDiscountTextFieldOnlyForCaseOne.dispose();
    _percentDiscountTextFieldOnlyForCaseOne.dispose();
    super.dispose();
  }
  @override
  Widget build (BuildContext context) {
    debugPrint('El productId es: ${widget.productItem.productId}');
    Widget tmpBuilder = Container (
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GestureDetector (
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
                  'Modificar pedido',
                  style: TextStyle(
                      fontSize: 24.0,
                      color: tanteLadenBackgroundWhite
                  ),
                ),
              ),
              onTap: () async {
                try {
                  debugPrint ('Comienzo la modificación del pedido');
                  _showPleaseWait(true);
                  // Detect if the amount purchased has changed
                  if (widget.father.banQuantity == "SI" && widget.father.banPrice == "SI") {
                    // Case 1
                    // The price and the quantity of the purchased has been changed by the user
                    if (_valueDiscount != 0 || _percentDiscount != 0
                        || _newNumItemsPurchased != widget.father.newProductPrice
                        || widget.productItem.purchased != widget.father.items) {
                      // There is a modification
                      debugPrint('Entro en el caso 1.');
                      debugPrint('El valor de _valueDiscountTextField es: ${_valueDiscountTextField.text}');
                      debugPrint('El valor de _percentDiscountTextField es: ${_percentDiscountTextField.text}');
                      final Uri url = Uri.parse('$SERVER_IP/modifyPurchaseLine/${widget.father.orderId}/${widget.father.providerName}');
                      debugPrint ("La URL es: $url");
                      final http.Response res = await http.put (
                          url,
                          headers: <String, String>{
                            'Content-Type': 'application/json; charset=UTF-8',
                            //'Authorization': jwt
                          },
                          body: jsonEncode (<String, String> {
                            'product_id': widget.father.productId.toString(),
                            'user_id': widget.userId.toString(),
                            'user_role': widget.userRole.toString(),
                            //'new_purchased': _newNumItemsPurchased != -1 ? _newNumItemsPurchased.toString() : widget.productItem.purchased.toString(),
                            'new_purchased': _newNumItemsPurchased != -1 ? _newNumItemsPurchased.toString() : (widget.productItem.purchased != widget.father.items ? widget.productItem.purchased.toString() : null)!,
                            'new_product_price': (_newNewProductPriceFinal != -1 ? _newNewProductPriceFinal.toString() : null)!,
                            'total_before_discount': _totalBeforeDiscount.toString(),
                            'total_amount': _totalAmount.toString(),
                            'discount_amount': _discountAmount.toString(),
                            'tax_amount': _taxAmount.toString(),
                            'is_official': _isOfficial.toString(),
                            'case_to_apply': '1',  // Case 1. he price and the quantity of the purchased has been changed
                            'comment': _comment
                          })
                      );
                      _showPleaseWait(false);
                      if (res.statusCode == 200) {
                        // Process the order
                        debugPrint ('OK. ');
                        final List<Map<String, dynamic>> resultListJson = json.decode(res.body)['statusToTransitionTo'].cast<Map<String, dynamic>>();
                        debugPrint ('Entre medias de la api RESPONSE.');
                        final List<PurchaseStatus> resultListPurchaseStatusToTransitionTo = resultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                        if (resultListPurchaseStatusToTransitionTo.isNotEmpty) {
                          widget.father.possibleStatusToTransitionTo.clear();
                          for (var element in resultListPurchaseStatusToTransitionTo) {
                            debugPrint ('El valor de statusName es: ${element.statusName}');
                            debugPrint ('El valor de BAN_PRICE es: ${element.banPrice}');
                            debugPrint ('El valor de BAN_QUANTITY es: ${element.banQuantity}');
                            widget.father.possibleStatusToTransitionTo.add(element);
                          }
                        }
                        debugPrint ('Despues de retornar los statusToTransitionTo.');
                        // get the values of BAN_PRICE and BAN_QUANTITY among the new state of the modified purchased line, "O" (OBSERVACIONES)
                        final List<Map<String, dynamic>> anotherResultListJson = json.decode(res.body)['currentBanQuantityBanPrice'].cast<Map<String, dynamic>>();
                        debugPrint ('Entre medias de la api RESPONSE.');
                        final List<PurchaseStatus> currentBanPriceBanStatusValues = anotherResultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                        if (currentBanPriceBanStatusValues.isNotEmpty) {
                          widget.father.banQuantity = currentBanPriceBanStatusValues[0].banQuantity;
                          widget.father.banPrice = currentBanPriceBanStatusValues[0].banPrice;
                        }
                        debugPrint ('Despues de retornar los currentBanPriceBanStatusValues.');
                        widget.stateChanged.changed = true;
                        widget.father.newQuantity = _newNumItemsPurchased != -1 ? _newNumItemsPurchased : (widget.productItem.purchased != widget.father.items ? widget.productItem.purchased : -1);
                        widget.father.newProductPrice = _newNewProductPriceFinal != -1 ? _newNewProductPriceFinal : widget.father.newProductPrice;
                        debugPrint ('El valor de widget.father.newProductPrice es: ${widget.father.newProductPrice}');
                        widget.father.totalBeforeDiscountWithoutTax = _totalBeforeDiscountWithoutTax;
                        widget.father.discountAmount = _discountAmount;
                        widget.father.totalAfterDiscountWithoutTax = _totalAfterDiscountWithoutTax;
                        widget.father.taxAmount = _taxAmount;
                        widget.father.totalAmount = _totalAmount;
                        if (widget.userRole == 'BUYER') {
                          widget.father.remarkBuyer = _comment;
                        } else {
                          widget.father.remarkSeller = _comment;
                        }
                        widget.father.statusId = "O";
                        widget.father.allStatus = "OBSERVACIONES";
                        if (!context.mounted) return;
                        Navigator.pop(context, widget.stateChanged.changed);
                      } else {
                        // Error
                        widget.stateChanged.changed = false;
                        if (!context.mounted) return;
                        ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'].toString());
                      }
                    }
                  } else if (widget.father.banQuantity == "NO" && widget.father.banPrice == "SI") {
                    // Case 2
                    // Only the price of the purchased has been changed by the user
                    debugPrint('Entro en el caso 2.');
                    final Uri url = Uri.parse('$SERVER_IP/modifyPurchaseLine/${widget.father.orderId}/${widget.father.providerName}');
                    debugPrint ("La URL es: $url");
                    final http.Response res = await http.put (
                        url,
                        headers: <String, String>{
                          'Content-Type': 'application/json; charset=UTF-8',
                          //'Authorization': jwt
                        },
                        body: jsonEncode (<String, String> {
                          'product_id': widget.father.productId.toString(),
                          'user_id': widget.userId.toString(),
                          'user_role': widget.userRole.toString(),
                          'new_product_price': _newNewProductPriceFinal.toString(),
                          'total_before_discount': _totalBeforeDiscount.toString(),
                          'total_amount': _totalAmount.toString(),
                          'discount_amount': _discountAmount.toString(),
                          'tax_amount': _taxAmount.toString(),
                          'is_official': _isOfficial.toString(),
                          'case_to_apply': '2',  // Only the price of the purchased has been changed by the user
                          'comment': _comment
                        })
                    );
                    _showPleaseWait(false);
                    if (res.statusCode == 200) {
                      // Process the order
                      debugPrint ('OK. ');
                      // get the list of new states to tansition to
                      final List<Map<String, dynamic>> resultListJson = json.decode(res.body)['statusToTransitionTo'].cast<Map<String, dynamic>>();
                      debugPrint ('Entre medias de la api RESPONSE.');
                      final List<PurchaseStatus> resultListPurchaseStatusToTransitionTo = resultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                      if (resultListPurchaseStatusToTransitionTo.isNotEmpty) {
                        widget.father.possibleStatusToTransitionTo.clear();
                        for (var element in resultListPurchaseStatusToTransitionTo) {
                          widget.father.possibleStatusToTransitionTo.add(element);
                        }
                      }
                      debugPrint ('Despues de retornar los statusToTransitionTo.');
                      // get the values of BAN_PRICE and BAN_QUANTITY among the new state of the modified purchased line, "O" (OBSERVACIONES)
                      final List<Map<String, dynamic>> anotherResultListJson = json.decode(res.body)['currentBanQuantityBanPrice'].cast<Map<String, dynamic>>();
                      debugPrint ('Entre medias de la api RESPONSE.');
                      final List<PurchaseStatus> currentBanPriceBanStatusValues = anotherResultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                      if (currentBanPriceBanStatusValues.isNotEmpty) {
                        widget.father.banQuantity = currentBanPriceBanStatusValues[0].banQuantity;
                        widget.father.banPrice = currentBanPriceBanStatusValues[0].banPrice;
                      }
                      debugPrint ('Despues de retornar los currentBanPriceBanStatusValues.');
                      widget.stateChanged.changed = true;
                      widget.father.totalBeforeDiscountWithoutTax = _totalBeforeDiscountWithoutTax;
                      widget.father.discountAmount = _discountAmount;
                      widget.father.newProductPrice = _newNewProductPriceFinal != -1 ? _newNewProductPriceFinal : widget.father.newProductPrice;
                      debugPrint ('El valor de widget.father.newProductPrice es: ${widget.father.newProductPrice}');
                      widget.father.totalAfterDiscountWithoutTax = _totalAfterDiscountWithoutTax;
                      widget.father.taxAmount = _taxAmount;
                      widget.father.totalAmount = _totalAmount;
                      if (widget.userRole == 'BUYER') {
                        widget.father.remarkBuyer = _comment;
                      } else {
                        widget.father.remarkSeller = _comment;
                      }
                      widget.father.statusId = "O";
                      widget.father.allStatus = "OBSERVACIONES";
                      if (!context.mounted) return;
                      Navigator.pop(context, widget.stateChanged.changed);
                    } else {
                      // Error
                      widget.stateChanged.changed = false;
                      if (!context.mounted) return;
                      ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'].toString());
                    }
                  } else if (widget.father.banQuantity == "SI" && widget.father.banPrice == "NO") {
                    // Case 3
                    // Only the quantity has been changed by the user
                    if (_newNumItemsPurchased != -1) {
                      // the quantity of the purchase line has been changed.
                      // The value -1 is the value if the field NEW_QUANTITY of the KRC_PURCHASE is null,
                      // then it has been not yet modified
                      if (_newNumItemsPurchased != widget.father.newQuantity) {
                        // the quantity of the purchase line has been modified
                        debugPrint ('Entro en el paso 3.');
                        final Uri url = Uri.parse('$SERVER_IP/modifyPurchaseLine/${widget.father.orderId}/${widget.father.providerName}');
                        debugPrint ("La URL es: $url");
                        final http.Response res = await http.put (
                            url,
                            headers: <String, String>{
                              'Content-Type': 'application/json; charset=UTF-8',
                              //'Authorization': jwt
                            },
                            body: jsonEncode (<String, String> {
                              'product_id': widget.father.productId.toString(),
                              'user_id': widget.userId.toString(),
                              'user_role': widget.userRole.toString(),
                              'new_purchased': _newNumItemsPurchased.toString(),
                              'total_before_discount': _totalBeforeDiscount.toString(),
                              'total_amount': _totalAmount.toString(),
                              'discount_amount': _discountAmount.toString(),
                              'tax_amount': _taxAmount.toString(),
                              'case_to_apply': '3', // Only the quantity has been changed by the user
                              'comment': _comment
                            })
                        );
                        _showPleaseWait(false);
                        if (res.statusCode == 200) {
                          // Process the order
                          debugPrint ('OK. ');
                          final List<Map<String, dynamic>> resultListJson = json.decode(res.body)['statusToTransitionTo'].cast<Map<String, dynamic>>();
                          debugPrint ('Entre medias de la api RESPONSE.');
                          final List<PurchaseStatus> resultListPurchaseStatusToTransitionTo = resultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                          if (resultListPurchaseStatusToTransitionTo.isNotEmpty) {
                            widget.father.possibleStatusToTransitionTo.clear();
                            for (var element in resultListPurchaseStatusToTransitionTo) {
                              widget.father.possibleStatusToTransitionTo.add(element);
                            }
                          }
                          debugPrint ('Despues de retornar los statusToTransitionTo.');
                          // get the values of BAN_PRICE and BAN_QUANTITY among the new state of the modified purchased line, "O" (OBSERVACIONES)
                          final List<Map<String, dynamic>> anotherResultListJson = json.decode(res.body)['currentBanQuantityBanPrice'].cast<Map<String, dynamic>>();
                          debugPrint ('Entre medias de la api RESPONSE.');
                          final List<PurchaseStatus> currentBanPriceBanStatusValues = anotherResultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                          if (currentBanPriceBanStatusValues.isNotEmpty) {
                            widget.father.banQuantity = currentBanPriceBanStatusValues[0].banQuantity;
                            widget.father.banPrice = currentBanPriceBanStatusValues[0].banPrice;
                          }
                          debugPrint ('Despues de retornar los currentBanPriceBanStatusValues.');
                          widget.stateChanged.changed = true;
                          //widget.father.items = widget.productItem.purchased;
                          widget.father.newQuantity = _newNumItemsPurchased;
                          debugPrint ("El valor de widget.father.newQuantity es: ${widget.father.newQuantity}");
                          widget.father.totalBeforeDiscountWithoutTax = _totalBeforeDiscountWithoutTax;
                          widget.father.discountAmount = _discountAmount;
                          widget.father.totalAfterDiscountWithoutTax = _totalAfterDiscountWithoutTax;
                          widget.father.taxAmount = _taxAmount;
                          widget.father.totalAmount = _totalAmount;
                          if (widget.userRole == 'BUYER') {
                            widget.father.remarkBuyer = _comment;
                          } else {
                            widget.father.remarkSeller = _comment;
                          }
                          widget.father.statusId = "O";
                          widget.father.allStatus = "OBSERVACIONES";
                          if (!context.mounted) return;
                          Navigator.pop(context, widget.stateChanged.changed);
                        } else {
                          // Error
                          widget.stateChanged.changed = false;
                          if (!context.mounted) return;
                          ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'].toString());
                        }
                      } else {
                        // Finally the quantity of the purchase line has not been changed.
                        widget.stateChanged.changed = false;
                        Navigator.pop(context, widget.stateChanged.changed);
                      }
                    } else {
                      // the quantity of the purchase line has not yet been changed.
                      if (widget.father.items != widget.productItem.purchased) {
                        // The quantity has been modified by the user
                        debugPrint ('Entro en el paso 3.');
                        final Uri url = Uri.parse('$SERVER_IP/modifyPurchaseLine/${widget.father.orderId}/${widget.father.providerName}');
                        debugPrint ("La URL es: $url");
                        final http.Response res = await http.put (
                            url,
                            headers: <String, String>{
                              'Content-Type': 'application/json; charset=UTF-8',
                              //'Authorization': jwt
                            },
                            body: jsonEncode (<String, String> {
                              'product_id': widget.father.productId.toString(),
                              'user_id': widget.userId.toString(),
                              'user_role': widget.userRole.toString(),
                              'new_purchased': (widget.productItem.purchased != widget.father.items ? widget.productItem.purchased.toString() : null)!,
                              'total_before_discount': _totalBeforeDiscount.toString(),
                              'total_amount': _totalAmount.toString(),
                              'discount_amount': _discountAmount.toString(),
                              'tax_amount': _taxAmount.toString(),
                              'case_to_apply': '3', // Only the quantity has been changed by the user
                              'comment': _comment
                            })
                        );
                        _showPleaseWait(false);
                        if (res.statusCode == 200) {
                          // Process the order
                          debugPrint ('OK. ');
                          final List<Map<String, dynamic>> resultListJson = json.decode(res.body)['statusToTransitionTo'].cast<Map<String, dynamic>>();
                          debugPrint ('Entre medias de la api RESPONSE.');
                          final List<PurchaseStatus> resultListPurchaseStatusToTransitionTo = resultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                          if (resultListPurchaseStatusToTransitionTo.isNotEmpty) {
                            widget.father.possibleStatusToTransitionTo.clear();
                            for (var element in resultListPurchaseStatusToTransitionTo) {
                              widget.father.possibleStatusToTransitionTo.add(element);
                            }
                          }
                          debugPrint ('Despues de retornar los statusToTransitionTo.');
                          // get the values of BAN_PRICE and BAN_QUANTITY among the new state of the modified purchased line, "O" (OBSERVACIONES)
                          final List<Map<String, dynamic>> anotherResultListJson = json.decode(res.body)['currentBanQuantityBanPrice'].cast<Map<String, dynamic>>();
                          debugPrint ('Entre medias de la api RESPONSE.');
                          final List<PurchaseStatus> currentBanPriceBanStatusValues = anotherResultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                          if (currentBanPriceBanStatusValues.isNotEmpty) {
                            widget.father.banQuantity = currentBanPriceBanStatusValues[0].banQuantity;
                            widget.father.banPrice = currentBanPriceBanStatusValues[0].banPrice;
                          }
                          debugPrint ('Despues de retornar los currentBanPriceBanStatusValues.');
                          widget.stateChanged.changed = true;
                          widget.father.newQuantity = widget.productItem.purchased != widget.father.items ? widget.productItem.purchased : -1;
                          debugPrint ("El valor de widget.father.newQuantity es: ${widget.father.newQuantity}");
                          widget.father.totalBeforeDiscountWithoutTax = _totalBeforeDiscountWithoutTax;
                          widget.father.discountAmount = _discountAmount;
                          widget.father.totalAfterDiscountWithoutTax = _totalAfterDiscountWithoutTax;
                          widget.father.taxAmount = _taxAmount;
                          widget.father.totalAmount = _totalAmount;
                          if (widget.userRole == 'BUYER') {
                            widget.father.remarkBuyer = _comment;
                          } else {
                            widget.father.remarkSeller = _comment;
                          }
                          widget.father.statusId = "O";
                          widget.father.allStatus = "OBSERVACIONES";
                          if (!context.mounted) return;
                          Navigator.pop(context, widget.stateChanged.changed);
                        } else {
                          // Error
                          widget.stateChanged.changed = false;
                          if (!context.mounted) return;
                          ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'].toString());
                        }
                      } else {
                        // Finally the quantity of the purchase line has not been changed.
                        widget.stateChanged.changed = false;
                        Navigator.pop(context, widget.stateChanged.changed);
                      }
                    }
                  } else {
                    // Case 4
                    // There is no change by the user
                    debugPrint ('Entro en el paso 4');
                    widget.stateChanged.changed = false;
                    Navigator.pop(context, widget.stateChanged.changed);
                  }
                } catch (e) {
                  _showPleaseWait(false);
                  widget.stateChanged.changed = false;
                  if (!context.mounted) return;
                  ShowSnackBar.showSnackBar(context, e.toString(), error: true);
                }
              },
            ),
          ],
        )
    );
    if (widget.father.banQuantity == "SI" && widget.father.banPrice == "NO") {
      // Case 3
      // Only the quantity has been changed by the user
      return SafeArea (
          child: LayoutBuilder(
            builder: (context, constraints) {
              final List<String> listImagesProduct = [];
              for (var i = 0; i < widget.productItem.numImages; i++){
                listImagesProduct.add('$SERVER_IP$IMAGES_DIRECTORY${widget.productItem.productCode}_$i.gif');
              }
              return ListView (
                children: [
                  widget.productItem.numImages > 1 ? Column (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CarouselSlider (
                        items: listImagesProduct.map((url) => AspectRatio (
                          aspectRatio: 3.0 / 2.0,
                          child: CachedNetworkImage(
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            imageUrl: url,
                            fit: BoxFit.scaleDown,
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        )
                        ).toList(),
                        options: CarouselOptions(
                            autoPlay: true,
                            enlargeCenterPage: true,
                            aspectRatio: 2.0,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _current = index;
                              });
                            }
                        ),
                      ),
                      Row (
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: listImagesProduct.map((url) {
                          int index = listImagesProduct.indexOf(url);
                          return Container(
                            width: 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _current == index
                                    ? const Color.fromRGBO(0, 0, 0, 0.9)
                                    : const Color.fromRGBO(0, 0, 0, 0.4)
                            ),
                          );
                        }).toList(),
                      )
                    ],
                  ) : Container(
                    alignment: Alignment.center,
                    width: constraints.maxWidth,
                    child: AspectRatio(
                      aspectRatio: 3.0 / 2.0,
                      child: CachedNetworkImage(
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        imageUrl: '$SERVER_IP$IMAGES_DIRECTORY${widget.productItem.productCode}_0.gif',
                        fit: BoxFit.scaleDown,
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    ),
                  ),
                  SizedBox (height: constraints.maxHeight * HeightInDpis_2),
                  Padding (
                    padding: const EdgeInsets.fromLTRB (15.0, 0.0, 15.0, 0.0),
                    child: Row (
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                          child: Image.asset ('assets/images/00002.png'),
                        ),
                        Padding (
                          padding: const EdgeInsets.only(right: 15.0),
                          child: widget.father.newProductPrice != -1 ? Text.rich (
                              TextSpan (
                                  text: NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.father.newProductPrice/MULTIPLYING_FACTOR).toString())),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 40.0,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                  children: <TextSpan>[
                                    TextSpan (
                                        text: '${' (${NumberFormat("##0.00", "es_ES").format(double.parse((widget.father.productPrice/MULTIPLYING_FACTOR).toString()))}'})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 30.0,
                                          fontFamily: 'SF Pro Display',
                                        )
                                    ),
                                  ]
                              )
                          ) : Text(
                              NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.father.productPrice/MULTIPLYING_FACTOR).toString())),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 40.0,
                                fontFamily: 'SF Pro Display',
                              ),
                              textAlign: TextAlign.start
                          ),
                        ),
                      ],
                    ),
                  ),
                  //SizedBox(height: 4.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_4),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        width: constraints.maxWidth,
                        child: Text(
                          widget.productItem.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      )
                    ],
                  ),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container (
                        padding: const EdgeInsets.only(left: 24.0),
                        width: constraints.maxWidth,
                        child: Text(
                          widget.productItem.businessName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 24.0,
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
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container (
                        padding: const EdgeInsets.only(left: 24),
                        child: Text(
                          'Unids. mínim. venta: ${widget.productItem.minQuantitySell} ${(widget.productItem.minQuantitySell > 1) ? '${widget.productItem.idUnit}s.' : '${widget.productItem.idUnit}.'}',
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
                      ),
                    ],
                  ),
                  SizedBox (height: constraints.maxHeight * HeightInDpis_35),
                  const Center (
                    child: Text (
                      'Cantidad',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Color(0xFF6C6D77),
                      ),
                    ),
                  ),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton (
                          onPressed: () {
                            if (_newNumItemsPurchased != -1) {
                              // the quantity of the purchase line has been changed.
                              // The value -1 is the value when the field NEW_QUANTITY of the KRC_PURCHASE is null,
                              // then it has been not yet modified
                              if (widget.father.newProductPrice != -1) {
                                if (_newNumItemsPurchased > 0) {
                                  setState (() {
                                    _newNumItemsPurchased = _newNumItemsPurchased - widget.productItem.minQuantitySell;
                                    if (_newNumItemsPurchased < 0) _newNumItemsPurchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = _newNumItemsPurchased * (_newNewProductPriceFinal * (widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              } else {
                                if (_newNumItemsPurchased > 0) {
                                  setState (() {
                                    _newNumItemsPurchased = _newNumItemsPurchased - widget.productItem.minQuantitySell;
                                    if (_newNumItemsPurchased < 0) _newNumItemsPurchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                  //_totalBeforeDiscountWithoutTax = _newNumItemsPurchased * (widget.father.totalBeforeDiscountWithoutTax / widget.father.items);
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice*(1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  //_discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  _discountAmount = 0;  // If widget.father.newProductPrice means that there si no discount
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = _newNumItemsPurchased * (widget.father.productPrice*(widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              }
                            } else {
                              // the quantity of the purchase line has not yet been changed.
                              if (widget.father.newProductPrice != -1) {
                                if (widget.productItem.purchased > 0) {
                                  setState (() {
                                    widget.productItem.purchased = widget.productItem.purchased - widget.productItem.minQuantitySell;
                                    if (widget.productItem.purchased < 0) widget.productItem.purchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = widget.productItem.purchased * (_newNewProductPriceFinal * (widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              } else {
                                if (widget.productItem.purchased > 0) {
                                  setState (() {
                                    widget.productItem.purchased = widget.productItem.purchased - widget.productItem.minQuantitySell;
                                    if (widget.productItem.purchased < 0) widget.productItem.purchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  //_discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  _discountAmount = 0;  // If widget.father.newProductPrice means that there si no discount
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = widget.productItem.purchased * (widget.father.productPrice*(widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              }
                            }
                          },
                          child: Container (
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(2.0),
                            decoration: BoxDecoration (
                                color: tanteLadenAmber500,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: tanteLadenButtonBorderGray,
                                    width: 1
                                )
                            ),
                            child: Container(
                              width: 40.0,
                              height: 40.0,
                              alignment: Alignment.center,
                              child: const Text(
                                '-',
                                style: TextStyle(
                                    fontWeight: FontWeight.w300,
                                    fontSize: 24.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: tanteLadenButtonBorderGray
                                ),
                              ),
                            ),
                          )
                      ),
                      Padding (
                        //padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                        padding: const EdgeInsets.only(left: WithInDpis_20, right: WithInDpis_20),
                        child: RichText (
                            text: TextSpan (
                                text: widget.father.newQuantity != -1
                                    ? '$_newNumItemsPurchased (${widget.productItem.purchased}) '
                                    : widget.productItem.purchased.toString(),
                                style: const TextStyle (
                                  fontWeight: FontWeight.w700,
                                  fontSize: 24.0,
                                  fontFamily: 'SF Pro Display',
                                  fontStyle: FontStyle.normal,
                                  color: Colors.black,
                                ),
                                children: <TextSpan>[
                                  TextSpan (
                                      text: widget.father.newQuantity != -1
                                          ? _newNumItemsPurchased > 1 ? ' ${widget.productItem.idUnit}s.' : ' ${widget.productItem.idUnit}.'
                                          : widget.productItem.purchased > 1 ? ' ${widget.productItem.idUnit}s.' : ' ${widget.productItem.idUnit}.',
                                      style: const TextStyle (
                                          fontWeight: FontWeight.bold
                                      )
                                  )
                                ]
                            )
                        ),
                      ),
                      TextButton(
                          onPressed: () {
                            if (_newNumItemsPurchased != -1) {
                              // the quantity of the purchase line has been changed.
                              // The value -1 is the value when the field NEW_QUANTITY of the KRC_PURCHASE is null,
                              // then it has been not yet modified
                              if(widget.father.newProductPrice != -1) {
                                if (_newNumItemsPurchased > 0) {
                                  setState (() {
                                    _newNumItemsPurchased = _newNumItemsPurchased + widget.productItem.minQuantitySell;
                                  });
                                  _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = _newNumItemsPurchased * (_newNewProductPriceFinal * (widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              } else {
                                if (_newNumItemsPurchased > 0) {
                                  setState (() {
                                    _newNumItemsPurchased = _newNumItemsPurchased + widget.productItem.minQuantitySell;
                                  });
                                  _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                  //_totalBeforeDiscountWithoutTax = _newNumItemsPurchased * (widget.father.totalBeforeDiscountWithoutTax / widget.father.items);
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice*(1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  _discountAmount = 0;  // If widget.father.newProductPrice means that there si no discount
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = _newNumItemsPurchased * (widget.father.productPrice*(widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              }
                            } else {
                              // the quantity of the purchase line has not yet been changed.
                              if (widget.father.newProductPrice != -1) {
                                if (widget.productItem.purchased > 0) {
                                  setState (() {
                                    widget.productItem.purchased = widget.productItem.purchased + widget.productItem.minQuantitySell;
                                  });
                                  _totalBeforeDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = widget.productItem.purchased * (_newNewProductPriceFinal * (widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              } else {
                                if (widget.productItem.purchased > 0) {
                                  setState (() {
                                    widget.productItem.purchased = widget.productItem.purchased + widget.productItem.minQuantitySell;
                                  });
                                  _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice*(1+(widget.productItem.taxApply/100)));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  _discountAmount = 0;  // If widget.father.newProductPrice means that there si no discount
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = widget.productItem.purchased * (widget.father.productPrice*(widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              }
                            }
                          },
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(2.0),
                            decoration: BoxDecoration(
                              color: tanteLadenAmber500,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF6C6D77),
                                width: 1,
                              ),
                            ),
                            child: Container(
                              width: 40.0,
                              height: 40.0,
                              alignment: Alignment.center,
                              child: const Text(
                                '+',
                                style: TextStyle(
                                  fontWeight: FontWeight.w300,
                                  fontSize: 24.0,
                                  fontFamily: 'SF Pro Display',
                                  fontStyle: FontStyle.normal,
                                  color: tanteLadenButtonBorderGray,
                                ),
                              ),
                            ),
                          )
                      )
                    ],
                  ),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: Image.asset (
                          'assets/images/logoComment.png',
                          fit: BoxFit.scaleDown,
                          width: 20.0,
                          height: 20.0,
                        ),
                      ),
                      Container (
                        padding: const EdgeInsets.only(left:8),
                        child: Text.rich(
                            TextSpan (
                                text: 'Introducir comentario',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: tanteLadenIconBrown,
                                    decoration: TextDecoration.underline
                                ),
                                recognizer: TapGestureRecognizer ()
                                  ..onTap = () async {
                                    _comment = await Navigator.push (context, MaterialPageRoute (
                                        builder: (context) => AddComment (_comment)
                                    ));
                                  }
                            )
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  _pleaseWait ? Stack(
                    key: const ObjectKey ("stack"),
                    alignment: AlignmentDirectional.center,
                    children: [
                      tmpBuilder,
                      _pleaseWaitWidget
                    ],
                  ): Stack(
                    key: const ObjectKey("stack"),
                    children: [tmpBuilder],
                  ),
                  //SizedBox(height: 35.0),
                ],
              );
            },
          )
      );
    } else if (widget.father.banQuantity == "NO" && widget.father.banPrice == "SI") {
      // Case 2
      // Only the price of the purchased has been changed by the user
      return SafeArea (
          child: LayoutBuilder (
            builder: (context, constraints) {
              final List<String> listImagesProduct = [];
              for (var i = 0; i < widget.productItem.numImages; i++) {
                listImagesProduct.add('$SERVER_IP$IMAGES_DIRECTORY${widget.productItem.productCode}_$i.gif');
              }
              return ListView (
                children: [
                  widget.productItem.numImages > 1 ? Column (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CarouselSlider (
                        items: listImagesProduct.map((url) => AspectRatio (
                          aspectRatio: 3.0 / 2.0,
                          child: CachedNetworkImage (
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            imageUrl: url,
                            fit: BoxFit.scaleDown,
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        )
                        ).toList(),
                        options: CarouselOptions(
                            autoPlay: true,
                            enlargeCenterPage: true,
                            aspectRatio: 2.0,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _current = index;
                              });
                            }
                        ),
                      ),
                      Row (
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: listImagesProduct.map((url) {
                          int index = listImagesProduct.indexOf(url);
                          return Container(
                            width: 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _current == index
                                    ? const Color.fromRGBO(0, 0, 0, 0.9)
                                    : const Color.fromRGBO(0, 0, 0, 0.4)
                            ),
                          );
                        }).toList(),
                      )
                    ],
                  ) : Container (
                    alignment: Alignment.center,
                    width: constraints.maxWidth,
                    child: AspectRatio(
                      aspectRatio: 3.0 / 2.0,
                      child: CachedNetworkImage(
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        imageUrl: '$SERVER_IP$IMAGES_DIRECTORY${widget.productItem.productCode}_0.gif',
                        fit: BoxFit.scaleDown,
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    ),
                  ),
                  SizedBox (height: constraints.maxHeight * HeightInDpis_2),
                  Padding(
                    padding: const EdgeInsets.fromLTRB (15.0, 0.0, 15.0, 0.0),
                    child: Row (
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                          child: Image.asset ('assets/images/00002.png'),
                        ),
                        Padding (
                          padding: const EdgeInsets.only(right: 15.0),
                          child: _newNewProductPriceFinal != -1 ? Text.rich (
                              TextSpan (
                                  text: NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((_newNewProductPriceFinal/MULTIPLYING_FACTOR).toString())),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 40.0,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                        text: '${' (${NumberFormat("##0.00", "es_ES").format(double.parse((widget.father.productPrice/MULTIPLYING_FACTOR).toString()))}'})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 30.0,
                                          fontFamily: 'SF Pro Display',
                                        )
                                    )
                                  ]
                              )
                          ) : Text(
                              NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((_newPrice/MULTIPLYING_FACTOR).toString())),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 40.0,
                                fontFamily: 'SF Pro Display',
                              ),
                              textAlign: TextAlign.start
                          ),
                        ),
                      ],
                    ),
                  ),
                  //SizedBox(height: 4.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_4),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        width: constraints.maxWidth,
                        child: Text(
                          widget.productItem.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      )
                    ],
                  ),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        width: constraints.maxWidth,
                        child: Text(
                          widget.productItem.businessName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 24.0,
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
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container (
                        padding: const EdgeInsets.only(left: 24),
                        child: Text(
                          'Unids. mínim. venta: ${widget.productItem.minQuantitySell}',
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
                      ),
                    ],
                  ),
                  //SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  const Divider (thickness: 2.0,),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container (
                        padding: const EdgeInsets.only(left: 24),
                        child: const Text (
                          'Modificación del precio por: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded (
                          flex: 1,
                          child: ListTile(
                            title: const Text('Valor'),
                            leading: Radio<PriceChangeType>(
                              value: PriceChangeType.priceValue,
                              groupValue: _changeType,
                              onChanged: (PriceChangeType? value){
                                setState(() {
                                  _changeType = value!;
                                  _valueDiscount = 0.0;
                                  _percentDiscount = 0.0;
                                  _newNewProductPriceFinal = widget.father.newProductPrice;
                                });
                                _valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                _percentDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
                              },
                            ),
                          )
                      ),
                      Expanded (
                          flex: 1,
                          child: ListTile(
                            title: const Text('Porcentaje'),
                            leading: Radio<PriceChangeType>(
                              value: PriceChangeType.percentValue,
                              groupValue: _changeType,
                              onChanged: (PriceChangeType? value){
                                setState(() {
                                  _changeType = value!;
                                  _percentDiscount = 0.0;
                                  _valueDiscount = 0.0;
                                  _newNewProductPriceFinal = widget.father.newProductPrice;
                                });
                                _percentDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
                                _valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                              },
                            ),
                          )
                      )
                    ],
                  ),
                  const Divider(thickness: 2.0,),
                  (_changeType == PriceChangeType.priceValue) ? const Center (
                    child: Text(
                      'Modificación neta',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Color(0xFF6C6D77),
                      ),
                    ),
                  ) : const Center (
                    child: Text (
                      'Modificación porcentual',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Color(0xFF6C6D77),
                      ),
                    ),
                  ),
                  (_changeType == PriceChangeType.priceValue) ? Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded (
                          flex:1,
                          child: Container()
                      ),
                      Expanded (
                        flex:4,
                        child: Row (
                          children: [
                            Expanded (
                              flex: 1,
                              child: TextButton (
                                  onPressed: () {
                                    debugPrint ('Estoy en el onPressed de -');
                                    if (widget.father.newProductPrice != -1) {
                                      // the price has been previously modified
                                      debugPrint ('Estoy en el onPressed de -. Dentro de la parte de que el precio ha sido previamente modificado.');
                                      final double tmpValueDiscount = _valueDiscount;
                                      _valueDiscount = _valueDiscount - 0.1;
                                      if (widget.father.newProductPrice >= (_valueDiscount * MULTIPLYING_FACTOR).abs()) {
                                        // the price can't be negative
                                        setState(() {
                                          _valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                        });
                                      } else {
                                        _valueDiscount = tmpValueDiscount;
                                      }
                                    } else {
                                      // the price has not yet modified
                                      //debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
                                      debugPrint ('Estoy en el onPressed de -. Dentro de la parte de que el precio nunca ha sido previamente modificado.');
                                      final double tmpValueDiscount = _valueDiscount;
                                      _valueDiscount = _valueDiscount - 0.1;
                                      debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
                                      if (widget.father.productPrice >= (_valueDiscount * MULTIPLYING_FACTOR).abs()) {
                                        // the price can't be negative
                                        setState(() {
                                          _valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                        });
                                      } else {
                                        _valueDiscount = tmpValueDiscount;
                                      }
                                    }
                                  },
                                  child: Container (
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration (
                                        color: tanteLadenAmber500,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: tanteLadenButtonBorderGray,
                                            width: 1
                                        )
                                    ),
                                    child: Container (
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '-',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w300,
                                            fontSize: 24.0,
                                            fontFamily: 'SF Pro Display',
                                            fontStyle: FontStyle.normal,
                                            color: tanteLadenButtonBorderGray
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            ),
                            Expanded (
                              flex: 2,
                              child: Form (
                                key: _formNewPricekey,
                                child: TextFormField(
                                  controller: _valueDiscountTextField,
                                  decoration: const InputDecoration (
                                      prefixIcon: Icon(Icons.euro_rounded)
                                  ),
                                  style: const TextStyle (
                                    fontWeight: FontWeight.w700,
                                    fontSize: 24.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$')),],
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (String? value) {
                                    RegExp regexp = RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$');
                                    if (!regexp.hasMatch(value!)) {
                                      return 'Introduce un valor neto válido. Formato: (+/-)##,##';
                                    } else {
                                      return null;
                                    }
                                  },
                                ),
                              ),
                            ),
                            Expanded (
                              flex: 1,
                              child: TextButton(
                                  onPressed: () {
                                    debugPrint ('Estoy en el onPressed de +');
                                    if (widget.father.newProductPrice != -1) {
                                      // the price has been previously modified
                                      debugPrint ('Estoy en el onPressed de +. Dentro de la parte de que el precio ha sido previamente modificado.');
                                      _valueDiscount = _valueDiscount + 0.1;
                                      setState(() {
                                        _valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                      });
                                    } else {
                                      // the price has not yet modified
                                      //debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
                                      debugPrint ('Estoy en el onPressed de +. Dentro de la parte de que el precio nunca ha sido previamente modificado.');
                                      _valueDiscount = _valueDiscount + 0.1;
                                      debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
                                      setState(() {
                                        _valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                      });
                                    }
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration(
                                      color: tanteLadenAmber500,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF6C6D77),
                                        width: 1,
                                      ),
                                    ),
                                    child: Container(
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '+',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 24.0,
                                          fontFamily: 'SF Pro Display',
                                          fontStyle: FontStyle.normal,
                                          color: tanteLadenButtonBorderGray,
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded (
                          flex:1,
                          child: Container()
                      )
                    ],
                  ) : Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded (
                          flex:1,
                          child: Container()
                      ),
                      Expanded (
                        flex:4,
                        child: Row (
                          children: [
                            Expanded (
                              flex: 1,
                              child: TextButton(
                                  onPressed: () {
                                    if (widget.father.newProductPrice != -1) {
                                      // the price has been previously modified
                                      debugPrint ('Estoy en el onPressed de -. Dentro de la parte de que el precio ha sido previamente modificado.');
                                      final double tmpPercentDiscount = _percentDiscount;
                                      _percentDiscount = _percentDiscount - 0.5;
                                      debugPrint ('El valor de _percentDiscount es: $_percentDiscount');
                                      debugPrint ('El valor de productPrice es: ${widget.father.productPrice}');
                                      debugPrint ('El valor de widget.father.productPrice * (1+(_percentDiscount/100)) es: ${((widget.father.productPrice * (1+(_percentDiscount/100)))).abs()}');
                                      if (widget.father.newProductPrice >= ((widget.father.newProductPrice * (1+(_percentDiscount/100)))).abs()) {
                                        setState(() {
                                          _percentDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse((_percentDiscount).toString()));
                                        });
                                      } else {
                                        _percentDiscount = tmpPercentDiscount;
                                      }
                                    } else {
                                      // the price has not yet modified
                                      debugPrint ('Estoy en el onPressed de -. Dentro de la parte de que el precio nunca ha sido previamente modificado.');
                                      final double tmpPercentDiscount = _percentDiscount;
                                      _percentDiscount = _percentDiscount - 0.5;
                                      debugPrint ('El valor de _percentDiscount es: $_percentDiscount');
                                      debugPrint ('El valor de productPrice es: ${widget.father.productPrice}');
                                      debugPrint ('El valor de widget.father.productPrice * (1+(_percentDiscount/100)) es: ${((widget.father.productPrice * (1+(_percentDiscount/100)))).abs()}');
                                      if (widget.father.productPrice >= ((widget.father.productPrice * (1+(_percentDiscount/100)))).abs()) {
                                        setState(() {
                                          _percentDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse((_percentDiscount).toString()));
                                        });
                                      } else {
                                        _percentDiscount = tmpPercentDiscount;
                                      }
                                    }
                                  },
                                  child: Container (
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration (
                                        color: tanteLadenAmber500,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: tanteLadenButtonBorderGray,
                                            width: 1
                                        )
                                    ),
                                    child: Container(
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '-',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w300,
                                            fontSize: 24.0,
                                            fontFamily: 'SF Pro Display',
                                            fontStyle: FontStyle.normal,
                                            color: tanteLadenButtonBorderGray
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            ),
                            Expanded (
                              flex: 2,
                              child: Form(
                                key: _formPercentKey,
                                child: TextFormField(
                                  controller: _percentDiscountTextField,
                                  decoration: const InputDecoration (
                                    prefixText: '  %  ',
                                    prefixStyle: TextStyle (
                                      fontWeight: FontWeight.w700,
                                      fontSize: 24.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.black45,
                                    ),
                                  ),
                                  style: const TextStyle (
                                    fontWeight: FontWeight.w700,
                                    fontSize: 24.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$')),],
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (String? value) {
                                    RegExp regexp = RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$');
                                    if (!regexp.hasMatch(value!)) {
                                      return 'Introduce un porcentaje válido. Formato: (+/-)##,##';
                                    } else {
                                      return null;
                                    }
                                  },
                                ),
                              ),
                            ),
                            Expanded (
                              flex: 1,
                              child: TextButton(
                                  onPressed: () {
                                    if (widget.father.newProductPrice != -1) {
                                      // the price has been previously modified
                                      debugPrint ('Estoy en el onPressed de +. Dentro de la parte de que el precio ha sido previamente modificado.');
                                      _percentDiscount = _percentDiscount + 0.5;
                                      debugPrint ('El valor de _percentDiscount es: $_percentDiscount');
                                      debugPrint ('El valor de productPrice es: ${widget.father.productPrice}');
                                      debugPrint ('El valor de widget.father.productPrice * (1+(_percentDiscount/100)) es: ${((widget.father.productPrice * (1+(_percentDiscount/100)))).abs()}');
                                      setState(() {
                                        _percentDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse((_percentDiscount).toString()));
                                      });
                                    } else {
                                      // the price has not yet modified
                                      debugPrint ('Estoy en el onPressed de +. Dentro de la parte de que el precio nunca ha sido previamente modificado.');
                                      _percentDiscount = _percentDiscount + 0.5;
                                      debugPrint ('El valor de _percentDiscount es: $_percentDiscount');
                                      debugPrint ('El valor de productPrice es: ${widget.father.productPrice}');
                                      debugPrint ('El valor de widget.father.productPrice * (1+(_percentDiscount/100)) es: ${((widget.father.productPrice * (1+(_percentDiscount/100)))).abs()}');
                                      setState(() {
                                        _percentDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse((_percentDiscount).toString()));
                                      });
                                    }
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration(
                                      color: tanteLadenAmber500,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF6C6D77),
                                        width: 1,
                                      ),
                                    ),
                                    child: Container(
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '+',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 24.0,
                                          fontFamily: 'SF Pro Display',
                                          fontStyle: FontStyle.normal,
                                          color: tanteLadenButtonBorderGray,
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded (
                          flex:1,
                          child: Container()
                      )
                    ],
                  ),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: Image.asset (
                          'assets/images/logoComment.png',
                          fit: BoxFit.scaleDown,
                          width: 20.0,
                          height: 20.0,
                        ),
                      ),
                      Container (
                        padding: const EdgeInsets.only(left:8),
                        child: Text.rich(
                            TextSpan (
                                text: 'Introducir comentario',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: tanteLadenIconBrown,
                                    decoration: TextDecoration.underline
                                ),
                                recognizer: TapGestureRecognizer ()
                                  ..onTap = () async {
                                    _comment = await Navigator.push (context, MaterialPageRoute (
                                        builder: (context) => AddComment (_comment)
                                    ));
                                  }
                            )
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container (
                          padding: const EdgeInsets.only(left: 24),
                          child: Checkbox (
                            checkColor: Colors.white,
                            fillColor: MaterialStateProperty.resolveWith(getColor),
                            value: _isOfficial,
                            onChanged: (bool? value) {
                              setState(() {
                                _isOfficial = value!;
                              });
                            },
                          )
                      ),
                      const Text (
                        'Oficializar el nuevo precio.',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14.0,
                          fontFamily: 'SF Pro Display',
                          fontStyle: FontStyle.normal,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ],
                  ),
                  _pleaseWait ? Stack (
                    key: const ObjectKey ("stack"),
                    alignment: AlignmentDirectional.center,
                    children: [
                      tmpBuilder,
                      _pleaseWaitWidget
                    ],
                  ): Stack (
                    key: const ObjectKey("stack"),
                    children: [tmpBuilder],
                  ),
                  //SizedBox(height: 35.0),
                ],
              );
            },
          )
      );
    } else {    // widget.father.banQuantity == "SI" && widget.father.banPrice == "SI"
      return SafeArea (
          child: LayoutBuilder(
            builder: (context, constraints) {
              final List<String> listImagesProduct = [];
              for (var i = 0; i < widget.productItem.numImages; i++) {
                listImagesProduct.add('$SERVER_IP$IMAGES_DIRECTORY${widget.productItem.productCode}_$i.gif');
              }
              return ListView (
                children: [
                  widget.productItem.numImages > 1 ? Column (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CarouselSlider (
                        items: listImagesProduct.map((url) => AspectRatio (
                          aspectRatio: 3.0 / 2.0,
                          child: CachedNetworkImage(
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            imageUrl: url,
                            fit: BoxFit.scaleDown,
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        )
                        ).toList(),
                        options: CarouselOptions(
                            autoPlay: true,
                            enlargeCenterPage: true,
                            aspectRatio: 2.0,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _current = index;
                              });
                            }
                        ),
                      ),
                      Row (
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: listImagesProduct.map((url) {
                          int index = listImagesProduct.indexOf(url);
                          return Container(
                            width: 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _current == index
                                    ? const Color.fromRGBO(0, 0, 0, 0.9)
                                    : const Color.fromRGBO(0, 0, 0, 0.4)
                            ),
                          );
                        }).toList(),
                      )
                    ],
                  ) : Container(
                    alignment: Alignment.center,
                    width: constraints.maxWidth,
                    child: AspectRatio(
                      aspectRatio: 3.0 / 2.0,
                      child: CachedNetworkImage(
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        imageUrl: '$SERVER_IP$IMAGES_DIRECTORY${widget.productItem.productCode}_0.gif',
                        fit: BoxFit.scaleDown,
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    ),
                  ),
                  SizedBox (height: constraints.maxHeight * HeightInDpis_2),
                  Padding(
                    padding: const EdgeInsets.fromLTRB (15.0, 0.0, 15.0, 0.0),
                    child: Row (
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                          child: Image.asset ('assets/images/00002.png'),
                        ),
                        Padding (
                          padding: const EdgeInsets.only(right: 15.0),
                          child: _newNewProductPriceFinal != -1 ? Text.rich (
                              TextSpan (
                                  text: NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((_newNewProductPriceFinal/MULTIPLYING_FACTOR).toString())),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 40.0,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                        text: '${' (${NumberFormat("##0.00", "es_ES").format(double.parse((widget.father.productPrice/MULTIPLYING_FACTOR).toString()))}'})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 30.0,
                                          fontFamily: 'SF Pro Display',
                                        )
                                    )
                                  ]
                              )
                          ) : Text(
                              NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((_newPrice/MULTIPLYING_FACTOR).toString())),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 40.0,
                                fontFamily: 'SF Pro Display',
                              ),
                              textAlign: TextAlign.start
                          ),
                        ),
                      ],
                    ),
                  ),
                  //SizedBox(height: 4.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        width: constraints.maxWidth,
                        child: Text(
                          widget.productItem.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      )
                    ],
                  ),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        width: constraints.maxWidth,
                        child: Text(
                          widget.productItem.businessName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 24.0,
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
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container (
                        padding: const EdgeInsets.only(left: 24),
                        child: Text(
                          'Unids. mínim. venta: ${widget.productItem.minQuantitySell} ${(widget.productItem.minQuantitySell > 1) ? '${widget.productItem.idUnit}s.' : '${widget.productItem.idUnit}.'}',
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
                      ),
                    ],
                  ),
                  //Divider (thickness: 8.0,),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  const Center(
                    child: Text(
                      'Cantidad',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Color(0xFF6C6D77),
                      ),
                    ),
                  ),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton (
                          onPressed: () {
                            if (widget.father.newQuantity != -1) {
                              // the quantity of the purchase line has been changed.
                              // The value -1 is the value if the field NEW_QUANTITY of the KRC_PURCHASE is null,
                              // then it has been not yet modified
                              if (_newNewProductPriceFinal != -1) {
                                if (_newNumItemsPurchased > 0) {
                                  setState (() {
                                    _newNumItemsPurchased = _newNumItemsPurchased - widget.productItem.minQuantitySell;
                                    if (_newNumItemsPurchased < 0) _newNumItemsPurchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  final double productPriceDiscounted = (_newNewProductPriceFinal + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                  debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
                                  _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                  debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                  _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              } else {
                                if (_newNumItemsPurchased > 0) {
                                  setState (() {
                                    _newNumItemsPurchased = _newNumItemsPurchased - widget.productItem.minQuantitySell;
                                    if (_newNumItemsPurchased < 0) _newNumItemsPurchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice*(1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                  _discountAmount = _newNumItemsPurchased * (((_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal) - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = _newNumItemsPurchased * (_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal);
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                  debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                  _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              }
                            } else {
                              // the quantity of the purchase line has not yet been changed.
                              if (_newNewProductPriceFinal != -1) {
                                if (widget.productItem.purchased > 0) {
                                  setState (() {
                                    widget.productItem.purchased = widget.productItem.purchased - widget.productItem.minQuantitySell;
                                    if (widget.productItem.purchased < 0) widget.productItem.purchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  final double productPriceDiscounted = (_newNewProductPriceFinal + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                  debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
                                  _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                  debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                  _taxAmount = widget.productItem.purchased * taxAmountByProduct;
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              } else {
                                if (widget.productItem.purchased > 0) {
                                  setState (() {
                                    widget.productItem.purchased = widget.productItem.purchased - widget.productItem.minQuantitySell;
                                    if (widget.productItem.purchased < 0) widget.productItem.purchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  _discountAmount = widget.productItem.purchased * (((_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal) - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                  debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
                                  _totalAfterDiscountWithoutTax = widget.productItem.purchased * (_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal);
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                  debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                  _taxAmount = widget.productItem.purchased * taxAmountByProduct;
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              }
                            }
                          },
                          child: Container (
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(2.0),
                            decoration: BoxDecoration (
                                color: tanteLadenAmber500,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: tanteLadenButtonBorderGray,
                                    width: 1
                                )
                            ),
                            child: Container(
                              width: 40.0,
                              height: 40.0,
                              alignment: Alignment.center,
                              child: const Text(
                                '-',
                                style: TextStyle(
                                    fontWeight: FontWeight.w300,
                                    fontSize: 24.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: tanteLadenButtonBorderGray
                                ),
                              ),
                            ),
                          )
                      ),
                      Padding (
                        //padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                        padding: const EdgeInsets.only(left: WithInDpis_20, right: WithInDpis_20),
                        child: RichText (
                          text: TextSpan (
                              text: widget.father.newQuantity != -1
                                  ? '$_newNumItemsPurchased (${widget.productItem.purchased}) '
                                  : widget.productItem.purchased.toString(),
                              style: const TextStyle (
                                fontWeight: FontWeight.w700,
                                fontSize: 24.0,
                                fontFamily: 'SF Pro Display',
                                fontStyle: FontStyle.normal,
                                color: Colors.black,
                              ),
                              children: <TextSpan>[
                                TextSpan (
                                    text: widget.father.newQuantity != -1
                                        ? _newNumItemsPurchased > 1 ? ' ${widget.productItem.idUnit}s.' : ' ${widget.productItem.idUnit}.'
                                        : widget.productItem.purchased > 1 ? ' ${widget.productItem.idUnit}s.' : ' ${widget.productItem.idUnit}.',
                                    style: const TextStyle (
                                        fontWeight: FontWeight.bold
                                    )
                                )
                              ]
                          ),
                        ),
                      ),
                      TextButton(
                          onPressed: () {
                            if (widget.father.newQuantity != -1) {
                              // the quantity of the purchase line has been changed.
                              // The value -1 is the value when the field NEW_QUANTITY of the KRC_PURCHASE is null,
                              // then it has been not yet modified
                              if (_newNewProductPriceFinal != -1) {
                                setState(() {
                                  _newNumItemsPurchased = _newNumItemsPurchased + widget.productItem.minQuantitySell;
                                });
                                _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
                                debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                final double productPriceDiscounted = (_newNewProductPriceFinal + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
                                _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
                                debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
                                debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                debugPrint ('El valor de _totalAmount es: $_totalAmount');
                              } else {
                                setState(() {
                                  _newNumItemsPurchased = _newNumItemsPurchased + widget.productItem.minQuantitySell;
                                });
                                _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice*(1+widget.productItem.taxApply/100));
                                debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
                                _discountAmount = _newNumItemsPurchased * (((_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal) - widget.father.productPrice));
                                debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                _totalAfterDiscountWithoutTax = _newNumItemsPurchased * (_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal);
                                debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
                                debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                debugPrint ('El valor de _totalAmount es: $_totalAmount');
                              }
                            } else {
                              // the quantity of the purchase line has not yet been changed.
                              if (_newNewProductPriceFinal != -1) {
                                setState(() {
                                  widget.productItem.purchased = widget.productItem.purchased + widget.productItem.minQuantitySell;
                                });
                                _totalBeforeDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
                                debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                final double productPriceDiscounted = (_newNewProductPriceFinal + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
                                _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
                                debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                _taxAmount = widget.productItem.purchased * taxAmountByProduct;
                                debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                //_totalAmount = widget.productItem.purchased * widget.productItem.totalAmount;
                                _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                debugPrint ('El valor de _totalAmount es: $_totalAmount');
                              } else {
                                setState(() {
                                  widget.productItem.purchased = widget.productItem.purchased + widget.productItem.minQuantitySell;
                                });
                                _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice*(1+(widget.productItem.taxApply/100)));
                                debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
                                final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
                                _discountAmount = widget.productItem.purchased * (((_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal) - widget.father.productPrice));
                                debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                _totalAfterDiscountWithoutTax = widget.productItem.purchased * (_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal);
                                debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                _taxAmount = widget.productItem.purchased * taxAmountByProduct;
                                debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                debugPrint ('El valor de _totalAmount es: $_totalAmount');
                              }
                            }
                          },
                          child: Container (
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(2.0),
                            decoration: BoxDecoration(
                              color: tanteLadenAmber500,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF6C6D77),
                                width: 1,
                              ),
                            ),
                            child: Container(
                              width: 40.0,
                              height: 40.0,
                              alignment: Alignment.center,
                              child: const Text(
                                '+',
                                style: TextStyle(
                                  fontWeight: FontWeight.w300,
                                  fontSize: 24.0,
                                  fontFamily: 'SF Pro Display',
                                  fontStyle: FontStyle.normal,
                                  color: tanteLadenButtonBorderGray,
                                ),
                              ),
                            ),
                          )
                      ),
                    ],
                  ),
                  //SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  const Divider (thickness: 2.0,),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container (
                        padding: const EdgeInsets.only(left: 24),
                        child: const Text (
                          'Modificación del precio por: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded (
                          flex: 1,
                          child: ListTile(
                            title: const Text('Valor'),
                            leading: Radio<PriceChangeType>(
                              value: PriceChangeType.priceValue,
                              groupValue: _changeType,
                              onChanged: (PriceChangeType? value){
                                setState(() {
                                  _changeType = value!;
                                  _valueDiscount = 0.0;
                                  _percentDiscount = 0.0;
                                  _newNewProductPriceFinal = widget.father.newProductPrice;
                                });
                                _valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                _percentDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
                              },
                            ),
                          )
                      ),
                      Expanded (
                          flex: 1,
                          child: ListTile(
                            title: const Text('Porcentaje'),
                            leading: Radio<PriceChangeType>(
                              value: PriceChangeType.percentValue,
                              groupValue: _changeType,
                              onChanged: (PriceChangeType? value){
                                setState(() {
                                  _changeType = value!;
                                  _percentDiscount = 0.0;
                                  _valueDiscount = 0.0;
                                  _newNewProductPriceFinal = widget.father.newProductPrice;
                                });
                                _percentDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
                                _valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                              },
                            ),
                          )
                      )
                    ],
                  ),
                  const Divider(thickness: 2.0,),
                  (_changeType == PriceChangeType.priceValue) ? const Center (
                    child: Text(
                      'Modificación neta',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Color(0xFF6C6D77),
                      ),
                    ),
                  ) : const Center(
                    child: Text (
                      'Modificación porcentual',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Color(0xFF6C6D77),
                      ),
                    ),
                  ),
                  (_changeType == PriceChangeType.priceValue) ? Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded (
                          flex:1,
                          child: Container()
                      ),
                      Expanded (
                        flex:4,
                        child: Row (
                          children: [
                            Expanded (
                              flex: 1,
                              child: TextButton(
                                  onPressed: () {
                                    debugPrint ('Estoy en el onPressed de -');
                                    if (widget.father.newProductPrice != -1) {
                                      // the price has been previously modified
                                      debugPrint ('Estoy en el onPressed de -. Dentro de la parte de que el precio ha sido previamente modificado.');
                                      final double tmpValueDiscount = _valueDiscount;
                                      _valueDiscount = _valueDiscount - 0.1;
                                      if (widget.father.newProductPrice >= (_valueDiscount * MULTIPLYING_FACTOR).abs()) {
                                        // the price can't be negative
                                        setState(() {
                                          _valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                        });
                                      } else {
                                        _valueDiscount = tmpValueDiscount;
                                      }
                                    } else {
                                      // the price has not yet modified
                                      //debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
                                      debugPrint ('Estoy en el onPressed de -. Dentro de la parte de que el precio nunca ha sido previamente modificado.');
                                      final double tmpValueDiscount = _valueDiscount;
                                      _valueDiscount = _valueDiscount - 0.1;
                                      debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
                                      if (widget.father.productPrice >= (_valueDiscount * MULTIPLYING_FACTOR).abs()) {
                                        // the price can't be negative
                                        setState(() {
                                          _valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                        });
                                      } else {
                                        _valueDiscount = tmpValueDiscount;
                                      }
                                    }
                                  },
                                  child: Container (
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration (
                                        color: tanteLadenAmber500,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: tanteLadenButtonBorderGray,
                                            width: 1
                                        )
                                    ),
                                    child: Container(
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text (
                                        '-',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w300,
                                            fontSize: 24.0,
                                            fontFamily: 'SF Pro Display',
                                            fontStyle: FontStyle.normal,
                                            color: tanteLadenButtonBorderGray
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            ),
                            Expanded (
                              flex: 2,
                              child: Form(
                                key: _formNewPricekey,
                                child: TextFormField(
                                  controller: _valueDiscountTextFieldOnlyForCaseOne,
                                  decoration: const InputDecoration (
                                      prefixIcon: Icon(Icons.euro_rounded)
                                  ),
                                  style: const TextStyle (
                                    fontWeight: FontWeight.w700,
                                    fontSize: 24.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$')),],
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  onEditingComplete: () {
                                    _percentDiscount = double.tryParse (_percentDiscountTextField.text.replaceAll(RegExp(','), '.'))!;
                                    debugPrint('El valor de: _percentDiscount es: $_percentDiscount');
                                  },
                                  validator: (String? value) {
                                    RegExp regexp = RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$');
                                    if (!regexp.hasMatch(value!)) {
                                      return 'Introduce un valor neto válido. Formato: (+/-)##,##';
                                    } else {
                                      return null;
                                    }
                                  },
                                ),
                              ),
                            ),
                            Expanded (
                              flex: 1,
                              child: TextButton(
                                  onPressed: () {
                                    debugPrint ('Estoy en el onPressed de +');
                                    if (widget.father.newProductPrice != -1) {
                                      // the price has been previously modified
                                      debugPrint ('Estoy en el onPressed de +. Dentro de la parte de que el precio ha sido previamente modificado.');
                                      _valueDiscount = _valueDiscount + 0.1;
                                      setState(() {
                                        _valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                      });
                                    } else {
                                      // the price has not yet modified
                                      //debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
                                      debugPrint ('Estoy en el onPressed de +. Dentro de la parte de que el precio nunca ha sido previamente modificado.');
                                      _valueDiscount = _valueDiscount + 0.1;
                                      debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
                                      setState(() {
                                        _valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                      });
                                    }
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration(
                                      color: tanteLadenAmber500,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF6C6D77),
                                        width: 1,
                                      ),
                                    ),
                                    child: Container(
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '+',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 24.0,
                                          fontFamily: 'SF Pro Display',
                                          fontStyle: FontStyle.normal,
                                          color: tanteLadenButtonBorderGray,
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded (
                          flex:1,
                          child: Container()
                      )
                    ],
                  ) : Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded (
                          flex:1,
                          child: Container()
                      ),
                      Expanded (
                        flex:4,
                        child: Row (
                          children: [
                            Expanded (
                              flex: 1,
                              child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _percentDiscount = _percentDiscount - 0.5;
                                      _percentDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse((_percentDiscount).toString()));
                                    });
                                    // There is a change in the price
                                    _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                    _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                    final double productPriceDiscounted = widget.father.productPrice * (1-(_percentDiscount/100)); // product price minus discount
                                    _discountAmount = widget.productItem.purchased * (widget.father.productPrice * (_percentDiscount/100));
                                    _totalAfterDiscountWithoutTax = _totalBeforeDiscountWithoutTax + _discountAmount;
                                    final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                    _taxAmount = widget.productItem.purchased * taxAmountByProduct;
                                    _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  },
                                  child: Container (
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration (
                                        color: tanteLadenAmber500,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: tanteLadenButtonBorderGray,
                                            width: 1
                                        )
                                    ),
                                    child: Container(
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '-',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w300,
                                            fontSize: 24.0,
                                            fontFamily: 'SF Pro Display',
                                            fontStyle: FontStyle.normal,
                                            color: tanteLadenButtonBorderGray
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            ),
                            Expanded (
                              flex: 2,
                              child: Form(
                                key: _formPercentKey,
                                child: TextFormField(
                                  controller: _percentDiscountTextFieldOnlyForCaseOne,
                                  decoration: const InputDecoration (
                                    prefixText: '  %  ',
                                    prefixStyle: TextStyle (
                                      fontWeight: FontWeight.w700,
                                      fontSize: 24.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.black45,
                                    ),
                                  ),
                                  style: const TextStyle (
                                    fontWeight: FontWeight.w700,
                                    fontSize: 24.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$')),],
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  onEditingComplete: () {
                                    _percentDiscount = double.tryParse (_percentDiscountTextField.text.replaceAll(RegExp(','), '.'))!;
                                    debugPrint('El valor de: _percentDiscount es: $_percentDiscount');
                                  },
                                  validator: (String? value) {
                                    RegExp regexp = RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$');
                                    if (!regexp.hasMatch(value!)) {
                                      return 'Introduce un porcentaje válido. Formato: (+/-)##,##';
                                    } else {
                                      return null;
                                    }
                                  },
                                ),
                              ),
                            ),
                            Expanded (
                              flex: 1,
                              child: TextButton(
                                  onPressed: () {
                                    if (_percentDiscount <= 100) {
                                      setState(() {
                                        _percentDiscount = _percentDiscount + 0.5;
                                        _percentDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse((_percentDiscount).toString()));
                                      });
                                      // There is a change in the price
                                      _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                      _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                      final double productPriceDiscounted = widget.father.productPrice * (1-(_percentDiscount/100)); // product price minus discount
                                      _discountAmount = widget.productItem.purchased * (widget.father.productPrice * (_percentDiscount/100));
                                      _totalAfterDiscountWithoutTax = _totalBeforeDiscountWithoutTax - _discountAmount;
                                      final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                      _taxAmount = widget.productItem.purchased * taxAmountByProduct;
                                      _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                    }
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration(
                                      color: tanteLadenAmber500,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF6C6D77),
                                        width: 1,
                                      ),
                                    ),
                                    child: Container(
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '+',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 24.0,
                                          fontFamily: 'SF Pro Display',
                                          fontStyle: FontStyle.normal,
                                          color: tanteLadenButtonBorderGray,
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded (
                          flex:1,
                          child: Container()
                      )
                    ],
                  ),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: Image.asset (
                          'assets/images/logoComment.png',
                          fit: BoxFit.scaleDown,
                          width: 20.0,
                          height: 20.0,
                        ),
                      ),
                      Container (
                        padding: const EdgeInsets.only(left:8),
                        child: Text.rich(
                            TextSpan (
                                text: 'Introducir comentario',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: tanteLadenIconBrown,
                                    decoration: TextDecoration.underline
                                ),
                                recognizer: TapGestureRecognizer ()
                                  ..onTap = () async {
                                    _comment = await Navigator.push (context, MaterialPageRoute (
                                        builder: (context) => AddComment (_comment)
                                    ));
                                  }
                            )
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container (
                          padding: const EdgeInsets.only(left: 24),
                          child: Checkbox (
                            checkColor: Colors.white,
                            fillColor: MaterialStateProperty.resolveWith(getColor),
                            value: _isOfficial,
                            onChanged: (bool? value) {
                              setState(() {
                                _isOfficial = value!;
                              });
                            },
                          )
                      ),
                      const Text (
                        'Oficializar el nuevo precio.',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14.0,
                          fontFamily: 'SF Pro Display',
                          fontStyle: FontStyle.normal,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ],
                  ),
                  _pleaseWait ? Stack(
                    key: const ObjectKey ("stack"),
                    alignment: AlignmentDirectional.center,
                    children: [
                      tmpBuilder,
                      _pleaseWaitWidget
                    ],
                  ): Stack(
                    key: const ObjectKey("stack"),
                    children: [tmpBuilder],
                  ),
                  //SizedBox(height: 35.0),
                ],
              );
            },
          )
      );
    }
  }
}
class _MediumScreen extends StatefulWidget {
  final PurchaseLine father;
  final ProductAvail productItem;
  final int userId;
  final _StateChanged stateChanged;
  final int partnerId;
  final String userRole;
  const _MediumScreen (this.father, this.productItem, this.userId, this.stateChanged, this.partnerId, this.userRole);
  @override
  _MediumScreenState createState() => _MediumScreenState();
}
class _MediumScreenState extends State<_MediumScreen> {
  // private variables
  int _current = 0; // Var to save the current carousel image
  bool _pleaseWait = false;
  final PleaseWaitWidget _pleaseWaitWidget = const PleaseWaitWidget(key: ObjectKey("pleaseWaitWidget"));
  final TextEditingController _valueDiscountTextField = TextEditingController();
  final TextEditingController _percentDiscountTextField = TextEditingController();
  final TextEditingController _valueDiscountTextFieldOnlyForCaseOne = TextEditingController();  // Use a new text controller only for modifying the price text field of the case 1
  final TextEditingController _percentDiscountTextFieldOnlyForCaseOne = TextEditingController();  // Use a new text controller only for modifying the price text field of the case 1
  final _formPercentKey = GlobalKey<FormState>();
  final _formNewPricekey = GlobalKey<FormState>();
  // fields to save temporal values
  double _valueDiscount = 0.0;
  double _percentDiscount = 0.0;
  double _totalBeforeDiscount = 0.0;
  double _totalBeforeDiscountWithoutTax = 0.0;
  double _discountAmount = 0.0;
  double _totalAfterDiscountWithoutTax = 0.0;
  double _taxAmount = 0.0;
  double _totalAmount = 0.0;
  double _newNumItemsPurchased = 0;  // save the value of the field NEW_QUANTITY of the KRC_PURCHASE table.
  late double _newNewProductPriceFinal;  // save the value of the field NEW_PRODUCT_PRICE_FINAL of the KRC_PURCHASE table.
  late double _newPrice; // save the value of the field PRODUCT_PRICE of the KRC_PURCHASE table.
  PriceChangeType _changeType = PriceChangeType.priceValue;
  bool _isOfficial = false;
  late String _comment;

  _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }
  Color getColor(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
    };
    if (states.any(interactiveStates.contains)) {
      return Colors.blue;
    }
    return Colors.red;
  }
  void _valueDiscountTextFieldProcessor () {
    debugPrint ('Estoy en el listener _valueDiscountTextFieldProcessor');
    if (widget.father.newProductPrice != -1) {
      debugPrint ('Estoy en el _newNewProductPriceFinal != -1');
      // the price has been previously modified
      if (widget.father.newQuantity != -1) {
        _valueDiscount = double.tryParse (_valueDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Estoy en el listener. El valor de _valueDiscount es: $_valueDiscount');
        //_valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('Valor de _valueDiscountTextField.text: ${_valueDiscountTextField.text}');
        _totalBeforeDiscountWithoutTax = widget.father.newQuantity * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.father.newQuantity * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.newProductPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = widget.father.newQuantity * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.father.newQuantity * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.father.newQuantity * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        _valueDiscount = double.tryParse (_valueDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Estoy en el listener. El valor de _valueDiscount es: $_valueDiscount');
        //_valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('Valor de _valueDiscountTextField.text: ${_valueDiscountTextField.text}');
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.newProductPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    } else {
      // the price has not yet modified
      debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
      if (widget.father.newQuantity != -1) {
        _valueDiscount = double.tryParse (_valueDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        //_valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
        _totalBeforeDiscountWithoutTax = widget.father.newQuantity * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.father.newQuantity * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_valueDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = widget.father.newQuantity * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.father.newQuantity * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.father.newQuantity * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        _valueDiscount = double.tryParse (_valueDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        //_valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_valueDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    }
  }
  void _percentDiscountTextFieldProcessor() {
    debugPrint ('Estoy en el listener _percentDiscountTextFieldProcessor');
    if (widget.father.newProductPrice != -1) {
      debugPrint ('Estoy en el _newNewProductPriceFinal != -1');
      if (widget.father.newQuantity != -1) {
        debugPrint ('Valor de _percentDiscountTextField.text: ${_percentDiscountTextField.text}');
        // the price has been previously modified
        _percentDiscount = double.tryParse (_percentDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('El valor de _percentDiscount es: $_valueDiscount');
        _totalBeforeDiscountWithoutTax = widget.father.newQuantity * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.father.newQuantity * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.newProductPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = widget.father.newQuantity * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.father.newQuantity * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.father.newQuantity * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        debugPrint ('Valor de _percentDiscountTextField.text: ${_percentDiscountTextField.text}');
        // the price has been previously modified
        _percentDiscount = double.tryParse (_percentDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('El valor de _percentDiscount es: $_valueDiscount');
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.newProductPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    } else {
      // the price has not yet modified
      debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
      if (widget.father.newQuantity != -1) {
        _percentDiscount = double.tryParse (_percentDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Valor de _percentDiscountTextField.text: ${_percentDiscountTextField.text}');
        _totalBeforeDiscountWithoutTax = widget.father.newQuantity * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.father.newQuantity * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.productPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_percentDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = widget.father.newQuantity * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.father.newQuantity * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.father.newQuantity * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        _percentDiscount = double.tryParse (_percentDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Valor de _percentDiscountTextField.text: ${_percentDiscountTextField.text}');
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.productPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_percentDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    }
  }
  void _valueDiscountTextFieldForCaseOneProcessor() {
    // Use a new and different listener for the case 1 (Price and Amount modified)
    debugPrint ('Estoy en el listener _valueDiscountTextFieldForCaseOneProcessor');
    if (widget.father.newProductPrice != -1) {
      if (widget.father.newQuantity != -1) {
        debugPrint ('Estoy en el _newNewProductPriceFinal != -1');
        // the price has been previously modified
        _valueDiscount = double.tryParse (_valueDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Estoy en el listener. El valor de _valueDiscount es: $_valueDiscount');
        //_valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('Valor de _valueDiscountTextFieldOnlyForCaseOne.text: ${_valueDiscountTextFieldOnlyForCaseOne.text}');
        _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.newProductPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        debugPrint ('Estoy en el _newNewProductPriceFinal != -1');
        // the price has been previously modified
        _valueDiscount = double.tryParse (_valueDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Estoy en el listener. El valor de _valueDiscount es: $_valueDiscount');
        //_valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('Valor de _valueDiscountTextFieldOnlyForCaseOne.text: ${_valueDiscountTextFieldOnlyForCaseOne.text}');
        //_totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.newProductPrice;
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.newProductPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    } else {
      // the price has not yet modified
      debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
      if (widget.father.newQuantity != -1) {
        _valueDiscount = double.tryParse (_valueDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        //_valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
        _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice*(1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_valueDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        _valueDiscount = double.tryParse (_valueDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        //_valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_valueDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    }
  }
  void _percentDiscountTextFieldForCaseOneProcessor() {
    // Use a new and different listener for the case 1 (Price and Amount modified)
    debugPrint ('Estoy en el listener _percentDiscountTextFieldForCaseOneProcessor.');
    if (widget.father.newProductPrice != -1) {
      if (widget.father.newQuantity != -1) {
        debugPrint ('Estoy en el _newNewProductPriceFinal != -1');
        debugPrint ('Valor de _percentDiscountTextFieldOnlyForCaseOne.text: ${_percentDiscountTextFieldOnlyForCaseOne.text}');
        // the price has been previously modified
        _percentDiscount = double.tryParse (_percentDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('El valor de _percentDiscount es: $_valueDiscount');
        _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        //_totalBeforeDiscount = _newNumItemsPurchased * (widget.father.newProductPrice * (1+widget.productItem.taxApply/100));
        _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.newProductPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        //_discountAmount = _newNumItemsPurchased * (_newNewProductPriceFinal * (_percentDiscount/100));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        //_totalAfterDiscountWithoutTax = _totalBeforeDiscountWithoutTax + _discountAmount;
        _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        debugPrint ('Estoy en el _newNewProductPriceFinal != -1');
        debugPrint ('Valor de _percentDiscountTextFieldOnlyForCaseOne.text: ${_percentDiscountTextFieldOnlyForCaseOne.text}');
        // the price has been previously modified
        _percentDiscount = double.tryParse (_percentDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('El valor de _percentDiscount es: $_percentDiscount');
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.newProductPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    } else {
      // the price has not yet modified
      if (widget.father.newQuantity != -1) {
        debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
        _percentDiscount = double.tryParse (_percentDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Valor de _percentDiscountTextField.text: ${_percentDiscountTextFieldOnlyForCaseOne.text}');
        _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.productPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_percentDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
        _percentDiscount = double.tryParse (_percentDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Valor de _percentDiscountTextFieldOnlyForCaseOne.text: ${_percentDiscountTextFieldOnlyForCaseOne.text}');
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.productPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_percentDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    }
  }
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES');
    _current = 0;
    _changeType = PriceChangeType.priceValue;
    _isOfficial = false;
    // fields to save temporal values
    widget.productItem.purchased = widget.father.items;
    _newNumItemsPurchased = widget.father.newQuantity;
    _totalBeforeDiscountWithoutTax = widget.father.totalBeforeDiscountWithoutTax;
    _valueDiscount = 0.0;
    _valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
    _valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
    _percentDiscount = 0.0;
    _newNewProductPriceFinal = widget.father.newProductPrice;
    _newPrice = widget.father.productPrice;
    debugPrint ('El valor de _newNewProductPriceFinal es: $_newNewProductPriceFinal');
    _percentDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
    _percentDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
    _totalBeforeDiscountWithoutTax = widget.father.totalBeforeDiscountWithoutTax;
    _totalBeforeDiscount = widget.productItem.totalBeforeDiscount;
    _discountAmount = widget.father.discountAmount;
    _totalAfterDiscountWithoutTax = widget.father.totalAfterDiscountWithoutTax;
    _taxAmount = widget.father.taxAmount;
    _totalAmount = widget.father.totalAmount;
    if (widget.userRole == 'BUYER') {
      _comment = widget.father.remarkBuyer;
    } else {
      _comment = widget.father.remarkSeller;
    }
    _valueDiscountTextField.addListener (_valueDiscountTextFieldProcessor);
    _percentDiscountTextField.addListener (_percentDiscountTextFieldProcessor);
    _valueDiscountTextFieldOnlyForCaseOne.addListener(_valueDiscountTextFieldForCaseOneProcessor);  // Use a new and different listener for the case 1 (Price and Amount modified)
    _percentDiscountTextFieldOnlyForCaseOne.addListener(_percentDiscountTextFieldForCaseOneProcessor);  // Use a new and different listener for the case 1 (Price and Amount modified)
  }
  @override
  void dispose() {
    _valueDiscountTextField.dispose();
    _percentDiscountTextField.dispose();
    _valueDiscountTextFieldOnlyForCaseOne.dispose();
    _percentDiscountTextFieldOnlyForCaseOne.dispose();
    super.dispose();
  }
  @override
  Widget build (BuildContext context) {
    debugPrint('El productId es: ${widget.productItem.productId}');
    Widget tmpBuilder = Container (
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GestureDetector (
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
                  'Modificar pedido',
                  style: TextStyle(
                      fontSize: 24.0,
                      color: tanteLadenBackgroundWhite
                  ),
                ),
              ),
              onTap: () async {
                try {
                  debugPrint ('Comienzo la modificación del pedido');
                  _showPleaseWait(true);
                  // Detect if the amount purchased has changed
                  if (widget.father.banQuantity == "SI" && widget.father.banPrice == "SI") {
                    // Case 1
                    // The price and the quantity of the purchased has been changed by the user
                    if (_valueDiscount != 0 || _percentDiscount != 0
                        || _newNumItemsPurchased != widget.father.newProductPrice
                        || widget.productItem.purchased != widget.father.items) {
                      // There is a modification
                      debugPrint('Entro en el caso 1.');
                      debugPrint('El valor de _valueDiscountTextField es: ${_valueDiscountTextField.text}');
                      debugPrint('El valor de _percentDiscountTextField es: ${_percentDiscountTextField.text}');
                      final Uri url = Uri.parse('$SERVER_IP/modifyPurchaseLine/${widget.father.orderId}/${widget.father.providerName}');
                      debugPrint ("La URL es: $url");
                      final http.Response res = await http.put (
                          url,
                          headers: <String, String>{
                            'Content-Type': 'application/json; charset=UTF-8',
                            //'Authorization': jwt
                          },
                          body: jsonEncode (<String, String> {
                            'product_id': widget.father.productId.toString(),
                            'user_id': widget.userId.toString(),
                            'user_role': widget.userRole.toString(),
                            //'new_purchased': _newNumItemsPurchased != -1 ? _newNumItemsPurchased.toString() : widget.productItem.purchased.toString(),
                            'new_purchased': _newNumItemsPurchased != -1 ? _newNumItemsPurchased.toString() : (widget.productItem.purchased != widget.father.items ? widget.productItem.purchased.toString() : null)!,
                            'new_product_price': (_newNewProductPriceFinal != -1 ? _newNewProductPriceFinal.toString() : null)!,
                            'total_before_discount': _totalBeforeDiscount.toString(),
                            'total_amount': _totalAmount.toString(),
                            'discount_amount': _discountAmount.toString(),
                            'tax_amount': _taxAmount.toString(),
                            'is_official': _isOfficial.toString(),
                            'case_to_apply': '1',  // Case 1. he price and the quantity of the purchased has been changed
                            'comment': _comment
                          })
                      );
                      _showPleaseWait(false);
                      if (res.statusCode == 200) {
                        // Process the order
                        debugPrint ('OK. ');
                        final List<Map<String, dynamic>> resultListJson = json.decode(res.body)['statusToTransitionTo'].cast<Map<String, dynamic>>();
                        debugPrint ('Entre medias de la api RESPONSE.');
                        final List<PurchaseStatus> resultListPurchaseStatusToTransitionTo = resultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                        if (resultListPurchaseStatusToTransitionTo.isNotEmpty) {
                          widget.father.possibleStatusToTransitionTo.clear();
                          for (var element in resultListPurchaseStatusToTransitionTo) {
                            debugPrint ('El valor de statusName es: ${element.statusName}');
                            debugPrint ('El valor de BAN_PRICE es: ${element.banPrice}');
                            debugPrint ('El valor de BAN_QUANTITY es: ${element.banQuantity}');
                            widget.father.possibleStatusToTransitionTo.add(element);
                          }
                        }
                        debugPrint ('Despues de retornar los statusToTransitionTo.');
                        // get the values of BAN_PRICE and BAN_QUANTITY among the new state of the modified purchased line, "O" (OBSERVACIONES)
                        final List<Map<String, dynamic>> anotherResultListJson = json.decode(res.body)['currentBanQuantityBanPrice'].cast<Map<String, dynamic>>();
                        debugPrint ('Entre medias de la api RESPONSE.');
                        final List<PurchaseStatus> currentBanPriceBanStatusValues = anotherResultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                        if (currentBanPriceBanStatusValues.isNotEmpty) {
                          widget.father.banQuantity = currentBanPriceBanStatusValues[0].banQuantity;
                          widget.father.banPrice = currentBanPriceBanStatusValues[0].banPrice;
                        }
                        debugPrint ('Despues de retornar los currentBanPriceBanStatusValues.');
                        widget.stateChanged.changed = true;
                        widget.father.newQuantity = _newNumItemsPurchased != -1 ? _newNumItemsPurchased : (widget.productItem.purchased != widget.father.items ? widget.productItem.purchased : -1);
                        widget.father.newProductPrice = _newNewProductPriceFinal != -1 ? _newNewProductPriceFinal : widget.father.newProductPrice;
                        debugPrint ('El valor de widget.father.newProductPrice es: ${widget.father.newProductPrice}');
                        widget.father.totalBeforeDiscountWithoutTax = _totalBeforeDiscountWithoutTax;
                        widget.father.discountAmount = _discountAmount;
                        widget.father.totalAfterDiscountWithoutTax = _totalAfterDiscountWithoutTax;
                        widget.father.taxAmount = _taxAmount;
                        widget.father.totalAmount = _totalAmount;
                        if (widget.userRole == 'BUYER') {
                          widget.father.remarkBuyer = _comment;
                        } else {
                          widget.father.remarkSeller = _comment;
                        }
                        widget.father.statusId = "O";
                        widget.father.allStatus = "OBSERVACIONES";
                        if (!context.mounted) return;
                        Navigator.pop(context, widget.stateChanged.changed);
                      } else {
                        // Error
                        widget.stateChanged.changed = false;
                        if (!context.mounted) return;
                        ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'].toString());
                      }
                    }
                  } else if (widget.father.banQuantity == "NO" && widget.father.banPrice == "SI") {
                    // Case 2
                    // Only the price of the purchased has been changed by the user
                    debugPrint('Entro en el caso 2.');
                    final Uri url = Uri.parse('$SERVER_IP/modifyPurchaseLine/${widget.father.orderId}/${widget.father.providerName}');
                    debugPrint ("La URL es: $url");
                    final http.Response res = await http.put (
                        url,
                        headers: <String, String>{
                          'Content-Type': 'application/json; charset=UTF-8',
                          //'Authorization': jwt
                        },
                        body: jsonEncode (<String, String> {
                          'product_id': widget.father.productId.toString(),
                          'user_id': widget.userId.toString(),
                          'user_role': widget.userRole.toString(),
                          'new_product_price': _newNewProductPriceFinal.toString(),
                          'total_before_discount': _totalBeforeDiscount.toString(),
                          'total_amount': _totalAmount.toString(),
                          'discount_amount': _discountAmount.toString(),
                          'tax_amount': _taxAmount.toString(),
                          'is_official': _isOfficial.toString(),
                          'case_to_apply': '2',  // Only the price of the purchased has been changed by the user
                          'comment': _comment
                        })
                    );
                    _showPleaseWait(false);
                    if (res.statusCode == 200) {
                      // Process the order
                      debugPrint ('OK. ');
                      // get the list of new states to tansition to
                      final List<Map<String, dynamic>> resultListJson = json.decode(res.body)['statusToTransitionTo'].cast<Map<String, dynamic>>();
                      debugPrint ('Entre medias de la api RESPONSE.');
                      final List<PurchaseStatus> resultListPurchaseStatusToTransitionTo = resultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                      if (resultListPurchaseStatusToTransitionTo.isNotEmpty) {
                        widget.father.possibleStatusToTransitionTo.clear();
                        for (var element in resultListPurchaseStatusToTransitionTo) {
                          widget.father.possibleStatusToTransitionTo.add(element);
                        }
                      }
                      debugPrint ('Despues de retornar los statusToTransitionTo.');
                      // get the values of BAN_PRICE and BAN_QUANTITY among the new state of the modified purchased line, "O" (OBSERVACIONES)
                      final List<Map<String, dynamic>> anotherResultListJson = json.decode(res.body)['currentBanQuantityBanPrice'].cast<Map<String, dynamic>>();
                      debugPrint ('Entre medias de la api RESPONSE.');
                      final List<PurchaseStatus> currentBanPriceBanStatusValues = anotherResultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                      if (currentBanPriceBanStatusValues.isNotEmpty) {
                        widget.father.banQuantity = currentBanPriceBanStatusValues[0].banQuantity;
                        widget.father.banPrice = currentBanPriceBanStatusValues[0].banPrice;
                      }
                      debugPrint ('Despues de retornar los currentBanPriceBanStatusValues.');
                      widget.stateChanged.changed = true;
                      widget.father.totalBeforeDiscountWithoutTax = _totalBeforeDiscountWithoutTax;
                      widget.father.discountAmount = _discountAmount;
                      widget.father.newProductPrice = _newNewProductPriceFinal != -1 ? _newNewProductPriceFinal : widget.father.newProductPrice;
                      debugPrint ('El valor de widget.father.newProductPrice es: ${widget.father.newProductPrice}');
                      widget.father.totalAfterDiscountWithoutTax = _totalAfterDiscountWithoutTax;
                      widget.father.taxAmount = _taxAmount;
                      widget.father.totalAmount = _totalAmount;
                      if (widget.userRole == 'BUYER') {
                        widget.father.remarkBuyer = _comment;
                      } else {
                        widget.father.remarkSeller = _comment;
                      }
                      widget.father.statusId = "O";
                      widget.father.allStatus = "OBSERVACIONES";
                      if (!context.mounted) return;
                      Navigator.pop(context, widget.stateChanged.changed);
                    } else {
                      // Error
                      widget.stateChanged.changed = false;
                      if (!context.mounted) return;
                      ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'].toString());
                    }
                  } else if (widget.father.banQuantity == "SI" && widget.father.banPrice == "NO") {
                    // Case 3
                    // Only the quantity has been changed by the user
                    if (_newNumItemsPurchased != -1) {
                      // the quantity of the purchase line has been changed.
                      // The value -1 is the value if the field NEW_QUANTITY of the KRC_PURCHASE is null,
                      // then it has been not yet modified
                      if (_newNumItemsPurchased != widget.father.newQuantity) {
                        // the quantity of the purchase line has been modified
                        debugPrint ('Entro en el paso 3.');
                        final Uri url = Uri.parse('$SERVER_IP/modifyPurchaseLine/${widget.father.orderId}/${widget.father.providerName}');
                        debugPrint ("La URL es: $url");
                        final http.Response res = await http.put (
                            url,
                            headers: <String, String>{
                              'Content-Type': 'application/json; charset=UTF-8',
                              //'Authorization': jwt
                            },
                            body: jsonEncode (<String, String> {
                              'product_id': widget.father.productId.toString(),
                              'user_id': widget.userId.toString(),
                              'user_role': widget.userRole.toString(),
                              'new_purchased': _newNumItemsPurchased.toString(),
                              'total_before_discount': _totalBeforeDiscount.toString(),
                              'total_amount': _totalAmount.toString(),
                              'discount_amount': _discountAmount.toString(),
                              'tax_amount': _taxAmount.toString(),
                              'case_to_apply': '3', // Only the quantity has been changed by the user
                              'comment': _comment
                            })
                        );
                        _showPleaseWait(false);
                        if (res.statusCode == 200) {
                          // Process the order
                          debugPrint ('OK. ');
                          final List<Map<String, dynamic>> resultListJson = json.decode(res.body)['statusToTransitionTo'].cast<Map<String, dynamic>>();
                          debugPrint ('Entre medias de la api RESPONSE.');
                          final List<PurchaseStatus> resultListPurchaseStatusToTransitionTo = resultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                          if (resultListPurchaseStatusToTransitionTo.isNotEmpty) {
                            widget.father.possibleStatusToTransitionTo.clear();
                            for (var element in resultListPurchaseStatusToTransitionTo) {
                              widget.father.possibleStatusToTransitionTo.add(element);
                            }
                          }
                          debugPrint ('Despues de retornar los statusToTransitionTo.');
                          // get the values of BAN_PRICE and BAN_QUANTITY among the new state of the modified purchased line, "O" (OBSERVACIONES)
                          final List<Map<String, dynamic>> anotherResultListJson = json.decode(res.body)['currentBanQuantityBanPrice'].cast<Map<String, dynamic>>();
                          debugPrint ('Entre medias de la api RESPONSE.');
                          final List<PurchaseStatus> currentBanPriceBanStatusValues = anotherResultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                          if (currentBanPriceBanStatusValues.isNotEmpty) {
                            widget.father.banQuantity = currentBanPriceBanStatusValues[0].banQuantity;
                            widget.father.banPrice = currentBanPriceBanStatusValues[0].banPrice;
                          }
                          debugPrint ('Despues de retornar los currentBanPriceBanStatusValues.');
                          widget.stateChanged.changed = true;
                          //widget.father.items = widget.productItem.purchased;
                          widget.father.newQuantity = _newNumItemsPurchased;
                          debugPrint ("El valor de widget.father.newQuantity es: ${widget.father.newQuantity}");
                          widget.father.totalBeforeDiscountWithoutTax = _totalBeforeDiscountWithoutTax;
                          widget.father.discountAmount = _discountAmount;
                          widget.father.totalAfterDiscountWithoutTax = _totalAfterDiscountWithoutTax;
                          widget.father.taxAmount = _taxAmount;
                          widget.father.totalAmount = _totalAmount;
                          if (widget.userRole == 'BUYER') {
                            widget.father.remarkBuyer = _comment;
                          } else {
                            widget.father.remarkSeller = _comment;
                          }
                          widget.father.statusId = "O";
                          widget.father.allStatus = "OBSERVACIONES";
                          if (!context.mounted) return;
                          Navigator.pop(context, widget.stateChanged.changed);
                        } else {
                          // Error
                          widget.stateChanged.changed = false;
                          if (!context.mounted) return;
                          ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'].toString());
                        }
                      } else {
                        // Finally the quantity of the purchase line has not been changed.
                        widget.stateChanged.changed = false;
                        Navigator.pop(context, widget.stateChanged.changed);
                      }
                    } else {
                      // the quantity of the purchase line has not yet been changed.
                      if (widget.father.items != widget.productItem.purchased) {
                        // The quantity has been modified by the user
                        debugPrint ('Entro en el paso 3.');
                        final Uri url = Uri.parse('$SERVER_IP/modifyPurchaseLine/${widget.father.orderId}/${widget.father.providerName}');
                        debugPrint ("La URL es: $url");
                        final http.Response res = await http.put (
                            url,
                            headers: <String, String>{
                              'Content-Type': 'application/json; charset=UTF-8',
                              //'Authorization': jwt
                            },
                            body: jsonEncode (<String, String> {
                              'product_id': widget.father.productId.toString(),
                              'user_id': widget.userId.toString(),
                              'user_role': widget.userRole.toString(),
                              'new_purchased': (widget.productItem.purchased != widget.father.items ? widget.productItem.purchased.toString() : null)!,
                              'total_before_discount': _totalBeforeDiscount.toString(),
                              'total_amount': _totalAmount.toString(),
                              'discount_amount': _discountAmount.toString(),
                              'tax_amount': _taxAmount.toString(),
                              'case_to_apply': '3', // Only the quantity has been changed by the user
                              'comment': _comment
                            })
                        );
                        _showPleaseWait(false);
                        if (res.statusCode == 200) {
                          // Process the order
                          debugPrint ('OK. ');
                          final List<Map<String, dynamic>> resultListJson = json.decode(res.body)['statusToTransitionTo'].cast<Map<String, dynamic>>();
                          debugPrint ('Entre medias de la api RESPONSE.');
                          final List<PurchaseStatus> resultListPurchaseStatusToTransitionTo = resultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                          if (resultListPurchaseStatusToTransitionTo.isNotEmpty) {
                            widget.father.possibleStatusToTransitionTo.clear();
                            for (var element in resultListPurchaseStatusToTransitionTo) {
                              widget.father.possibleStatusToTransitionTo.add(element);
                            }
                          }
                          debugPrint ('Despues de retornar los statusToTransitionTo.');
                          // get the values of BAN_PRICE and BAN_QUANTITY among the new state of the modified purchased line, "O" (OBSERVACIONES)
                          final List<Map<String, dynamic>> anotherResultListJson = json.decode(res.body)['currentBanQuantityBanPrice'].cast<Map<String, dynamic>>();
                          debugPrint ('Entre medias de la api RESPONSE.');
                          final List<PurchaseStatus> currentBanPriceBanStatusValues = anotherResultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                          if (currentBanPriceBanStatusValues.isNotEmpty) {
                            widget.father.banQuantity = currentBanPriceBanStatusValues[0].banQuantity;
                            widget.father.banPrice = currentBanPriceBanStatusValues[0].banPrice;
                          }
                          debugPrint ('Despues de retornar los currentBanPriceBanStatusValues.');
                          widget.stateChanged.changed = true;
                          widget.father.newQuantity = widget.productItem.purchased != widget.father.items ? widget.productItem.purchased : -1;
                          debugPrint ("El valor de widget.father.newQuantity es: ${widget.father.newQuantity}");
                          widget.father.totalBeforeDiscountWithoutTax = _totalBeforeDiscountWithoutTax;
                          widget.father.discountAmount = _discountAmount;
                          widget.father.totalAfterDiscountWithoutTax = _totalAfterDiscountWithoutTax;
                          widget.father.taxAmount = _taxAmount;
                          widget.father.totalAmount = _totalAmount;
                          if (widget.userRole == 'BUYER') {
                            widget.father.remarkBuyer = _comment;
                          } else {
                            widget.father.remarkSeller = _comment;
                          }
                          widget.father.statusId = "O";
                          widget.father.allStatus = "OBSERVACIONES";
                          if (!context.mounted) return;
                          Navigator.pop(context, widget.stateChanged.changed);
                        } else {
                          // Error
                          widget.stateChanged.changed = false;
                          if (!context.mounted) return;
                          ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'].toString());
                        }
                      } else {
                        // Finally the quantity of the purchase line has not been changed.
                        widget.stateChanged.changed = false;
                        Navigator.pop(context, widget.stateChanged.changed);
                      }
                    }
                  } else {
                    // Case 4
                    // There is no change by the user
                    debugPrint ('Entro en el paso 4');
                    widget.stateChanged.changed = false;
                    Navigator.pop(context, widget.stateChanged.changed);
                  }
                } catch (e) {
                  _showPleaseWait(false);
                  widget.stateChanged.changed = false;
                  if (!context.mounted) return;
                  ShowSnackBar.showSnackBar(context, e.toString(), error: true);
                }
              },
            ),
          ],
        )
    );
    if (widget.father.banQuantity == "SI" && widget.father.banPrice == "NO") {
      // Case 3
      // Only the quantity has been changed by the user
      return SafeArea (
          child: LayoutBuilder(
            builder: (context, constraints) {
              final List<String> listImagesProduct = [];
              for (var i = 0; i < widget.productItem.numImages; i++){
                listImagesProduct.add('$SERVER_IP$IMAGES_DIRECTORY${widget.productItem.productCode}_$i.gif');
              }
              return ListView (
                children: [
                  widget.productItem.numImages > 1 ? Column (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CarouselSlider (
                        items: listImagesProduct.map((url) => AspectRatio (
                          aspectRatio: 3.0 / 2.0,
                          child: CachedNetworkImage(
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            imageUrl: url,
                            fit: BoxFit.scaleDown,
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        )
                        ).toList(),
                        options: CarouselOptions(
                            autoPlay: true,
                            enlargeCenterPage: true,
                            aspectRatio: 2.0,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _current = index;
                              });
                            }
                        ),
                      ),
                      Row (
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: listImagesProduct.map((url) {
                          int index = listImagesProduct.indexOf(url);
                          return Container(
                            width: 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _current == index
                                    ? const Color.fromRGBO(0, 0, 0, 0.9)
                                    : const Color.fromRGBO(0, 0, 0, 0.4)
                            ),
                          );
                        }).toList(),
                      )
                    ],
                  ) : Container(
                    alignment: Alignment.center,
                    width: constraints.maxWidth,
                    child: AspectRatio(
                      aspectRatio: 3.0 / 2.0,
                      child: CachedNetworkImage(
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        imageUrl: '$SERVER_IP$IMAGES_DIRECTORY${widget.productItem.productCode}_0.gif',
                        fit: BoxFit.scaleDown,
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    ),
                  ),
                  SizedBox (height: constraints.maxHeight * HeightInDpis_2),
                  Padding (
                    padding: const EdgeInsets.fromLTRB (15.0, 0.0, 15.0, 0.0),
                    child: Row (
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                          child: Image.asset ('assets/images/00002.png'),
                        ),
                        Padding (
                          padding: const EdgeInsets.only(right: 15.0),
                          child: widget.father.newProductPrice != -1 ? Text.rich (
                              TextSpan (
                                  text: NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.father.newProductPrice/MULTIPLYING_FACTOR).toString())),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 40.0,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                  children: <TextSpan>[
                                    TextSpan (
                                        text: '${' (${NumberFormat("##0.00", "es_ES").format(double.parse((widget.father.productPrice/MULTIPLYING_FACTOR).toString()))}'})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 30.0,
                                          fontFamily: 'SF Pro Display',
                                        )
                                    ),
                                  ]
                              )
                          ) : Text(
                              NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.father.productPrice/MULTIPLYING_FACTOR).toString())),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 40.0,
                                fontFamily: 'SF Pro Display',
                              ),
                              textAlign: TextAlign.start
                          ),
                        ),
                      ],
                    ),
                  ),
                  //SizedBox(height: 4.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_4),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        width: constraints.maxWidth,
                        child: Text(
                          widget.productItem.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      )
                    ],
                  ),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container (
                        padding: const EdgeInsets.only(left: 24.0),
                        width: constraints.maxWidth,
                        child: Text(
                          widget.productItem.businessName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 24.0,
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
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container (
                        padding: const EdgeInsets.only(left: 24),
                        child: Text(
                          'Unids. mínim. venta: ${widget.productItem.minQuantitySell} ${(widget.productItem.minQuantitySell > 1) ? '${widget.productItem.idUnit}s.' : '${widget.productItem.idUnit}.'}',
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
                      ),
                    ],
                  ),
                  SizedBox (height: constraints.maxHeight * HeightInDpis_35),
                  const Center (
                    child: Text (
                      'Cantidad',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Color(0xFF6C6D77),
                      ),
                    ),
                  ),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton (
                          onPressed: () {
                            if (_newNumItemsPurchased != -1) {
                              // the quantity of the purchase line has been changed.
                              // The value -1 is the value when the field NEW_QUANTITY of the KRC_PURCHASE is null,
                              // then it has been not yet modified
                              if (widget.father.newProductPrice != -1) {
                                if (_newNumItemsPurchased > 0) {
                                  setState (() {
                                    _newNumItemsPurchased = _newNumItemsPurchased - widget.productItem.minQuantitySell;
                                    if (_newNumItemsPurchased < 0) _newNumItemsPurchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = _newNumItemsPurchased * (_newNewProductPriceFinal * (widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              } else {
                                if (_newNumItemsPurchased > 0) {
                                  setState (() {
                                    _newNumItemsPurchased = _newNumItemsPurchased - widget.productItem.minQuantitySell;
                                    if (_newNumItemsPurchased < 0) _newNumItemsPurchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                  //_totalBeforeDiscountWithoutTax = _newNumItemsPurchased * (widget.father.totalBeforeDiscountWithoutTax / widget.father.items);
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice*(1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  //_discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  _discountAmount = 0;  // If widget.father.newProductPrice means that there si no discount
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = _newNumItemsPurchased * (widget.father.productPrice*(widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              }
                            } else {
                              // the quantity of the purchase line has not yet been changed.
                              if (widget.father.newProductPrice != -1) {
                                if (widget.productItem.purchased > 0) {
                                  setState (() {
                                    widget.productItem.purchased = widget.productItem.purchased - widget.productItem.minQuantitySell;
                                    if (widget.productItem.purchased < 0) widget.productItem.purchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = widget.productItem.purchased * (_newNewProductPriceFinal * (widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              } else {
                                if (widget.productItem.purchased > 0) {
                                  setState (() {
                                    widget.productItem.purchased = widget.productItem.purchased - widget.productItem.minQuantitySell;
                                    if (widget.productItem.purchased < 0) widget.productItem.purchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  //_discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  _discountAmount = 0;  // If widget.father.newProductPrice means that there si no discount
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = widget.productItem.purchased * (widget.father.productPrice*(widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              }
                            }
                          },
                          child: Container (
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(2.0),
                            decoration: BoxDecoration (
                                color: tanteLadenAmber500,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: tanteLadenButtonBorderGray,
                                    width: 1
                                )
                            ),
                            child: Container(
                              width: 40.0,
                              height: 40.0,
                              alignment: Alignment.center,
                              child: const Text(
                                '-',
                                style: TextStyle(
                                    fontWeight: FontWeight.w300,
                                    fontSize: 24.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: tanteLadenButtonBorderGray
                                ),
                              ),
                            ),
                          )
                      ),
                      Padding (
                        //padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                        padding: const EdgeInsets.only(left: WithInDpis_20, right: WithInDpis_20),
                        child: RichText (
                            text: TextSpan (
                                text: widget.father.newQuantity != -1
                                    ? '$_newNumItemsPurchased (${widget.productItem.purchased}) '
                                    : widget.productItem.purchased.toString(),
                                style: const TextStyle (
                                  fontWeight: FontWeight.w700,
                                  fontSize: 24.0,
                                  fontFamily: 'SF Pro Display',
                                  fontStyle: FontStyle.normal,
                                  color: Colors.black,
                                ),
                                children: <TextSpan>[
                                  TextSpan (
                                      text: widget.father.newQuantity != -1
                                          ? _newNumItemsPurchased > 1 ? ' ${widget.productItem.idUnit}s.' : ' ${widget.productItem.idUnit}.'
                                          : widget.productItem.purchased > 1 ? ' ${widget.productItem.idUnit}s.' : ' ${widget.productItem.idUnit}.',
                                      style: const TextStyle (
                                          fontWeight: FontWeight.bold
                                      )
                                  )
                                ]
                            )
                        ),
                      ),
                      TextButton(
                          onPressed: () {
                            if (_newNumItemsPurchased != -1) {
                              // the quantity of the purchase line has been changed.
                              // The value -1 is the value when the field NEW_QUANTITY of the KRC_PURCHASE is null,
                              // then it has been not yet modified
                              if(widget.father.newProductPrice != -1) {
                                if (_newNumItemsPurchased > 0) {
                                  setState (() {
                                    _newNumItemsPurchased = _newNumItemsPurchased + widget.productItem.minQuantitySell;
                                  });
                                  _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = _newNumItemsPurchased * (_newNewProductPriceFinal * (widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              } else {
                                if (_newNumItemsPurchased > 0) {
                                  setState (() {
                                    _newNumItemsPurchased = _newNumItemsPurchased + widget.productItem.minQuantitySell;
                                  });
                                  _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                  //_totalBeforeDiscountWithoutTax = _newNumItemsPurchased * (widget.father.totalBeforeDiscountWithoutTax / widget.father.items);
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice*(1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  _discountAmount = 0;  // If widget.father.newProductPrice means that there si no discount
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = _newNumItemsPurchased * (widget.father.productPrice*(widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              }
                            } else {
                              // the quantity of the purchase line has not yet been changed.
                              if (widget.father.newProductPrice != -1) {
                                if (widget.productItem.purchased > 0) {
                                  setState (() {
                                    widget.productItem.purchased = widget.productItem.purchased + widget.productItem.minQuantitySell;
                                  });
                                  _totalBeforeDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = widget.productItem.purchased * (_newNewProductPriceFinal * (widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              } else {
                                if (widget.productItem.purchased > 0) {
                                  setState (() {
                                    widget.productItem.purchased = widget.productItem.purchased + widget.productItem.minQuantitySell;
                                  });
                                  _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice*(1+(widget.productItem.taxApply/100)));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  _discountAmount = 0;  // If widget.father.newProductPrice means that there si no discount
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = widget.productItem.purchased * (widget.father.productPrice*(widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              }
                            }
                          },
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(2.0),
                            decoration: BoxDecoration(
                              color: tanteLadenAmber500,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF6C6D77),
                                width: 1,
                              ),
                            ),
                            child: Container(
                              width: 40.0,
                              height: 40.0,
                              alignment: Alignment.center,
                              child: const Text(
                                '+',
                                style: TextStyle(
                                  fontWeight: FontWeight.w300,
                                  fontSize: 24.0,
                                  fontFamily: 'SF Pro Display',
                                  fontStyle: FontStyle.normal,
                                  color: tanteLadenButtonBorderGray,
                                ),
                              ),
                            ),
                          )
                      )
                    ],
                  ),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: Image.asset (
                          'assets/images/logoComment.png',
                          fit: BoxFit.scaleDown,
                          width: 20.0,
                          height: 20.0,
                        ),
                      ),
                      Container (
                        padding: const EdgeInsets.only(left:8),
                        child: Text.rich(
                            TextSpan (
                                text: 'Introducir comentario',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: tanteLadenIconBrown,
                                    decoration: TextDecoration.underline
                                ),
                                recognizer: TapGestureRecognizer ()
                                  ..onTap = () async {
                                    _comment = await Navigator.push (context, MaterialPageRoute (
                                        builder: (context) => AddComment (_comment)
                                    ));
                                  }
                            )
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  _pleaseWait ? Stack(
                    key: const ObjectKey ("stack"),
                    alignment: AlignmentDirectional.center,
                    children: [
                      tmpBuilder,
                      _pleaseWaitWidget
                    ],
                  ): Stack(
                    key: const ObjectKey("stack"),
                    children: [tmpBuilder],
                  ),
                  //SizedBox(height: 35.0),
                ],
              );
            },
          )
      );
    } else if (widget.father.banQuantity == "NO" && widget.father.banPrice == "SI") {
      // Case 2
      // Only the price of the purchased has been changed by the user
      return SafeArea (
          child: LayoutBuilder (
            builder: (context, constraints) {
              final List<String> listImagesProduct = [];
              for (var i = 0; i < widget.productItem.numImages; i++) {
                listImagesProduct.add('$SERVER_IP$IMAGES_DIRECTORY${widget.productItem.productCode}_$i.gif');
              }
              return ListView (
                children: [
                  widget.productItem.numImages > 1 ? Column (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CarouselSlider (
                        items: listImagesProduct.map((url) => AspectRatio (
                          aspectRatio: 3.0 / 2.0,
                          child: CachedNetworkImage (
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            imageUrl: url,
                            fit: BoxFit.scaleDown,
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        )
                        ).toList(),
                        options: CarouselOptions(
                            autoPlay: true,
                            enlargeCenterPage: true,
                            aspectRatio: 2.0,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _current = index;
                              });
                            }
                        ),
                      ),
                      Row (
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: listImagesProduct.map((url) {
                          int index = listImagesProduct.indexOf(url);
                          return Container(
                            width: 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _current == index
                                    ? const Color.fromRGBO(0, 0, 0, 0.9)
                                    : const Color.fromRGBO(0, 0, 0, 0.4)
                            ),
                          );
                        }).toList(),
                      )
                    ],
                  ) : Container (
                    alignment: Alignment.center,
                    width: constraints.maxWidth,
                    child: AspectRatio(
                      aspectRatio: 3.0 / 2.0,
                      child: CachedNetworkImage(
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        imageUrl: '$SERVER_IP$IMAGES_DIRECTORY${widget.productItem.productCode}_0.gif',
                        fit: BoxFit.scaleDown,
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    ),
                  ),
                  SizedBox (height: constraints.maxHeight * HeightInDpis_2),
                  Padding(
                    padding: const EdgeInsets.fromLTRB (15.0, 0.0, 15.0, 0.0),
                    child: Row (
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                          child: Image.asset ('assets/images/00002.png'),
                        ),
                        Padding (
                          padding: const EdgeInsets.only(right: 15.0),
                          child: _newNewProductPriceFinal != -1 ? Text.rich (
                              TextSpan (
                                  text: NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((_newNewProductPriceFinal/MULTIPLYING_FACTOR).toString())),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 40.0,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                        text: '${' (${NumberFormat("##0.00", "es_ES").format(double.parse((widget.father.productPrice/MULTIPLYING_FACTOR).toString()))}'})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 30.0,
                                          fontFamily: 'SF Pro Display',
                                        )
                                    )
                                  ]
                              )
                          ) : Text(
                              NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((_newPrice/MULTIPLYING_FACTOR).toString())),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 40.0,
                                fontFamily: 'SF Pro Display',
                              ),
                              textAlign: TextAlign.start
                          ),
                        ),
                      ],
                    ),
                  ),
                  //SizedBox(height: 4.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_4),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        width: constraints.maxWidth,
                        child: Text(
                          widget.productItem.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      )
                    ],
                  ),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        width: constraints.maxWidth,
                        child: Text(
                          widget.productItem.businessName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 24.0,
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
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container (
                        padding: const EdgeInsets.only(left: 24),
                        child: Text(
                          'Unids. mínim. venta: ${widget.productItem.minQuantitySell}',
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
                      ),
                    ],
                  ),
                  //SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  const Divider (thickness: 2.0,),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container (
                        padding: const EdgeInsets.only(left: 24),
                        child: const Text (
                          'Modificación del precio por: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded (
                          flex: 1,
                          child: ListTile(
                            title: const Text('Valor'),
                            leading: Radio<PriceChangeType>(
                              value: PriceChangeType.priceValue,
                              groupValue: _changeType,
                              onChanged: (PriceChangeType? value){
                                setState(() {
                                  _changeType = value!;
                                  _valueDiscount = 0.0;
                                  _percentDiscount = 0.0;
                                  _newNewProductPriceFinal = widget.father.newProductPrice;
                                });
                                _valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                _percentDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
                              },
                            ),
                          )
                      ),
                      Expanded (
                          flex: 1,
                          child: ListTile(
                            title: const Text('Porcentaje'),
                            leading: Radio<PriceChangeType>(
                              value: PriceChangeType.percentValue,
                              groupValue: _changeType,
                              onChanged: (PriceChangeType? value){
                                setState(() {
                                  _changeType = value!;
                                  _percentDiscount = 0.0;
                                  _valueDiscount = 0.0;
                                  _newNewProductPriceFinal = widget.father.newProductPrice;
                                });
                                _percentDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
                                _valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                              },
                            ),
                          )
                      )
                    ],
                  ),
                  const Divider(thickness: 2.0,),
                  (_changeType == PriceChangeType.priceValue) ? const Center (
                    child: Text(
                      'Modificación neta',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Color(0xFF6C6D77),
                      ),
                    ),
                  ) : const Center (
                    child: Text (
                      'Modificación porcentual',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Color(0xFF6C6D77),
                      ),
                    ),
                  ),
                  (_changeType == PriceChangeType.priceValue) ? Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded (
                          flex:1,
                          child: Container()
                      ),
                      Expanded (
                        flex:4,
                        child: Row (
                          children: [
                            Expanded (
                              flex: 1,
                              child: TextButton (
                                  onPressed: () {
                                    debugPrint ('Estoy en el onPressed de -');
                                    if (widget.father.newProductPrice != -1) {
                                      // the price has been previously modified
                                      debugPrint ('Estoy en el onPressed de -. Dentro de la parte de que el precio ha sido previamente modificado.');
                                      final double tmpValueDiscount = _valueDiscount;
                                      _valueDiscount = _valueDiscount - 0.1;
                                      if (widget.father.newProductPrice >= (_valueDiscount * MULTIPLYING_FACTOR).abs()) {
                                        // the price can't be negative
                                        setState(() {
                                          _valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                        });
                                      } else {
                                        _valueDiscount = tmpValueDiscount;
                                      }
                                    } else {
                                      // the price has not yet modified
                                      //debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
                                      debugPrint ('Estoy en el onPressed de -. Dentro de la parte de que el precio nunca ha sido previamente modificado.');
                                      final double tmpValueDiscount = _valueDiscount;
                                      _valueDiscount = _valueDiscount - 0.1;
                                      debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
                                      if (widget.father.productPrice >= (_valueDiscount * MULTIPLYING_FACTOR).abs()) {
                                        // the price can't be negative
                                        setState(() {
                                          _valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                        });
                                      } else {
                                        _valueDiscount = tmpValueDiscount;
                                      }
                                    }
                                  },
                                  child: Container (
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration (
                                        color: tanteLadenAmber500,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: tanteLadenButtonBorderGray,
                                            width: 1
                                        )
                                    ),
                                    child: Container (
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '-',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w300,
                                            fontSize: 24.0,
                                            fontFamily: 'SF Pro Display',
                                            fontStyle: FontStyle.normal,
                                            color: tanteLadenButtonBorderGray
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            ),
                            Expanded (
                              flex: 2,
                              child: Form (
                                key: _formNewPricekey,
                                child: TextFormField(
                                  controller: _valueDiscountTextField,
                                  decoration: const InputDecoration (
                                      prefixIcon: Icon(Icons.euro_rounded)
                                  ),
                                  style: const TextStyle (
                                    fontWeight: FontWeight.w700,
                                    fontSize: 24.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$')),],
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (String? value) {
                                    RegExp regexp = RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$');
                                    if (!regexp.hasMatch(value!)) {
                                      return 'Introduce un valor neto válido. Formato: (+/-)##,##';
                                    } else {
                                      return null;
                                    }
                                  },
                                ),
                              ),
                            ),
                            Expanded (
                              flex: 1,
                              child: TextButton(
                                  onPressed: () {
                                    debugPrint ('Estoy en el onPressed de +');
                                    if (widget.father.newProductPrice != -1) {
                                      // the price has been previously modified
                                      debugPrint ('Estoy en el onPressed de +. Dentro de la parte de que el precio ha sido previamente modificado.');
                                      _valueDiscount = _valueDiscount + 0.1;
                                      setState(() {
                                        _valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                      });
                                    } else {
                                      // the price has not yet modified
                                      //debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
                                      debugPrint ('Estoy en el onPressed de +. Dentro de la parte de que el precio nunca ha sido previamente modificado.');
                                      _valueDiscount = _valueDiscount + 0.1;
                                      debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
                                      setState(() {
                                        _valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                      });
                                    }
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration(
                                      color: tanteLadenAmber500,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF6C6D77),
                                        width: 1,
                                      ),
                                    ),
                                    child: Container(
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '+',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 24.0,
                                          fontFamily: 'SF Pro Display',
                                          fontStyle: FontStyle.normal,
                                          color: tanteLadenButtonBorderGray,
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded (
                          flex:1,
                          child: Container()
                      )
                    ],
                  ) : Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded (
                          flex:1,
                          child: Container()
                      ),
                      Expanded (
                        flex:4,
                        child: Row (
                          children: [
                            Expanded (
                              flex: 1,
                              child: TextButton(
                                  onPressed: () {
                                    if (widget.father.newProductPrice != -1) {
                                      // the price has been previously modified
                                      debugPrint ('Estoy en el onPressed de -. Dentro de la parte de que el precio ha sido previamente modificado.');
                                      final double tmpPercentDiscount = _percentDiscount;
                                      _percentDiscount = _percentDiscount - 0.5;
                                      debugPrint ('El valor de _percentDiscount es: $_percentDiscount');
                                      debugPrint ('El valor de productPrice es: ${widget.father.productPrice}');
                                      debugPrint ('El valor de widget.father.productPrice * (1+(_percentDiscount/100)) es: ${((widget.father.productPrice * (1+(_percentDiscount/100)))).abs()}');
                                      if (widget.father.newProductPrice >= ((widget.father.newProductPrice * (1+(_percentDiscount/100)))).abs()) {
                                        setState(() {
                                          _percentDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse((_percentDiscount).toString()));
                                        });
                                      } else {
                                        _percentDiscount = tmpPercentDiscount;
                                      }
                                    } else {
                                      // the price has not yet modified
                                      debugPrint ('Estoy en el onPressed de -. Dentro de la parte de que el precio nunca ha sido previamente modificado.');
                                      final double tmpPercentDiscount = _percentDiscount;
                                      _percentDiscount = _percentDiscount - 0.5;
                                      debugPrint ('El valor de _percentDiscount es: $_percentDiscount');
                                      debugPrint ('El valor de productPrice es: ${widget.father.productPrice}');
                                      debugPrint ('El valor de widget.father.productPrice * (1+(_percentDiscount/100)) es: ${((widget.father.productPrice * (1+(_percentDiscount/100)))).abs()}');
                                      if (widget.father.productPrice >= ((widget.father.productPrice * (1+(_percentDiscount/100)))).abs()) {
                                        setState(() {
                                          _percentDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse((_percentDiscount).toString()));
                                        });
                                      } else {
                                        _percentDiscount = tmpPercentDiscount;
                                      }
                                    }
                                  },
                                  child: Container (
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration (
                                        color: tanteLadenAmber500,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: tanteLadenButtonBorderGray,
                                            width: 1
                                        )
                                    ),
                                    child: Container(
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '-',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w300,
                                            fontSize: 24.0,
                                            fontFamily: 'SF Pro Display',
                                            fontStyle: FontStyle.normal,
                                            color: tanteLadenButtonBorderGray
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            ),
                            Expanded (
                              flex: 2,
                              child: Form(
                                key: _formPercentKey,
                                child: TextFormField(
                                  controller: _percentDiscountTextField,
                                  decoration: const InputDecoration (
                                    prefixText: '  %  ',
                                    prefixStyle: TextStyle (
                                      fontWeight: FontWeight.w700,
                                      fontSize: 24.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.black45,
                                    ),
                                  ),
                                  style: const TextStyle (
                                    fontWeight: FontWeight.w700,
                                    fontSize: 24.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$')),],
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (String? value) {
                                    RegExp regexp = RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$');
                                    if (!regexp.hasMatch(value!)) {
                                      return 'Introduce un porcentaje válido. Formato: (+/-)##,##';
                                    } else {
                                      return null;
                                    }
                                  },
                                ),
                              ),
                            ),
                            Expanded (
                              flex: 1,
                              child: TextButton(
                                  onPressed: () {
                                    if (widget.father.newProductPrice != -1) {
                                      // the price has been previously modified
                                      debugPrint ('Estoy en el onPressed de +. Dentro de la parte de que el precio ha sido previamente modificado.');
                                      _percentDiscount = _percentDiscount + 0.5;
                                      debugPrint ('El valor de _percentDiscount es: $_percentDiscount');
                                      debugPrint ('El valor de productPrice es: ${widget.father.productPrice}');
                                      debugPrint ('El valor de widget.father.productPrice * (1+(_percentDiscount/100)) es: ${((widget.father.productPrice * (1+(_percentDiscount/100)))).abs()}');
                                      setState(() {
                                        _percentDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse((_percentDiscount).toString()));
                                      });
                                    } else {
                                      // the price has not yet modified
                                      debugPrint ('Estoy en el onPressed de +. Dentro de la parte de que el precio nunca ha sido previamente modificado.');
                                      _percentDiscount = _percentDiscount + 0.5;
                                      debugPrint ('El valor de _percentDiscount es: $_percentDiscount');
                                      debugPrint ('El valor de productPrice es: ${widget.father.productPrice}');
                                      debugPrint ('El valor de widget.father.productPrice * (1+(_percentDiscount/100)) es: ${((widget.father.productPrice * (1+(_percentDiscount/100)))).abs()}');
                                      setState(() {
                                        _percentDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse((_percentDiscount).toString()));
                                      });
                                    }
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration(
                                      color: tanteLadenAmber500,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF6C6D77),
                                        width: 1,
                                      ),
                                    ),
                                    child: Container(
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '+',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 24.0,
                                          fontFamily: 'SF Pro Display',
                                          fontStyle: FontStyle.normal,
                                          color: tanteLadenButtonBorderGray,
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded (
                          flex:1,
                          child: Container()
                      )
                    ],
                  ),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: Image.asset (
                          'assets/images/logoComment.png',
                          fit: BoxFit.scaleDown,
                          width: 20.0,
                          height: 20.0,
                        ),
                      ),
                      Container (
                        padding: const EdgeInsets.only(left:8),
                        child: Text.rich(
                            TextSpan (
                                text: 'Introducir comentario',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: tanteLadenIconBrown,
                                    decoration: TextDecoration.underline
                                ),
                                recognizer: TapGestureRecognizer ()
                                  ..onTap = () async {
                                    _comment = await Navigator.push (context, MaterialPageRoute (
                                        builder: (context) => AddComment (_comment)
                                    ));
                                  }
                            )
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container (
                          padding: const EdgeInsets.only(left: 24),
                          child: Checkbox (
                            checkColor: Colors.white,
                            fillColor: MaterialStateProperty.resolveWith(getColor),
                            value: _isOfficial,
                            onChanged: (bool? value) {
                              setState(() {
                                _isOfficial = value!;
                              });
                            },
                          )
                      ),
                      const Text (
                        'Oficializar el nuevo precio.',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14.0,
                          fontFamily: 'SF Pro Display',
                          fontStyle: FontStyle.normal,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ],
                  ),
                  _pleaseWait ? Stack (
                    key: const ObjectKey ("stack"),
                    alignment: AlignmentDirectional.center,
                    children: [
                      tmpBuilder,
                      _pleaseWaitWidget
                    ],
                  ): Stack (
                    key: const ObjectKey("stack"),
                    children: [tmpBuilder],
                  ),
                  //SizedBox(height: 35.0),
                ],
              );
            },
          )
      );
    } else {    // widget.father.banQuantity == "SI" && widget.father.banPrice == "SI"
      return SafeArea (
          child: LayoutBuilder(
            builder: (context, constraints) {
              final List<String> listImagesProduct = [];
              for (var i = 0; i < widget.productItem.numImages; i++) {
                listImagesProduct.add('$SERVER_IP$IMAGES_DIRECTORY${widget.productItem.productCode}_$i.gif');
              }
              return ListView (
                children: [
                  widget.productItem.numImages > 1 ? Column (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CarouselSlider (
                        items: listImagesProduct.map((url) => AspectRatio (
                          aspectRatio: 3.0 / 2.0,
                          child: CachedNetworkImage(
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            imageUrl: url,
                            fit: BoxFit.scaleDown,
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        )
                        ).toList(),
                        options: CarouselOptions(
                            autoPlay: true,
                            enlargeCenterPage: true,
                            aspectRatio: 2.0,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _current = index;
                              });
                            }
                        ),
                      ),
                      Row (
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: listImagesProduct.map((url) {
                          int index = listImagesProduct.indexOf(url);
                          return Container(
                            width: 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _current == index
                                    ? const Color.fromRGBO(0, 0, 0, 0.9)
                                    : const Color.fromRGBO(0, 0, 0, 0.4)
                            ),
                          );
                        }).toList(),
                      )
                    ],
                  ) : Container(
                    alignment: Alignment.center,
                    width: constraints.maxWidth,
                    child: AspectRatio(
                      aspectRatio: 3.0 / 2.0,
                      child: CachedNetworkImage(
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        imageUrl: '$SERVER_IP$IMAGES_DIRECTORY${widget.productItem.productCode}_0.gif',
                        fit: BoxFit.scaleDown,
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    ),
                  ),
                  SizedBox (height: constraints.maxHeight * HeightInDpis_2),
                  Padding(
                    padding: const EdgeInsets.fromLTRB (15.0, 0.0, 15.0, 0.0),
                    child: Row (
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                          child: Image.asset ('assets/images/00002.png'),
                        ),
                        Padding (
                          padding: const EdgeInsets.only(right: 15.0),
                          child: _newNewProductPriceFinal != -1 ? Text.rich (
                              TextSpan (
                                  text: NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((_newNewProductPriceFinal/MULTIPLYING_FACTOR).toString())),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 40.0,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                        text: '${' (${NumberFormat("##0.00", "es_ES").format(double.parse((widget.father.productPrice/MULTIPLYING_FACTOR).toString()))}'})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 30.0,
                                          fontFamily: 'SF Pro Display',
                                        )
                                    )
                                  ]
                              )
                          ) : Text(
                              NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((_newPrice/MULTIPLYING_FACTOR).toString())),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 40.0,
                                fontFamily: 'SF Pro Display',
                              ),
                              textAlign: TextAlign.start
                          ),
                        ),
                      ],
                    ),
                  ),
                  //SizedBox(height: 4.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        width: constraints.maxWidth,
                        child: Text(
                          widget.productItem.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      )
                    ],
                  ),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        width: constraints.maxWidth,
                        child: Text(
                          widget.productItem.businessName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 24.0,
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
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container (
                        padding: const EdgeInsets.only(left: 24),
                        child: Text(
                          'Unids. mínim. venta: ${widget.productItem.minQuantitySell} ${(widget.productItem.minQuantitySell > 1) ? '${widget.productItem.idUnit}s.' : '${widget.productItem.idUnit}.'}',
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
                      ),
                    ],
                  ),
                  //Divider (thickness: 8.0,),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  const Center(
                    child: Text(
                      'Cantidad',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Color(0xFF6C6D77),
                      ),
                    ),
                  ),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton (
                          onPressed: () {
                            if (widget.father.newQuantity != -1) {
                              // the quantity of the purchase line has been changed.
                              // The value -1 is the value if the field NEW_QUANTITY of the KRC_PURCHASE is null,
                              // then it has been not yet modified
                              if (_newNewProductPriceFinal != -1) {
                                if (_newNumItemsPurchased > 0) {
                                  setState (() {
                                    _newNumItemsPurchased = _newNumItemsPurchased - widget.productItem.minQuantitySell;
                                    if (_newNumItemsPurchased < 0) _newNumItemsPurchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  final double productPriceDiscounted = (_newNewProductPriceFinal + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                  debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
                                  _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                  debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                  _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              } else {
                                if (_newNumItemsPurchased > 0) {
                                  setState (() {
                                    _newNumItemsPurchased = _newNumItemsPurchased - widget.productItem.minQuantitySell;
                                    if (_newNumItemsPurchased < 0) _newNumItemsPurchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice*(1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                  _discountAmount = _newNumItemsPurchased * (((_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal) - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = _newNumItemsPurchased * (_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal);
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                  debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                  _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              }
                            } else {
                              // the quantity of the purchase line has not yet been changed.
                              if (_newNewProductPriceFinal != -1) {
                                if (widget.productItem.purchased > 0) {
                                  setState (() {
                                    widget.productItem.purchased = widget.productItem.purchased - widget.productItem.minQuantitySell;
                                    if (widget.productItem.purchased < 0) widget.productItem.purchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  final double productPriceDiscounted = (_newNewProductPriceFinal + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                  debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
                                  _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                  debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                  _taxAmount = widget.productItem.purchased * taxAmountByProduct;
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              } else {
                                if (widget.productItem.purchased > 0) {
                                  setState (() {
                                    widget.productItem.purchased = widget.productItem.purchased - widget.productItem.minQuantitySell;
                                    if (widget.productItem.purchased < 0) widget.productItem.purchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  _discountAmount = widget.productItem.purchased * (((_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal) - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                  debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
                                  _totalAfterDiscountWithoutTax = widget.productItem.purchased * (_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal);
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                  debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                  _taxAmount = widget.productItem.purchased * taxAmountByProduct;
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              }
                            }
                          },
                          child: Container (
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(2.0),
                            decoration: BoxDecoration (
                                color: tanteLadenAmber500,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: tanteLadenButtonBorderGray,
                                    width: 1
                                )
                            ),
                            child: Container(
                              width: 40.0,
                              height: 40.0,
                              alignment: Alignment.center,
                              child: const Text(
                                '-',
                                style: TextStyle(
                                    fontWeight: FontWeight.w300,
                                    fontSize: 24.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: tanteLadenButtonBorderGray
                                ),
                              ),
                            ),
                          )
                      ),
                      Padding (
                        //padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                        padding: const EdgeInsets.only(left: WithInDpis_20, right: WithInDpis_20),
                        child: RichText (
                          text: TextSpan (
                              text: widget.father.newQuantity != -1
                                  ? '$_newNumItemsPurchased (${widget.productItem.purchased}) '
                                  : widget.productItem.purchased.toString(),
                              style: const TextStyle (
                                fontWeight: FontWeight.w700,
                                fontSize: 24.0,
                                fontFamily: 'SF Pro Display',
                                fontStyle: FontStyle.normal,
                                color: Colors.black,
                              ),
                              children: <TextSpan>[
                                TextSpan (
                                    text: widget.father.newQuantity != -1
                                        ? _newNumItemsPurchased > 1 ? ' ${widget.productItem.idUnit}s.' : ' ${widget.productItem.idUnit}.'
                                        : widget.productItem.purchased > 1 ? ' ${widget.productItem.idUnit}s.' : ' ${widget.productItem.idUnit}.',
                                    style: const TextStyle (
                                        fontWeight: FontWeight.bold
                                    )
                                )
                              ]
                          ),
                        ),
                      ),
                      TextButton(
                          onPressed: () {
                            if (widget.father.newQuantity != -1) {
                              // the quantity of the purchase line has been changed.
                              // The value -1 is the value when the field NEW_QUANTITY of the KRC_PURCHASE is null,
                              // then it has been not yet modified
                              if (_newNewProductPriceFinal != -1) {
                                setState(() {
                                  _newNumItemsPurchased = _newNumItemsPurchased + widget.productItem.minQuantitySell;
                                });
                                _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
                                debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                final double productPriceDiscounted = (_newNewProductPriceFinal + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
                                _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
                                debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
                                debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                debugPrint ('El valor de _totalAmount es: $_totalAmount');
                              } else {
                                setState(() {
                                  _newNumItemsPurchased = _newNumItemsPurchased + widget.productItem.minQuantitySell;
                                });
                                _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice*(1+widget.productItem.taxApply/100));
                                debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
                                _discountAmount = _newNumItemsPurchased * (((_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal) - widget.father.productPrice));
                                debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                _totalAfterDiscountWithoutTax = _newNumItemsPurchased * (_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal);
                                debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
                                debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                debugPrint ('El valor de _totalAmount es: $_totalAmount');
                              }
                            } else {
                              // the quantity of the purchase line has not yet been changed.
                              if (_newNewProductPriceFinal != -1) {
                                setState(() {
                                  widget.productItem.purchased = widget.productItem.purchased + widget.productItem.minQuantitySell;
                                });
                                _totalBeforeDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
                                debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                final double productPriceDiscounted = (_newNewProductPriceFinal + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
                                _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
                                debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                _taxAmount = widget.productItem.purchased * taxAmountByProduct;
                                debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                //_totalAmount = widget.productItem.purchased * widget.productItem.totalAmount;
                                _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                debugPrint ('El valor de _totalAmount es: $_totalAmount');
                              } else {
                                setState(() {
                                  widget.productItem.purchased = widget.productItem.purchased + widget.productItem.minQuantitySell;
                                });
                                _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice*(1+(widget.productItem.taxApply/100)));
                                debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
                                final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
                                _discountAmount = widget.productItem.purchased * (((_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal) - widget.father.productPrice));
                                debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                _totalAfterDiscountWithoutTax = widget.productItem.purchased * (_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal);
                                debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                _taxAmount = widget.productItem.purchased * taxAmountByProduct;
                                debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                debugPrint ('El valor de _totalAmount es: $_totalAmount');
                              }
                            }
                          },
                          child: Container (
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(2.0),
                            decoration: BoxDecoration(
                              color: tanteLadenAmber500,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF6C6D77),
                                width: 1,
                              ),
                            ),
                            child: Container(
                              width: 40.0,
                              height: 40.0,
                              alignment: Alignment.center,
                              child: const Text(
                                '+',
                                style: TextStyle(
                                  fontWeight: FontWeight.w300,
                                  fontSize: 24.0,
                                  fontFamily: 'SF Pro Display',
                                  fontStyle: FontStyle.normal,
                                  color: tanteLadenButtonBorderGray,
                                ),
                              ),
                            ),
                          )
                      ),
                    ],
                  ),
                  //SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  const Divider (thickness: 2.0,),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container (
                        padding: const EdgeInsets.only(left: 24),
                        child: const Text (
                          'Modificación del precio por: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded (
                          flex: 1,
                          child: ListTile(
                            title: const Text('Valor'),
                            leading: Radio<PriceChangeType>(
                              value: PriceChangeType.priceValue,
                              groupValue: _changeType,
                              onChanged: (PriceChangeType? value){
                                setState(() {
                                  _changeType = value!;
                                  _valueDiscount = 0.0;
                                  _percentDiscount = 0.0;
                                  _newNewProductPriceFinal = widget.father.newProductPrice;
                                });
                                _valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                _percentDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
                              },
                            ),
                          )
                      ),
                      Expanded (
                          flex: 1,
                          child: ListTile(
                            title: const Text('Porcentaje'),
                            leading: Radio<PriceChangeType>(
                              value: PriceChangeType.percentValue,
                              groupValue: _changeType,
                              onChanged: (PriceChangeType? value){
                                setState(() {
                                  _changeType = value!;
                                  _percentDiscount = 0.0;
                                  _valueDiscount = 0.0;
                                  _newNewProductPriceFinal = widget.father.newProductPrice;
                                });
                                _percentDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
                                _valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                              },
                            ),
                          )
                      )
                    ],
                  ),
                  const Divider(thickness: 2.0,),
                  (_changeType == PriceChangeType.priceValue) ? const Center (
                    child: Text(
                      'Modificación neta',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Color(0xFF6C6D77),
                      ),
                    ),
                  ) : const Center(
                    child: Text (
                      'Modificación porcentual',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Color(0xFF6C6D77),
                      ),
                    ),
                  ),
                  (_changeType == PriceChangeType.priceValue) ? Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded (
                          flex:1,
                          child: Container()
                      ),
                      Expanded (
                        flex:4,
                        child: Row (
                          children: [
                            Expanded (
                              flex: 1,
                              child: TextButton(
                                  onPressed: () {
                                    debugPrint ('Estoy en el onPressed de -');
                                    if (widget.father.newProductPrice != -1) {
                                      // the price has been previously modified
                                      debugPrint ('Estoy en el onPressed de -. Dentro de la parte de que el precio ha sido previamente modificado.');
                                      final double tmpValueDiscount = _valueDiscount;
                                      _valueDiscount = _valueDiscount - 0.1;
                                      if (widget.father.newProductPrice >= (_valueDiscount * MULTIPLYING_FACTOR).abs()) {
                                        // the price can't be negative
                                        setState(() {
                                          _valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                        });
                                      } else {
                                        _valueDiscount = tmpValueDiscount;
                                      }
                                    } else {
                                      // the price has not yet modified
                                      //debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
                                      debugPrint ('Estoy en el onPressed de -. Dentro de la parte de que el precio nunca ha sido previamente modificado.');
                                      final double tmpValueDiscount = _valueDiscount;
                                      _valueDiscount = _valueDiscount - 0.1;
                                      debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
                                      if (widget.father.productPrice >= (_valueDiscount * MULTIPLYING_FACTOR).abs()) {
                                        // the price can't be negative
                                        setState(() {
                                          _valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                        });
                                      } else {
                                        _valueDiscount = tmpValueDiscount;
                                      }
                                    }
                                  },
                                  child: Container (
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration (
                                        color: tanteLadenAmber500,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: tanteLadenButtonBorderGray,
                                            width: 1
                                        )
                                    ),
                                    child: Container(
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text (
                                        '-',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w300,
                                            fontSize: 24.0,
                                            fontFamily: 'SF Pro Display',
                                            fontStyle: FontStyle.normal,
                                            color: tanteLadenButtonBorderGray
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            ),
                            Expanded (
                              flex: 2,
                              child: Form(
                                key: _formNewPricekey,
                                child: TextFormField(
                                  controller: _valueDiscountTextFieldOnlyForCaseOne,
                                  decoration: const InputDecoration (
                                      prefixIcon: Icon(Icons.euro_rounded)
                                  ),
                                  style: const TextStyle (
                                    fontWeight: FontWeight.w700,
                                    fontSize: 24.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$')),],
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  onEditingComplete: () {
                                    _percentDiscount = double.tryParse (_percentDiscountTextField.text.replaceAll(RegExp(','), '.'))!;
                                    debugPrint('El valor de: _percentDiscount es: $_percentDiscount');
                                  },
                                  validator: (String? value) {
                                    RegExp regexp = RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$');
                                    if (!regexp.hasMatch(value!)) {
                                      return 'Introduce un valor neto válido. Formato: (+/-)##,##';
                                    } else {
                                      return null;
                                    }
                                  },
                                ),
                              ),
                            ),
                            Expanded (
                              flex: 1,
                              child: TextButton(
                                  onPressed: () {
                                    debugPrint ('Estoy en el onPressed de +');
                                    if (widget.father.newProductPrice != -1) {
                                      // the price has been previously modified
                                      debugPrint ('Estoy en el onPressed de +. Dentro de la parte de que el precio ha sido previamente modificado.');
                                      _valueDiscount = _valueDiscount + 0.1;
                                      setState(() {
                                        _valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                      });
                                    } else {
                                      // the price has not yet modified
                                      //debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
                                      debugPrint ('Estoy en el onPressed de +. Dentro de la parte de que el precio nunca ha sido previamente modificado.');
                                      _valueDiscount = _valueDiscount + 0.1;
                                      debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
                                      setState(() {
                                        _valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                      });
                                    }
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration(
                                      color: tanteLadenAmber500,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF6C6D77),
                                        width: 1,
                                      ),
                                    ),
                                    child: Container(
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '+',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 24.0,
                                          fontFamily: 'SF Pro Display',
                                          fontStyle: FontStyle.normal,
                                          color: tanteLadenButtonBorderGray,
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded (
                          flex:1,
                          child: Container()
                      )
                    ],
                  ) : Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded (
                          flex:1,
                          child: Container()
                      ),
                      Expanded (
                        flex:4,
                        child: Row (
                          children: [
                            Expanded (
                              flex: 1,
                              child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _percentDiscount = _percentDiscount - 0.5;
                                      _percentDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse((_percentDiscount).toString()));
                                    });
                                    // There is a change in the price
                                    _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                    _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                    final double productPriceDiscounted = widget.father.productPrice * (1-(_percentDiscount/100)); // product price minus discount
                                    _discountAmount = widget.productItem.purchased * (widget.father.productPrice * (_percentDiscount/100));
                                    _totalAfterDiscountWithoutTax = _totalBeforeDiscountWithoutTax + _discountAmount;
                                    final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                    _taxAmount = widget.productItem.purchased * taxAmountByProduct;
                                    _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  },
                                  child: Container (
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration (
                                        color: tanteLadenAmber500,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: tanteLadenButtonBorderGray,
                                            width: 1
                                        )
                                    ),
                                    child: Container(
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '-',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w300,
                                            fontSize: 24.0,
                                            fontFamily: 'SF Pro Display',
                                            fontStyle: FontStyle.normal,
                                            color: tanteLadenButtonBorderGray
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            ),
                            Expanded (
                              flex: 2,
                              child: Form(
                                key: _formPercentKey,
                                child: TextFormField(
                                  controller: _percentDiscountTextFieldOnlyForCaseOne,
                                  decoration: const InputDecoration (
                                    prefixText: '  %  ',
                                    prefixStyle: TextStyle (
                                      fontWeight: FontWeight.w700,
                                      fontSize: 24.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.black45,
                                    ),
                                  ),
                                  style: const TextStyle (
                                    fontWeight: FontWeight.w700,
                                    fontSize: 24.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$')),],
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  onEditingComplete: () {
                                    _percentDiscount = double.tryParse (_percentDiscountTextField.text.replaceAll(RegExp(','), '.'))!;
                                    debugPrint('El valor de: _percentDiscount es: $_percentDiscount');
                                  },
                                  validator: (String? value) {
                                    RegExp regexp = RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$');
                                    if (!regexp.hasMatch(value!)) {
                                      return 'Introduce un porcentaje válido. Formato: (+/-)##,##';
                                    } else {
                                      return null;
                                    }
                                  },
                                ),
                              ),
                            ),
                            Expanded (
                              flex: 1,
                              child: TextButton(
                                  onPressed: () {
                                    if (_percentDiscount <= 100) {
                                      setState(() {
                                        _percentDiscount = _percentDiscount + 0.5;
                                        _percentDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse((_percentDiscount).toString()));
                                      });
                                      // There is a change in the price
                                      _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                      _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                      final double productPriceDiscounted = widget.father.productPrice * (1-(_percentDiscount/100)); // product price minus discount
                                      _discountAmount = widget.productItem.purchased * (widget.father.productPrice * (_percentDiscount/100));
                                      _totalAfterDiscountWithoutTax = _totalBeforeDiscountWithoutTax - _discountAmount;
                                      final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                      _taxAmount = widget.productItem.purchased * taxAmountByProduct;
                                      _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                    }
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration(
                                      color: tanteLadenAmber500,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF6C6D77),
                                        width: 1,
                                      ),
                                    ),
                                    child: Container(
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '+',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 24.0,
                                          fontFamily: 'SF Pro Display',
                                          fontStyle: FontStyle.normal,
                                          color: tanteLadenButtonBorderGray,
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded (
                          flex:1,
                          child: Container()
                      )
                    ],
                  ),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: Image.asset (
                          'assets/images/logoComment.png',
                          fit: BoxFit.scaleDown,
                          width: 20.0,
                          height: 20.0,
                        ),
                      ),
                      Container (
                        padding: const EdgeInsets.only(left:8),
                        child: Text.rich(
                            TextSpan (
                                text: 'Introducir comentario',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: tanteLadenIconBrown,
                                    decoration: TextDecoration.underline
                                ),
                                recognizer: TapGestureRecognizer ()
                                  ..onTap = () async {
                                    _comment = await Navigator.push (context, MaterialPageRoute (
                                        builder: (context) => AddComment (_comment)
                                    ));
                                  }
                            )
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container (
                          padding: const EdgeInsets.only(left: 24),
                          child: Checkbox (
                            checkColor: Colors.white,
                            fillColor: MaterialStateProperty.resolveWith(getColor),
                            value: _isOfficial,
                            onChanged: (bool? value) {
                              setState(() {
                                _isOfficial = value!;
                              });
                            },
                          )
                      ),
                      const Text (
                        'Oficializar el nuevo precio.',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14.0,
                          fontFamily: 'SF Pro Display',
                          fontStyle: FontStyle.normal,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ],
                  ),
                  _pleaseWait ? Stack(
                    key: const ObjectKey ("stack"),
                    alignment: AlignmentDirectional.center,
                    children: [
                      tmpBuilder,
                      _pleaseWaitWidget
                    ],
                  ): Stack(
                    key: const ObjectKey("stack"),
                    children: [tmpBuilder],
                  ),
                  //SizedBox(height: 35.0),
                ],
              );
            },
          )
      );
    }
  }
}
class _LargeScreen extends StatefulWidget {
  final PurchaseLine father;
  final ProductAvail productItem;
  final int userId;
  final _StateChanged stateChanged;
  final int partnerId;
  final String userRole;
  const _LargeScreen (this.father, this.productItem, this.userId, this.stateChanged, this.partnerId, this.userRole);
  @override
  _LargeScreenState createState() => _LargeScreenState();
}
class _LargeScreenState extends State<_LargeScreen> {
  // private variables
  int _current = 0; // Var to save the current carousel image
  bool _pleaseWait = false;
  final PleaseWaitWidget _pleaseWaitWidget = const PleaseWaitWidget(key: ObjectKey("pleaseWaitWidget"));
  final TextEditingController _valueDiscountTextField = TextEditingController();
  final TextEditingController _percentDiscountTextField = TextEditingController();
  final TextEditingController _valueDiscountTextFieldOnlyForCaseOne = TextEditingController();  // Use a new text controller only for modifying the price text field of the case 1
  final TextEditingController _percentDiscountTextFieldOnlyForCaseOne = TextEditingController();  // Use a new text controller only for modifying the price text field of the case 1
  final _formPercentKey = GlobalKey<FormState>();
  final _formNewPricekey = GlobalKey<FormState>();
  // fields to save temporal values
  double _valueDiscount = 0.0;
  double _percentDiscount = 0.0;
  double _totalBeforeDiscount = 0.0;
  double _totalBeforeDiscountWithoutTax = 0.0;
  double _discountAmount = 0.0;
  double _totalAfterDiscountWithoutTax = 0.0;
  double _taxAmount = 0.0;
  double _totalAmount = 0.0;
  double _newNumItemsPurchased = 0;  // save the value of the field NEW_QUANTITY of the KRC_PURCHASE table.
  late double _newNewProductPriceFinal;  // save the value of the field NEW_PRODUCT_PRICE_FINAL of the KRC_PURCHASE table.
  late double _newPrice; // save the value of the field PRODUCT_PRICE of the KRC_PURCHASE table.
  PriceChangeType _changeType = PriceChangeType.priceValue;
  bool _isOfficial = false;
  late String _comment;

  _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }
  Color getColor(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
    };
    if (states.any(interactiveStates.contains)) {
      return Colors.blue;
    }
    return Colors.red;
  }
  void _valueDiscountTextFieldProcessor () {
    debugPrint ('Estoy en el listener _valueDiscountTextFieldProcessor');
    if (widget.father.newProductPrice != -1) {
      debugPrint ('Estoy en el _newNewProductPriceFinal != -1');
      // the price has been previously modified
      if (widget.father.newQuantity != -1) {
        _valueDiscount = double.tryParse (_valueDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Estoy en el listener. El valor de _valueDiscount es: $_valueDiscount');
        //_valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('Valor de _valueDiscountTextField.text: ${_valueDiscountTextField.text}');
        _totalBeforeDiscountWithoutTax = widget.father.newQuantity * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.father.newQuantity * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.newProductPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = widget.father.newQuantity * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.father.newQuantity * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.father.newQuantity * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        _valueDiscount = double.tryParse (_valueDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Estoy en el listener. El valor de _valueDiscount es: $_valueDiscount');
        //_valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('Valor de _valueDiscountTextField.text: ${_valueDiscountTextField.text}');
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.newProductPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    } else {
      // the price has not yet modified
      debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
      if (widget.father.newQuantity != -1) {
        _valueDiscount = double.tryParse (_valueDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        //_valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
        _totalBeforeDiscountWithoutTax = widget.father.newQuantity * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.father.newQuantity * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_valueDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = widget.father.newQuantity * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.father.newQuantity * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.father.newQuantity * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        _valueDiscount = double.tryParse (_valueDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        //_valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_valueDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    }
  }
  void _percentDiscountTextFieldProcessor() {
    debugPrint ('Estoy en el listener _percentDiscountTextFieldProcessor');
    if (widget.father.newProductPrice != -1) {
      debugPrint ('Estoy en el _newNewProductPriceFinal != -1');
      if (widget.father.newQuantity != -1) {
        debugPrint ('Valor de _percentDiscountTextField.text: ${_percentDiscountTextField.text}');
        // the price has been previously modified
        _percentDiscount = double.tryParse (_percentDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('El valor de _percentDiscount es: $_valueDiscount');
        _totalBeforeDiscountWithoutTax = widget.father.newQuantity * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.father.newQuantity * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.newProductPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = widget.father.newQuantity * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.father.newQuantity * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.father.newQuantity * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        debugPrint ('Valor de _percentDiscountTextField.text: ${_percentDiscountTextField.text}');
        // the price has been previously modified
        _percentDiscount = double.tryParse (_percentDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('El valor de _percentDiscount es: $_valueDiscount');
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.newProductPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    } else {
      // the price has not yet modified
      debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
      if (widget.father.newQuantity != -1) {
        _percentDiscount = double.tryParse (_percentDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Valor de _percentDiscountTextField.text: ${_percentDiscountTextField.text}');
        _totalBeforeDiscountWithoutTax = widget.father.newQuantity * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.father.newQuantity * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.productPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_percentDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = widget.father.newQuantity * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.father.newQuantity * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.father.newQuantity * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        _percentDiscount = double.tryParse (_percentDiscountTextField.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Valor de _percentDiscountTextField.text: ${_percentDiscountTextField.text}');
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.productPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_percentDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    }
  }
  void _valueDiscountTextFieldForCaseOneProcessor() {
    // Use a new and different listener for the case 1 (Price and Amount modified)
    debugPrint ('Estoy en el listener _valueDiscountTextFieldForCaseOneProcessor');
    if (widget.father.newProductPrice != -1) {
      if (widget.father.newQuantity != -1) {
        debugPrint ('Estoy en el _newNewProductPriceFinal != -1');
        // the price has been previously modified
        _valueDiscount = double.tryParse (_valueDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Estoy en el listener. El valor de _valueDiscount es: $_valueDiscount');
        //_valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('Valor de _valueDiscountTextFieldOnlyForCaseOne.text: ${_valueDiscountTextFieldOnlyForCaseOne.text}');
        _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.newProductPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        debugPrint ('Estoy en el _newNewProductPriceFinal != -1');
        // the price has been previously modified
        _valueDiscount = double.tryParse (_valueDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Estoy en el listener. El valor de _valueDiscount es: $_valueDiscount');
        //_valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('Valor de _valueDiscountTextFieldOnlyForCaseOne.text: ${_valueDiscountTextFieldOnlyForCaseOne.text}');
        //_totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.newProductPrice;
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.newProductPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    } else {
      // the price has not yet modified
      debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
      if (widget.father.newQuantity != -1) {
        _valueDiscount = double.tryParse (_valueDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        //_valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
        _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice*(1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_valueDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        _valueDiscount = double.tryParse (_valueDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        //_valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
        // There is a change in the price
        debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_valueDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    }
  }
  void _percentDiscountTextFieldForCaseOneProcessor() {
    // Use a new and different listener for the case 1 (Price and Amount modified)
    debugPrint ('Estoy en el listener _percentDiscountTextFieldForCaseOneProcessor.');
    if (widget.father.newProductPrice != -1) {
      if (widget.father.newQuantity != -1) {
        debugPrint ('Estoy en el _newNewProductPriceFinal != -1');
        debugPrint ('Valor de _percentDiscountTextFieldOnlyForCaseOne.text: ${_percentDiscountTextFieldOnlyForCaseOne.text}');
        // the price has been previously modified
        _percentDiscount = double.tryParse (_percentDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('El valor de _percentDiscount es: $_valueDiscount');
        _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        //_totalBeforeDiscount = _newNumItemsPurchased * (widget.father.newProductPrice * (1+widget.productItem.taxApply/100));
        _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.newProductPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        //_discountAmount = _newNumItemsPurchased * (_newNewProductPriceFinal * (_percentDiscount/100));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        //_totalAfterDiscountWithoutTax = _totalBeforeDiscountWithoutTax + _discountAmount;
        _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        debugPrint ('Estoy en el _newNewProductPriceFinal != -1');
        debugPrint ('Valor de _percentDiscountTextFieldOnlyForCaseOne.text: ${_percentDiscountTextFieldOnlyForCaseOne.text}');
        // the price has been previously modified
        _percentDiscount = double.tryParse (_percentDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('El valor de _percentDiscount es: $_percentDiscount');
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.newProductPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          _newNewProductPriceFinal = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    } else {
      // the price has not yet modified
      if (widget.father.newQuantity != -1) {
        debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
        _percentDiscount = double.tryParse (_percentDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Valor de _percentDiscountTextField.text: ${_percentDiscountTextFieldOnlyForCaseOne.text}');
        _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.productPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_percentDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      } else {
        debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
        _percentDiscount = double.tryParse (_percentDiscountTextFieldOnlyForCaseOne.text.replaceFirst(RegExp(','), '.'))!;
        debugPrint ('Valor de _percentDiscountTextFieldOnlyForCaseOne.text: ${_percentDiscountTextFieldOnlyForCaseOne.text}');
        _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
        debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
        _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
        debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
        final double productPriceDiscounted = widget.father.productPrice * (1+(_percentDiscount/100)); // product price minus discount
        debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
        setState(() {
          if (_percentDiscount == 0) {
            _newNewProductPriceFinal = -1;
          } else {
            _newNewProductPriceFinal = productPriceDiscounted;
          }
          _newPrice = productPriceDiscounted;
        });
        _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
        debugPrint ('El valor de _discountAmount es: $_discountAmount');
        _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
        debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
        final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
        debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
        _taxAmount = widget.productItem.purchased * taxAmountByProduct;
        debugPrint ('El valor de _taxAmount es: $_taxAmount');
        _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
        debugPrint ('El valor de _totalAmount es: $_totalAmount');
      }
    }
  }
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES');
    _current = 0;
    _changeType = PriceChangeType.priceValue;
    _isOfficial = false;
    // fields to save temporal values
    widget.productItem.purchased = widget.father.items;
    _newNumItemsPurchased = widget.father.newQuantity;
    _totalBeforeDiscountWithoutTax = widget.father.totalBeforeDiscountWithoutTax;
    _valueDiscount = 0.0;
    _valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
    _valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
    _percentDiscount = 0.0;
    _newNewProductPriceFinal = widget.father.newProductPrice;
    _newPrice = widget.father.productPrice;
    debugPrint ('El valor de _newNewProductPriceFinal es: $_newNewProductPriceFinal');
    _percentDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
    _percentDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
    _totalBeforeDiscountWithoutTax = widget.father.totalBeforeDiscountWithoutTax;
    _totalBeforeDiscount = widget.productItem.totalBeforeDiscount;
    _discountAmount = widget.father.discountAmount;
    _totalAfterDiscountWithoutTax = widget.father.totalAfterDiscountWithoutTax;
    _taxAmount = widget.father.taxAmount;
    _totalAmount = widget.father.totalAmount;
    if (widget.userRole == 'BUYER') {
      _comment = widget.father.remarkBuyer;
    } else {
      _comment = widget.father.remarkSeller;
    }
    _valueDiscountTextField.addListener (_valueDiscountTextFieldProcessor);
    _percentDiscountTextField.addListener (_percentDiscountTextFieldProcessor);
    _valueDiscountTextFieldOnlyForCaseOne.addListener(_valueDiscountTextFieldForCaseOneProcessor);  // Use a new and different listener for the case 1 (Price and Amount modified)
    _percentDiscountTextFieldOnlyForCaseOne.addListener(_percentDiscountTextFieldForCaseOneProcessor);  // Use a new and different listener for the case 1 (Price and Amount modified)
  }
  @override
  void dispose() {
    _valueDiscountTextField.dispose();
    _percentDiscountTextField.dispose();
    _valueDiscountTextFieldOnlyForCaseOne.dispose();
    _percentDiscountTextFieldOnlyForCaseOne.dispose();
    super.dispose();
  }
  @override
  Widget build (BuildContext context) {
    debugPrint('El productId es: ${widget.productItem.productId}');
    Widget tmpBuilder = Container (
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GestureDetector (
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
                  'Modificar pedido',
                  style: TextStyle(
                      fontSize: 24.0,
                      color: tanteLadenBackgroundWhite
                  ),
                ),
              ),
              onTap: () async {
                try {
                  debugPrint ('Comienzo la modificación del pedido');
                  _showPleaseWait(true);
                  // Detect if the amount purchased has changed
                  if (widget.father.banQuantity == "SI" && widget.father.banPrice == "SI") {
                    // Case 1
                    // The price and the quantity of the purchased has been changed by the user
                    if (_valueDiscount != 0 || _percentDiscount != 0
                        || _newNumItemsPurchased != widget.father.newProductPrice
                        || widget.productItem.purchased != widget.father.items) {
                      // There is a modification
                      debugPrint('Entro en el caso 1.');
                      debugPrint('El valor de _valueDiscountTextField es: ${_valueDiscountTextField.text}');
                      debugPrint('El valor de _percentDiscountTextField es: ${_percentDiscountTextField.text}');
                      final Uri url = Uri.parse('$SERVER_IP/modifyPurchaseLine/${widget.father.orderId}/${widget.father.providerName}');
                      debugPrint ("La URL es: $url");
                      final http.Response res = await http.put (
                          url,
                          headers: <String, String>{
                            'Content-Type': 'application/json; charset=UTF-8',
                            //'Authorization': jwt
                          },
                          body: jsonEncode (<String, String> {
                            'product_id': widget.father.productId.toString(),
                            'user_id': widget.userId.toString(),
                            'user_role': widget.userRole.toString(),
                            //'new_purchased': _newNumItemsPurchased != -1 ? _newNumItemsPurchased.toString() : widget.productItem.purchased.toString(),
                            'new_purchased': _newNumItemsPurchased != -1 ? _newNumItemsPurchased.toString() : (widget.productItem.purchased != widget.father.items ? widget.productItem.purchased.toString() : null)!,
                            'new_product_price': (_newNewProductPriceFinal != -1 ? _newNewProductPriceFinal.toString() : null)!,
                            'total_before_discount': _totalBeforeDiscount.toString(),
                            'total_amount': _totalAmount.toString(),
                            'discount_amount': _discountAmount.toString(),
                            'tax_amount': _taxAmount.toString(),
                            'is_official': _isOfficial.toString(),
                            'case_to_apply': '1',  // Case 1. he price and the quantity of the purchased has been changed
                            'comment': _comment
                          })
                      );
                      _showPleaseWait(false);
                      if (res.statusCode == 200) {
                        // Process the order
                        debugPrint ('OK. ');
                        final List<Map<String, dynamic>> resultListJson = json.decode(res.body)['statusToTransitionTo'].cast<Map<String, dynamic>>();
                        debugPrint ('Entre medias de la api RESPONSE.');
                        final List<PurchaseStatus> resultListPurchaseStatusToTransitionTo = resultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                        if (resultListPurchaseStatusToTransitionTo.isNotEmpty) {
                          widget.father.possibleStatusToTransitionTo.clear();
                          for (var element in resultListPurchaseStatusToTransitionTo) {
                            debugPrint ('El valor de statusName es: ${element.statusName}');
                            debugPrint ('El valor de BAN_PRICE es: ${element.banPrice}');
                            debugPrint ('El valor de BAN_QUANTITY es: ${element.banQuantity}');
                            widget.father.possibleStatusToTransitionTo.add(element);
                          }
                        }
                        debugPrint ('Despues de retornar los statusToTransitionTo.');
                        // get the values of BAN_PRICE and BAN_QUANTITY among the new state of the modified purchased line, "O" (OBSERVACIONES)
                        final List<Map<String, dynamic>> anotherResultListJson = json.decode(res.body)['currentBanQuantityBanPrice'].cast<Map<String, dynamic>>();
                        debugPrint ('Entre medias de la api RESPONSE.');
                        final List<PurchaseStatus> currentBanPriceBanStatusValues = anotherResultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                        if (currentBanPriceBanStatusValues.isNotEmpty) {
                          widget.father.banQuantity = currentBanPriceBanStatusValues[0].banQuantity;
                          widget.father.banPrice = currentBanPriceBanStatusValues[0].banPrice;
                        }
                        debugPrint ('Despues de retornar los currentBanPriceBanStatusValues.');
                        widget.stateChanged.changed = true;
                        widget.father.newQuantity = _newNumItemsPurchased != -1 ? _newNumItemsPurchased : (widget.productItem.purchased != widget.father.items ? widget.productItem.purchased : -1);
                        widget.father.newProductPrice = _newNewProductPriceFinal != -1 ? _newNewProductPriceFinal : widget.father.newProductPrice;
                        debugPrint ('El valor de widget.father.newProductPrice es: ${widget.father.newProductPrice}');
                        widget.father.totalBeforeDiscountWithoutTax = _totalBeforeDiscountWithoutTax;
                        widget.father.discountAmount = _discountAmount;
                        widget.father.totalAfterDiscountWithoutTax = _totalAfterDiscountWithoutTax;
                        widget.father.taxAmount = _taxAmount;
                        widget.father.totalAmount = _totalAmount;
                        if (widget.userRole == 'BUYER') {
                          widget.father.remarkBuyer = _comment;
                        } else {
                          widget.father.remarkSeller = _comment;
                        }
                        widget.father.statusId = "O";
                        widget.father.allStatus = "OBSERVACIONES";
                        if (!context.mounted) return;
                        Navigator.pop(context, widget.stateChanged.changed);
                      } else {
                        // Error
                        widget.stateChanged.changed = false;
                        if (!context.mounted) return;
                        ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'].toString());
                      }
                    }
                  } else if (widget.father.banQuantity == "NO" && widget.father.banPrice == "SI") {
                    // Case 2
                    // Only the price of the purchased has been changed by the user
                    debugPrint('Entro en el caso 2.');
                    final Uri url = Uri.parse('$SERVER_IP/modifyPurchaseLine/${widget.father.orderId}/${widget.father.providerName}');
                    debugPrint ("La URL es: $url");
                    final http.Response res = await http.put (
                        url,
                        headers: <String, String>{
                          'Content-Type': 'application/json; charset=UTF-8',
                          //'Authorization': jwt
                        },
                        body: jsonEncode (<String, String> {
                          'product_id': widget.father.productId.toString(),
                          'user_id': widget.userId.toString(),
                          'user_role': widget.userRole.toString(),
                          'new_product_price': _newNewProductPriceFinal.toString(),
                          'total_before_discount': _totalBeforeDiscount.toString(),
                          'total_amount': _totalAmount.toString(),
                          'discount_amount': _discountAmount.toString(),
                          'tax_amount': _taxAmount.toString(),
                          'is_official': _isOfficial.toString(),
                          'case_to_apply': '2',  // Only the price of the purchased has been changed by the user
                          'comment': _comment
                        })
                    );
                    _showPleaseWait(false);
                    if (res.statusCode == 200) {
                      // Process the order
                      debugPrint ('OK. ');
                      // get the list of new states to tansition to
                      final List<Map<String, dynamic>> resultListJson = json.decode(res.body)['statusToTransitionTo'].cast<Map<String, dynamic>>();
                      debugPrint ('Entre medias de la api RESPONSE.');
                      final List<PurchaseStatus> resultListPurchaseStatusToTransitionTo = resultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                      if (resultListPurchaseStatusToTransitionTo.isNotEmpty) {
                        widget.father.possibleStatusToTransitionTo.clear();
                        for (var element in resultListPurchaseStatusToTransitionTo) {
                          widget.father.possibleStatusToTransitionTo.add(element);
                        }
                      }
                      debugPrint ('Despues de retornar los statusToTransitionTo.');
                      // get the values of BAN_PRICE and BAN_QUANTITY among the new state of the modified purchased line, "O" (OBSERVACIONES)
                      final List<Map<String, dynamic>> anotherResultListJson = json.decode(res.body)['currentBanQuantityBanPrice'].cast<Map<String, dynamic>>();
                      debugPrint ('Entre medias de la api RESPONSE.');
                      final List<PurchaseStatus> currentBanPriceBanStatusValues = anotherResultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                      if (currentBanPriceBanStatusValues.isNotEmpty) {
                        widget.father.banQuantity = currentBanPriceBanStatusValues[0].banQuantity;
                        widget.father.banPrice = currentBanPriceBanStatusValues[0].banPrice;
                      }
                      debugPrint ('Despues de retornar los currentBanPriceBanStatusValues.');
                      widget.stateChanged.changed = true;
                      widget.father.totalBeforeDiscountWithoutTax = _totalBeforeDiscountWithoutTax;
                      widget.father.discountAmount = _discountAmount;
                      widget.father.newProductPrice = _newNewProductPriceFinal != -1 ? _newNewProductPriceFinal : widget.father.newProductPrice;
                      debugPrint ('El valor de widget.father.newProductPrice es: ${widget.father.newProductPrice}');
                      widget.father.totalAfterDiscountWithoutTax = _totalAfterDiscountWithoutTax;
                      widget.father.taxAmount = _taxAmount;
                      widget.father.totalAmount = _totalAmount;
                      if (widget.userRole == 'BUYER') {
                        widget.father.remarkBuyer = _comment;
                      } else {
                        widget.father.remarkSeller = _comment;
                      }
                      widget.father.statusId = "O";
                      widget.father.allStatus = "OBSERVACIONES";
                      if (!context.mounted) return;
                      Navigator.pop(context, widget.stateChanged.changed);
                    } else {
                      // Error
                      widget.stateChanged.changed = false;
                      if (!context.mounted) return;
                      ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'].toString());
                    }
                  } else if (widget.father.banQuantity == "SI" && widget.father.banPrice == "NO") {
                    // Case 3
                    // Only the quantity has been changed by the user
                    if (_newNumItemsPurchased != -1) {
                      // the quantity of the purchase line has been changed.
                      // The value -1 is the value if the field NEW_QUANTITY of the KRC_PURCHASE is null,
                      // then it has been not yet modified
                      if (_newNumItemsPurchased != widget.father.newQuantity) {
                        // the quantity of the purchase line has been modified
                        debugPrint ('Entro en el paso 3.');
                        final Uri url = Uri.parse('$SERVER_IP/modifyPurchaseLine/${widget.father.orderId}/${widget.father.providerName}');
                        debugPrint ("La URL es: $url");
                        final http.Response res = await http.put (
                            url,
                            headers: <String, String>{
                              'Content-Type': 'application/json; charset=UTF-8',
                              //'Authorization': jwt
                            },
                            body: jsonEncode (<String, String> {
                              'product_id': widget.father.productId.toString(),
                              'user_id': widget.userId.toString(),
                              'user_role': widget.userRole.toString(),
                              'new_purchased': _newNumItemsPurchased.toString(),
                              'total_before_discount': _totalBeforeDiscount.toString(),
                              'total_amount': _totalAmount.toString(),
                              'discount_amount': _discountAmount.toString(),
                              'tax_amount': _taxAmount.toString(),
                              'case_to_apply': '3', // Only the quantity has been changed by the user
                              'comment': _comment
                            })
                        );
                        _showPleaseWait(false);
                        if (res.statusCode == 200) {
                          // Process the order
                          debugPrint ('OK. ');
                          final List<Map<String, dynamic>> resultListJson = json.decode(res.body)['statusToTransitionTo'].cast<Map<String, dynamic>>();
                          debugPrint ('Entre medias de la api RESPONSE.');
                          final List<PurchaseStatus> resultListPurchaseStatusToTransitionTo = resultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                          if (resultListPurchaseStatusToTransitionTo.isNotEmpty) {
                            widget.father.possibleStatusToTransitionTo.clear();
                            for (var element in resultListPurchaseStatusToTransitionTo) {
                              widget.father.possibleStatusToTransitionTo.add(element);
                            }
                          }
                          debugPrint ('Despues de retornar los statusToTransitionTo.');
                          // get the values of BAN_PRICE and BAN_QUANTITY among the new state of the modified purchased line, "O" (OBSERVACIONES)
                          final List<Map<String, dynamic>> anotherResultListJson = json.decode(res.body)['currentBanQuantityBanPrice'].cast<Map<String, dynamic>>();
                          debugPrint ('Entre medias de la api RESPONSE.');
                          final List<PurchaseStatus> currentBanPriceBanStatusValues = anotherResultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                          if (currentBanPriceBanStatusValues.isNotEmpty) {
                            widget.father.banQuantity = currentBanPriceBanStatusValues[0].banQuantity;
                            widget.father.banPrice = currentBanPriceBanStatusValues[0].banPrice;
                          }
                          debugPrint ('Despues de retornar los currentBanPriceBanStatusValues.');
                          widget.stateChanged.changed = true;
                          //widget.father.items = widget.productItem.purchased;
                          widget.father.newQuantity = _newNumItemsPurchased;
                          debugPrint ("El valor de widget.father.newQuantity es: ${widget.father.newQuantity}");
                          widget.father.totalBeforeDiscountWithoutTax = _totalBeforeDiscountWithoutTax;
                          widget.father.discountAmount = _discountAmount;
                          widget.father.totalAfterDiscountWithoutTax = _totalAfterDiscountWithoutTax;
                          widget.father.taxAmount = _taxAmount;
                          widget.father.totalAmount = _totalAmount;
                          if (widget.userRole == 'BUYER') {
                            widget.father.remarkBuyer = _comment;
                          } else {
                            widget.father.remarkSeller = _comment;
                          }
                          widget.father.statusId = "O";
                          widget.father.allStatus = "OBSERVACIONES";
                          if (!context.mounted) return;
                          Navigator.pop(context, widget.stateChanged.changed);
                        } else {
                          // Error
                          widget.stateChanged.changed = false;
                          if (!context.mounted) return;
                          ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'].toString());
                        }
                      } else {
                        // Finally the quantity of the purchase line has not been changed.
                        widget.stateChanged.changed = false;
                        Navigator.pop(context, widget.stateChanged.changed);
                      }
                    } else {
                      // the quantity of the purchase line has not yet been changed.
                      if (widget.father.items != widget.productItem.purchased) {
                        // The quantity has been modified by the user
                        debugPrint ('Entro en el paso 3.');
                        final Uri url = Uri.parse('$SERVER_IP/modifyPurchaseLine/${widget.father.orderId}/${widget.father.providerName}');
                        debugPrint ("La URL es: $url");
                        final http.Response res = await http.put (
                            url,
                            headers: <String, String>{
                              'Content-Type': 'application/json; charset=UTF-8',
                              //'Authorization': jwt
                            },
                            body: jsonEncode (<String, String> {
                              'product_id': widget.father.productId.toString(),
                              'user_id': widget.userId.toString(),
                              'user_role': widget.userRole.toString(),
                              'new_purchased': (widget.productItem.purchased != widget.father.items ? widget.productItem.purchased.toString() : null)!,
                              'total_before_discount': _totalBeforeDiscount.toString(),
                              'total_amount': _totalAmount.toString(),
                              'discount_amount': _discountAmount.toString(),
                              'tax_amount': _taxAmount.toString(),
                              'case_to_apply': '3', // Only the quantity has been changed by the user
                              'comment': _comment
                            })
                        );
                        _showPleaseWait(false);
                        if (res.statusCode == 200) {
                          // Process the order
                          debugPrint ('OK. ');
                          final List<Map<String, dynamic>> resultListJson = json.decode(res.body)['statusToTransitionTo'].cast<Map<String, dynamic>>();
                          debugPrint ('Entre medias de la api RESPONSE.');
                          final List<PurchaseStatus> resultListPurchaseStatusToTransitionTo = resultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                          if (resultListPurchaseStatusToTransitionTo.isNotEmpty) {
                            widget.father.possibleStatusToTransitionTo.clear();
                            for (var element in resultListPurchaseStatusToTransitionTo) {
                              widget.father.possibleStatusToTransitionTo.add(element);
                            }
                          }
                          debugPrint ('Despues de retornar los statusToTransitionTo.');
                          // get the values of BAN_PRICE and BAN_QUANTITY among the new state of the modified purchased line, "O" (OBSERVACIONES)
                          final List<Map<String, dynamic>> anotherResultListJson = json.decode(res.body)['currentBanQuantityBanPrice'].cast<Map<String, dynamic>>();
                          debugPrint ('Entre medias de la api RESPONSE.');
                          final List<PurchaseStatus> currentBanPriceBanStatusValues = anotherResultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                          if (currentBanPriceBanStatusValues.isNotEmpty) {
                            widget.father.banQuantity = currentBanPriceBanStatusValues[0].banQuantity;
                            widget.father.banPrice = currentBanPriceBanStatusValues[0].banPrice;
                          }
                          debugPrint ('Despues de retornar los currentBanPriceBanStatusValues.');
                          widget.stateChanged.changed = true;
                          widget.father.newQuantity = widget.productItem.purchased != widget.father.items ? widget.productItem.purchased : -1;
                          debugPrint ("El valor de widget.father.newQuantity es: ${widget.father.newQuantity}");
                          widget.father.totalBeforeDiscountWithoutTax = _totalBeforeDiscountWithoutTax;
                          widget.father.discountAmount = _discountAmount;
                          widget.father.totalAfterDiscountWithoutTax = _totalAfterDiscountWithoutTax;
                          widget.father.taxAmount = _taxAmount;
                          widget.father.totalAmount = _totalAmount;
                          if (widget.userRole == 'BUYER') {
                            widget.father.remarkBuyer = _comment;
                          } else {
                            widget.father.remarkSeller = _comment;
                          }
                          widget.father.statusId = "O";
                          widget.father.allStatus = "OBSERVACIONES";
                          if (!context.mounted) return;
                          Navigator.pop(context, widget.stateChanged.changed);
                        } else {
                          // Error
                          widget.stateChanged.changed = false;
                          if (!context.mounted) return;
                          ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'].toString());
                        }
                      } else {
                        // Finally the quantity of the purchase line has not been changed.
                        widget.stateChanged.changed = false;
                        Navigator.pop(context, widget.stateChanged.changed);
                      }
                    }
                  } else {
                    // Case 4
                    // There is no change by the user
                    debugPrint ('Entro en el paso 4');
                    widget.stateChanged.changed = false;
                    Navigator.pop(context, widget.stateChanged.changed);
                  }
                } catch (e) {
                  _showPleaseWait(false);
                  widget.stateChanged.changed = false;
                  if (!context.mounted) return;
                  ShowSnackBar.showSnackBar(context, e.toString(), error: true);
                }
              },
            ),
          ],
        )
    );
    if (widget.father.banQuantity == "SI" && widget.father.banPrice == "NO") {
      // Case 3
      // Only the quantity has been changed by the user
      return SafeArea (
          child: LayoutBuilder(
            builder: (context, constraints) {
              final List<String> listImagesProduct = [];
              for (var i = 0; i < widget.productItem.numImages; i++){
                listImagesProduct.add('$SERVER_IP$IMAGES_DIRECTORY${widget.productItem.productCode}_$i.gif');
              }
              return ListView (
                children: [
                  widget.productItem.numImages > 1 ? Column (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CarouselSlider (
                        items: listImagesProduct.map((url) => AspectRatio (
                          aspectRatio: 3.0 / 2.0,
                          child: CachedNetworkImage(
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            imageUrl: url,
                            fit: BoxFit.scaleDown,
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        )
                        ).toList(),
                        options: CarouselOptions(
                            autoPlay: true,
                            enlargeCenterPage: true,
                            aspectRatio: 2.0,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _current = index;
                              });
                            }
                        ),
                      ),
                      Row (
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: listImagesProduct.map((url) {
                          int index = listImagesProduct.indexOf(url);
                          return Container(
                            width: 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _current == index
                                    ? const Color.fromRGBO(0, 0, 0, 0.9)
                                    : const Color.fromRGBO(0, 0, 0, 0.4)
                            ),
                          );
                        }).toList(),
                      )
                    ],
                  ) : Container(
                    alignment: Alignment.center,
                    width: constraints.maxWidth,
                    child: AspectRatio(
                      aspectRatio: 3.0 / 2.0,
                      child: CachedNetworkImage(
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        imageUrl: '$SERVER_IP$IMAGES_DIRECTORY${widget.productItem.productCode}_0.gif',
                        fit: BoxFit.scaleDown,
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    ),
                  ),
                  SizedBox (height: constraints.maxHeight * HeightInDpis_2),
                  Padding (
                    padding: const EdgeInsets.fromLTRB (15.0, 0.0, 15.0, 0.0),
                    child: Row (
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                          child: Image.asset ('assets/images/00002.png'),
                        ),
                        Padding (
                          padding: const EdgeInsets.only(right: 15.0),
                          child: widget.father.newProductPrice != -1 ? Text.rich (
                              TextSpan (
                                  text: NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.father.newProductPrice/MULTIPLYING_FACTOR).toString())),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 40.0,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                  children: <TextSpan>[
                                    TextSpan (
                                        text: '${' (${NumberFormat("##0.00", "es_ES").format(double.parse((widget.father.productPrice/MULTIPLYING_FACTOR).toString()))}'})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 30.0,
                                          fontFamily: 'SF Pro Display',
                                        )
                                    ),
                                  ]
                              )
                          ) : Text(
                              NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.father.productPrice/MULTIPLYING_FACTOR).toString())),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 40.0,
                                fontFamily: 'SF Pro Display',
                              ),
                              textAlign: TextAlign.start
                          ),
                        ),
                      ],
                    ),
                  ),
                  //SizedBox(height: 4.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_4),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        width: constraints.maxWidth,
                        child: Text(
                          widget.productItem.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      )
                    ],
                  ),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container (
                        padding: const EdgeInsets.only(left: 24.0),
                        width: constraints.maxWidth,
                        child: Text(
                          widget.productItem.businessName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 24.0,
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
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container (
                        padding: const EdgeInsets.only(left: 24),
                        child: Text(
                          'Unids. mínim. venta: ${widget.productItem.minQuantitySell} ${(widget.productItem.minQuantitySell > 1) ? '${widget.productItem.idUnit}s.' : '${widget.productItem.idUnit}.'}',
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
                      ),
                    ],
                  ),
                  SizedBox (height: constraints.maxHeight * HeightInDpis_35),
                  const Center (
                    child: Text (
                      'Cantidad',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Color(0xFF6C6D77),
                      ),
                    ),
                  ),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton (
                          onPressed: () {
                            if (_newNumItemsPurchased != -1) {
                              // the quantity of the purchase line has been changed.
                              // The value -1 is the value when the field NEW_QUANTITY of the KRC_PURCHASE is null,
                              // then it has been not yet modified
                              if (widget.father.newProductPrice != -1) {
                                if (_newNumItemsPurchased > 0) {
                                  setState (() {
                                    _newNumItemsPurchased = _newNumItemsPurchased - widget.productItem.minQuantitySell;
                                    if (_newNumItemsPurchased < 0) _newNumItemsPurchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = _newNumItemsPurchased * (_newNewProductPriceFinal * (widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              } else {
                                if (_newNumItemsPurchased > 0) {
                                  setState (() {
                                    _newNumItemsPurchased = _newNumItemsPurchased - widget.productItem.minQuantitySell;
                                    if (_newNumItemsPurchased < 0) _newNumItemsPurchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                  //_totalBeforeDiscountWithoutTax = _newNumItemsPurchased * (widget.father.totalBeforeDiscountWithoutTax / widget.father.items);
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice*(1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  //_discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  _discountAmount = 0;  // If widget.father.newProductPrice means that there si no discount
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = _newNumItemsPurchased * (widget.father.productPrice*(widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              }
                            } else {
                              // the quantity of the purchase line has not yet been changed.
                              if (widget.father.newProductPrice != -1) {
                                if (widget.productItem.purchased > 0) {
                                  setState (() {
                                    widget.productItem.purchased = widget.productItem.purchased - widget.productItem.minQuantitySell;
                                    if (widget.productItem.purchased < 0) widget.productItem.purchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = widget.productItem.purchased * (_newNewProductPriceFinal * (widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              } else {
                                if (widget.productItem.purchased > 0) {
                                  setState (() {
                                    widget.productItem.purchased = widget.productItem.purchased - widget.productItem.minQuantitySell;
                                    if (widget.productItem.purchased < 0) widget.productItem.purchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  //_discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  _discountAmount = 0;  // If widget.father.newProductPrice means that there si no discount
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = widget.productItem.purchased * (widget.father.productPrice*(widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              }
                            }
                          },
                          child: Container (
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(2.0),
                            decoration: BoxDecoration (
                                color: tanteLadenAmber500,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: tanteLadenButtonBorderGray,
                                    width: 1
                                )
                            ),
                            child: Container(
                              width: 40.0,
                              height: 40.0,
                              alignment: Alignment.center,
                              child: const Text(
                                '-',
                                style: TextStyle(
                                    fontWeight: FontWeight.w300,
                                    fontSize: 24.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: tanteLadenButtonBorderGray
                                ),
                              ),
                            ),
                          )
                      ),
                      Padding (
                        //padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                        padding: const EdgeInsets.only(left: WithInDpis_20, right: WithInDpis_20),
                        child: RichText (
                            text: TextSpan (
                                text: widget.father.newQuantity != -1
                                    ? '$_newNumItemsPurchased (${widget.productItem.purchased}) '
                                    : widget.productItem.purchased.toString(),
                                style: const TextStyle (
                                  fontWeight: FontWeight.w700,
                                  fontSize: 24.0,
                                  fontFamily: 'SF Pro Display',
                                  fontStyle: FontStyle.normal,
                                  color: Colors.black,
                                ),
                                children: <TextSpan>[
                                  TextSpan (
                                      text: widget.father.newQuantity != -1
                                          ? _newNumItemsPurchased > 1 ? ' ${widget.productItem.idUnit}s.' : ' ${widget.productItem.idUnit}.'
                                          : widget.productItem.purchased > 1 ? ' ${widget.productItem.idUnit}s.' : ' ${widget.productItem.idUnit}.',
                                      style: const TextStyle (
                                          fontWeight: FontWeight.bold
                                      )
                                  )
                                ]
                            )
                        ),
                      ),
                      TextButton(
                          onPressed: () {
                            if (_newNumItemsPurchased != -1) {
                              // the quantity of the purchase line has been changed.
                              // The value -1 is the value when the field NEW_QUANTITY of the KRC_PURCHASE is null,
                              // then it has been not yet modified
                              if(widget.father.newProductPrice != -1) {
                                if (_newNumItemsPurchased > 0) {
                                  setState (() {
                                    _newNumItemsPurchased = _newNumItemsPurchased + widget.productItem.minQuantitySell;
                                  });
                                  _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = _newNumItemsPurchased * (_newNewProductPriceFinal * (widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              } else {
                                if (_newNumItemsPurchased > 0) {
                                  setState (() {
                                    _newNumItemsPurchased = _newNumItemsPurchased + widget.productItem.minQuantitySell;
                                  });
                                  _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                  //_totalBeforeDiscountWithoutTax = _newNumItemsPurchased * (widget.father.totalBeforeDiscountWithoutTax / widget.father.items);
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice*(1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  _discountAmount = 0;  // If widget.father.newProductPrice means that there si no discount
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = _newNumItemsPurchased * (widget.father.productPrice*(widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              }
                            } else {
                              // the quantity of the purchase line has not yet been changed.
                              if (widget.father.newProductPrice != -1) {
                                if (widget.productItem.purchased > 0) {
                                  setState (() {
                                    widget.productItem.purchased = widget.productItem.purchased + widget.productItem.minQuantitySell;
                                  });
                                  _totalBeforeDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = widget.productItem.purchased * (_newNewProductPriceFinal * (widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              } else {
                                if (widget.productItem.purchased > 0) {
                                  setState (() {
                                    widget.productItem.purchased = widget.productItem.purchased + widget.productItem.minQuantitySell;
                                  });
                                  _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice*(1+(widget.productItem.taxApply/100)));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  _discountAmount = 0;  // If widget.father.newProductPrice means that there si no discount
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  _taxAmount = widget.productItem.purchased * (widget.father.productPrice*(widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              }
                            }
                          },
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(2.0),
                            decoration: BoxDecoration(
                              color: tanteLadenAmber500,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF6C6D77),
                                width: 1,
                              ),
                            ),
                            child: Container(
                              width: 40.0,
                              height: 40.0,
                              alignment: Alignment.center,
                              child: const Text(
                                '+',
                                style: TextStyle(
                                  fontWeight: FontWeight.w300,
                                  fontSize: 24.0,
                                  fontFamily: 'SF Pro Display',
                                  fontStyle: FontStyle.normal,
                                  color: tanteLadenButtonBorderGray,
                                ),
                              ),
                            ),
                          )
                      )
                    ],
                  ),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: Image.asset (
                          'assets/images/logoComment.png',
                          fit: BoxFit.scaleDown,
                          width: 20.0,
                          height: 20.0,
                        ),
                      ),
                      Container (
                        padding: const EdgeInsets.only(left:8),
                        child: Text.rich(
                            TextSpan (
                                text: 'Introducir comentario',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: tanteLadenIconBrown,
                                    decoration: TextDecoration.underline
                                ),
                                recognizer: TapGestureRecognizer ()
                                  ..onTap = () async {
                                    _comment = await Navigator.push (context, MaterialPageRoute (
                                        builder: (context) => AddComment (_comment)
                                    ));
                                  }
                            )
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  _pleaseWait ? Stack(
                    key: const ObjectKey ("stack"),
                    alignment: AlignmentDirectional.center,
                    children: [
                      tmpBuilder,
                      _pleaseWaitWidget
                    ],
                  ): Stack(
                    key: const ObjectKey("stack"),
                    children: [tmpBuilder],
                  ),
                  //SizedBox(height: 35.0),
                ],
              );
            },
          )
      );
    } else if (widget.father.banQuantity == "NO" && widget.father.banPrice == "SI") {
      // Case 2
      // Only the price of the purchased has been changed by the user
      return SafeArea (
          child: LayoutBuilder (
            builder: (context, constraints) {
              final List<String> listImagesProduct = [];
              for (var i = 0; i < widget.productItem.numImages; i++) {
                listImagesProduct.add('$SERVER_IP$IMAGES_DIRECTORY${widget.productItem.productCode}_$i.gif');
              }
              return ListView (
                children: [
                  widget.productItem.numImages > 1 ? Column (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CarouselSlider (
                        items: listImagesProduct.map((url) => AspectRatio (
                          aspectRatio: 3.0 / 2.0,
                          child: CachedNetworkImage (
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            imageUrl: url,
                            fit: BoxFit.scaleDown,
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        )
                        ).toList(),
                        options: CarouselOptions(
                            autoPlay: true,
                            enlargeCenterPage: true,
                            aspectRatio: 2.0,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _current = index;
                              });
                            }
                        ),
                      ),
                      Row (
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: listImagesProduct.map((url) {
                          int index = listImagesProduct.indexOf(url);
                          return Container(
                            width: 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _current == index
                                    ? const Color.fromRGBO(0, 0, 0, 0.9)
                                    : const Color.fromRGBO(0, 0, 0, 0.4)
                            ),
                          );
                        }).toList(),
                      )
                    ],
                  ) : Container (
                    alignment: Alignment.center,
                    width: constraints.maxWidth,
                    child: AspectRatio(
                      aspectRatio: 3.0 / 2.0,
                      child: CachedNetworkImage(
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        imageUrl: '$SERVER_IP$IMAGES_DIRECTORY${widget.productItem.productCode}_0.gif',
                        fit: BoxFit.scaleDown,
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    ),
                  ),
                  SizedBox (height: constraints.maxHeight * HeightInDpis_2),
                  Padding(
                    padding: const EdgeInsets.fromLTRB (15.0, 0.0, 15.0, 0.0),
                    child: Row (
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                          child: Image.asset ('assets/images/00002.png'),
                        ),
                        Padding (
                          padding: const EdgeInsets.only(right: 15.0),
                          child: _newNewProductPriceFinal != -1 ? Text.rich (
                              TextSpan (
                                  text: NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((_newNewProductPriceFinal/MULTIPLYING_FACTOR).toString())),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 40.0,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                        text: '${' (${NumberFormat("##0.00", "es_ES").format(double.parse((widget.father.productPrice/MULTIPLYING_FACTOR).toString()))}'})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 30.0,
                                          fontFamily: 'SF Pro Display',
                                        )
                                    )
                                  ]
                              )
                          ) : Text(
                              NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((_newPrice/MULTIPLYING_FACTOR).toString())),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 40.0,
                                fontFamily: 'SF Pro Display',
                              ),
                              textAlign: TextAlign.start
                          ),
                        ),
                      ],
                    ),
                  ),
                  //SizedBox(height: 4.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_4),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        width: constraints.maxWidth,
                        child: Text(
                          widget.productItem.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      )
                    ],
                  ),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        width: constraints.maxWidth,
                        child: Text(
                          widget.productItem.businessName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 24.0,
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
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container (
                        padding: const EdgeInsets.only(left: 24),
                        child: Text(
                          'Unids. mínim. venta: ${widget.productItem.minQuantitySell}',
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
                      ),
                    ],
                  ),
                  //SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  const Divider (thickness: 2.0,),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container (
                        padding: const EdgeInsets.only(left: 24),
                        child: const Text (
                          'Modificación del precio por: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded (
                          flex: 1,
                          child: ListTile(
                            title: const Text('Valor'),
                            leading: Radio<PriceChangeType>(
                              value: PriceChangeType.priceValue,
                              groupValue: _changeType,
                              onChanged: (PriceChangeType? value){
                                setState(() {
                                  _changeType = value!;
                                  _valueDiscount = 0.0;
                                  _percentDiscount = 0.0;
                                  _newNewProductPriceFinal = widget.father.newProductPrice;
                                });
                                _valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                _percentDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
                              },
                            ),
                          )
                      ),
                      Expanded (
                          flex: 1,
                          child: ListTile(
                            title: const Text('Porcentaje'),
                            leading: Radio<PriceChangeType>(
                              value: PriceChangeType.percentValue,
                              groupValue: _changeType,
                              onChanged: (PriceChangeType? value){
                                setState(() {
                                  _changeType = value!;
                                  _percentDiscount = 0.0;
                                  _valueDiscount = 0.0;
                                  _newNewProductPriceFinal = widget.father.newProductPrice;
                                });
                                _percentDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
                                _valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                              },
                            ),
                          )
                      )
                    ],
                  ),
                  const Divider(thickness: 2.0,),
                  (_changeType == PriceChangeType.priceValue) ? const Center (
                    child: Text(
                      'Modificación neta',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Color(0xFF6C6D77),
                      ),
                    ),
                  ) : const Center (
                    child: Text (
                      'Modificación porcentual',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Color(0xFF6C6D77),
                      ),
                    ),
                  ),
                  (_changeType == PriceChangeType.priceValue) ? Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded (
                          flex:1,
                          child: Container()
                      ),
                      Expanded (
                        flex:4,
                        child: Row (
                          children: [
                            Expanded (
                              flex: 1,
                              child: TextButton (
                                  onPressed: () {
                                    debugPrint ('Estoy en el onPressed de -');
                                    if (widget.father.newProductPrice != -1) {
                                      // the price has been previously modified
                                      debugPrint ('Estoy en el onPressed de -. Dentro de la parte de que el precio ha sido previamente modificado.');
                                      final double tmpValueDiscount = _valueDiscount;
                                      _valueDiscount = _valueDiscount - 0.1;
                                      if (widget.father.newProductPrice >= (_valueDiscount * MULTIPLYING_FACTOR).abs()) {
                                        // the price can't be negative
                                        setState(() {
                                          _valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                        });
                                      } else {
                                        _valueDiscount = tmpValueDiscount;
                                      }
                                    } else {
                                      // the price has not yet modified
                                      //debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
                                      debugPrint ('Estoy en el onPressed de -. Dentro de la parte de que el precio nunca ha sido previamente modificado.');
                                      final double tmpValueDiscount = _valueDiscount;
                                      _valueDiscount = _valueDiscount - 0.1;
                                      debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
                                      if (widget.father.productPrice >= (_valueDiscount * MULTIPLYING_FACTOR).abs()) {
                                        // the price can't be negative
                                        setState(() {
                                          _valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                        });
                                      } else {
                                        _valueDiscount = tmpValueDiscount;
                                      }
                                    }
                                  },
                                  child: Container (
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration (
                                        color: tanteLadenAmber500,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: tanteLadenButtonBorderGray,
                                            width: 1
                                        )
                                    ),
                                    child: Container (
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '-',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w300,
                                            fontSize: 24.0,
                                            fontFamily: 'SF Pro Display',
                                            fontStyle: FontStyle.normal,
                                            color: tanteLadenButtonBorderGray
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            ),
                            Expanded (
                              flex: 2,
                              child: Form (
                                key: _formNewPricekey,
                                child: TextFormField(
                                  controller: _valueDiscountTextField,
                                  decoration: const InputDecoration (
                                      prefixIcon: Icon(Icons.euro_rounded)
                                  ),
                                  style: const TextStyle (
                                    fontWeight: FontWeight.w700,
                                    fontSize: 24.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$')),],
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (String? value) {
                                    RegExp regexp = RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$');
                                    if (!regexp.hasMatch(value!)) {
                                      return 'Introduce un valor neto válido. Formato: (+/-)##,##';
                                    } else {
                                      return null;
                                    }
                                  },
                                ),
                              ),
                            ),
                            Expanded (
                              flex: 1,
                              child: TextButton(
                                  onPressed: () {
                                    debugPrint ('Estoy en el onPressed de +');
                                    if (widget.father.newProductPrice != -1) {
                                      // the price has been previously modified
                                      debugPrint ('Estoy en el onPressed de +. Dentro de la parte de que el precio ha sido previamente modificado.');
                                      _valueDiscount = _valueDiscount + 0.1;
                                      setState(() {
                                        _valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                      });
                                    } else {
                                      // the price has not yet modified
                                      //debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
                                      debugPrint ('Estoy en el onPressed de +. Dentro de la parte de que el precio nunca ha sido previamente modificado.');
                                      _valueDiscount = _valueDiscount + 0.1;
                                      debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
                                      setState(() {
                                        _valueDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                      });
                                    }
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration(
                                      color: tanteLadenAmber500,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF6C6D77),
                                        width: 1,
                                      ),
                                    ),
                                    child: Container(
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '+',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 24.0,
                                          fontFamily: 'SF Pro Display',
                                          fontStyle: FontStyle.normal,
                                          color: tanteLadenButtonBorderGray,
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded (
                          flex:1,
                          child: Container()
                      )
                    ],
                  ) : Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded (
                          flex:1,
                          child: Container()
                      ),
                      Expanded (
                        flex:4,
                        child: Row (
                          children: [
                            Expanded (
                              flex: 1,
                              child: TextButton(
                                  onPressed: () {
                                    if (widget.father.newProductPrice != -1) {
                                      // the price has been previously modified
                                      debugPrint ('Estoy en el onPressed de -. Dentro de la parte de que el precio ha sido previamente modificado.');
                                      final double tmpPercentDiscount = _percentDiscount;
                                      _percentDiscount = _percentDiscount - 0.5;
                                      debugPrint ('El valor de _percentDiscount es: $_percentDiscount');
                                      debugPrint ('El valor de productPrice es: ${widget.father.productPrice}');
                                      debugPrint ('El valor de widget.father.productPrice * (1+(_percentDiscount/100)) es: ${((widget.father.productPrice * (1+(_percentDiscount/100)))).abs()}');
                                      if (widget.father.newProductPrice >= ((widget.father.newProductPrice * (1+(_percentDiscount/100)))).abs()) {
                                        setState(() {
                                          _percentDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse((_percentDiscount).toString()));
                                        });
                                      } else {
                                        _percentDiscount = tmpPercentDiscount;
                                      }
                                    } else {
                                      // the price has not yet modified
                                      debugPrint ('Estoy en el onPressed de -. Dentro de la parte de que el precio nunca ha sido previamente modificado.');
                                      final double tmpPercentDiscount = _percentDiscount;
                                      _percentDiscount = _percentDiscount - 0.5;
                                      debugPrint ('El valor de _percentDiscount es: $_percentDiscount');
                                      debugPrint ('El valor de productPrice es: ${widget.father.productPrice}');
                                      debugPrint ('El valor de widget.father.productPrice * (1+(_percentDiscount/100)) es: ${((widget.father.productPrice * (1+(_percentDiscount/100)))).abs()}');
                                      if (widget.father.productPrice >= ((widget.father.productPrice * (1+(_percentDiscount/100)))).abs()) {
                                        setState(() {
                                          _percentDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse((_percentDiscount).toString()));
                                        });
                                      } else {
                                        _percentDiscount = tmpPercentDiscount;
                                      }
                                    }
                                  },
                                  child: Container (
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration (
                                        color: tanteLadenAmber500,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: tanteLadenButtonBorderGray,
                                            width: 1
                                        )
                                    ),
                                    child: Container(
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '-',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w300,
                                            fontSize: 24.0,
                                            fontFamily: 'SF Pro Display',
                                            fontStyle: FontStyle.normal,
                                            color: tanteLadenButtonBorderGray
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            ),
                            Expanded (
                              flex: 2,
                              child: Form(
                                key: _formPercentKey,
                                child: TextFormField(
                                  controller: _percentDiscountTextField,
                                  decoration: const InputDecoration (
                                    prefixText: '  %  ',
                                    prefixStyle: TextStyle (
                                      fontWeight: FontWeight.w700,
                                      fontSize: 24.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.black45,
                                    ),
                                  ),
                                  style: const TextStyle (
                                    fontWeight: FontWeight.w700,
                                    fontSize: 24.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$')),],
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (String? value) {
                                    RegExp regexp = RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$');
                                    if (!regexp.hasMatch(value!)) {
                                      return 'Introduce un porcentaje válido. Formato: (+/-)##,##';
                                    } else {
                                      return null;
                                    }
                                  },
                                ),
                              ),
                            ),
                            Expanded (
                              flex: 1,
                              child: TextButton(
                                  onPressed: () {
                                    if (widget.father.newProductPrice != -1) {
                                      // the price has been previously modified
                                      debugPrint ('Estoy en el onPressed de +. Dentro de la parte de que el precio ha sido previamente modificado.');
                                      _percentDiscount = _percentDiscount + 0.5;
                                      debugPrint ('El valor de _percentDiscount es: $_percentDiscount');
                                      debugPrint ('El valor de productPrice es: ${widget.father.productPrice}');
                                      debugPrint ('El valor de widget.father.productPrice * (1+(_percentDiscount/100)) es: ${((widget.father.productPrice * (1+(_percentDiscount/100)))).abs()}');
                                      setState(() {
                                        _percentDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse((_percentDiscount).toString()));
                                      });
                                    } else {
                                      // the price has not yet modified
                                      debugPrint ('Estoy en el onPressed de +. Dentro de la parte de que el precio nunca ha sido previamente modificado.');
                                      _percentDiscount = _percentDiscount + 0.5;
                                      debugPrint ('El valor de _percentDiscount es: $_percentDiscount');
                                      debugPrint ('El valor de productPrice es: ${widget.father.productPrice}');
                                      debugPrint ('El valor de widget.father.productPrice * (1+(_percentDiscount/100)) es: ${((widget.father.productPrice * (1+(_percentDiscount/100)))).abs()}');
                                      setState(() {
                                        _percentDiscountTextField.text = NumberFormat('##0.00', 'es_ES').format(double.parse((_percentDiscount).toString()));
                                      });
                                    }
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration(
                                      color: tanteLadenAmber500,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF6C6D77),
                                        width: 1,
                                      ),
                                    ),
                                    child: Container(
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '+',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 24.0,
                                          fontFamily: 'SF Pro Display',
                                          fontStyle: FontStyle.normal,
                                          color: tanteLadenButtonBorderGray,
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded (
                          flex:1,
                          child: Container()
                      )
                    ],
                  ),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: Image.asset (
                          'assets/images/logoComment.png',
                          fit: BoxFit.scaleDown,
                          width: 20.0,
                          height: 20.0,
                        ),
                      ),
                      Container (
                        padding: const EdgeInsets.only(left:8),
                        child: Text.rich(
                            TextSpan (
                                text: 'Introducir comentario',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: tanteLadenIconBrown,
                                    decoration: TextDecoration.underline
                                ),
                                recognizer: TapGestureRecognizer ()
                                  ..onTap = () async {
                                    _comment = await Navigator.push (context, MaterialPageRoute (
                                        builder: (context) => AddComment (_comment)
                                    ));
                                  }
                            )
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container (
                          padding: const EdgeInsets.only(left: 24),
                          child: Checkbox (
                            checkColor: Colors.white,
                            fillColor: MaterialStateProperty.resolveWith(getColor),
                            value: _isOfficial,
                            onChanged: (bool? value) {
                              setState(() {
                                _isOfficial = value!;
                              });
                            },
                          )
                      ),
                      const Text (
                        'Oficializar el nuevo precio.',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14.0,
                          fontFamily: 'SF Pro Display',
                          fontStyle: FontStyle.normal,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ],
                  ),
                  _pleaseWait ? Stack (
                    key: const ObjectKey ("stack"),
                    alignment: AlignmentDirectional.center,
                    children: [
                      tmpBuilder,
                      _pleaseWaitWidget
                    ],
                  ): Stack (
                    key: const ObjectKey("stack"),
                    children: [tmpBuilder],
                  ),
                  //SizedBox(height: 35.0),
                ],
              );
            },
          )
      );
    } else {    // widget.father.banQuantity == "SI" && widget.father.banPrice == "SI"
      return SafeArea (
          child: LayoutBuilder(
            builder: (context, constraints) {
              final List<String> listImagesProduct = [];
              for (var i = 0; i < widget.productItem.numImages; i++) {
                listImagesProduct.add('$SERVER_IP$IMAGES_DIRECTORY${widget.productItem.productCode}_$i.gif');
              }
              return ListView (
                children: [
                  widget.productItem.numImages > 1 ? Column (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CarouselSlider (
                        items: listImagesProduct.map((url) => AspectRatio (
                          aspectRatio: 3.0 / 2.0,
                          child: CachedNetworkImage(
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            imageUrl: url,
                            fit: BoxFit.scaleDown,
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        )
                        ).toList(),
                        options: CarouselOptions(
                            autoPlay: true,
                            enlargeCenterPage: true,
                            aspectRatio: 2.0,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _current = index;
                              });
                            }
                        ),
                      ),
                      Row (
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: listImagesProduct.map((url) {
                          int index = listImagesProduct.indexOf(url);
                          return Container(
                            width: 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _current == index
                                    ? const Color.fromRGBO(0, 0, 0, 0.9)
                                    : const Color.fromRGBO(0, 0, 0, 0.4)
                            ),
                          );
                        }).toList(),
                      )
                    ],
                  ) : Container(
                    alignment: Alignment.center,
                    width: constraints.maxWidth,
                    child: AspectRatio(
                      aspectRatio: 3.0 / 2.0,
                      child: CachedNetworkImage(
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        imageUrl: '$SERVER_IP$IMAGES_DIRECTORY${widget.productItem.productCode}_0.gif',
                        fit: BoxFit.scaleDown,
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    ),
                  ),
                  SizedBox (height: constraints.maxHeight * HeightInDpis_2),
                  Padding(
                    padding: const EdgeInsets.fromLTRB (15.0, 0.0, 15.0, 0.0),
                    child: Row (
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                          child: Image.asset ('assets/images/00002.png'),
                        ),
                        Padding (
                          padding: const EdgeInsets.only(right: 15.0),
                          child: _newNewProductPriceFinal != -1 ? Text.rich (
                              TextSpan (
                                  text: NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((_newNewProductPriceFinal/MULTIPLYING_FACTOR).toString())),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 40.0,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                        text: '${' (${NumberFormat("##0.00", "es_ES").format(double.parse((widget.father.productPrice/MULTIPLYING_FACTOR).toString()))}'})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 30.0,
                                          fontFamily: 'SF Pro Display',
                                        )
                                    )
                                  ]
                              )
                          ) : Text(
                              NumberFormat.currency(locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((_newPrice/MULTIPLYING_FACTOR).toString())),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 40.0,
                                fontFamily: 'SF Pro Display',
                              ),
                              textAlign: TextAlign.start
                          ),
                        ),
                      ],
                    ),
                  ),
                  //SizedBox(height: 4.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        width: constraints.maxWidth,
                        child: Text(
                          widget.productItem.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      )
                    ],
                  ),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  //SizedBox(height: 2.0),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_2),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        width: constraints.maxWidth,
                        child: Text(
                          widget.productItem.businessName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 24.0,
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
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container (
                        padding: const EdgeInsets.only(left: 24),
                        child: Text(
                          'Unids. mínim. venta: ${widget.productItem.minQuantitySell} ${(widget.productItem.minQuantitySell > 1) ? '${widget.productItem.idUnit}s.' : '${widget.productItem.idUnit}.'}',
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
                      ),
                    ],
                  ),
                  //Divider (thickness: 8.0,),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  const Center(
                    child: Text(
                      'Cantidad',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Color(0xFF6C6D77),
                      ),
                    ),
                  ),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton (
                          onPressed: () {
                            if (widget.father.newQuantity != -1) {
                              // the quantity of the purchase line has been changed.
                              // The value -1 is the value if the field NEW_QUANTITY of the KRC_PURCHASE is null,
                              // then it has been not yet modified
                              if (_newNewProductPriceFinal != -1) {
                                if (_newNumItemsPurchased > 0) {
                                  setState (() {
                                    _newNumItemsPurchased = _newNumItemsPurchased - widget.productItem.minQuantitySell;
                                    if (_newNumItemsPurchased < 0) _newNumItemsPurchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  final double productPriceDiscounted = (_newNewProductPriceFinal + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                  debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
                                  _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                  debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                  _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              } else {
                                if (_newNumItemsPurchased > 0) {
                                  setState (() {
                                    _newNumItemsPurchased = _newNumItemsPurchased - widget.productItem.minQuantitySell;
                                    if (_newNumItemsPurchased < 0) _newNumItemsPurchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice*(1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                  _discountAmount = _newNumItemsPurchased * (((_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal) - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = _newNumItemsPurchased * (_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal);
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                  debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                  _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              }
                            } else {
                              // the quantity of the purchase line has not yet been changed.
                              if (_newNewProductPriceFinal != -1) {
                                if (widget.productItem.purchased > 0) {
                                  setState (() {
                                    widget.productItem.purchased = widget.productItem.purchased - widget.productItem.minQuantitySell;
                                    if (widget.productItem.purchased < 0) widget.productItem.purchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  final double productPriceDiscounted = (_newNewProductPriceFinal + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                  debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
                                  _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                  debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                  _taxAmount = widget.productItem.purchased * taxAmountByProduct;
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              } else {
                                if (widget.productItem.purchased > 0) {
                                  setState (() {
                                    widget.productItem.purchased = widget.productItem.purchased - widget.productItem.minQuantitySell;
                                    if (widget.productItem.purchased < 0) widget.productItem.purchased = 0;
                                  });
                                  _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                  debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                  _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                  debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                  _discountAmount = widget.productItem.purchased * (((_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal) - widget.father.productPrice));
                                  debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                  final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                  debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
                                  _totalAfterDiscountWithoutTax = widget.productItem.purchased * (_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal);
                                  debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                  final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                  debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                  _taxAmount = widget.productItem.purchased * taxAmountByProduct;
                                  debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                  _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  debugPrint ('El valor de _totalAmount es: $_totalAmount');
                                }
                              }
                            }
                          },
                          child: Container (
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(2.0),
                            decoration: BoxDecoration (
                                color: tanteLadenAmber500,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: tanteLadenButtonBorderGray,
                                    width: 1
                                )
                            ),
                            child: Container(
                              width: 40.0,
                              height: 40.0,
                              alignment: Alignment.center,
                              child: const Text(
                                '-',
                                style: TextStyle(
                                    fontWeight: FontWeight.w300,
                                    fontSize: 24.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: tanteLadenButtonBorderGray
                                ),
                              ),
                            ),
                          )
                      ),
                      Padding (
                        //padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                        padding: const EdgeInsets.only(left: WithInDpis_20, right: WithInDpis_20),
                        child: RichText (
                          text: TextSpan (
                              text: widget.father.newQuantity != -1
                                  ? '$_newNumItemsPurchased (${widget.productItem.purchased}) '
                                  : widget.productItem.purchased.toString(),
                              style: const TextStyle (
                                fontWeight: FontWeight.w700,
                                fontSize: 24.0,
                                fontFamily: 'SF Pro Display',
                                fontStyle: FontStyle.normal,
                                color: Colors.black,
                              ),
                              children: <TextSpan>[
                                TextSpan (
                                    text: widget.father.newQuantity != -1
                                        ? _newNumItemsPurchased > 1 ? ' ${widget.productItem.idUnit}s.' : ' ${widget.productItem.idUnit}.'
                                        : widget.productItem.purchased > 1 ? ' ${widget.productItem.idUnit}s.' : ' ${widget.productItem.idUnit}.',
                                    style: const TextStyle (
                                        fontWeight: FontWeight.bold
                                    )
                                )
                              ]
                          ),
                        ),
                      ),
                      TextButton(
                          onPressed: () {
                            if (widget.father.newQuantity != -1) {
                              // the quantity of the purchase line has been changed.
                              // The value -1 is the value when the field NEW_QUANTITY of the KRC_PURCHASE is null,
                              // then it has been not yet modified
                              if (_newNewProductPriceFinal != -1) {
                                setState(() {
                                  _newNumItemsPurchased = _newNumItemsPurchased + widget.productItem.minQuantitySell;
                                });
                                _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
                                debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                final double productPriceDiscounted = (_newNewProductPriceFinal + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
                                _discountAmount = _newNumItemsPurchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                _totalAfterDiscountWithoutTax = _newNumItemsPurchased * _newNewProductPriceFinal;
                                debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
                                debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                debugPrint ('El valor de _totalAmount es: $_totalAmount');
                              } else {
                                setState(() {
                                  _newNumItemsPurchased = _newNumItemsPurchased + widget.productItem.minQuantitySell;
                                });
                                _totalBeforeDiscountWithoutTax = _newNumItemsPurchased * widget.father.productPrice;
                                debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                _totalBeforeDiscount = _newNumItemsPurchased * (widget.father.productPrice*(1+widget.productItem.taxApply/100));
                                debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
                                _discountAmount = _newNumItemsPurchased * (((_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal) - widget.father.productPrice));
                                debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                _totalAfterDiscountWithoutTax = _newNumItemsPurchased * (_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal);
                                debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                _taxAmount = _newNumItemsPurchased * taxAmountByProduct;
                                debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                debugPrint ('El valor de _totalAmount es: $_totalAmount');
                              }
                            } else {
                              // the quantity of the purchase line has not yet been changed.
                              if (_newNewProductPriceFinal != -1) {
                                setState(() {
                                  widget.productItem.purchased = widget.productItem.purchased + widget.productItem.minQuantitySell;
                                });
                                _totalBeforeDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
                                debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                final double productPriceDiscounted = (_newNewProductPriceFinal + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
                                _discountAmount = widget.productItem.purchased * ((_newNewProductPriceFinal - widget.father.productPrice));
                                debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                _totalAfterDiscountWithoutTax = widget.productItem.purchased * _newNewProductPriceFinal;
                                debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                _taxAmount = widget.productItem.purchased * taxAmountByProduct;
                                debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                //_totalAmount = widget.productItem.purchased * widget.productItem.totalAmount;
                                _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                debugPrint ('El valor de _totalAmount es: $_totalAmount');
                              } else {
                                setState(() {
                                  widget.productItem.purchased = widget.productItem.purchased + widget.productItem.minQuantitySell;
                                });
                                _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                debugPrint ('El valor de _totalBeforeDiscountWithoutTax es: $_totalBeforeDiscountWithoutTax');
                                _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice*(1+(widget.productItem.taxApply/100)));
                                debugPrint ('El valor de _totalBeforeDiscount es: $_totalBeforeDiscount');
                                debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
                                final double productPriceDiscounted = (widget.father.productPrice + (_valueDiscount * MULTIPLYING_FACTOR)); // product price minus discount
                                debugPrint ('El valor de productPriceDiscounted es: $productPriceDiscounted');
                                _discountAmount = widget.productItem.purchased * (((_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal) - widget.father.productPrice));
                                debugPrint ('El valor de _discountAmount es: $_discountAmount');
                                _totalAfterDiscountWithoutTax = widget.productItem.purchased * (_newNewProductPriceFinal == -1 ? widget.father.productPrice : _newNewProductPriceFinal);
                                debugPrint ('El valor de _totalAfterDiscountWithoutTax es: $_totalAfterDiscountWithoutTax');
                                final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                debugPrint ('El valor de taxAmountByProduct es: $taxAmountByProduct');
                                _taxAmount = widget.productItem.purchased * taxAmountByProduct;
                                debugPrint ('El valor de _taxAmount es: $_taxAmount');
                                _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                debugPrint ('El valor de _totalAmount es: $_totalAmount');
                              }
                            }
                          },
                          child: Container (
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(2.0),
                            decoration: BoxDecoration(
                              color: tanteLadenAmber500,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF6C6D77),
                                width: 1,
                              ),
                            ),
                            child: Container(
                              width: 40.0,
                              height: 40.0,
                              alignment: Alignment.center,
                              child: const Text(
                                '+',
                                style: TextStyle(
                                  fontWeight: FontWeight.w300,
                                  fontSize: 24.0,
                                  fontFamily: 'SF Pro Display',
                                  fontStyle: FontStyle.normal,
                                  color: tanteLadenButtonBorderGray,
                                ),
                              ),
                            ),
                          )
                      ),
                    ],
                  ),
                  //SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  const Divider (thickness: 2.0,),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container (
                        padding: const EdgeInsets.only(left: 24),
                        child: const Text (
                          'Modificación del precio por: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded (
                          flex: 1,
                          child: ListTile(
                            title: const Text('Valor'),
                            leading: Radio<PriceChangeType>(
                              value: PriceChangeType.priceValue,
                              groupValue: _changeType,
                              onChanged: (PriceChangeType? value){
                                setState(() {
                                  _changeType = value!;
                                  _valueDiscount = 0.0;
                                  _percentDiscount = 0.0;
                                  _newNewProductPriceFinal = widget.father.newProductPrice;
                                });
                                _valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                _percentDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
                              },
                            ),
                          )
                      ),
                      Expanded (
                          flex: 1,
                          child: ListTile(
                            title: const Text('Porcentaje'),
                            leading: Radio<PriceChangeType>(
                              value: PriceChangeType.percentValue,
                              groupValue: _changeType,
                              onChanged: (PriceChangeType? value){
                                setState(() {
                                  _changeType = value!;
                                  _percentDiscount = 0.0;
                                  _valueDiscount = 0.0;
                                  _newNewProductPriceFinal = widget.father.newProductPrice;
                                });
                                _percentDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
                                _valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                              },
                            ),
                          )
                      )
                    ],
                  ),
                  const Divider(thickness: 2.0,),
                  (_changeType == PriceChangeType.priceValue) ? const Center (
                    child: Text(
                      'Modificación neta',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Color(0xFF6C6D77),
                      ),
                    ),
                  ) : const Center(
                    child: Text (
                      'Modificación porcentual',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Color(0xFF6C6D77),
                      ),
                    ),
                  ),
                  (_changeType == PriceChangeType.priceValue) ? Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded (
                          flex:1,
                          child: Container()
                      ),
                      Expanded (
                        flex:4,
                        child: Row (
                          children: [
                            Expanded (
                              flex: 1,
                              child: TextButton(
                                  onPressed: () {
                                    debugPrint ('Estoy en el onPressed de -');
                                    if (widget.father.newProductPrice != -1) {
                                      // the price has been previously modified
                                      debugPrint ('Estoy en el onPressed de -. Dentro de la parte de que el precio ha sido previamente modificado.');
                                      final double tmpValueDiscount = _valueDiscount;
                                      _valueDiscount = _valueDiscount - 0.1;
                                      if (widget.father.newProductPrice >= (_valueDiscount * MULTIPLYING_FACTOR).abs()) {
                                        // the price can't be negative
                                        setState(() {
                                          _valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                        });
                                      } else {
                                        _valueDiscount = tmpValueDiscount;
                                      }
                                    } else {
                                      // the price has not yet modified
                                      //debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
                                      debugPrint ('Estoy en el onPressed de -. Dentro de la parte de que el precio nunca ha sido previamente modificado.');
                                      final double tmpValueDiscount = _valueDiscount;
                                      _valueDiscount = _valueDiscount - 0.1;
                                      debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
                                      if (widget.father.productPrice >= (_valueDiscount * MULTIPLYING_FACTOR).abs()) {
                                        // the price can't be negative
                                        setState(() {
                                          _valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                        });
                                      } else {
                                        _valueDiscount = tmpValueDiscount;
                                      }
                                    }
                                  },
                                  child: Container (
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration (
                                        color: tanteLadenAmber500,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: tanteLadenButtonBorderGray,
                                            width: 1
                                        )
                                    ),
                                    child: Container(
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text (
                                        '-',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w300,
                                            fontSize: 24.0,
                                            fontFamily: 'SF Pro Display',
                                            fontStyle: FontStyle.normal,
                                            color: tanteLadenButtonBorderGray
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            ),
                            Expanded (
                              flex: 2,
                              child: Form(
                                key: _formNewPricekey,
                                child: TextFormField(
                                  controller: _valueDiscountTextFieldOnlyForCaseOne,
                                  decoration: const InputDecoration (
                                      prefixIcon: Icon(Icons.euro_rounded)
                                  ),
                                  style: const TextStyle (
                                    fontWeight: FontWeight.w700,
                                    fontSize: 24.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$')),],
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  onEditingComplete: () {
                                    _percentDiscount = double.tryParse (_percentDiscountTextField.text.replaceAll(RegExp(','), '.'))!;
                                    debugPrint('El valor de: _percentDiscount es: $_percentDiscount');
                                  },
                                  validator: (String? value) {
                                    RegExp regexp = RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$');
                                    if (!regexp.hasMatch(value!)) {
                                      return 'Introduce un valor neto válido. Formato: (+/-)##,##';
                                    } else {
                                      return null;
                                    }
                                  },
                                ),
                              ),
                            ),
                            Expanded (
                              flex: 1,
                              child: TextButton(
                                  onPressed: () {
                                    debugPrint ('Estoy en el onPressed de +');
                                    if (widget.father.newProductPrice != -1) {
                                      // the price has been previously modified
                                      debugPrint ('Estoy en el onPressed de +. Dentro de la parte de que el precio ha sido previamente modificado.');
                                      _valueDiscount = _valueDiscount + 0.1;
                                      setState(() {
                                        _valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                      });
                                    } else {
                                      // the price has not yet modified
                                      //debugPrint ('Estoy en el que el precio aún no ha sido modificado nunca');
                                      debugPrint ('Estoy en el onPressed de +. Dentro de la parte de que el precio nunca ha sido previamente modificado.');
                                      _valueDiscount = _valueDiscount + 0.1;
                                      debugPrint ('El valor de _valueDiscount es: $_valueDiscount');
                                      setState(() {
                                        _valueDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                      });
                                    }
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration(
                                      color: tanteLadenAmber500,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF6C6D77),
                                        width: 1,
                                      ),
                                    ),
                                    child: Container(
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '+',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 24.0,
                                          fontFamily: 'SF Pro Display',
                                          fontStyle: FontStyle.normal,
                                          color: tanteLadenButtonBorderGray,
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded (
                          flex:1,
                          child: Container()
                      )
                    ],
                  ) : Row (
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded (
                          flex:1,
                          child: Container()
                      ),
                      Expanded (
                        flex:4,
                        child: Row (
                          children: [
                            Expanded (
                              flex: 1,
                              child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _percentDiscount = _percentDiscount - 0.5;
                                      _percentDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse((_percentDiscount).toString()));
                                    });
                                    // There is a change in the price
                                    _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                    _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                    final double productPriceDiscounted = widget.father.productPrice * (1-(_percentDiscount/100)); // product price minus discount
                                    _discountAmount = widget.productItem.purchased * (widget.father.productPrice * (_percentDiscount/100));
                                    _totalAfterDiscountWithoutTax = _totalBeforeDiscountWithoutTax + _discountAmount;
                                    final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                    _taxAmount = widget.productItem.purchased * taxAmountByProduct;
                                    _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                  },
                                  child: Container (
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration (
                                        color: tanteLadenAmber500,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: tanteLadenButtonBorderGray,
                                            width: 1
                                        )
                                    ),
                                    child: Container(
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '-',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w300,
                                            fontSize: 24.0,
                                            fontFamily: 'SF Pro Display',
                                            fontStyle: FontStyle.normal,
                                            color: tanteLadenButtonBorderGray
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            ),
                            Expanded (
                              flex: 2,
                              child: Form(
                                key: _formPercentKey,
                                child: TextFormField(
                                  controller: _percentDiscountTextFieldOnlyForCaseOne,
                                  decoration: const InputDecoration (
                                    prefixText: '  %  ',
                                    prefixStyle: TextStyle (
                                      fontWeight: FontWeight.w700,
                                      fontSize: 24.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.black45,
                                    ),
                                  ),
                                  style: const TextStyle (
                                    fontWeight: FontWeight.w700,
                                    fontSize: 24.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$')),],
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  onEditingComplete: () {
                                    _percentDiscount = double.tryParse (_percentDiscountTextField.text.replaceAll(RegExp(','), '.'))!;
                                    debugPrint('El valor de: _percentDiscount es: $_percentDiscount');
                                  },
                                  validator: (String? value) {
                                    RegExp regexp = RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$');
                                    if (!regexp.hasMatch(value!)) {
                                      return 'Introduce un porcentaje válido. Formato: (+/-)##,##';
                                    } else {
                                      return null;
                                    }
                                  },
                                ),
                              ),
                            ),
                            Expanded (
                              flex: 1,
                              child: TextButton(
                                  onPressed: () {
                                    if (_percentDiscount <= 100) {
                                      setState(() {
                                        _percentDiscount = _percentDiscount + 0.5;
                                        _percentDiscountTextFieldOnlyForCaseOne.text = NumberFormat('##0.00', 'es_ES').format(double.parse((_percentDiscount).toString()));
                                      });
                                      // There is a change in the price
                                      _totalBeforeDiscountWithoutTax = widget.productItem.purchased * widget.father.productPrice;
                                      _totalBeforeDiscount = widget.productItem.purchased * (widget.father.productPrice * (1+widget.productItem.taxApply/100));
                                      final double productPriceDiscounted = widget.father.productPrice * (1-(_percentDiscount/100)); // product price minus discount
                                      _discountAmount = widget.productItem.purchased * (widget.father.productPrice * (_percentDiscount/100));
                                      _totalAfterDiscountWithoutTax = _totalBeforeDiscountWithoutTax - _discountAmount;
                                      final double taxAmountByProduct = productPriceDiscounted * (widget.productItem.taxApply/100);
                                      _taxAmount = widget.productItem.purchased * taxAmountByProduct;
                                      _totalAmount = _totalAfterDiscountWithoutTax + _taxAmount;
                                    }
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration(
                                      color: tanteLadenAmber500,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF6C6D77),
                                        width: 1,
                                      ),
                                    ),
                                    child: Container(
                                      width: 40.0,
                                      height: 40.0,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '+',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 24.0,
                                          fontFamily: 'SF Pro Display',
                                          fontStyle: FontStyle.normal,
                                          color: tanteLadenButtonBorderGray,
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded (
                          flex:1,
                          child: Container()
                      )
                    ],
                  ),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: Image.asset (
                          'assets/images/logoComment.png',
                          fit: BoxFit.scaleDown,
                          width: 20.0,
                          height: 20.0,
                        ),
                      ),
                      Container (
                        padding: const EdgeInsets.only(left:8),
                        child: Text.rich(
                            TextSpan (
                                text: 'Introducir comentario',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: tanteLadenIconBrown,
                                    decoration: TextDecoration.underline
                                ),
                                recognizer: TapGestureRecognizer ()
                                  ..onTap = () async {
                                    _comment = await Navigator.push (context, MaterialPageRoute (
                                        builder: (context) => AddComment (_comment)
                                    ));
                                  }
                            )
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: constraints.maxHeight * HeightInDpis_35),
                  Row (
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container (
                          padding: const EdgeInsets.only(left: 24),
                          child: Checkbox (
                            checkColor: Colors.white,
                            fillColor: MaterialStateProperty.resolveWith(getColor),
                            value: _isOfficial,
                            onChanged: (bool? value) {
                              setState(() {
                                _isOfficial = value!;
                              });
                            },
                          )
                      ),
                      const Text (
                        'Oficializar el nuevo precio.',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14.0,
                          fontFamily: 'SF Pro Display',
                          fontStyle: FontStyle.normal,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ],
                  ),
                  _pleaseWait ? Stack(
                    key: const ObjectKey ("stack"),
                    alignment: AlignmentDirectional.center,
                    children: [
                      tmpBuilder,
                      _pleaseWaitWidget
                    ],
                  ): Stack(
                    key: const ObjectKey("stack"),
                    children: [tmpBuilder],
                  ),
                  //SizedBox(height: 35.0),
                ],
              );
            },
          )
      );
    }
  }
}