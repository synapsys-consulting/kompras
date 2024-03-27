import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:kompras/controller/PurchaseDetailController.controller.dart';
import 'package:kompras/model/Purchase.model.dart';
import 'package:kompras/model/PurchaseLine.model.dart';
import 'package:kompras/model/PurchaseStatus.model.dart';
import 'package:kompras/util/PleaseWaitWidget.util.dart';
import 'package:kompras/util/ResponsiveWidget.util.dart';
import 'package:kompras/util/ShowSnackBar.util.dart';
import 'package:kompras/util/configuration.util.dart';
import 'package:kompras/view/PurchaseDetailModifyView.view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

class _StateChanged {
  bool changed;
  _StateChanged(this.changed);
}
class PurchaseDetailView extends StatefulWidget {

  final int userId;
  final Purchase father;
  final int partnerId;
  final String userRole;

  const PurchaseDetailView(this.userId, this.father, this.partnerId, this.userRole, {super.key});

  @override
  PurchaseDetailViewState createState() {
    return PurchaseDetailViewState();
  }
}
class PurchaseDetailViewState extends State<PurchaseDetailView> {
  final PurchaseDetailController _controller = PurchaseDetailController();
  final _StateChanged _stateChangedAttr = _StateChanged(false);
  late List<PurchaseLine> itemsPurchase;   // (20220517) Angel Ruiz. I need the purchased product to share them
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

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
  Widget build (BuildContext context) {
    return Scaffold (
      appBar: AppBar (
        elevation: 0.0,
        leading: IconButton (
          icon: Image.asset('assets/images/leftArrow.png'),
          onPressed: () {
            Navigator.pop(context, _stateChangedAttr.changed);
          },
        ),
        title: Row (
          children: [
            Expanded (
                child: Text (
                  'Pedido: ${widget.father.orderId}',
                )
            ),
            Expanded (
                child: Text (
                  widget.father.showName,
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                )
            )
          ],
        ),
        actions: <Widget>[
          IconButton(
              icon: Image.asset('assets/images/logoWhatsapp.png'),
              onPressed: () async {
                if (itemsPurchase.isNotEmpty) {
                  final SharedPreferences prefs = await _prefs;
                  final String token = prefs.get ('token').toString();
                  String fullName;
                  if (token != "") {
                    Map<String, dynamic> payload;
                    payload = json.decode(
                        utf8.decode(
                            base64.decode (base64.normalize(token.split(".")[1]))
                        )
                    );
                    fullName = payload['partner_name'];
                  } else {
                    fullName = "usuario no autenticado en el sistema";
                  }
                  if (!context.mounted) return;
                  final box = context.findRenderObject() as RenderBox;
                  String textToShare = "Pedido de $fullName:\n\nPRODUCT_ID|UNIDADES|DESCRIPCION\n";
                  for (var element in itemsPurchase) {
                    textToShare = '$textToShare${element.productId}|${element.newQuantity != -1 ? '${element.newQuantity}(${element.items})' : element.items.toString()}${element.newQuantity != -1 ? (element.newQuantity > 1 ? ' ${element.idUnit}s.' : '${element.idUnit}.') : element.items > 1 ? ' ${element.idUnit}s.' : '${element.idUnit}.'}|${element.productName}\n';
                  }
                  Share.share(
                      textToShare,
                      subject: 'Pedido de $fullName.',
                      sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size
                  );
                }
              }
          )
        ],
      ),
      body: FutureBuilder <List<PurchaseLine>> (
          future: _controller.getPurchaseLinesByOrderId (widget.userId, widget.father.orderId, widget.father.providerName),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              itemsPurchase = snapshot.data!; // (20220517) Angel Ruiz. I need these data to share them
              return ResponsiveWidget (
                smallScreen: _SmallScreen (widget.father, snapshot.data!, widget.userId, _stateChangedAttr, widget.partnerId, widget.userRole),
                mediumScreen: _MediumScreen (widget.father, snapshot.data!, widget.userId, _stateChangedAttr, widget.partnerId, widget.userRole),
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
          }
      ),
    );
  }
}
class _SmallScreen extends StatefulWidget {
  final Purchase father;
  final List<PurchaseLine> itemsPurchase;
  final int userId;
  final _StateChanged stateChanged;
  final int partnerId;
  final String userRole;
  const _SmallScreen (this.father, this.itemsPurchase, this.userId, this.stateChanged, this.partnerId, this.userRole);

  @override
  _SmallScreenState createState() => _SmallScreenState();
}
class _SmallScreenState extends State<_SmallScreen> {
  bool _pleaseWait = false;
  final PleaseWaitWidget _pleaseWaitWidget = const PleaseWaitWidget (key: ObjectKey("pleaseWaitWidget"));

