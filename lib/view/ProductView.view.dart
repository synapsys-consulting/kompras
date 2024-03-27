import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kompras/model/Cart.model.dart';
import 'package:kompras/model/Catalog.model.dart';
import 'package:kompras/model/MultiPricesProductAvail.model.dart';
import 'package:kompras/util/ResponsiveWidget.util.dart';
import 'package:kompras/util/color.util.dart';
import 'package:kompras/util/configuration.util.dart';
import 'package:kompras/util/sizes.util.dart';
import 'package:provider/provider.dart';

class ProductView extends StatelessWidget {
  final MultiPricesProductAvail currentProduct;
  const ProductView (this.currentProduct, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      appBar: AppBar(
        elevation: 0.0,
        leading: IconButton(
            icon: Image.asset('assets/images/leftArrow.png'),
            onPressed: (){
              Navigator.pop(context);
            }
        ),
        title: Text(
          currentProduct.productName,
          style: const TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 16.0,
              fontWeight: FontWeight.w500
          ),
          textAlign: TextAlign.left,
        ),
      ),
      body: ResponsiveWidget(
        smallScreen: _SmallScreen (currentProduct),
        mediumScreen: _MediumScreen(currentProduct),
        largeScreen: _LargeScreen(currentProduct),
      ),
    );
  }
}
class _SmallScreen extends StatefulWidget {
  final MultiPricesProductAvail currentProduct;
  const _SmallScreen(this.currentProduct);
  @override
  _SmallScreenState createState() {
    return _SmallScreenState();
  }
}
class _SmallScreenState extends State<_SmallScreen> {
  //final MultiPricesProductAvail currentProduct;
  _SmallScreenState();

