import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kompras/model/NewProductData.model.dart';
import 'package:kompras/model/PriceChangeType.model.dart';
import 'package:kompras/model/ProductType.model.dart';
import 'package:kompras/model/ProviderProduct.model.dart';
import 'package:kompras/model/TaxType.model.dart';
import 'package:kompras/model/UnitType.model.dart';
import 'package:kompras/service/NewProduct.service.dart';
import 'package:kompras/util/ResponsiveWidget.util.dart';
import 'package:kompras/util/color.util.dart';
import 'package:intl/intl.dart' show NumberFormat hide TextDirection;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewProductView extends StatefulWidget {
  const NewProductView({super.key});

  @override
  NewProductViewState createState() => NewProductViewState();
}
class NewProductViewState extends State<NewProductView> {
  late NewProductService _service;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _service = NewProductService();
  }
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold (
      appBar: AppBar (
        elevation: 0.0,
        leading: IconButton (
            icon: Image.asset('assets/images/leftArrow.png'),
            onPressed: () {
              Navigator.pop(context);
            }
        ),
        title: const Text (
          'Introducir nuevo producto',
          style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 20.0,
              fontWeight: FontWeight.w300,
              color: tanteLadenIconBrown
          ),
        ),
      ),
      body: FutureBuilder <NewProductData> (
        future: _service.getNewProductData(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            debugPrint ('He retornado datos');
            return ResponsiveWidget (
              smallScreen: _SmallScreenView(snapshot.data!, _service),
              mediumScreen: _MediumScreenView(snapshot.data!, _service),
              largeScreen: _LargeScreenView(snapshot.data!, _service),
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
class _SmallScreenView extends StatefulWidget {
  final NewProductData data;
  final NewProductService service;
  const _SmallScreenView (this.data, this.service);
  @override
  _SmallScreenViewState createState() {
    return _SmallScreenViewState();
  }
}
class _SmallScreenViewState extends State <_SmallScreenView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _categoryIdController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _valueDiscountController = TextEditingController();
  final TextEditingController _percentDiscountController = TextEditingController();
  final TextEditingController _weeksWarningController = TextEditingController();
  final TextEditingController _quantityMinPriceController = TextEditingController();
  final TextEditingController _quantityMaxPriceController = TextEditingController();
  // vars
  bool _pleaseWait = false;
  double _productPrice = 0.0;
  PriceChangeType _changeType = PriceChangeType.priceValue;
  double _valueDiscount = 0.0;
  double _percentDiscount = 0.0;
  String _unitType = '';
  String _taxType = '';
  int _weekWarning = 0;
  int _categoryId = 0;
  int _quantityMinPrice = 0;
  int _quantityMaxPrice = 999999;
  String _productType = '';
  String _provider = '';

  // listeners
  void _categoryIdControllerProcessor() {
    _categoryId = int.tryParse(_categoryIdController.text)!;
  }
  void _productPriceControllerProcessor() {
    _productPrice = double.tryParse(_productPriceController.text.replaceAll(RegExp(','), '.'))!;
  }
  void _valueDiscountControllerProcessor() {
    _valueDiscount = double.tryParse(_valueDiscountController.text.replaceAll(RegExp(','), '.'))!;
  }
  void _percentDiscountControllerProcessor() {
    _percentDiscount = double.tryParse (_percentDiscountController.text.replaceAll(RegExp(','), '.'))!;
  }
  void _weeksWarningControllerProcessor() {
    _weekWarning = int.tryParse(_weeksWarningController.text)!;
  }
  void _quantityMinPriceControllerProcessor() {
    _quantityMinPrice = int.tryParse(_quantityMinPriceController.text)!;
  }
  void _quantityMaxPriceControllerProcessor() {
    _quantityMaxPrice = int.tryParse(_quantityMaxPriceController.text)!;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _taxType = (widget.data.taxTypeItems[0].taxType);
    _unitType = (widget.data.unitTypeItems[0].idUnit);
    _productType = (widget.data.productTypeItems[0].productType);
    _provider = (widget.data.providerItems[0].personeName);
    _categoryIdController.text = _categoryId.toString();
    _categoryIdController.addListener(_categoryIdControllerProcessor);
    _productPriceController.text = NumberFormat('##0.00', 'es_ES').format(double.parse((0.00).toString()));
    _productPriceController.addListener(_productPriceControllerProcessor);
    _valueDiscountController.text = NumberFormat('##0.00', 'es_ES').format(double.parse((0.00).toString()));
    _valueDiscountController.addListener(_valueDiscountControllerProcessor);
    _percentDiscountController.text = NumberFormat('##0.00', 'es_ES').format(double.parse((0.00).toString()));
    _percentDiscountController.addListener(_percentDiscountControllerProcessor);
    _weeksWarningController.text = _weekWarning.toString();
    _weeksWarningController.addListener(_weeksWarningControllerProcessor);
    _quantityMinPriceController.text = _quantityMinPrice.toString();
    _quantityMinPriceController.addListener(_quantityMinPriceControllerProcessor);
    _quantityMaxPriceController.text = _quantityMaxPrice.toString();
    _quantityMaxPriceController.addListener(_quantityMaxPriceControllerProcessor);
  }
  @override
  void dispose() {
    _productNameController.dispose();
    _categoryIdController.dispose();
    _valueDiscountController.dispose();
    _percentDiscountController.dispose();
    _weeksWarningController.dispose();
    _quantityMinPriceController.dispose();
    _quantityMaxPriceController.dispose();
    super.dispose();
  }
  _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }
  @override
  Widget build (BuildContext context) {
    return SafeArea(
        child: LayoutBuilder(
            builder: (context, constraints) {
              return Form(
                key: _formKey,
                child: ListView (
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                  children: [
                    Row (
                      children: <Widget>[
                        Flexible(
                          flex: 1,
                          child: TextFormField(
                            decoration: const InputDecoration (
                                labelText: 'Nombre del producto',
                                labelStyle: TextStyle(
                                    color: tanteLadenIconBrown
                                )
                            ),
                            style: const TextStyle (
                              fontWeight: FontWeight.w500,
                              fontSize: 24.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                            controller: _productNameController,
                          ),
                        ),
                      ],
                    ),
                    Row (
                      children: <Widget>[
                        Flexible(
                          flex: 3,
                          child: TextFormField (
                            decoration: const InputDecoration (
                                labelText: 'Id. Categoría',
                                labelStyle: TextStyle(
                                    color: tanteLadenIconBrown
                                )
                            ),
                            style: const TextStyle (
                              fontWeight: FontWeight.w500,
                              fontSize: 24.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                            controller: _categoryIdController,
                            keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^[0-9]{1,3}$'))],
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            onEditingComplete: () {
                              _categoryId = int.tryParse(_weeksWarningController.text)!;
                              debugPrint('El valor de: _categoryId es: $_categoryId');
                            },
                            validator: (String? value) {
                              RegExp regexp = RegExp(r'^[0-9]{1,3}$');
                              if (!regexp.hasMatch(value ?? "") || value == null) {
                                return 'Introduce un valor entero entre 0 y 999';
                              } else {
                                return null;
                              }
                            },
                          ),
                        ),
                        Flexible(flex: 1, child: Container())
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Flexible(
                            flex: 2,
                            child: TextFormField (
                              controller: _productPriceController,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.euro_rounded),
                                labelText: 'Precio',
                                labelStyle: TextStyle (
                                    color: tanteLadenIconBrown
                                ),
                              ),
                              style: const TextStyle (
                                fontWeight: FontWeight.w500,
                                fontSize: 24.0,
                                fontFamily: 'SF Pro Display',
                                fontStyle: FontStyle.normal,
                                color: Colors.black,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('^\\d?\\d?\\,?\\d?\\d?\$')),],
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              onEditingComplete: () {
                                _productPrice = double.tryParse(_productPriceController.text.replaceAll(RegExp(','), '.'))!;
                                debugPrint('El valor de: productPrice es: $_productPrice');
                              },
                              validator: (String? value) {
                                RegExp regexp = RegExp('^\\d?\\d?\\,?\\d?\\d?\$');
                                if (!regexp.hasMatch(value ?? "") || value == null) {
                                  return 'Introduce un valor para el precio válido. Formato: ##,##';
                                } else {
                                  return null;
                                }
                              },
                            )
                        ),
                        Flexible(
                            flex: 2,
                            child: Container()
                        )
                      ],
                    ),
                    const SizedBox(height: 10.0,),
                    const Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text (
                          'Tipo de descuento',
                          style: TextStyle (
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: tanteLadenIconBrown,
                          ),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ],
                    ),
                    Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded (
                            flex: 1,
                            child: ListTile(
                              title: const Text('Valor'),
                              leading: Radio<PriceChangeType>(
                                value: PriceChangeType.priceValue,
                                groupValue: _changeType,
                                onChanged: (PriceChangeType? value) {
                                  setState(() {
                                    _changeType = value!;
                                    _valueDiscount = 0.0;
                                    _percentDiscount = 0.0;
                                  });
                                  _valueDiscountController.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                  _percentDiscountController.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
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
                                  });
                                  _percentDiscountController.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
                                  _valueDiscountController.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                },
                              ),
                            )
                        )
                      ],
                    ),
                    (_changeType == PriceChangeType.priceValue) ? const Text(
                      'Descuento neto',
                      style: TextStyle (
                        fontWeight: FontWeight.w500,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: tanteLadenIconBrown,
                      ),
                    ) : const Text (
                      'Descuento porcentual',
                      style: TextStyle (
                        fontWeight: FontWeight.w500,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: tanteLadenIconBrown,
                      ),
                    ),
                    (_changeType == PriceChangeType.priceValue) ? Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Flexible (
                          flex: 1,
                          child: TextFormField(
                            controller: _valueDiscountController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.euro_rounded),
                              prefixStyle: TextStyle (
                                fontWeight: FontWeight.w700,
                                fontSize: 24.0,
                                fontFamily: 'SF Pro Display',
                                fontStyle: FontStyle.normal,
                                color: Colors.black45,
                              ),
                            ),
                            style: const TextStyle (
                              fontWeight: FontWeight.w500,
                              fontSize: 24.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$')),],
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            onEditingComplete: () {
                              _valueDiscount = double.tryParse(_valueDiscountController.text.replaceAll(RegExp(','), '.'))!;
                            },
                            validator: (String? value) {
                              RegExp regexp = RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$');
                              if (!regexp.hasMatch(value ?? "") || value == null) {
                                return 'Introduce un valor neto válido. Formato: (+/-)##,##';
                              } else {
                                return null;
                              }
                            },
                          ),
                        ),
                        Flexible(
                            flex: 1,
                            child: Container()
                        )
                      ],
                    ): Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Flexible(
                          child: TextFormField (
                            controller: _percentDiscountController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.percent_rounded),
                              prefixStyle: TextStyle (
                                fontWeight: FontWeight.w700,
                                fontSize: 24.0,
                                fontFamily: 'SF Pro Display',
                                fontStyle: FontStyle.normal,
                                color: Colors.black45,
                              ),
                            ),
                            style: const TextStyle (
                              fontWeight: FontWeight.w500,
                              fontSize: 24.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$')),],
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            onEditingComplete: () {
                              _percentDiscount = double.tryParse (_percentDiscountController.text.replaceAll(RegExp(','), '.'))!;
                              debugPrint('El valor de: _percentDiscount es: $_percentDiscount');
                            },
                            validator: (String? value) {
                              RegExp regexp = RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$');
                              if (!regexp.hasMatch(value ?? "") || value == null) {
                                return 'Introduce un porcentaje válido. Formato: (+/-)##,##';
                              } else {
                                return null;
                              }
                            },
                          ),
                        ),
                        Flexible(child: Container())
                      ],
                    ),
                    const SizedBox(height: 10.0,),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text (
                          'Tipo de IVA',
                          style: TextStyle (
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: tanteLadenIconBrown,
                          ),
                        ),
                      ],
                    ),
                    Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:<Widget> [
                        Flexible(
                          flex: 1,
                          child: DropdownButtonFormField (
                            decoration: InputDecoration (
                              enabledBorder: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              border: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              filled: true,
                              fillColor: tanteLadenAmber100,
                            ),
                            iconEnabledColor: Colors.black,
                            focusColor: tanteLadenAmber100,
                            dropdownColor: tanteLadenAmber100,
                            value: _taxType,
                            items: widget.data.taxTypeItems.map<DropdownMenuItem<String>>((TaxType value) {
                              return DropdownMenuItem<String>(
                                value: value.taxType,
                                child: Text(
                                  value.taxType,
                                  style: const TextStyle (
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.black,
                                      overflow: TextOverflow.visible
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _taxType = newValue!;
                              });
                            },
                          ),
                        ),
                        Flexible(flex:1, child: Container())
                      ],
                    ),
                    const SizedBox(height: 10.0,),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text (
                          'Tipo de unidad',
                          style: TextStyle (
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: tanteLadenIconBrown,
                          ),
                        ),
                      ],
                    ),
                    Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:<Widget> [
                        Flexible(
                          flex: 1,
                          child: DropdownButtonFormField (
                            decoration: InputDecoration (
                              enabledBorder: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              border: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              filled: true,
                              fillColor: tanteLadenAmber100,
                            ),
                            iconEnabledColor: Colors.black,
                            focusColor: tanteLadenAmber100,
                            dropdownColor: tanteLadenAmber100,
                            value: _unitType,
                            items: widget.data.unitTypeItems.map<DropdownMenuItem<String>>((UnitType value){
                              return DropdownMenuItem<String>(
                                value: value.idUnit,
                                child: Text(
                                  value.idUnit,
                                  style: const TextStyle (
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.black,
                                      overflow: TextOverflow.visible
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _unitType = newValue!;
                              });
                            },
                          ),
                        ),
                        Flexible(flex:1, child: Container())
                      ],
                    ),
                    const SizedBox(height: 10.0,),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text (
                          'Tipo de producto',
                          style: TextStyle (
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: tanteLadenIconBrown,
                          ),
                        ),
                      ],
                    ),
                    Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:<Widget> [
                        Flexible(
                          flex: 1,
                          child: DropdownButtonFormField (
                            decoration: InputDecoration (
                              enabledBorder: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              border: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              filled: true,
                              fillColor: tanteLadenAmber100,
                            ),
                            //dropdownColor: Colors.blueAccent,
                            iconEnabledColor: tanteLadenIconBrown,
                            focusColor: tanteLadenAmber100,
                            dropdownColor: tanteLadenAmber100,
                            value: _productType,
                            items: widget.data.productTypeItems.map<DropdownMenuItem<String>>((ProductType value) {
                              return DropdownMenuItem<String>(
                                value: value.productType,
                                child: Text(
                                  value.productType,
                                  style: const TextStyle (
                                    fontWeight: FontWeight.w500,
                                    fontSize: 20.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  softWrap: true,
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _productType = newValue!;
                              });
                            },
                            isExpanded: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0,),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text (
                          'Proveedor',
                          style: TextStyle (
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: tanteLadenIconBrown,
                          ),
                        ),
                      ],
                    ),
                    Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:<Widget> [
                        Flexible (
                          flex: 1,
                          child: DropdownButtonFormField(
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              border: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              filled: true,
                              fillColor: tanteLadenAmber100,
                            ),
                            //dropdownColor: Colors.blueAccent,
                            iconEnabledColor: Colors.black,
                            focusColor: tanteLadenAmber100,
                            dropdownColor: tanteLadenAmber100,
                            value: _provider,
                            items: widget.data.providerItems.map<DropdownMenuItem<String>>((ProviderProduct value) {
                              return DropdownMenuItem<String> (
                                value: value.personeName,
                                child: Text(
                                  value.personeName,
                                  style: const TextStyle (
                                    fontWeight: FontWeight.w500,
                                    fontSize: 20.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  softWrap: true,
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _provider = newValue!;
                              });
                            },
                            isExpanded: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0,),
                    Row (
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Flexible(
                          flex: 2,
                          child: TextFormField(
                            controller: _weeksWarningController,
                            decoration: const InputDecoration (
                                labelText: 'Semanas de aviso',
                                labelStyle: TextStyle(
                                    color: tanteLadenIconBrown
                                )
                            ),
                            style: const TextStyle (
                              fontWeight: FontWeight.w500,
                              fontSize: 24.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^[0-9]{1,2}$'))],
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            onEditingComplete: () {
                              _weekWarning = int.tryParse(_weeksWarningController.text)!;
                              debugPrint('El valor de: _weekWarning es: $_weekWarning');
                            },
                            validator: (String? value) {
                              RegExp regexp = RegExp(r'^[0-9]{1,2}$');
                              if (!regexp.hasMatch(value ?? "") || value == null) {
                                return 'Introduce un valor válido. Formato: ##. Introduce un valor entre 0 y 99';
                              } else {
                                return null;
                              }
                            },
                          ),
                        ),
                        Flexible(flex: 2, child: Container())
                      ],
                    ),
                    Row (
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Flexible(
                          flex: 2,
                          child: TextFormField(
                            controller: _quantityMinPriceController,
                            decoration: const InputDecoration (
                                labelText: 'Cantidad mínima',
                                labelStyle: TextStyle(
                                    color: tanteLadenIconBrown
                                )
                            ),
                            style: const TextStyle (
                              fontWeight: FontWeight.w500,
                              fontSize: 24.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^[0-9]{1,6}$'))],
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            onEditingComplete: () {
                              _quantityMinPrice = int.tryParse(_quantityMinPriceController.text)!;
                            },
                            validator: (String? value) {
                              RegExp regexp = RegExp(r'^[0-9]{1,6}$');
                              if (!regexp.hasMatch(value ?? "") || value == null) {
                                return 'Introduce un valor válido. Formato: ######. Valor entre 0 y 999999';
                              } else {
                                return null;
                              }
                            },
                          ),
                        ),
                        Flexible(flex: 2, child: Container())
                      ],
                    ),
                    Row (
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Flexible(
                          flex: 2,
                          child: TextFormField(
                            controller: _quantityMaxPriceController,
                            decoration: const InputDecoration (
                                labelText: 'Cantidad máxima',
                                labelStyle: TextStyle(
                                    color: tanteLadenIconBrown
                                )
                            ),
                            style: const TextStyle (
                              fontWeight: FontWeight.w500,
                              fontSize: 24.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^[0-9]{1,6}$'))],
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            onEditingComplete: () {
                              _quantityMaxPrice = int.tryParse(_quantityMaxPriceController.text)!;
                            },
                            validator: (String? value) {
                              RegExp regexp = RegExp(r'^[0-9]{1,6}$');
                              if (!regexp.hasMatch(value ?? "") || value == null) {
                                return 'Introduce un valor válido. Formato: ######. Valor entre 0 y 999999';
                              } else {
                                return null;
                              }
                            },
                          ),
                        ),
                        Flexible(flex: 2, child: Container())
                      ],
                    ),
                    const SizedBox (height: 40.0,),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 10.0),
                      child: Row (
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          GestureDetector(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 80.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration (
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(8.0),
                                    gradient: const LinearGradient (
                                        colors: <Color> [
                                          Color (0xFF833C26),
                                          Color (0xFF9A541F),
                                          Color (0xFFF9B806),
                                          Color (0XFFFFC107),
                                        ]
                                    )
                                ),
                                height: 64.0,
                                child: const Text(
                                  'Añadir Producto',
                                  style: TextStyle(
                                      fontSize: 24.0,
                                      color: tanteLadenBackgroundWhite
                                  ),
                                ),
                              ),
                              onTap: () async {
                                try {
                                  _showPleaseWait(true);
                                  Future<SharedPreferences> prefs0 = SharedPreferences.getInstance();
                                  final SharedPreferences prefs = await prefs0;
                                  final String token = prefs.getString ('token') ?? '';
                                  Map<String, dynamic> payload;
                                  payload = json.decode(
                                      utf8.decode(
                                          base64.decode (base64.normalize(token.split(".")[1]))
                                      )
                                  );
                                  final String partnerId = payload['partner_id'].toString();
                                  final String partnerName = payload['partner_name'].toString();
                                  final String userCreateId = payload['user_id'].toString();
                                  widget.service.saveProduct(
                                      categoryId: _categoryId,
                                      productName: _productNameController.text,
                                      minQuantitySell: _quantityMinPrice,
                                      productPrice: _productPrice,
                                      discountType: _changeType,
                                      discountValue: (_changeType == PriceChangeType.priceValue) ? _valueDiscount : _percentDiscount,
                                      taxType: _taxType,
                                      idUnit: _unitType,
                                      weeksWarning: _weekWarning,
                                      quantityMinPrice: _quantityMinPrice.toDouble(),
                                      quantityMaxPrice: _quantityMaxPrice.toDouble(),
                                      productType: _productType,
                                      personeName: _provider,
                                      partnerId: int.parse(partnerId),
                                      partnerName: partnerName,
                                      userCreateId: int.parse(userCreateId)
                                  );
                                  _showPleaseWait(false);
                                } catch(e) {
                                  _showPleaseWait(false);
                                  //ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'].toString());
                                }
                              }
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
        )
    );
  }
}
class _MediumScreenView extends StatefulWidget {
  final NewProductData data;
  final NewProductService service;
  const _MediumScreenView (this.data, this.service);
  @override
  _MediumScreenViewState createState() {
    return _MediumScreenViewState();
  }
}
class _MediumScreenViewState extends State <_MediumScreenView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _categoryIdController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _valueDiscountController = TextEditingController();
  final TextEditingController _percentDiscountController = TextEditingController();
  final TextEditingController _weeksWarningController = TextEditingController();
  final TextEditingController _quantityMinPriceController = TextEditingController();
  final TextEditingController _quantityMaxPriceController = TextEditingController();
  // vars
  bool _pleaseWait = false;
  double _productPrice = 0.0;
  PriceChangeType _changeType = PriceChangeType.priceValue;
  double _valueDiscount = 0.0;
  double _percentDiscount = 0.0;
  String _unitType = '';
  String _taxType = '';
  int _weekWarning = 0;
  int _categoryId = 0;
  int _quantityMinPrice = 0;
  int _quantityMaxPrice = 999999;
  String _productType = '';
  String _provider = '';

  // listeners
  void _categoryIdControllerProcessor() {
    _categoryId = int.tryParse(_categoryIdController.text)!;
  }
  void _productPriceControllerProcessor() {
    _productPrice = double.tryParse(_productPriceController.text.replaceAll(RegExp(','), '.'))!;
  }
  void _valueDiscountControllerProcessor() {
    _valueDiscount = double.tryParse(_valueDiscountController.text.replaceAll(RegExp(','), '.'))!;
  }
  void _percentDiscountControllerProcessor() {
    _percentDiscount = double.tryParse (_percentDiscountController.text.replaceAll(RegExp(','), '.'))!;
  }
  void _weeksWarningControllerProcessor() {
    _weekWarning = int.tryParse(_weeksWarningController.text)!;
  }
  void _quantityMinPriceControllerProcessor() {
    _quantityMinPrice = int.tryParse(_quantityMinPriceController.text)!;
  }
  void _quantityMaxPriceControllerProcessor() {
    _quantityMaxPrice = int.tryParse(_quantityMaxPriceController.text)!;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _taxType = (widget.data.taxTypeItems[0].taxType);
    _unitType = (widget.data.unitTypeItems[0].idUnit);
    _productType = (widget.data.productTypeItems[0].productType);
    _provider = (widget.data.providerItems[0].personeName);
    _categoryIdController.text = _categoryId.toString();
    _categoryIdController.addListener(_categoryIdControllerProcessor);
    _productPriceController.text = NumberFormat('##0.00', 'es_ES').format(double.parse((0.00).toString()));
    _productPriceController.addListener(_productPriceControllerProcessor);
    _valueDiscountController.text = NumberFormat('##0.00', 'es_ES').format(double.parse((0.00).toString()));
    _valueDiscountController.addListener(_valueDiscountControllerProcessor);
    _percentDiscountController.text = NumberFormat('##0.00', 'es_ES').format(double.parse((0.00).toString()));
    _percentDiscountController.addListener(_percentDiscountControllerProcessor);
    _weeksWarningController.text = _weekWarning.toString();
    _weeksWarningController.addListener(_weeksWarningControllerProcessor);
    _quantityMinPriceController.text = _quantityMinPrice.toString();
    _quantityMinPriceController.addListener(_quantityMinPriceControllerProcessor);
    _quantityMaxPriceController.text = _quantityMaxPrice.toString();
    _quantityMaxPriceController.addListener(_quantityMaxPriceControllerProcessor);
  }
  @override
  void dispose() {
    _productNameController.dispose();
    _categoryIdController.dispose();
    _valueDiscountController.dispose();
    _percentDiscountController.dispose();
    _weeksWarningController.dispose();
    _quantityMinPriceController.dispose();
    _quantityMaxPriceController.dispose();
    super.dispose();
  }
  _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }
  @override
  Widget build (BuildContext context) {
    return SafeArea(
        child: LayoutBuilder(
            builder: (context, constraints) {
              return Form(
                key: _formKey,
                child: ListView (
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                  children: [
                    Row (
                      children: <Widget>[
                        Flexible(
                          flex: 1,
                          child: TextFormField(
                            decoration: const InputDecoration (
                                labelText: 'Nombre del producto',
                                labelStyle: TextStyle(
                                    color: tanteLadenIconBrown
                                )
                            ),
                            style: const TextStyle (
                              fontWeight: FontWeight.w500,
                              fontSize: 24.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                            controller: _productNameController,
                          ),
                        ),
                      ],
                    ),
                    Row (
                      children: <Widget>[
                        Flexible(
                          flex: 3,
                          child: TextFormField (
                            decoration: const InputDecoration (
                                labelText: 'Id. Categoría',
                                labelStyle: TextStyle(
                                    color: tanteLadenIconBrown
                                )
                            ),
                            style: const TextStyle (
                              fontWeight: FontWeight.w500,
                              fontSize: 24.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                            controller: _categoryIdController,
                            keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^[0-9]{1,3}$'))],
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            onEditingComplete: () {
                              _categoryId = int.tryParse(_weeksWarningController.text)!;
                              debugPrint('El valor de: _categoryId es: $_categoryId');
                            },
                            validator: (String? value) {
                              RegExp regexp = RegExp(r'^[0-9]{1,3}$');
                              if (!regexp.hasMatch(value ?? "") || value == null) {
                                return 'Introduce un valor entero entre 0 y 999';
                              } else {
                                return null;
                              }
                            },
                          ),
                        ),
                        Flexible(flex: 1, child: Container())
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Flexible(
                            flex: 2,
                            child: TextFormField (
                              controller: _productPriceController,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.euro_rounded),
                                labelText: 'Precio',
                                labelStyle: TextStyle (
                                    color: tanteLadenIconBrown
                                ),
                              ),
                              style: const TextStyle (
                                fontWeight: FontWeight.w500,
                                fontSize: 24.0,
                                fontFamily: 'SF Pro Display',
                                fontStyle: FontStyle.normal,
                                color: Colors.black,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('^\\d?\\d?\\,?\\d?\\d?\$')),],
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              onEditingComplete: () {
                                _productPrice = double.tryParse(_productPriceController.text.replaceAll(RegExp(','), '.'))!;
                                debugPrint('El valor de: productPrice es: $_productPrice');
                              },
                              validator: (String? value) {
                                RegExp regexp = RegExp('^\\d?\\d?\\,?\\d?\\d?\$');
                                if (!regexp.hasMatch(value ?? "") || value == null) {
                                  return 'Introduce un valor para el precio válido. Formato: ##,##';
                                } else {
                                  return null;
                                }
                              },
                            )
                        ),
                        Flexible(
                            flex: 2,
                            child: Container()
                        )
                      ],
                    ),
                    const SizedBox(height: 10.0,),
                    const Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text (
                          'Tipo de descuento',
                          style: TextStyle (
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: tanteLadenIconBrown,
                          ),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ],
                    ),
                    Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded (
                            flex: 1,
                            child: ListTile(
                              title: const Text('Valor'),
                              leading: Radio<PriceChangeType>(
                                value: PriceChangeType.priceValue,
                                groupValue: _changeType,
                                onChanged: (PriceChangeType? value) {
                                  setState(() {
                                    _changeType = value!;
                                    _valueDiscount = 0.0;
                                    _percentDiscount = 0.0;
                                  });
                                  _valueDiscountController.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                  _percentDiscountController.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
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
                                  });
                                  _percentDiscountController.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
                                  _valueDiscountController.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                },
                              ),
                            )
                        )
                      ],
                    ),
                    (_changeType == PriceChangeType.priceValue) ? const Text(
                      'Descuento neto',
                      style: TextStyle (
                        fontWeight: FontWeight.w500,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: tanteLadenIconBrown,
                      ),
                    ) : const Text (
                      'Descuento porcentual',
                      style: TextStyle (
                        fontWeight: FontWeight.w500,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: tanteLadenIconBrown,
                      ),
                    ),
                    (_changeType == PriceChangeType.priceValue) ? Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Flexible (
                          flex: 1,
                          child: TextFormField(
                            controller: _valueDiscountController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.euro_rounded),
                              prefixStyle: TextStyle (
                                fontWeight: FontWeight.w700,
                                fontSize: 24.0,
                                fontFamily: 'SF Pro Display',
                                fontStyle: FontStyle.normal,
                                color: Colors.black45,
                              ),
                            ),
                            style: const TextStyle (
                              fontWeight: FontWeight.w500,
                              fontSize: 24.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$')),],
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            onEditingComplete: () {
                              _valueDiscount = double.tryParse(_valueDiscountController.text.replaceAll(RegExp(','), '.'))!;
                            },
                            validator: (String? value) {
                              RegExp regexp = RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$');
                              if (!regexp.hasMatch(value ?? "") || value == null) {
                                return 'Introduce un valor neto válido. Formato: (+/-)##,##';
                              } else {
                                return null;
                              }
                            },
                          ),
                        ),
                        Flexible(
                            flex: 1,
                            child: Container()
                        )
                      ],
                    ): Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Flexible(
                          child: TextFormField (
                            controller: _percentDiscountController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.percent_rounded),
                              prefixStyle: TextStyle (
                                fontWeight: FontWeight.w700,
                                fontSize: 24.0,
                                fontFamily: 'SF Pro Display',
                                fontStyle: FontStyle.normal,
                                color: Colors.black45,
                              ),
                            ),
                            style: const TextStyle (
                              fontWeight: FontWeight.w500,
                              fontSize: 24.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$')),],
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            onEditingComplete: () {
                              _percentDiscount = double.tryParse (_percentDiscountController.text.replaceAll(RegExp(','), '.'))!;
                              debugPrint('El valor de: _percentDiscount es: $_percentDiscount');
                            },
                            validator: (String? value) {
                              RegExp regexp = RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$');
                              if (!regexp.hasMatch(value ?? "") || value == null) {
                                return 'Introduce un porcentaje válido. Formato: (+/-)##,##';
                              } else {
                                return null;
                              }
                            },
                          ),
                        ),
                        Flexible(child: Container())
                      ],
                    ),
                    const SizedBox(height: 10.0,),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text (
                          'Tipo de IVA',
                          style: TextStyle (
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: tanteLadenIconBrown,
                          ),
                        ),
                      ],
                    ),
                    Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:<Widget> [
                        Flexible(
                          flex: 1,
                          child: DropdownButtonFormField (
                            decoration: InputDecoration (
                              enabledBorder: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              border: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              filled: true,
                              fillColor: tanteLadenAmber100,
                            ),
                            iconEnabledColor: Colors.black,
                            focusColor: tanteLadenAmber100,
                            dropdownColor: tanteLadenAmber100,
                            value: _taxType,
                            items: widget.data.taxTypeItems.map<DropdownMenuItem<String>>((TaxType value) {
                              return DropdownMenuItem<String>(
                                value: value.taxType,
                                child: Text(
                                  value.taxType,
                                  style: const TextStyle (
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.black,
                                      overflow: TextOverflow.visible
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _taxType = newValue!;
                              });
                            },
                          ),
                        ),
                        Flexible(flex:1, child: Container())
                      ],
                    ),
                    const SizedBox(height: 10.0,),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text (
                          'Tipo de unidad',
                          style: TextStyle (
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: tanteLadenIconBrown,
                          ),
                        ),
                      ],
                    ),
                    Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:<Widget> [
                        Flexible(
                          flex: 1,
                          child: DropdownButtonFormField (
                            decoration: InputDecoration (
                              enabledBorder: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              border: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              filled: true,
                              fillColor: tanteLadenAmber100,
                            ),
                            iconEnabledColor: Colors.black,
                            focusColor: tanteLadenAmber100,
                            dropdownColor: tanteLadenAmber100,
                            value: _unitType,
                            items: widget.data.unitTypeItems.map<DropdownMenuItem<String>>((UnitType value){
                              return DropdownMenuItem<String>(
                                value: value.idUnit,
                                child: Text(
                                  value.idUnit,
                                  style: const TextStyle (
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.black,
                                      overflow: TextOverflow.visible
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _unitType = newValue!;
                              });
                            },
                          ),
                        ),
                        Flexible(flex:1, child: Container())
                      ],
                    ),
                    const SizedBox(height: 10.0,),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text (
                          'Tipo de producto',
                          style: TextStyle (
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: tanteLadenIconBrown,
                          ),
                        ),
                      ],
                    ),
                    Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:<Widget> [
                        Flexible(
                          flex: 1,
                          child: DropdownButtonFormField (
                            decoration: InputDecoration (
                              enabledBorder: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              border: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              filled: true,
                              fillColor: tanteLadenAmber100,
                            ),
                            //dropdownColor: Colors.blueAccent,
                            iconEnabledColor: tanteLadenIconBrown,
                            focusColor: tanteLadenAmber100,
                            dropdownColor: tanteLadenAmber100,
                            value: _productType,
                            items: widget.data.productTypeItems.map<DropdownMenuItem<String>>((ProductType value) {
                              return DropdownMenuItem<String>(
                                value: value.productType,
                                child: Text(
                                  value.productType,
                                  style: const TextStyle (
                                    fontWeight: FontWeight.w500,
                                    fontSize: 20.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  softWrap: true,
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _productType = newValue!;
                              });
                            },
                            isExpanded: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0,),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text (
                          'Proveedor',
                          style: TextStyle (
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: tanteLadenIconBrown,
                          ),
                        ),
                      ],
                    ),
                    Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:<Widget> [
                        Flexible (
                          flex: 1,
                          child: DropdownButtonFormField(
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              border: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              filled: true,
                              fillColor: tanteLadenAmber100,
                            ),
                            //dropdownColor: Colors.blueAccent,
                            iconEnabledColor: Colors.black,
                            focusColor: tanteLadenAmber100,
                            dropdownColor: tanteLadenAmber100,
                            value: _provider,
                            items: widget.data.providerItems.map<DropdownMenuItem<String>>((ProviderProduct value) {
                              return DropdownMenuItem<String> (
                                value: value.personeName,
                                child: Text(
                                  value.personeName,
                                  style: const TextStyle (
                                    fontWeight: FontWeight.w500,
                                    fontSize: 20.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  softWrap: true,
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _provider = newValue!;
                              });
                            },
                            isExpanded: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0,),
                    Row (
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Flexible(
                          flex: 2,
                          child: TextFormField(
                            controller: _weeksWarningController,
                            decoration: const InputDecoration (
                                labelText: 'Semanas de aviso',
                                labelStyle: TextStyle(
                                    color: tanteLadenIconBrown
                                )
                            ),
                            style: const TextStyle (
                              fontWeight: FontWeight.w500,
                              fontSize: 24.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^[0-9]{1,2}$'))],
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            onEditingComplete: () {
                              _weekWarning = int.tryParse(_weeksWarningController.text)!;
                              debugPrint('El valor de: _weekWarning es: $_weekWarning');
                            },
                            validator: (String? value) {
                              RegExp regexp = RegExp(r'^[0-9]{1,2}$');
                              if (!regexp.hasMatch(value ?? "") || value == null) {
                                return 'Introduce un valor válido. Formato: ##. Introduce un valor entre 0 y 99';
                              } else {
                                return null;
                              }
                            },
                          ),
                        ),
                        Flexible(flex: 2, child: Container())
                      ],
                    ),
                    Row (
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Flexible(
                          flex: 2,
                          child: TextFormField(
                            controller: _quantityMinPriceController,
                            decoration: const InputDecoration (
                                labelText: 'Cantidad mínima',
                                labelStyle: TextStyle(
                                    color: tanteLadenIconBrown
                                )
                            ),
                            style: const TextStyle (
                              fontWeight: FontWeight.w500,
                              fontSize: 24.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^[0-9]{1,6}$'))],
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            onEditingComplete: () {
                              _quantityMinPrice = int.tryParse(_quantityMinPriceController.text)!;
                            },
                            validator: (String? value) {
                              RegExp regexp = RegExp(r'^[0-9]{1,6}$');
                              if (!regexp.hasMatch(value ?? "") || value == null) {
                                return 'Introduce un valor válido. Formato: ######. Valor entre 0 y 999999';
                              } else {
                                return null;
                              }
                            },
                          ),
                        ),
                        Flexible(flex: 2, child: Container())
                      ],
                    ),
                    Row (
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Flexible(
                          flex: 2,
                          child: TextFormField(
                            controller: _quantityMaxPriceController,
                            decoration: const InputDecoration (
                                labelText: 'Cantidad máxima',
                                labelStyle: TextStyle(
                                    color: tanteLadenIconBrown
                                )
                            ),
                            style: const TextStyle (
                              fontWeight: FontWeight.w500,
                              fontSize: 24.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^[0-9]{1,6}$'))],
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            onEditingComplete: () {
                              _quantityMaxPrice = int.tryParse(_quantityMaxPriceController.text)!;
                            },
                            validator: (String? value) {
                              RegExp regexp = RegExp(r'^[0-9]{1,6}$');
                              if (!regexp.hasMatch(value ?? "") || value == null) {
                                return 'Introduce un valor válido. Formato: ######. Valor entre 0 y 999999';
                              } else {
                                return null;
                              }
                            },
                          ),
                        ),
                        Flexible(flex: 2, child: Container())
                      ],
                    ),
                    const SizedBox (height: 40.0,),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 10.0),
                      child: Row (
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          GestureDetector(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 80.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration (
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(8.0),
                                    gradient: const LinearGradient (
                                        colors: <Color> [
                                          Color (0xFF833C26),
                                          Color (0xFF9A541F),
                                          Color (0xFFF9B806),
                                          Color (0XFFFFC107),
                                        ]
                                    )
                                ),
                                height: 64.0,
                                child: const Text(
                                  'Añadir Producto',
                                  style: TextStyle(
                                      fontSize: 24.0,
                                      color: tanteLadenBackgroundWhite
                                  ),
                                ),
                              ),
                              onTap: () async {
                                try {
                                  _showPleaseWait(true);
                                  Future<SharedPreferences> prefs0 = SharedPreferences.getInstance();
                                  final SharedPreferences prefs = await prefs0;
                                  final String token = prefs.getString ('token') ?? '';
                                  Map<String, dynamic> payload;
                                  payload = json.decode(
                                      utf8.decode(
                                          base64.decode (base64.normalize(token.split(".")[1]))
                                      )
                                  );
                                  final String partnerId = payload['partner_id'].toString();
                                  final String partnerName = payload['partner_name'].toString();
                                  final String userCreateId = payload['user_id'].toString();
                                  widget.service.saveProduct(
                                      categoryId: _categoryId,
                                      productName: _productNameController.text,
                                      minQuantitySell: _quantityMinPrice,
                                      productPrice: _productPrice,
                                      discountType: _changeType,
                                      discountValue: (_changeType == PriceChangeType.priceValue) ? _valueDiscount : _percentDiscount,
                                      taxType: _taxType,
                                      idUnit: _unitType,
                                      weeksWarning: _weekWarning,
                                      quantityMinPrice: _quantityMinPrice.toDouble(),
                                      quantityMaxPrice: _quantityMaxPrice.toDouble(),
                                      productType: _productType,
                                      personeName: _provider,
                                      partnerId: int.parse(partnerId),
                                      partnerName: partnerName,
                                      userCreateId: int.parse(userCreateId)
                                  );
                                  _showPleaseWait(false);
                                } catch(e) {
                                  _showPleaseWait(false);
                                  //ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'].toString());
                                }
                              }
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
        )
    );
  }
}
class _LargeScreenView extends StatefulWidget {
  final NewProductData data;
  final NewProductService service;
  const _LargeScreenView (this.data, this.service);
  @override
  _LargeScreenViewState createState() {
    return _LargeScreenViewState();
  }
}
class _LargeScreenViewState extends State <_LargeScreenView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _categoryIdController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _valueDiscountController = TextEditingController();
  final TextEditingController _percentDiscountController = TextEditingController();
  final TextEditingController _weeksWarningController = TextEditingController();
  final TextEditingController _quantityMinPriceController = TextEditingController();
  final TextEditingController _quantityMaxPriceController = TextEditingController();
  // vars
  bool _pleaseWait = false;
  double _productPrice = 0.0;
  PriceChangeType _changeType = PriceChangeType.priceValue;
  double _valueDiscount = 0.0;
  double _percentDiscount = 0.0;
  String _unitType = '';
  String _taxType = '';
  int _weekWarning = 0;
  int _categoryId = 0;
  int _quantityMinPrice = 0;
  int _quantityMaxPrice = 999999;
  String _productType = '';
  String _provider = '';

  // listeners
  void _categoryIdControllerProcessor() {
    _categoryId = int.tryParse(_categoryIdController.text)!;
  }
  void _productPriceControllerProcessor() {
    _productPrice = double.tryParse(_productPriceController.text.replaceAll(RegExp(','), '.'))!;
  }
  void _valueDiscountControllerProcessor() {
    _valueDiscount = double.tryParse(_valueDiscountController.text.replaceAll(RegExp(','), '.'))!;
  }
  void _percentDiscountControllerProcessor() {
    _percentDiscount = double.tryParse (_percentDiscountController.text.replaceAll(RegExp(','), '.'))!;
  }
  void _weeksWarningControllerProcessor() {
    _weekWarning = int.tryParse(_weeksWarningController.text)!;
  }
  void _quantityMinPriceControllerProcessor() {
    _quantityMinPrice = int.tryParse(_quantityMinPriceController.text)!;
  }
  void _quantityMaxPriceControllerProcessor() {
    _quantityMaxPrice = int.tryParse(_quantityMaxPriceController.text)!;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _taxType = (widget.data.taxTypeItems[0].taxType);
    _unitType = (widget.data.unitTypeItems[0].idUnit);
    _productType = (widget.data.productTypeItems[0].productType);
    _provider = (widget.data.providerItems[0].personeName);
    _categoryIdController.text = _categoryId.toString();
    _categoryIdController.addListener(_categoryIdControllerProcessor);
    _productPriceController.text = NumberFormat('##0.00', 'es_ES').format(double.parse((0.00).toString()));
    _productPriceController.addListener(_productPriceControllerProcessor);
    _valueDiscountController.text = NumberFormat('##0.00', 'es_ES').format(double.parse((0.00).toString()));
    _valueDiscountController.addListener(_valueDiscountControllerProcessor);
    _percentDiscountController.text = NumberFormat('##0.00', 'es_ES').format(double.parse((0.00).toString()));
    _percentDiscountController.addListener(_percentDiscountControllerProcessor);
    _weeksWarningController.text = _weekWarning.toString();
    _weeksWarningController.addListener(_weeksWarningControllerProcessor);
    _quantityMinPriceController.text = _quantityMinPrice.toString();
    _quantityMinPriceController.addListener(_quantityMinPriceControllerProcessor);
    _quantityMaxPriceController.text = _quantityMaxPrice.toString();
    _quantityMaxPriceController.addListener(_quantityMaxPriceControllerProcessor);
  }
  @override
  void dispose() {
    _productNameController.dispose();
    _categoryIdController.dispose();
    _valueDiscountController.dispose();
    _percentDiscountController.dispose();
    _weeksWarningController.dispose();
    _quantityMinPriceController.dispose();
    _quantityMaxPriceController.dispose();
    super.dispose();
  }
  _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }
  @override
  Widget build (BuildContext context) {
    return SafeArea(
        child: LayoutBuilder(
            builder: (context, constraints) {
              return Form(
                key: _formKey,
                child: ListView (
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                  children: [
                    Row (
                      children: <Widget>[
                        Flexible(
                          flex: 1,
                          child: TextFormField(
                            decoration: const InputDecoration (
                                labelText: 'Nombre del producto',
                                labelStyle: TextStyle(
                                    color: tanteLadenIconBrown
                                )
                            ),
                            style: const TextStyle (
                              fontWeight: FontWeight.w500,
                              fontSize: 24.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                            controller: _productNameController,
                          ),
                        ),
                      ],
                    ),
                    Row (
                      children: <Widget>[
                        Flexible(
                          flex: 3,
                          child: TextFormField (
                            decoration: const InputDecoration (
                                labelText: 'Id. Categoría',
                                labelStyle: TextStyle(
                                    color: tanteLadenIconBrown
                                )
                            ),
                            style: const TextStyle (
                              fontWeight: FontWeight.w500,
                              fontSize: 24.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                            controller: _categoryIdController,
                            keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^[0-9]{1,3}$'))],
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            onEditingComplete: () {
                              _categoryId = int.tryParse(_weeksWarningController.text)!;
                              debugPrint('El valor de: _categoryId es: $_categoryId');
                            },
                            validator: (String? value) {
                              RegExp regexp = RegExp(r'^[0-9]{1,3}$');
                              if (!regexp.hasMatch(value ?? "") || value == null) {
                                return 'Introduce un valor entero entre 0 y 999';
                              } else {
                                return null;
                              }
                            },
                          ),
                        ),
                        Flexible(flex: 1, child: Container())
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Flexible(
                            flex: 2,
                            child: TextFormField (
                              controller: _productPriceController,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.euro_rounded),
                                labelText: 'Precio',
                                labelStyle: TextStyle (
                                    color: tanteLadenIconBrown
                                ),
                              ),
                              style: const TextStyle (
                                fontWeight: FontWeight.w500,
                                fontSize: 24.0,
                                fontFamily: 'SF Pro Display',
                                fontStyle: FontStyle.normal,
                                color: Colors.black,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('^\\d?\\d?\\,?\\d?\\d?\$')),],
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              onEditingComplete: () {
                                _productPrice = double.tryParse(_productPriceController.text.replaceAll(RegExp(','), '.'))!;
                                debugPrint('El valor de: productPrice es: $_productPrice');
                              },
                              validator: (String? value) {
                                RegExp regexp = RegExp('^\\d?\\d?\\,?\\d?\\d?\$');
                                if (!regexp.hasMatch(value ?? "") || value == null) {
                                  return 'Introduce un valor para el precio válido. Formato: ##,##';
                                } else {
                                  return null;
                                }
                              },
                            )
                        ),
                        Flexible(
                            flex: 2,
                            child: Container()
                        )
                      ],
                    ),
                    const SizedBox(height: 10.0,),
                    const Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text (
                          'Tipo de descuento',
                          style: TextStyle (
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: tanteLadenIconBrown,
                          ),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ],
                    ),
                    Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded (
                            flex: 1,
                            child: ListTile(
                              title: const Text('Valor'),
                              leading: Radio<PriceChangeType>(
                                value: PriceChangeType.priceValue,
                                groupValue: _changeType,
                                onChanged: (PriceChangeType? value) {
                                  setState(() {
                                    _changeType = value!;
                                    _valueDiscount = 0.0;
                                    _percentDiscount = 0.0;
                                  });
                                  _valueDiscountController.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                  _percentDiscountController.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
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
                                  });
                                  _percentDiscountController.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_percentDiscount.toString()));
                                  _valueDiscountController.text = NumberFormat('##0.00', 'es_ES').format(double.parse(_valueDiscount.toString()));
                                },
                              ),
                            )
                        )
                      ],
                    ),
                    (_changeType == PriceChangeType.priceValue) ? const Text(
                      'Descuento neto',
                      style: TextStyle (
                        fontWeight: FontWeight.w500,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: tanteLadenIconBrown,
                      ),
                    ) : const Text (
                      'Descuento porcentual',
                      style: TextStyle (
                        fontWeight: FontWeight.w500,
                        fontSize: 24.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: tanteLadenIconBrown,
                      ),
                    ),
                    (_changeType == PriceChangeType.priceValue) ? Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Flexible (
                          flex: 1,
                          child: TextFormField(
                            controller: _valueDiscountController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.euro_rounded),
                              prefixStyle: TextStyle (
                                fontWeight: FontWeight.w700,
                                fontSize: 24.0,
                                fontFamily: 'SF Pro Display',
                                fontStyle: FontStyle.normal,
                                color: Colors.black45,
                              ),
                            ),
                            style: const TextStyle (
                              fontWeight: FontWeight.w500,
                              fontSize: 24.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$')),],
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            onEditingComplete: () {
                              _valueDiscount = double.tryParse(_valueDiscountController.text.replaceAll(RegExp(','), '.'))!;
                            },
                            validator: (String? value) {
                              RegExp regexp = RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$');
                              if (!regexp.hasMatch(value ?? "") || value == null) {
                                return 'Introduce un valor neto válido. Formato: (+/-)##,##';
                              } else {
                                return null;
                              }
                            },
                          ),
                        ),
                        Flexible(
                            flex: 1,
                            child: Container()
                        )
                      ],
                    ): Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Flexible(
                          child: TextFormField (
                            controller: _percentDiscountController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.percent_rounded),
                              prefixStyle: TextStyle (
                                fontWeight: FontWeight.w700,
                                fontSize: 24.0,
                                fontFamily: 'SF Pro Display',
                                fontStyle: FontStyle.normal,
                                color: Colors.black45,
                              ),
                            ),
                            style: const TextStyle (
                              fontWeight: FontWeight.w500,
                              fontSize: 24.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$')),],
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            onEditingComplete: () {
                              _percentDiscount = double.tryParse (_percentDiscountController.text.replaceAll(RegExp(','), '.'))!;
                              debugPrint('El valor de: _percentDiscount es: $_percentDiscount');
                            },
                            validator: (String? value) {
                              RegExp regexp = RegExp('^[+-]?\\d?\\d?\\,?\\d?\\d?\$');
                              if (!regexp.hasMatch(value ?? "") || value == null) {
                                return 'Introduce un porcentaje válido. Formato: (+/-)##,##';
                              } else {
                                return null;
                              }
                            },
                          ),
                        ),
                        Flexible(child: Container())
                      ],
                    ),
                    const SizedBox(height: 10.0,),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text (
                          'Tipo de IVA',
                          style: TextStyle (
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: tanteLadenIconBrown,
                          ),
                        ),
                      ],
                    ),
                    Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:<Widget> [
                        Flexible(
                          flex: 1,
                          child: DropdownButtonFormField (
                            decoration: InputDecoration (
                              enabledBorder: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              border: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              filled: true,
                              fillColor: tanteLadenAmber100,
                            ),
                            iconEnabledColor: Colors.black,
                            focusColor: tanteLadenAmber100,
                            dropdownColor: tanteLadenAmber100,
                            value: _taxType,
                            items: widget.data.taxTypeItems.map<DropdownMenuItem<String>>((TaxType value) {
                              return DropdownMenuItem<String>(
                                value: value.taxType,
                                child: Text(
                                  value.taxType,
                                  style: const TextStyle (
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.black,
                                      overflow: TextOverflow.visible
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _taxType = newValue!;
                              });
                            },
                          ),
                        ),
                        Flexible(flex:1, child: Container())
                      ],
                    ),
                    const SizedBox(height: 10.0,),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text (
                          'Tipo de unidad',
                          style: TextStyle (
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: tanteLadenIconBrown,
                          ),
                        ),
                      ],
                    ),
                    Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:<Widget> [
                        Flexible(
                          flex: 1,
                          child: DropdownButtonFormField (
                            decoration: InputDecoration (
                              enabledBorder: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              border: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              filled: true,
                              fillColor: tanteLadenAmber100,
                            ),
                            iconEnabledColor: Colors.black,
                            focusColor: tanteLadenAmber100,
                            dropdownColor: tanteLadenAmber100,
                            value: _unitType,
                            items: widget.data.unitTypeItems.map<DropdownMenuItem<String>>((UnitType value){
                              return DropdownMenuItem<String>(
                                value: value.idUnit,
                                child: Text(
                                  value.idUnit,
                                  style: const TextStyle (
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.black,
                                      overflow: TextOverflow.visible
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _unitType = newValue!;
                              });
                            },
                          ),
                        ),
                        Flexible(flex:1, child: Container())
                      ],
                    ),
                    const SizedBox(height: 10.0,),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text (
                          'Tipo de producto',
                          style: TextStyle (
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: tanteLadenIconBrown,
                          ),
                        ),
                      ],
                    ),
                    Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:<Widget> [
                        Flexible(
                          flex: 1,
                          child: DropdownButtonFormField (
                            decoration: InputDecoration (
                              enabledBorder: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              border: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              filled: true,
                              fillColor: tanteLadenAmber100,
                            ),
                            //dropdownColor: Colors.blueAccent,
                            iconEnabledColor: tanteLadenIconBrown,
                            focusColor: tanteLadenAmber100,
                            dropdownColor: tanteLadenAmber100,
                            value: _productType,
                            items: widget.data.productTypeItems.map<DropdownMenuItem<String>>((ProductType value) {
                              return DropdownMenuItem<String>(
                                value: value.productType,
                                child: Text(
                                  value.productType,
                                  style: const TextStyle (
                                    fontWeight: FontWeight.w500,
                                    fontSize: 20.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  softWrap: true,
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _productType = newValue!;
                              });
                            },
                            isExpanded: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0,),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text (
                          'Proveedor',
                          style: TextStyle (
                            fontWeight: FontWeight.w500,
                            fontSize: 24.0,
                            fontFamily: 'SF Pro Display',
                            fontStyle: FontStyle.normal,
                            color: tanteLadenIconBrown,
                          ),
                        ),
                      ],
                    ),
                    Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:<Widget> [
                        Flexible (
                          flex: 1,
                          child: DropdownButtonFormField(
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              border: OutlineInputBorder (
                                borderSide: const BorderSide (color: tanteLadenAmber100, width: 2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              filled: true,
                              fillColor: tanteLadenAmber100,
                            ),
                            //dropdownColor: Colors.blueAccent,
                            iconEnabledColor: Colors.black,
                            focusColor: tanteLadenAmber100,
                            dropdownColor: tanteLadenAmber100,
                            value: _provider,
                            items: widget.data.providerItems.map<DropdownMenuItem<String>>((ProviderProduct value) {
                              return DropdownMenuItem<String> (
                                value: value.personeName,
                                child: Text(
                                  value.personeName,
                                  style: const TextStyle (
                                    fontWeight: FontWeight.w500,
                                    fontSize: 20.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  softWrap: true,
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _provider = newValue!;
                              });
                            },
                            isExpanded: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0,),
                    Row (
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Flexible(
                          flex: 2,
                          child: TextFormField(
                            controller: _weeksWarningController,
                            decoration: const InputDecoration (
                                labelText: 'Semanas de aviso',
                                labelStyle: TextStyle(
                                    color: tanteLadenIconBrown
                                )
                            ),
                            style: const TextStyle (
                              fontWeight: FontWeight.w500,
                              fontSize: 24.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^[0-9]{1,2}$'))],
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            onEditingComplete: () {
                              _weekWarning = int.tryParse(_weeksWarningController.text)!;
                              debugPrint('El valor de: _weekWarning es: $_weekWarning');
                            },
                            validator: (String? value) {
                              RegExp regexp = RegExp(r'^[0-9]{1,2}$');
                              if (!regexp.hasMatch(value ?? "") || value == null) {
                                return 'Introduce un valor válido. Formato: ##. Introduce un valor entre 0 y 99';
                              } else {
                                return null;
                              }
                            },
                          ),
                        ),
                        Flexible(flex: 2, child: Container())
                      ],
                    ),
                    Row (
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Flexible(
                          flex: 2,
                          child: TextFormField(
                            controller: _quantityMinPriceController,
                            decoration: const InputDecoration (
                                labelText: 'Cantidad mínima',
                                labelStyle: TextStyle(
                                    color: tanteLadenIconBrown
                                )
                            ),
                            style: const TextStyle (
                              fontWeight: FontWeight.w500,
                              fontSize: 24.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^[0-9]{1,6}$'))],
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            onEditingComplete: () {
                              _quantityMinPrice = int.tryParse(_quantityMinPriceController.text)!;
                            },
                            validator: (String? value) {
                              RegExp regexp = RegExp(r'^[0-9]{1,6}$');
                              if (!regexp.hasMatch(value ?? "") || value == null) {
                                return 'Introduce un valor válido. Formato: ######. Valor entre 0 y 999999';
                              } else {
                                return null;
                              }
                            },
                          ),
                        ),
                        Flexible(flex: 2, child: Container())
                      ],
                    ),
                    Row (
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Flexible(
                          flex: 2,
                          child: TextFormField(
                            controller: _quantityMaxPriceController,
                            decoration: const InputDecoration (
                                labelText: 'Cantidad máxima',
                                labelStyle: TextStyle(
                                    color: tanteLadenIconBrown
                                )
                            ),
                            style: const TextStyle (
                              fontWeight: FontWeight.w500,
                              fontSize: 24.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^[0-9]{1,6}$'))],
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            onEditingComplete: () {
                              _quantityMaxPrice = int.tryParse(_quantityMaxPriceController.text)!;
                            },
                            validator: (String? value) {
                              RegExp regexp = RegExp(r'^[0-9]{1,6}$');
                              if (!regexp.hasMatch(value ?? "") || value == null) {
                                return 'Introduce un valor válido. Formato: ######. Valor entre 0 y 999999';
                              } else {
                                return null;
                              }
                            },
                          ),
                        ),
                        Flexible(flex: 2, child: Container())
                      ],
                    ),
                    const SizedBox (height: 40.0,),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 10.0),
                      child: Row (
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          GestureDetector(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 80.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration (
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(8.0),
                                    gradient: const LinearGradient (
                                        colors: <Color> [
                                          Color (0xFF833C26),
                                          Color (0xFF9A541F),
                                          Color (0xFFF9B806),
                                          Color (0XFFFFC107),
                                        ]
                                    )
                                ),
                                height: 64.0,
                                child: const Text(
                                  'Añadir Producto',
                                  style: TextStyle(
                                      fontSize: 24.0,
                                      color: tanteLadenBackgroundWhite
                                  ),
                                ),
                              ),
                              onTap: () async {
                                try {
                                  _showPleaseWait(true);
                                  Future<SharedPreferences> prefs0 = SharedPreferences.getInstance();
                                  final SharedPreferences prefs = await prefs0;
                                  final String token = prefs.getString ('token') ?? '';
                                  Map<String, dynamic> payload;
                                  payload = json.decode(
                                      utf8.decode(
                                          base64.decode (base64.normalize(token.split(".")[1]))
                                      )
                                  );
                                  final String partnerId = payload['partner_id'].toString();
                                  final String partnerName = payload['partner_name'].toString();
                                  final String userCreateId = payload['user_id'].toString();
                                  widget.service.saveProduct(
                                      categoryId: _categoryId,
                                      productName: _productNameController.text,
                                      minQuantitySell: _quantityMinPrice,
                                      productPrice: _productPrice,
                                      discountType: _changeType,
                                      discountValue: (_changeType == PriceChangeType.priceValue) ? _valueDiscount : _percentDiscount,
                                      taxType: _taxType,
                                      idUnit: _unitType,
                                      weeksWarning: _weekWarning,
                                      quantityMinPrice: _quantityMinPrice.toDouble(),
                                      quantityMaxPrice: _quantityMaxPrice.toDouble(),
                                      productType: _productType,
                                      personeName: _provider,
                                      partnerId: int.parse(partnerId),
                                      partnerName: partnerName,
                                      userCreateId: int.parse(userCreateId)
                                  );
                                  _showPleaseWait(false);
                                } catch(e) {
                                  _showPleaseWait(false);
                                  //ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'].toString());
                                }
                              }
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
        )
    );
  }
}