  _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }
  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build (BuildContext context) {
    Widget tmpBuilder = ListView.builder (
        itemCount: widget.itemsPurchase.length,
        itemBuilder: (BuildContext context, int index) {
          return Card (
            elevation: 4.0,
            child: ListTile (
              leading: Container (
                padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
                child: AspectRatio (
                  aspectRatio: 3.0 / 2.0,
                  child: CachedNetworkImage (
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    imageUrl: '$SERVER_IP$IMAGES_DIRECTORY${widget.itemsPurchase[index].productCode}_0.gif',
                    fit: BoxFit.scaleDown,
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
              ),
              title: Text (
                widget.itemsPurchase[index].productName,
                style: const TextStyle (
                  fontWeight: FontWeight.w500,
                  fontSize: 16.0,
                  fontFamily: 'SF Pro Display',
                  fontStyle: FontStyle.normal,
                  color: Colors.black,
                ),
                textAlign: TextAlign.start,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
                softWrap: false,
              ),
              subtitle: Row (
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText (
                          text: TextSpan(
                              text: 'Estado: ',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              children: <TextSpan>[
                                TextSpan (
                                    text: widget.itemsPurchase[index].allStatus,
                                    style: const TextStyle (
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                              ]
                          ),
                        ),
                        RichText (
                          text: TextSpan (
                              text: 'Items: ',
                              style: const TextStyle (
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              children: <TextSpan>[
                                TextSpan (
                                    text: widget.itemsPurchase[index].newQuantity != -1
                                        ? '${widget.itemsPurchase[index].newQuantity} (${widget.itemsPurchase[index].items})'
                                        : widget.itemsPurchase[index].items.toString(),
                                    // -1 means that there is a null in the field NEW_QUANTITY of the table KRC_PURCHASE
                                    style: const TextStyle (
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                                TextSpan(
                                    text: widget.itemsPurchase[index].newQuantity != -1
                                        ? widget.itemsPurchase[index].newQuantity > 1 ? ' ${widget.itemsPurchase[index].idUnit}s.' : ' ${widget.itemsPurchase[index].idUnit}.'
                                        : widget.itemsPurchase[index].items > 1 ? ' ${widget.itemsPurchase[index].idUnit}s.' : ' ${widget.itemsPurchase[index].idUnit}.',
                                    style: const TextStyle (
                                        fontWeight: FontWeight.bold
                                    )
                                )
                              ]
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                              text: 'Importe: ',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.itemsPurchase[index].totalBeforeDiscountWithoutTax/MULTIPLYING_FACTOR).toString())),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                              ]
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                              text: 'Modificación: ',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: widget.itemsPurchase[index].discountAmount/MULTIPLYING_FACTOR > 0 ? '+${NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.itemsPurchase[index].discountAmount/MULTIPLYING_FACTOR).toString()))}' : NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.itemsPurchase[index].discountAmount/MULTIPLYING_FACTOR).toString())),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                              ]
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                              text: 'Subtotal: ',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.itemsPurchase[index].totalAfterDiscountWithoutTax/MULTIPLYING_FACTOR).toString())),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                              ]
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                              text: 'IVA: ',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.itemsPurchase[index].taxAmount/MULTIPLYING_FACTOR).toString())),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                              ]
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                              text: 'Total: ',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.itemsPurchase[index].totalAmount/MULTIPLYING_FACTOR).toString())),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                              ]
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              trailing: Column (
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded (
                    child: (widget.itemsPurchase[index].possibleStatusToTransitionTo.isNotEmpty && widget.itemsPurchase[index].possibleStatusToTransitionTo[0].priority == 1 && widget.partnerId != DEFAULT_PARTNER_ID) ? IconButton (
                      padding: const EdgeInsets.all(5.0),
                      icon: Image.asset (
                        'assets/images/logoPlay.png',
                        fit: BoxFit.scaleDown,
                      ),
                      onPressed: () async {
                        try {
                          debugPrint ('Estoy en el onPressed');
                          _showPleaseWait(true);
                          final Uri url = Uri.parse('$SERVER_IP/purchaseLineStateTransition/${widget.itemsPurchase[index].orderId}/${widget.itemsPurchase[index].providerName}');
                          final http.Response res = await http.put (
                              url,
                              headers: <String, String>{
                                'Content-Type': 'application/json; charset=UTF-8',
                                //'Authorization': jwt
                              },
                              body: jsonEncode(<String, String> {
                                'user_id': widget.userId.toString(),
                                'next_state': widget.itemsPurchase[index].possibleStatusToTransitionTo.elementAt(0).destinationStateId, // Always exists at least the next state if this icon has appeared
                                'product_id': widget.itemsPurchase[index].productId.toString()
                              })
                          ).timeout(TIMEOUT);
                          if (res.statusCode == 200) {
                            _showPleaseWait(false);
                            debugPrint ('The Rest API has responsed.');
                            final List<Map<String, dynamic>> resultListJson = json.decode(res.body)['nextStatesToTransitionTo'].cast<Map<String, dynamic>>();
                            debugPrint ('Entre medias de la api RESPONSE.');
                            final List<PurchaseStatus> resultListNextStatus = resultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                            setState(() {
                              widget.itemsPurchase[index].allStatus = widget.itemsPurchase[index].possibleStatusToTransitionTo.elementAt(0).statusName;
                              widget.itemsPurchase[index].statusId = widget.itemsPurchase[index].possibleStatusToTransitionTo.elementAt(0).destinationStateId;
                              widget.itemsPurchase[index].banPrice = widget.itemsPurchase[index].possibleStatusToTransitionTo.elementAt(0).banPrice;
                              widget.itemsPurchase[index].banQuantity = widget.itemsPurchase[index].possibleStatusToTransitionTo.elementAt(0).banQuantity;
                              widget.itemsPurchase[index].possibleStatusToTransitionTo = resultListNextStatus;
                            });
                            // process the possibility that the status of the item father could have changed
                            final List<Map<String, dynamic>> resultListJsonFather = json.decode(res.body)['nextStatesToTransitionToItemFather'].cast<Map<String, dynamic>>();
                            final List<PurchaseStatus> resultListNextStatusFather = resultListJsonFather.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                            final String statusIdOfTheItemFather = json.decode(res.body)['statusIdOfTheItemFather'].toString(); // status_id of the father item since the father item status could have been changed because have changed the item products of the item father
                            final String statusNameOfTheItemFather = json.decode(res.body)['statusNameOfTheItemFather'].toString(); // status_name of the father item since the father item status could have been changed because have changed the item products of the item father
                            final int numStatusOfTheItemFather = int.parse(json.decode(res.body)['numStatusOfTheItemFather'].toString()); // num_status of the father item since the father item status could have been changed because have changed the item products of the item father
                            widget.father.numStatus = numStatusOfTheItemFather;
                            widget.father.allStatus = statusNameOfTheItemFather;
                            widget.father.statusId = statusIdOfTheItemFather;
                            widget.father.possibleStatusToTransitionTo.clear();
                            widget.father.possibleStatusToTransitionTo = resultListNextStatusFather;
                            widget.stateChanged.changed = true;
                          } else {
                            _showPleaseWait(false);
                            widget.stateChanged.changed = false;
                            if (!context.mounted) return;
                            ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'], error: true);
                          }
                        } catch (e) {
                          _showPleaseWait(false);
                          widget.stateChanged.changed = false;
                          if (!context.mounted) return;
                          ShowSnackBar.showSnackBar(context, e.toString(), error: true);
                        }
                      },
                    ) : Container(padding: EdgeInsets.zero, width: 20, height: 20),
                  ),
                  Expanded (
                    child: (widget.itemsPurchase[index].possibleStatusToTransitionTo.isNotEmpty && widget.partnerId != DEFAULT_PARTNER_ID) ? PopupMenuButton (
                        icon: const Icon (Icons.more_horiz, color: Colors.black,),
                        itemBuilder: (BuildContext context) =>
                            widget.itemsPurchase[index].possibleStatusToTransitionTo.map((e) {
                              return PopupMenuItem (
                                value: e,
                                child: Center(child: Text(e.statusName),),
                              );
                            }).toList(),
                        onSelected: (PurchaseStatus result) async {
                          try {
                            debugPrint ('Estoy en el onSelected');
                            debugPrint ('El valor de result.banPrice es: ${result.banPrice}');
                            debugPrint ('El valor de result.banQuantity es: ${result.banQuantity}');
                            _showPleaseWait(true);
                            final Uri url = Uri.parse ('$SERVER_IP/purchaseLineStateTransition/${widget.itemsPurchase[index].orderId}/${widget.itemsPurchase[index].providerName}');
                            final http.Response res = await http.put (
                                url,
                                headers: <String, String>{
                                  'Content-Type': 'application/json; charset=UTF-8',
                                  //'Authorization': jwt
                                },
                                body: jsonEncode(<String, String>{
                                  'user_id': widget.userId.toString(),
                                  'next_state': result.destinationStateId,
                                  'product_id': widget.itemsPurchase[index].productId.toString()
                                })
                            ).timeout(TIMEOUT);
                            if (res.statusCode == 200) {
                              _showPleaseWait(false);
                              debugPrint ('The Rest API has responsed.');
                              final List<Map<String, dynamic>> resultListJson = json.decode(res.body)['nextStatesToTransitionTo'].cast<Map<String, dynamic>>();
                              debugPrint ('Entre medias de la api RESPONSE.');
                              final List<PurchaseStatus> resultListProducts = resultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                              setState (() {
                                widget.itemsPurchase[index].allStatus = result.statusName;
                                widget.itemsPurchase[index].statusId = result.destinationStateId;
                                widget.itemsPurchase[index].banPrice = result.banPrice;
                                widget.itemsPurchase[index].banQuantity = result.banQuantity;
                                widget.itemsPurchase[index].possibleStatusToTransitionTo = resultListProducts;
                              });
                              debugPrint ('El valor de banPrice es: ${widget.itemsPurchase[index].banPrice}');
                              debugPrint ('El valor de banQuantity es: ${widget.itemsPurchase[index].banQuantity}');
                              // process the possibility that the status of the item father could have changed
                              final List<Map<String, dynamic>> resultListJsonFather = json.decode(res.body)['nextStatesToTransitionToItemFather'].cast<Map<String, dynamic>>();
                              final List<PurchaseStatus> resultListNextStatusFather = resultListJsonFather.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                              final String statusIdOfTheItemFather = json.decode(res.body)['statusIdOfTheItemFather'].toString(); // status_id of the father item since the father item status could have been changed because have changed the item products of the item father
                              final String statusNameOfTheItemFather = json.decode(res.body)['statusNameOfTheItemFather'].toString(); // status_name of the father item since the father item status could have been changed because have changed the item products of the item father
                              final int numStatusOfTheItemFather = int.parse(json.decode(res.body)['numStatusOfTheItemFather'].toString()); // num_status of the father item since the father item status could have been changed because have changed the item products of the item father
                              widget.father.numStatus = numStatusOfTheItemFather;
                              widget.father.allStatus = statusNameOfTheItemFather;
                              widget.father.statusId = statusIdOfTheItemFather;
                              widget.father.possibleStatusToTransitionTo.clear();
                              widget.father.possibleStatusToTransitionTo = resultListNextStatusFather;
                              widget.stateChanged.changed = true;
                            } else {
                              _showPleaseWait(false);
                              widget.stateChanged.changed = false;
                              if (!context.mounted) return;
                              ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'], error: true);
                            }
                          } catch (e) {
                            _showPleaseWait(false);
                            widget.stateChanged.changed = false;
                            if (!context.mounted) return;
                            ShowSnackBar.showSnackBar(context, e.toString(), error: true);
                          }
                        }
                    ) : Container (padding: EdgeInsets.zero, width: 20, height: 20),
                  )
                ],
              ),
              onTap: () async {
                if (widget.itemsPurchase[index].banQuantity == "SI" || widget.itemsPurchase[index].banPrice == "SI") {
                  final bool purchaseDetailStateChanged = await Navigator.push(context, MaterialPageRoute(
                      builder: (context) => PurchaseDetailModifyView (widget.userId, widget.father, widget.partnerId, widget.itemsPurchase[index], widget.userRole)
                  ));
                  debugPrint ("El valor de purchaseDetailStateChanged es: $purchaseDetailStateChanged");
                  if (purchaseDetailStateChanged) {
                    setState(() {
                      debugPrint ('Estoy dentro de setState. El valor de purchaseDetailStateChanged es: $purchaseDetailStateChanged');
                      debugPrint ('Sigo dentro del setState. El valor de widget.itemsPurchase[index]${widget.itemsPurchase[index].newQuantity}');
                    });
                  }
                }
              },
            ),
          );
        }
    );
    return SafeArea (
      child: _pleaseWait ? Stack(
        key: const ObjectKey ("stack"),
        alignment: AlignmentDirectional.center,
        children: [tmpBuilder, _pleaseWaitWidget],
      ) : Stack (
        key: const ObjectKey ("stack"),
        children: [tmpBuilder],
      ),
    );
  }
}
class _MediumScreen extends StatefulWidget {
  final Purchase father;
  final List<PurchaseLine> itemsPurchase;
  final int userId;
  final _StateChanged stateChanged;
  final int partnerId;
  final String userRole;
  const _MediumScreen (this.father, this.itemsPurchase, this.userId, this.stateChanged, this.partnerId, this.userRole);