  // private variables
  int _current = 0; // Var to save the current carousel image

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _current = 0;
  }
  @override
  Widget build(BuildContext context) {
    debugPrint('El productId es: ${widget.currentProduct.productId}');
    debugPrint('El número de images es: ${widget.currentProduct.numImages}');
    // Process if the product has multiprice
    final List<_MultiPriceListElement> listMultiPriceListElement = [];
    if (widget.currentProduct.quantityMaxPrice != 999999) {
      // There is multiprice for this product
      final item = _MultiPriceListElement(widget.currentProduct.quantityMinPrice, widget.currentProduct.quantityMaxPrice, widget.currentProduct.totalAmount);
      listMultiPriceListElement.add(item);
      widget.currentProduct.items.where((element) => element.partnerId != 1)
          .forEach((element) {
        final item = _MultiPriceListElement(element.quantityMinPrice, element.quantityMaxPrice, element.totalAmount);
        listMultiPriceListElement.add(item);
      });
    }
    return SafeArea (
        child: LayoutBuilder (
          builder: (context, constraints) {
            var cart = context.read<Cart>();
            var catalog = context.read<Catalog>();
            final List<String> listImagesProduct = [];
            for (var i = 0; i < widget.currentProduct.numImages; i++){
              listImagesProduct.add('$SERVER_IP$IMAGES_DIRECTORY${widget.currentProduct.productCode}_$i.gif');
            }
            return ListView (
              children: [
                widget.currentProduct.numImages > 1
                    ? Column(
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
                        options: CarouselOptions (
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
                    )
                    : Container(
                        alignment: Alignment.center,
                        width: constraints.maxWidth,
                        child: AspectRatio(
                          aspectRatio: 3.0 / 2.0,
                          child: CachedNetworkImage(
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            imageUrl: '$SERVER_IP$IMAGES_DIRECTORY${widget.currentProduct.productCode}_0.gif',
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
                        child: Text(
                            NumberFormat.currency(locale:'en_US', symbol: '€', decimalDigits:2).format(double.parse((widget.currentProduct.totalAmountAccordingQuantity/MULTIPLYING_FACTOR).toString())),
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
                        widget.currentProduct.productName,
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 24.0),
                      width: constraints.maxWidth,
                      child: Text(
                        widget.currentProduct.businessName,
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container (
                      padding: const EdgeInsets.only(left: 24),
                      child: Text(
                        'Unids. mínim. venta: ${widget.currentProduct.minQuantitySell} ${(widget.currentProduct.minQuantitySell > 1) ? '${widget.currentProduct.idUnit}s.' : '${widget.currentProduct.idUnit}.'}',
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
                SizedBox(height: constraints.maxHeight * HeightInDpis_24),
                widget.currentProduct.quantityMaxPrice != 999999 ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 24),
                      child: const Text(
                        'Descuentos por cantidad comprada:',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 12.0,
                          fontFamily: 'SF Pro Display',
                          fontStyle: FontStyle.normal,
                          color: Color(0xFF6C6D77),
                        ),
                      ),
                    )
                  ],
                ): Container(),
                widget.currentProduct.quantityMaxPrice != 999999 ? Row (
                  children: <Widget>[
                    Container (
                        padding: const EdgeInsets.only(left: 24),
                        child: DataTable (
                            columns: const <DataColumn>[
                              DataColumn (
                                  label: Text(
                                    'Unds. desde',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Color(0xFF6C6D77),
                                    ),
                                  )
                              ),
                              DataColumn (
                                  label: Text(
                                    'Unds. hasta',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Color(0xFF6C6D77),
                                    ),
                                  )
                              ),
                              DataColumn (
                                  label: Text(
                                    'Precio',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Color(0xFF6C6D77),
                                    ),
                                  )
                              ),
                            ],
                            rows: List<DataRow>.generate(listMultiPriceListElement.length, (int index) => DataRow(
                                cells: [
                                  DataCell (
                                      Text (
                                        listMultiPriceListElement[index].unitsFrom.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12.0,
                                          fontFamily: 'SF Pro Display',
                                          fontStyle: FontStyle.normal,
                                          color: Color(0xFF6C6D77),
                                        ),
                                      )
                                  ),
                                  DataCell (
                                      Text (
                                        listMultiPriceListElement[index].unitsTo.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12.0,
                                          fontFamily: 'SF Pro Display',
                                          fontStyle: FontStyle.normal,
                                          color: Color(0xFF6C6D77),
                                        ),
                                      )
                                  ),
                                  DataCell (
                                      Text (
                                        NumberFormat.currency(locale:'en_US', symbol: '€', decimalDigits:2).format(double.parse((listMultiPriceListElement[index].price/MULTIPLYING_FACTOR).toString())),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12.0,
                                          fontFamily: 'SF Pro Display',
                                          fontStyle: FontStyle.normal,
                                          color: Color(0xFF6C6D77),
                                        ),
                                      )
                                  )
                                ]
                            ))
                        )
                    ),
                  ],
                ) : Container(),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                        onPressed: () {
                          if (widget.currentProduct.purchased > 0) {
                            setState(() {
                              cart.remove (widget.currentProduct);
                              catalog.remove(widget.currentProduct);
                            });
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
                    Padding(
                      //padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                      padding: const EdgeInsets.only(left: WithInDpis_20, right: WithInDpis_20),
                      child: Text(
                        widget.currentProduct.purchased > 1 ? '${widget.currentProduct.purchased} ${widget.currentProduct.idUnit}s.' : widget.currentProduct.purchased == 0 ? '${widget.currentProduct.purchased} ${widget.currentProduct.idUnit}s.' : '${widget.currentProduct.purchased} ${widget.currentProduct.idUnit}.',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 24.0,
                          fontFamily: 'SF Pro Display',
                          fontStyle: FontStyle.normal,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    TextButton(
                        onPressed: () {
                          setState(() {
                            cart.add(widget.currentProduct);
                            catalog.add(widget.currentProduct);
                          });
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
                //SizedBox(height: 35.0),
              ],
            );
          },
        )
    );
  }
}
class _MediumScreen extends StatefulWidget {
  final MultiPricesProductAvail currentProduct;
  const _MediumScreen(this.currentProduct);
  @override
  _MediumScreenState createState() {
    return _MediumScreenState();
  }
}
class _MediumScreenState extends State<_MediumScreen> {
  //final MultiPricesProductAvail currentProduct;
  _MediumScreenState();

  // private variables
  int _current = 0; // Var to save the current carousel image

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _current = 0;
  }
  @override
  Widget build(BuildContext context) {
    debugPrint('El productId es: ${widget.currentProduct.productId}');
    debugPrint('El número de images es: ${widget.currentProduct.numImages}');
    // Process if the product has multiprice
    final List<_MultiPriceListElement> listMultiPriceListElement = [];
    if (widget.currentProduct.quantityMaxPrice != 999999) {
      // There is multiprice for this product
      final item = _MultiPriceListElement(widget.currentProduct.quantityMinPrice, widget.currentProduct.quantityMaxPrice, widget.currentProduct.totalAmount);
      listMultiPriceListElement.add(item);
      widget.currentProduct.items.where((element) => element.partnerId != 1)
          .forEach((element) {
        final item = _MultiPriceListElement(element.quantityMinPrice, element.quantityMaxPrice, element.totalAmount);
        listMultiPriceListElement.add(item);
      });
    }
    return SafeArea (
        child: LayoutBuilder (
          builder: (context, constraints) {
            var cart = context.read<Cart>();
            var catalog = context.read<Catalog>();
            final List<String> listImagesProduct = [];
            for (var i = 0; i < widget.currentProduct.numImages; i++){
              listImagesProduct.add('$SERVER_IP$IMAGES_DIRECTORY${widget.currentProduct.productCode}_$i.gif');
            }
            return ListView (
              children: [
                widget.currentProduct.numImages > 1
                    ? Column(
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
                      options: CarouselOptions (
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
                )
                    : Container(
                  alignment: Alignment.center,
                  width: constraints.maxWidth,
                  child: AspectRatio(
                    aspectRatio: 3.0 / 2.0,
                    child: CachedNetworkImage(
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      imageUrl: '$SERVER_IP$IMAGES_DIRECTORY${widget.currentProduct.productCode}_0.gif',
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
                        child: Text(
                            NumberFormat.currency(locale:'en_US', symbol: '€', decimalDigits:2).format(double.parse((widget.currentProduct.totalAmountAccordingQuantity/MULTIPLYING_FACTOR).toString())),
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
                        widget.currentProduct.productName,
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 24.0),
                      width: constraints.maxWidth,
                      child: Text(
                        widget.currentProduct.businessName,
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container (
                      padding: const EdgeInsets.only(left: 24),
                      child: Text(
                        'Unids. mínim. venta: ${widget.currentProduct.minQuantitySell} ${(widget.currentProduct.minQuantitySell > 1) ? '${widget.currentProduct.idUnit}s.' : '${widget.currentProduct.idUnit}.'}',
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
                SizedBox(height: constraints.maxHeight * HeightInDpis_24),
                widget.currentProduct.quantityMaxPrice != 999999 ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 24),
                      child: const Text(
                        'Descuentos por cantidad comprada:',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 12.0,
                          fontFamily: 'SF Pro Display',
                          fontStyle: FontStyle.normal,
                          color: Color(0xFF6C6D77),
                        ),
                      ),
                    )
                  ],
                ): Container(),
                widget.currentProduct.quantityMaxPrice != 999999 ? Row (
                  children: <Widget>[
                    Container (
                        padding: const EdgeInsets.only(left: 24),
                        child: DataTable (
                            columns: const <DataColumn>[
                              DataColumn (
                                  label: Text(
                                    'Unds. desde',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Color(0xFF6C6D77),
                                    ),
                                  )
                              ),
                              DataColumn (
                                  label: Text(
                                    'Unds. hasta',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Color(0xFF6C6D77),
                                    ),
                                  )
                              ),
                              DataColumn (
                                  label: Text(
                                    'Precio',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Color(0xFF6C6D77),
                                    ),
                                  )
                              ),
                            ],
                            rows: List<DataRow>.generate(listMultiPriceListElement.length, (int index) => DataRow(
                                cells: [
                                  DataCell (
                                      Text (
                                        listMultiPriceListElement[index].unitsFrom.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12.0,
                                          fontFamily: 'SF Pro Display',
                                          fontStyle: FontStyle.normal,
                                          color: Color(0xFF6C6D77),
                                        ),
                                      )
                                  ),
                                  DataCell (
                                      Text (
                                        listMultiPriceListElement[index].unitsTo.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12.0,
                                          fontFamily: 'SF Pro Display',
                                          fontStyle: FontStyle.normal,
                                          color: Color(0xFF6C6D77),
                                        ),
                                      )
                                  ),
                                  DataCell (
                                      Text (
                                        NumberFormat.currency(locale:'en_US', symbol: '€', decimalDigits:2).format(double.parse((listMultiPriceListElement[index].price/MULTIPLYING_FACTOR).toString())),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12.0,
                                          fontFamily: 'SF Pro Display',
                                          fontStyle: FontStyle.normal,
                                          color: Color(0xFF6C6D77),
                                        ),
                                      )
                                  )
                                ]
                            ))
                        )
                    ),
                  ],
                ) : Container(),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                        onPressed: () {
                          if (widget.currentProduct.purchased > 0) {
                            setState(() {
                              cart.remove (widget.currentProduct);
                              catalog.remove(widget.currentProduct);
                            });
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
                    Padding(
                      //padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                      padding: const EdgeInsets.only(left: WithInDpis_20, right: WithInDpis_20),
                      child: Text(
                        widget.currentProduct.purchased > 1 ? '${widget.currentProduct.purchased} ${widget.currentProduct.idUnit}s.' : widget.currentProduct.purchased == 0 ? '${widget.currentProduct.purchased} ${widget.currentProduct.idUnit}s.' : '${widget.currentProduct.purchased} ${widget.currentProduct.idUnit}.',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 24.0,
                          fontFamily: 'SF Pro Display',
                          fontStyle: FontStyle.normal,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    TextButton(
                        onPressed: () {
                          setState(() {
                            cart.add(widget.currentProduct);
                            catalog.add(widget.currentProduct);
                          });
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
                //SizedBox(height: 35.0),
              ],
            );
          },
        )
    );
  }
}
class _LargeScreen extends StatefulWidget {
  final MultiPricesProductAvail currentProduct;
  const _LargeScreen(this.currentProduct);
  @override
  _LargeScreenState createState() {
    return _LargeScreenState();
  }
}
class _LargeScreenState extends State<_LargeScreen> {
  //final MultiPricesProductAvail currentProduct;
  _LargeScreenState();

  // private variables
  int _current = 0; // Var to save the current carousel image

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _current = 0;
  }
  @override
  Widget build(BuildContext context) {
    debugPrint('El productId es: ${widget.currentProduct.productId}');
    debugPrint('El número de images es: ${widget.currentProduct.numImages}');
    // Process if the product has multiprice
    final List<_MultiPriceListElement> listMultiPriceListElement = [];
    if (widget.currentProduct.quantityMaxPrice != 999999) {
      // There is multiprice for this product
      final item = _MultiPriceListElement(widget.currentProduct.quantityMinPrice, widget.currentProduct.quantityMaxPrice, widget.currentProduct.totalAmount);
      listMultiPriceListElement.add(item);
      widget.currentProduct.items.where((element) => element.partnerId != 1)
          .forEach((element) {
        final item = _MultiPriceListElement(element.quantityMinPrice, element.quantityMaxPrice, element.totalAmount);
        listMultiPriceListElement.add(item);
      });
    }
    return SafeArea (
        child: LayoutBuilder (
          builder: (context, constraints) {
            var cart = context.read<Cart>();
            var catalog = context.read<Catalog>();
            final List<String> listImagesProduct = [];
            for (var i = 0; i < widget.currentProduct.numImages; i++){
              listImagesProduct.add('$SERVER_IP$IMAGES_DIRECTORY${widget.currentProduct.productCode}_$i.gif');
            }
            return ListView (
              children: [
                widget.currentProduct.numImages > 1
                    ? Column(
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
                      options: CarouselOptions (
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
                )
                    : Container(
                  alignment: Alignment.center,
                  width: constraints.maxWidth,
                  child: AspectRatio(
                    aspectRatio: 3.0 / 2.0,
                    child: CachedNetworkImage(
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      imageUrl: '$SERVER_IP$IMAGES_DIRECTORY${widget.currentProduct.productCode}_0.gif',
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
                        child: Text(
                            NumberFormat.currency(locale:'en_US', symbol: '€', decimalDigits:2).format(double.parse((widget.currentProduct.totalAmountAccordingQuantity/MULTIPLYING_FACTOR).toString())),
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
                        widget.currentProduct.productName,
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 24.0),
                      width: constraints.maxWidth,
                      child: Text(
                        widget.currentProduct.businessName,
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container (
                      padding: const EdgeInsets.only(left: 24),
                      child: Text(
                        'Unids. mínim. venta: ${widget.currentProduct.minQuantitySell} ${(widget.currentProduct.minQuantitySell > 1) ? '${widget.currentProduct.idUnit}s.' : '${widget.currentProduct.idUnit}.'}',
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
                SizedBox(height: constraints.maxHeight * HeightInDpis_24),
                widget.currentProduct.quantityMaxPrice != 999999 ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 24),
                      child: const Text(
                        'Descuentos por cantidad comprada:',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 12.0,
                          fontFamily: 'SF Pro Display',
                          fontStyle: FontStyle.normal,
                          color: Color(0xFF6C6D77),
                        ),
                      ),
                    )
                  ],
                ): Container(),
                widget.currentProduct.quantityMaxPrice != 999999 ? Row (
                  children: <Widget>[
                    Container (
                        padding: const EdgeInsets.only(left: 24),
                        child: DataTable (
                            columns: const <DataColumn>[
                              DataColumn (
                                  label: Text(
                                    'Unds. desde',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Color(0xFF6C6D77),
                                    ),
                                  )
                              ),
                              DataColumn (
                                  label: Text(
                                    'Unds. hasta',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Color(0xFF6C6D77),
                                    ),
                                  )
                              ),
                              DataColumn (
                                  label: Text(
                                    'Precio',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Color(0xFF6C6D77),
                                    ),
                                  )
                              ),
                            ],
                            rows: List<DataRow>.generate(listMultiPriceListElement.length, (int index) => DataRow(
                                cells: [
                                  DataCell (
                                      Text (
                                        listMultiPriceListElement[index].unitsFrom.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12.0,
                                          fontFamily: 'SF Pro Display',
                                          fontStyle: FontStyle.normal,
                                          color: Color(0xFF6C6D77),
                                        ),
                                      )
                                  ),
                                  DataCell (
                                      Text (
                                        listMultiPriceListElement[index].unitsTo.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12.0,
                                          fontFamily: 'SF Pro Display',
                                          fontStyle: FontStyle.normal,
                                          color: Color(0xFF6C6D77),
                                        ),
                                      )
                                  ),
                                  DataCell (
                                      Text (
                                        NumberFormat.currency(locale:'en_US', symbol: '€', decimalDigits:2).format(double.parse((listMultiPriceListElement[index].price/MULTIPLYING_FACTOR).toString())),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12.0,
                                          fontFamily: 'SF Pro Display',
                                          fontStyle: FontStyle.normal,
                                          color: Color(0xFF6C6D77),
                                        ),
                                      )
                                  )
                                ]
                            ))
                        )
                    ),
                  ],
                ) : Container(),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                        onPressed: () {
                          if (widget.currentProduct.purchased > 0) {
                            setState(() {
                              cart.remove (widget.currentProduct);
                              catalog.remove(widget.currentProduct);
                            });
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
                    Padding(
                      //padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                      padding: const EdgeInsets.only(left: WithInDpis_20, right: WithInDpis_20),
                      child: Text(
                        widget.currentProduct.purchased > 1 ? '${widget.currentProduct.purchased} ${widget.currentProduct.idUnit}s.' : widget.currentProduct.purchased == 0 ? '${widget.currentProduct.purchased} ${widget.currentProduct.idUnit}s.' : '${widget.currentProduct.purchased} ${widget.currentProduct.idUnit}.',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 24.0,
                          fontFamily: 'SF Pro Display',
                          fontStyle: FontStyle.normal,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    TextButton(
                        onPressed: () {
                          setState(() {
                            cart.add(widget.currentProduct);
                            catalog.add(widget.currentProduct);
                          });
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
                //SizedBox(height: 35.0),
              ],
            );
          },
        )
    );
  }
}
class _MultiPriceListElement {
  final double unitsFrom;
  final double unitsTo;
  final double price;
  _MultiPriceListElement(this.unitsFrom, this.unitsTo, this.price);
}