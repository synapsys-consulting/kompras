import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kompras/model/Cart.model.dart';
import 'package:kompras/model/Catalog.model.dart';
import 'package:kompras/model/MultiPricesProductAvail.model.dart';
import 'package:kompras/util/DisplayDialog.util.dart';
import 'package:kompras/util/MultiPriceListElement.util.dart';
import 'package:kompras/util/color.util.dart';
import 'package:kompras/util/configuration.util.dart';
import 'package:provider/provider.dart';

class LookingForProducts extends StatefulWidget {
  const LookingForProducts({super.key});

@override
  _LookingForProductsState createState() {
    return _LookingForProductsState();
  }
}
class _LookingForProductsState extends State<LookingForProducts> {
  final TextEditingController _searchController = TextEditingController();
  List<MultiPricesProductAvail> _productList = [];
  late Timer _throttle;

  @override
  void initState() {
    super.initState();
    _searchController.addListener (_onSearchChanged);
  }
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _productList.clear();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          //automaticallyImplyLeading: false,   //if false and leading is null, leading space is given to title.
          //leading: null,
          backgroundColor: tanteLadenBackgroundWhite,
          title: _AccentColorOverride(
            color: tanteLadenOnPrimary,
            child: TextField (
              controller: _searchController,
              decoration: InputDecoration (
                  prefixIcon: const Icon(Icons.youtube_searched_for_outlined),
                  labelText: 'Buscar producto',
                  //helperText: 'Teclea el nombre de la calle que quieres buscar',
                  suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _productList.clear();
                        });
                      }
                  )
              ),
            ),
          ),
        ),
        body: buildBody(context)
    );
  }
  Widget buildBody (BuildContext context) {
    var catalog = context.read<Catalog>();
    var cart = context.read<Cart>();
    return LayoutBuilder(
        builder: (context, constraints) {
          return SafeArea(
              child: Padding (
                  padding: const EdgeInsets.only(top: 5.0),
                  child: GridView.builder (
                      itemCount: _productList.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: (constraints.maxWidth > 1200) ? 3 : 2,
                          childAspectRatio: (constraints.maxWidth > 1200) ? 200.0 / 281.0 : 200.0 / 303.0
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
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        //padding: EdgeInsets.fromLTRB(15.0, 5.0, 15.0, 0.0),
                                        alignment: Alignment.center,
                                        width: constraints.maxWidth,
                                        child: AspectRatio(
                                          aspectRatio: 3.0 / 2.0,
                                          child: CachedNetworkImage(
                                            placeholder: (context, url) => const CircularProgressIndicator(),
                                            imageUrl: '$SERVER_IP$IMAGES_DIRECTORY${_productList[index].productCode}_0.gif',
                                            fit: BoxFit.scaleDown,
                                            errorWidget: (context, url, error) => const Icon(Icons.error),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(15.0, 0.0, 0.0, 0.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: Image.asset('assets/images/00001.png'),
                                        ),
                                        Container (
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: Text.rich (
                                            TextSpan (
                                                text: NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((_productList[index].totalAmountAccordingQuantity/MULTIPLYING_FACTOR).toString())),
                                                style: const TextStyle (
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 24.0,
                                                  fontFamily: 'SF Pro Display',
                                                ),
                                                //textAlign: TextAlign.start
                                                children: <TextSpan>[
                                                  TextSpan (
                                                    text: _productList[index].totalAmountAccordingQuantity == _productList[index].totalAmount
                                                        ? ''
                                                        : ' (${NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((_productList[index].totalAmount/MULTIPLYING_FACTOR).toString()))})',
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
                                        _productList[index].quantityMaxPrice != QUANTITY_MAX_PRICE ? Container (
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
                                              if (_productList[index].quantityMaxPrice != QUANTITY_MAX_PRICE) {
                                                // There is multiprice for this product
                                                final item = MultiPriceListElement(_productList[index].quantityMinPrice, _productList[index].quantityMaxPrice, _productList[index].totalAmount);
                                                listMultiPriceListElement.add(item);
                                                _productList[index].items.where((element) => element.partnerId != 1)
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
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container (
                                        padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                                        width: constraints.maxWidth,
                                        child: Text(
                                          _productList[index].productName,
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
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container (
                                        padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                                        child: Text (
                                          _productList[index].businessName,
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
                                      visible : _productList[index].purchased == 0,
                                      replacement: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            (_productList[index].purchased > 1) ? '${_productList[index].purchased} ${_productList[index].idUnit}s.' : '${_productList[index].purchased} ${_productList[index].idUnit}.',
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
                                                  visible: (_productList[index].purchased > 1) ? true : false,
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
                                                        if (_productList[index].purchased > 1) {
                                                          // Manage the item of the local list
                                                          // Manage the delete of the _productList
                                                          (_productList[index].purchased == _productList[index].minQuantitySell) ? _productList[index].purchased = 0 : _productList[index].purchased -= _productList[index].minQuantitySell;
                                                          _productList[index].totalAmountAccordingQuantity = _productList[index].getTotalAmountAccordingQuantity();   // Update the price according the quantity purchased
                                                        }
                                                      });
                                                      cart.remove(_productList[index]);
                                                      catalog.remove(_productList[index]);
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
                                                      _productList[index].purchased += _productList[index].minQuantitySell;
                                                      _productList[index].totalAmountAccordingQuantity = _productList[index].getTotalAmountAccordingQuantity();   // Update the price according the quantity purchased
                                                    });
                                                    cart.add(_productList[index]);
                                                    catalog.add(_productList[index]);
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
                                              Text(
                                                  'Unids. mín. venta: ${_productList[index].minQuantitySell} ${(_productList[index].minQuantitySell > 1) ? '${_productList[index].idUnit}s.' : '${_productList[index].idUnit}.'}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w300,
                                                    fontSize: 12.0,
                                                    fontFamily: 'SF Pro Display',
                                                    fontStyle: FontStyle.normal,
                                                    color: Color(0xFF6C6D77),
                                                  ),
                                                  textAlign: TextAlign.start
                                              )
                                            ],
                                          ),
                                          TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  // Manage the item of the local list
                                                  // Manage the add of the _productList
                                                  _productList[index].purchased += _productList[index].minQuantitySell;
                                                  _productList[index].totalAmountAccordingQuantity = _productList[index].getTotalAmountAccordingQuantity(); // Update the price according the quantity purchased
                                                });
                                                catalog.add(_productList[index]);
                                                cart.add(_productList[index]);
                                              },
                                              child: Container(
                                                alignment: Alignment.center,
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
              )
          );
        }
    );
  }
  _onSearchChanged() {
    debugPrint('Entro en onS');
    //if (_throttle.isActive) _throttle.cancel();
    debugPrint('Antes de inicializar el timer _throttle');
    _throttle = Timer (const Duration(microseconds: 100), () {
      if (_searchController.text != '') {
        _getProductResults(_searchController.text);
      }
    });
  }
  void _getProductResults (String input) {
    List<MultiPricesProductAvail> tempProductList = [];
    RegExp exp = RegExp (input, caseSensitive: false);
    var catalog = context.read<Catalog>();
    for (var i = 0; i < catalog.numItems; i++) {
      if (exp.hasMatch(catalog.getItem(i).productName)) {
        // Add the catalog element to the temporal list
        final itemCatalog = MultiPricesProductAvail (
            productId: catalog.getItem(i).productId,
            productCode: catalog.getItem(i).productCode,
            productName: catalog.getItem(i).productName,
            productNameLong: catalog.getItem(i).productNameLong,
            productDescription: catalog.getItem(i).productDescription,
            productType: catalog.getItem(i).productType,
            brand: catalog.getItem(i).brand,
            numImages: catalog.getItem(i).numImages,
            numVideos: catalog.getItem(i).numVideos,
            purchased: catalog.getItem(i).purchased,
            productPrice: catalog.getItem(i).productPrice,
            totalBeforeDiscount: catalog.getItem(i).totalBeforeDiscount,
            taxAmount: catalog.getItem(i).taxAmount,
            personeId: catalog.getItem(i).personeId,
            personeName: catalog.getItem(i).personeName,
            businessName: catalog.getItem(i).businessName,
            email: catalog.getItem(i).email,
            taxId: catalog.getItem(i).taxId,
            taxApply: catalog.getItem(i).taxApply,
            productPriceDiscounted: catalog.getItem(i).productPriceDiscounted,
            totalAmount: catalog.getItem(i).totalAmount,
            discountAmount: catalog.getItem(i).discountAmount,
            idUnit: catalog.getItem(i).idUnit,
            remark: catalog.getItem(i).remark,
            minQuantitySell: catalog.getItem(i).minQuantitySell,
            partnerId: catalog.getItem(i).partnerId,
            partnerName: catalog.getItem(i).partnerName,
            quantityMinPrice: catalog.getItem(i).quantityMinPrice,
            quantityMaxPrice: catalog.getItem(i).quantityMaxPrice,
            productCategoryId: catalog.getItem(i).productCategoryId,
            rn: catalog.getItem(i).rn
        );
        if (catalog.getItem(i).numItems > 0) {
          catalog.getItem(i).items.forEach((element) {
            itemCatalog.add(element);
          });
        }
        tempProductList.add(itemCatalog);
      }
    }
    setState(() {
      _productList = tempProductList;
    });
  }
}
class _AccentColorOverride extends StatelessWidget {
  const _AccentColorOverride ({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(secondary: color),
        brightness: Brightness.dark,
      ),
      child: child,
    );
  }
}