  @override
  _MediumScreenState createState() => _MediumScreenState();
}
class _MediumScreenState extends State<_MediumScreen> {
  bool _pleaseWait = false;
  final PleaseWaitWidget _pleaseWaitWidget = const PleaseWaitWidget (key: ObjectKey("pleaseWaitWidget"));

  _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }
  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build (BuildContext context) {
    Widget tmpBuilder = ListView.builder (
        itemCount: widget.itemsPurchase.length,
        itemBuilder: (BuildContext context, int index) {
          return Card (
            elevation: 4.0,
            child: ListTile (
              leading: Container (
                padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
                child: AspectRatio (
                  aspectRatio: 3.0 / 2.0,
                  child: CachedNetworkImage (
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    imageUrl: '$SERVER_IP$IMAGES_DIRECTORY${widget.itemsPurchase[index].productCode}_0.gif',
                    fit: BoxFit.scaleDown,
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
              ),
              title: Text (
                widget.itemsPurchase[index].productName,
                style: const TextStyle (
                  fontWeight: FontWeight.w500,
                  fontSize: 16.0,
                  fontFamily: 'SF Pro Display',
                  fontStyle: FontStyle.normal,
                  color: Colors.black,
                ),
                textAlign: TextAlign.start,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
                softWrap: false,
              ),
              subtitle: Row (
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText (
                          text: TextSpan(
                              text: 'Estado: ',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: widget.itemsPurchase[index].allStatus,
                                    style: const TextStyle (
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                              ]
                          ),
                        ),
                        RichText (
                          text: TextSpan (
                              text: 'Items: ',
                              style: const TextStyle (
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              children: <TextSpan>[
                                TextSpan (
                                    text: widget.itemsPurchase[index].newQuantity != -1
                                        ? '${widget.itemsPurchase[index].newQuantity} (${widget.itemsPurchase[index].items})'
                                        : widget.itemsPurchase[index].items.toString(),
                                    // -1 means that there is a null in the field NEW_QUANTITY of the table KRC_PURCHASE
                                    style: const TextStyle (
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                                TextSpan(
                                    text: widget.itemsPurchase[index].newQuantity != -1
                                        ? widget.itemsPurchase[index].newQuantity > 1 ? ' ${widget.itemsPurchase[index].idUnit}s.' : ' ${widget.itemsPurchase[index].idUnit}.'
                                        : widget.itemsPurchase[index].items > 1 ? ' ${widget.itemsPurchase[index].idUnit}s.' : ' ${widget.itemsPurchase[index].idUnit}.',
                                    style: const TextStyle (
                                        fontWeight: FontWeight.bold
                                    )
                                )
                              ]
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                              text: 'Importe: ',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.itemsPurchase[index].totalBeforeDiscountWithoutTax/MULTIPLYING_FACTOR).toString())),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                              ]
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                              text: 'Modificación: ',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: widget.itemsPurchase[index].discountAmount/MULTIPLYING_FACTOR > 0 ? '+${NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.itemsPurchase[index].discountAmount/MULTIPLYING_FACTOR).toString()))}' : NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.itemsPurchase[index].discountAmount/MULTIPLYING_FACTOR).toString())),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                              ]
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                              text: 'Subtotal: ',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.itemsPurchase[index].totalAfterDiscountWithoutTax/MULTIPLYING_FACTOR).toString())),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                              ]
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                              text: 'IVA: ',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.itemsPurchase[index].taxAmount/MULTIPLYING_FACTOR).toString())),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                              ]
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                              text: 'Total: ',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.itemsPurchase[index].totalAmount/MULTIPLYING_FACTOR).toString())),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                              ]
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              trailing: Column (
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded (
                    child: (widget.itemsPurchase[index].possibleStatusToTransitionTo.isNotEmpty && widget.itemsPurchase[index].possibleStatusToTransitionTo[0].priority == 1 && widget.partnerId != DEFAULT_PARTNER_ID) ? IconButton (
                      padding: const EdgeInsets.all(5.0),
                      icon: Image.asset (
                        'assets/images/logoPlay.png',
                        fit: BoxFit.scaleDown,
                      ),
                      onPressed: () async {
                        try {
                          debugPrint ('Estoy en el onPressed');
                          _showPleaseWait(true);
                          final Uri url = Uri.parse('$SERVER_IP/purchaseLineStateTransition/${widget.itemsPurchase[index].orderId}/${widget.itemsPurchase[index].providerName}');
                          final http.Response res = await http.put (
                              url,
                              headers: <String, String>{
                                'Content-Type': 'application/json; charset=UTF-8',
                                //'Authorization': jwt
                              },
                              body: jsonEncode(<String, String> {
                                'user_id': widget.userId.toString(),
                                'next_state': widget.itemsPurchase[index].possibleStatusToTransitionTo.elementAt(0).destinationStateId, // Always exists at least the next state if this icon has appeared
                                'product_id': widget.itemsPurchase[index].productId.toString()
                              })
                          ).timeout(TIMEOUT);
                          if (res.statusCode == 200) {
                            _showPleaseWait(false);
                            debugPrint ('The Rest API has responsed.');
                            final List<Map<String, dynamic>> resultListJson = json.decode(res.body)['nextStatesToTransitionTo'].cast<Map<String, dynamic>>();
                            debugPrint ('Entre medias de la api RESPONSE.');
                            final List<PurchaseStatus> resultListNextStatus = resultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                            setState(() {
                              widget.itemsPurchase[index].allStatus = widget.itemsPurchase[index].possibleStatusToTransitionTo.elementAt(0).statusName;
                              widget.itemsPurchase[index].statusId = widget.itemsPurchase[index].possibleStatusToTransitionTo.elementAt(0).destinationStateId;
                              widget.itemsPurchase[index].banPrice = widget.itemsPurchase[index].possibleStatusToTransitionTo.elementAt(0).banPrice;
                              widget.itemsPurchase[index].banQuantity = widget.itemsPurchase[index].possibleStatusToTransitionTo.elementAt(0).banQuantity;
                              widget.itemsPurchase[index].possibleStatusToTransitionTo = resultListNextStatus;
                            });
                            // process the possibility that the status of the item father could have changed
                            final List<Map<String, dynamic>> resultListJsonFather = json.decode(res.body)['nextStatesToTransitionToItemFather'].cast<Map<String, dynamic>>();
                            final List<PurchaseStatus> resultListNextStatusFather = resultListJsonFather.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                            final String statusIdOfTheItemFather = json.decode(res.body)['statusIdOfTheItemFather'].toString(); // status_id of the father item since the father item status could have been changed because have changed the item products of the item father
                            final String statusNameOfTheItemFather = json.decode(res.body)['statusNameOfTheItemFather'].toString(); // status_name of the father item since the father item status could have been changed because have changed the item products of the item father
                            final int numStatusOfTheItemFather = int.parse(json.decode(res.body)['numStatusOfTheItemFather'].toString()); // num_status of the father item since the father item status could have been changed because have changed the item products of the item father
                            widget.father.numStatus = numStatusOfTheItemFather;
                            widget.father.allStatus = statusNameOfTheItemFather;
                            widget.father.statusId = statusIdOfTheItemFather;
                            widget.father.possibleStatusToTransitionTo.clear();
                            widget.father.possibleStatusToTransitionTo = resultListNextStatusFather;
                            widget.stateChanged.changed = true;
                          } else {
                            _showPleaseWait(false);
                            widget.stateChanged.changed = false;
                            if (!context.mounted) return;
                            ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'], error: true);
                          }
                        } catch (e) {
                          _showPleaseWait(false);
                          widget.stateChanged.changed = false;
                          if (!context.mounted) return;
                          ShowSnackBar.showSnackBar(context, e.toString(), error: true);
                        }
                      },
                    ) : Container(padding: EdgeInsets.zero, width: 20, height: 20),
                  ),
                  Expanded (
                    child: (widget.itemsPurchase[index].possibleStatusToTransitionTo.isNotEmpty && widget.partnerId != DEFAULT_PARTNER_ID) ? PopupMenuButton (
                        icon: const Icon (Icons.more_horiz, color: Colors.black,),
                        itemBuilder: (BuildContext context) =>
                            widget.itemsPurchase[index].possibleStatusToTransitionTo.map((e) {
                              return PopupMenuItem (
                                value: e,
                                child: Center(child: Text(e.statusName),),
                              );
                            }).toList(),
                        onSelected: (PurchaseStatus result) async {
                          try {
                            debugPrint ('Estoy en el onSelected');
                            debugPrint ('El valor de result.banPrice es: ${result.banPrice}');
                            debugPrint ('El valor de result.banQuantity es: ${result.banQuantity}');
                            _showPleaseWait(true);
                            final Uri url = Uri.parse ('$SERVER_IP/purchaseLineStateTransition/${widget.itemsPurchase[index].orderId}/${widget.itemsPurchase[index].providerName}');
                            final http.Response res = await http.put (
                                url,
                                headers: <String, String>{
                                  'Content-Type': 'application/json; charset=UTF-8',
                                  //'Authorization': jwt
                                },
                                body: jsonEncode(<String, String>{
                                  'user_id': widget.userId.toString(),
                                  'next_state': result.destinationStateId,
                                  'product_id': widget.itemsPurchase[index].productId.toString()
                                })
                            ).timeout(TIMEOUT);
                            if (res.statusCode == 200) {
                              _showPleaseWait(false);
                              debugPrint ('The Rest API has responsed.');
                              final List<Map<String, dynamic>> resultListJson = json.decode(res.body)['nextStatesToTransitionTo'].cast<Map<String, dynamic>>();
                              debugPrint ('Entre medias de la api RESPONSE.');
                              final List<PurchaseStatus> resultListProducts = resultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                              setState (() {
                                widget.itemsPurchase[index].allStatus = result.statusName;
                                widget.itemsPurchase[index].statusId = result.destinationStateId;
                                widget.itemsPurchase[index].banPrice = result.banPrice;
                                widget.itemsPurchase[index].banQuantity = result.banQuantity;
                                widget.itemsPurchase[index].possibleStatusToTransitionTo = resultListProducts;
                              });
                              debugPrint ('El valor de banPrice es: ${widget.itemsPurchase[index].banPrice}');
                              debugPrint ('El valor de banQuantity es: ${widget.itemsPurchase[index].banQuantity}');
                              // process the possibility that the status of the item father could have changed
                              final List<Map<String, dynamic>> resultListJsonFather = json.decode(res.body)['nextStatesToTransitionToItemFather'].cast<Map<String, dynamic>>();
                              final List<PurchaseStatus> resultListNextStatusFather = resultListJsonFather.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                              final String statusIdOfTheItemFather = json.decode(res.body)['statusIdOfTheItemFather'].toString(); // status_id of the father item since the father item status could have been changed because have changed the item products of the item father
                              final String statusNameOfTheItemFather = json.decode(res.body)['statusNameOfTheItemFather'].toString(); // status_name of the father item since the father item status could have been changed because have changed the item products of the item father
                              final int numStatusOfTheItemFather = int.parse(json.decode(res.body)['numStatusOfTheItemFather'].toString()); // num_status of the father item since the father item status could have been changed because have changed the item products of the item father
                              widget.father.numStatus = numStatusOfTheItemFather;
                              widget.father.allStatus = statusNameOfTheItemFather;
                              widget.father.statusId = statusIdOfTheItemFather;
                              widget.father.possibleStatusToTransitionTo.clear();
                              widget.father.possibleStatusToTransitionTo = resultListNextStatusFather;
                              widget.stateChanged.changed = true;
                            } else {
                              _showPleaseWait(false);
                              widget.stateChanged.changed = false;
                              if (!context.mounted) return;
                              ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'], error: true);
                            }
                          } catch (e) {
                            _showPleaseWait(false);
                            widget.stateChanged.changed = false;
                            if (!context.mounted) return;
                            ShowSnackBar.showSnackBar(context, e.toString(), error: true);
                          }
                        }
                    ) : Container (padding: EdgeInsets.zero, width: 20, height: 20),
                  )
                ],
              ),
              onTap: () async {
                if (widget.itemsPurchase[index].banQuantity == "SI" || widget.itemsPurchase[index].banPrice == "SI") {
                  final bool purchaseDetailStateChanged = await Navigator.push(context, MaterialPageRoute(
                      builder: (context) => PurchaseDetailModifyView (widget.userId, widget.father, widget.partnerId, widget.itemsPurchase[index], widget.userRole)
                  ));
                  debugPrint ("El valor de purchaseDetailStateChanged es: $purchaseDetailStateChanged");
                  if (purchaseDetailStateChanged) {
                    setState(() {
                      debugPrint ('Estoy dentro de setState. El valor de purchaseDetailStateChanged es: $purchaseDetailStateChanged');
                      debugPrint ('Sigo dentro del setState. El valor de widget.itemsPurchase[index]${widget.itemsPurchase[index].newQuantity}');
                    });
                  }
                }
              },
            ),
          );
        }
    );
    return SafeArea (
      child: _pleaseWait ? Stack(
        key: const ObjectKey ("stack"),
        alignment: AlignmentDirectional.center,
        children: [tmpBuilder, _pleaseWaitWidget],
      ) : Stack (
        key: const ObjectKey ("stack"),
        children: [tmpBuilder],
      ),
    );
  }
}
class _LargeScreen extends StatefulWidget {
  final Purchase father;
  final List<PurchaseLine> itemsPurchase;
  final int userId;
  final _StateChanged stateChanged;
  final int partnerId;
  final String userRole;
  const _LargeScreen (this.father, this.itemsPurchase, this.userId, this.stateChanged, this.partnerId, this.userRole);

  @override
  _LargeScreenState createState() => _LargeScreenState();
}
class _LargeScreenState extends State<_LargeScreen> {
  bool _pleaseWait = false;
  final PleaseWaitWidget _pleaseWaitWidget = const PleaseWaitWidget (key: ObjectKey("pleaseWaitWidget"));

  _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }
  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build (BuildContext context) {
    Widget tmpBuilder = ListView.builder (
        itemCount: widget.itemsPurchase.length,
        itemBuilder: (BuildContext context, int index) {
          return Card (
            elevation: 4.0,
            child: ListTile (
              leading: Container (
                padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
                child: AspectRatio (
                  aspectRatio: 3.0 / 2.0,
                  child: CachedNetworkImage (
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    imageUrl: '$SERVER_IP$IMAGES_DIRECTORY${widget.itemsPurchase[index].productCode}_0.gif',
                    fit: BoxFit.scaleDown,
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
              ),
              title: Text (
                widget.itemsPurchase[index].productName,
                style: const TextStyle (
                  fontWeight: FontWeight.w500,
                  fontSize: 16.0,
                  fontFamily: 'SF Pro Display',
                  fontStyle: FontStyle.normal,
                  color: Colors.black,
                ),
                textAlign: TextAlign.start,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
                softWrap: false,
              ),
              subtitle: Row (
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText (
                          text: TextSpan(
                              text: 'Estado: ',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: widget.itemsPurchase[index].allStatus,
                                    style: const TextStyle (
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                              ]
                          ),
                        ),
                        RichText (
                          text: TextSpan (
                              text: 'Items: ',
                              style: const TextStyle (
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              children: <TextSpan>[
                                TextSpan (
                                    text: widget.itemsPurchase[index].newQuantity != -1
                                        ? '${widget.itemsPurchase[index].newQuantity} (${widget.itemsPurchase[index].items})'
                                        : widget.itemsPurchase[index].items.toString(),
                                    // -1 means that there is a null in the field NEW_QUANTITY of the table KRC_PURCHASE
                                    style: const TextStyle (
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                                TextSpan(
                                    text: widget.itemsPurchase[index].newQuantity != -1
                                        ? widget.itemsPurchase[index].newQuantity > 1 ? ' ${widget.itemsPurchase[index].idUnit}s.' : ' ${widget.itemsPurchase[index].idUnit}.'
                                        : widget.itemsPurchase[index].items > 1 ? ' ${widget.itemsPurchase[index].idUnit}s.' : ' ${widget.itemsPurchase[index].idUnit}.',
                                    style: const TextStyle (
                                        fontWeight: FontWeight.bold
                                    )
                                )
                              ]
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                              text: 'Importe: ',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.itemsPurchase[index].totalBeforeDiscountWithoutTax/MULTIPLYING_FACTOR).toString())),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                              ]
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                              text: 'Modificación: ',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: widget.itemsPurchase[index].discountAmount/MULTIPLYING_FACTOR > 0 ? '+${NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.itemsPurchase[index].discountAmount/MULTIPLYING_FACTOR).toString()))}' : NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.itemsPurchase[index].discountAmount/MULTIPLYING_FACTOR).toString())),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                              ]
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                              text: 'Subtotal: ',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.itemsPurchase[index].totalAfterDiscountWithoutTax/MULTIPLYING_FACTOR).toString())),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                              ]
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                              text: 'IVA: ',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.itemsPurchase[index].taxAmount/MULTIPLYING_FACTOR).toString())),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                              ]
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                              text: 'Total: ',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: NumberFormat.currency (locale:'es_ES', symbol: '€', decimalDigits:2).format(double.parse((widget.itemsPurchase[index].totalAmount/MULTIPLYING_FACTOR).toString())),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                              ]
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              trailing: Column (
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded (
                    child: (widget.itemsPurchase[index].possibleStatusToTransitionTo.isNotEmpty && widget.itemsPurchase[index].possibleStatusToTransitionTo[0].priority == 1 && widget.partnerId != DEFAULT_PARTNER_ID) ? IconButton (
                      padding: const EdgeInsets.all(5.0),
                      icon: Image.asset (
                        'assets/images/logoPlay.png',
                        fit: BoxFit.scaleDown,
                      ),
                      onPressed: () async {
                        try {
                          debugPrint ('Estoy en el onPressed');
                          _showPleaseWait(true);
                          final Uri url = Uri.parse('$SERVER_IP/purchaseLineStateTransition/${widget.itemsPurchase[index].orderId}/${widget.itemsPurchase[index].providerName}');
                          final http.Response res = await http.put (
                              url,
                              headers: <String, String>{
                                'Content-Type': 'application/json; charset=UTF-8',
                                //'Authorization': jwt
                              },
                              body: jsonEncode(<String, String> {
                                'user_id': widget.userId.toString(),
                                'next_state': widget.itemsPurchase[index].possibleStatusToTransitionTo.elementAt(0).destinationStateId, // Always exists at least the next state if this icon has appeared
                                'product_id': widget.itemsPurchase[index].productId.toString()
                              })
                          ).timeout(TIMEOUT);
                          if (res.statusCode == 200) {
                            _showPleaseWait(false);
                            debugPrint ('The Rest API has responsed.');
                            final List<Map<String, dynamic>> resultListJson = json.decode(res.body)['nextStatesToTransitionTo'].cast<Map<String, dynamic>>();
                            debugPrint ('Entre medias de la api RESPONSE.');
                            final List<PurchaseStatus> resultListNextStatus = resultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                            setState(() {
                              widget.itemsPurchase[index].allStatus = widget.itemsPurchase[index].possibleStatusToTransitionTo.elementAt(0).statusName;
                              widget.itemsPurchase[index].statusId = widget.itemsPurchase[index].possibleStatusToTransitionTo.elementAt(0).destinationStateId;
                              widget.itemsPurchase[index].banPrice = widget.itemsPurchase[index].possibleStatusToTransitionTo.elementAt(0).banPrice;
                              widget.itemsPurchase[index].banQuantity = widget.itemsPurchase[index].possibleStatusToTransitionTo.elementAt(0).banQuantity;
                              widget.itemsPurchase[index].possibleStatusToTransitionTo = resultListNextStatus;
                            });
                            // process the possibility that the status of the item father could have changed
                            final List<Map<String, dynamic>> resultListJsonFather = json.decode(res.body)['nextStatesToTransitionToItemFather'].cast<Map<String, dynamic>>();
                            final List<PurchaseStatus> resultListNextStatusFather = resultListJsonFather.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                            final String statusIdOfTheItemFather = json.decode(res.body)['statusIdOfTheItemFather'].toString(); // status_id of the father item since the father item status could have been changed because have changed the item products of the item father
                            final String statusNameOfTheItemFather = json.decode(res.body)['statusNameOfTheItemFather'].toString(); // status_name of the father item since the father item status could have been changed because have changed the item products of the item father
                            final int numStatusOfTheItemFather = int.parse(json.decode(res.body)['numStatusOfTheItemFather'].toString()); // num_status of the father item since the father item status could have been changed because have changed the item products of the item father
                            widget.father.numStatus = numStatusOfTheItemFather;
                            widget.father.allStatus = statusNameOfTheItemFather;
                            widget.father.statusId = statusIdOfTheItemFather;
                            widget.father.possibleStatusToTransitionTo.clear();
                            widget.father.possibleStatusToTransitionTo = resultListNextStatusFather;
                            widget.stateChanged.changed = true;
                          } else {
                            _showPleaseWait(false);
                            widget.stateChanged.changed = false;
                            if (!context.mounted) return;
                            ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'], error: true);
                          }
                        } catch (e) {
                          _showPleaseWait(false);
                          widget.stateChanged.changed = false;
                          if (!context.mounted) return;
                          ShowSnackBar.showSnackBar(context, e.toString(), error: true);
                        }
                      },
                    ) : Container(padding: EdgeInsets.zero, width: 20, height: 20),
                  ),
                  Expanded (
                    child: (widget.itemsPurchase[index].possibleStatusToTransitionTo.isNotEmpty && widget.partnerId != DEFAULT_PARTNER_ID) ? PopupMenuButton (
                        icon: const Icon (Icons.more_horiz, color: Colors.black,),
                        itemBuilder: (BuildContext context) =>
                            widget.itemsPurchase[index].possibleStatusToTransitionTo.map((e) {
                              return PopupMenuItem (
                                value: e,
                                child: Center(child: Text(e.statusName),),
                              );
                            }).toList(),
                        onSelected: (PurchaseStatus result) async {
                          try {
                            debugPrint ('Estoy en el onSelected');
                            debugPrint ('El valor de result.banPrice es: ${result.banPrice}');
                            debugPrint ('El valor de result.banQuantity es: ${result.banQuantity}');
                            _showPleaseWait(true);
                            final Uri url = Uri.parse ('$SERVER_IP/purchaseLineStateTransition/${widget.itemsPurchase[index].orderId}/${widget.itemsPurchase[index].providerName}');
                            final http.Response res = await http.put (
                                url,
                                headers: <String, String>{
                                  'Content-Type': 'application/json; charset=UTF-8',
                                  //'Authorization': jwt
                                },
                                body: jsonEncode(<String, String>{
                                  'user_id': widget.userId.toString(),
                                  'next_state': result.destinationStateId,
                                  'product_id': widget.itemsPurchase[index].productId.toString()
                                })
                            ).timeout(TIMEOUT);
                            if (res.statusCode == 200) {
                              _showPleaseWait(false);
                              debugPrint ('The Rest API has responsed.');
                              final List<Map<String, dynamic>> resultListJson = json.decode(res.body)['nextStatesToTransitionTo'].cast<Map<String, dynamic>>();
                              debugPrint ('Entre medias de la api RESPONSE.');
                              final List<PurchaseStatus> resultListProducts = resultListJson.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                              setState (() {
                                widget.itemsPurchase[index].allStatus = result.statusName;
                                widget.itemsPurchase[index].statusId = result.destinationStateId;
                                widget.itemsPurchase[index].banPrice = result.banPrice;
                                widget.itemsPurchase[index].banQuantity = result.banQuantity;
                                widget.itemsPurchase[index].possibleStatusToTransitionTo = resultListProducts;
                              });
                              debugPrint ('El valor de banPrice es: ${widget.itemsPurchase[index].banPrice}');
                              debugPrint ('El valor de banQuantity es: ${widget.itemsPurchase[index].banQuantity}');
                              // process the possibility that the status of the item father could have changed
                              final List<Map<String, dynamic>> resultListJsonFather = json.decode(res.body)['nextStatesToTransitionToItemFather'].cast<Map<String, dynamic>>();
                              final List<PurchaseStatus> resultListNextStatusFather = resultListJsonFather.map<PurchaseStatus>((json) => PurchaseStatus.fromJson(json)).toList();
                              final String statusIdOfTheItemFather = json.decode(res.body)['statusIdOfTheItemFather'].toString(); // status_id of the father item since the father item status could have been changed because have changed the item products of the item father
                              final String statusNameOfTheItemFather = json.decode(res.body)['statusNameOfTheItemFather'].toString(); // status_name of the father item since the father item status could have been changed because have changed the item products of the item father
                              final int numStatusOfTheItemFather = int.parse(json.decode(res.body)['numStatusOfTheItemFather'].toString()); // num_status of the father item since the father item status could have been changed because have changed the item products of the item father
                              widget.father.numStatus = numStatusOfTheItemFather;
                              widget.father.allStatus = statusNameOfTheItemFather;
                              widget.father.statusId = statusIdOfTheItemFather;
                              widget.father.possibleStatusToTransitionTo.clear();
                              widget.father.possibleStatusToTransitionTo = resultListNextStatusFather;
                              widget.stateChanged.changed = true;
                            } else {
                              _showPleaseWait(false);
                              widget.stateChanged.changed = false;
                              if (!context.mounted) return;
                              ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'], error: true);
                            }
                          } catch (e) {
                            _showPleaseWait(false);
                            widget.stateChanged.changed = false;
                            if (!context.mounted) return;
                            ShowSnackBar.showSnackBar(context, e.toString(), error: true);
                          }
                        }
                    ) : Container (padding: EdgeInsets.zero, width: 20, height: 20),
                  )
                ],
              ),
              onTap: () async {
                if (widget.itemsPurchase[index].banQuantity == "SI" || widget.itemsPurchase[index].banPrice == "SI") {
                  final bool purchaseDetailStateChanged = await Navigator.push(context, MaterialPageRoute(
                      builder: (context) => PurchaseDetailModifyView (widget.userId, widget.father, widget.partnerId, widget.itemsPurchase[index], widget.userRole)
                  ));
                  debugPrint ("El valor de purchaseDetailStateChanged es: $purchaseDetailStateChanged");
                  if (purchaseDetailStateChanged) {
                    setState(() {
                      debugPrint ('Estoy dentro de setState. El valor de purchaseDetailStateChanged es: $purchaseDetailStateChanged');
                      debugPrint ('Sigo dentro del setState. El valor de widget.itemsPurchase[index]${widget.itemsPurchase[index].newQuantity}');
                    });
                  }
                }
              },
            ),
          );
        }
    );
    return SafeArea (
      child: _pleaseWait ? Stack(
        key: const ObjectKey ("stack"),
        alignment: AlignmentDirectional.center,
        children: [tmpBuilder, _pleaseWaitWidget],
      ) : Stack (
        key: const ObjectKey ("stack"),
        children: [tmpBuilder],
      ),
    );
  }
}
