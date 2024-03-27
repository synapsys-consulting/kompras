
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kompras/model/Address.model.dart';
import 'package:kompras/model/AddressList.model.dart';
import 'package:kompras/model/DefaultAddressList.model.dart';
import 'package:kompras/util/PleaseWaitWidget.util.dart';
import 'package:kompras/util/ResponsiveWidget.util.dart';
import 'package:kompras/util/ShowSnackBar.util.dart';
import 'package:kompras/util/color.util.dart';
import 'package:kompras/util/configuration.util.dart';
import 'package:http/http.dart' as http;
import 'package:kompras/view/AddressView.view.dart';
import 'package:provider/provider.dart';

class ManageAddresses extends StatefulWidget {
  final String personeId;
  final String userId;
  const ManageAddresses (this.personeId, this.userId, {super.key});
  @override
  ManageAddressesState createState() {
    return ManageAddressesState();
  }
}
class ManageAddressesState extends State<ManageAddresses> {
  late Future<List<Address>> itemsAdress;


  Future<List<Address>> _getLogisticAdresses() async {
    final Uri url = Uri.parse('$SERVER_IP/getLogisticAdresses/${widget.personeId}');
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
      final List<Map<String, dynamic>> resultListJson = json.decode(res.body)['data'].cast<Map<String, dynamic>>();
      final List<Address> resultListAddresses = resultListJson.map<Address>((json) => Address.fromJson(json)).toList();
      Provider.of<DefaultAddressList>(context, listen: false).clearDefaultAddressList();
      Provider.of<AddressesList>(context, listen: false).clearAddressList();
      for (var element in resultListAddresses) {
        if (element.statusId == 'D') {
          Provider.of<DefaultAddressList>(context, listen: false).add(element);
        } else {
          Provider.of<AddressesList>(context, listen: false).add(element);
        }
      }
      debugPrint ('Justo antes de retornar.');
      return resultListAddresses;
    } else {
      final List<Address> resultListProducts = [];
      return resultListProducts;
    }
  }
  @override
  void initState() {
    super.initState();
    itemsAdress = _getLogisticAdresses();
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        leading: IconButton (
          icon: Image.asset ('assets/images/leftArrow.png'),
          onPressed: () {
            Navigator.popUntil(context, ModalRoute.withName('/'));
          },
        ),
        title: const Text (
          'Direcciones',
          style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 20.0,
              fontWeight: FontWeight.w300,
              color: tanteLadenIconBrown
          ),
        ),
        actions: [
          Container(
            alignment: Alignment.center,
            child: TextButton(
              child: const Text (
                'Añadir',
                style: TextStyle (
                  fontFamily: 'SF Pro Display',
                  fontSize: 16.0,
                  fontWeight: FontWeight.w900,
                  color: tanteLadenIconBrown,
                ),
                textAlign: TextAlign.right,
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => AddressView(widget.personeId, widget.userId, COME_FROM_DRAWER)
                  // const COME_FROM_DRAWER = 1;
                  // const COME_FROM_ANOTHER = 2;
                  // 2: ist called from purchase management; 1: ist called from the Drawer option
                ));
              },
            ),
          )
        ],
      ),
      body: FutureBuilder <List<Address>>(
        future: itemsAdress,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ResponsiveWidget (
              smallScreen: _SmallScreenView (snapshot.data!, widget.personeId, widget.userId),
              mediumScreen: _MediumScreenView (snapshot.data!, widget.personeId, widget.userId),
              largeScreen: _LargeScreenView (snapshot.data!, widget.personeId, widget.userId),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column (
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text ('Error. ${snapshot.error}')
                ],
              ),
            );
          } else {
            return const Center(
              child: SizedBox(
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
  final List<Address> itemsAddress;
  final String personeId;
  final String userId;
  const _SmallScreenView (this.itemsAddress, this.personeId, this.userId);
  @override
  _SmallScreenViewState createState() {
    return _SmallScreenViewState();
  }
}
class _SmallScreenViewState extends State<_SmallScreenView> {
  bool _pleaseWait = false;
  final PleaseWaitWidget _pleaseWaitWidget = const PleaseWaitWidget(key: ObjectKey("pleaseWaitWidget"));

  _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }
  @override
  void initState() {
    super.initState();
    _pleaseWait = false;
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build (BuildContext context) {
    var addressesList = context.watch<AddressesList>();
    var defaultAddressList = context.watch<DefaultAddressList>();
    return (defaultAddressList.numItems + addressesList.numItems > 0)
        ? SafeArea (
        child: CustomScrollView (
          slivers: <Widget>[
            SliverList(
                delegate: SliverChildBuilderDelegate (
                        (BuildContext context, int index) {
                      return Card (
                          elevation: 4.0,
                          child: ListTile (
                            leading: Image.asset (
                              'assets/images/logoDefaultAddress.png',
                              width: 20,
                              height: 16,
                            ),
                            title: Text (
                              '${defaultAddressList.getItem(index).streetName}, ${defaultAddressList.getItem(index).streetNumber}',
                              style: const TextStyle (
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
                                    defaultAddressList.getItem(index).flatDoor,
                                    style: const TextStyle (
                                      fontWeight: FontWeight.normal,
                                      fontSize: 16.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    '${defaultAddressList.getItem(index).postalCode} ${defaultAddressList.getItem(index).locality}',
                                    style: const TextStyle (
                                      fontWeight: FontWeight.normal,
                                      fontSize: 16.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 10.0),
                                  Text(
                                    defaultAddressList.getItem(index).optional,
                                    style: const TextStyle (
                                      fontWeight: FontWeight.normal,
                                      fontSize: 16.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.black38,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                      );
                    },
                    childCount: defaultAddressList.numItems
                )
            ),
            SliverList (
              delegate: SliverChildBuilderDelegate (
                      (BuildContext context, int index) {
                    return Card (
                      elevation: 4.0,
                      child: ListTile (
                          leading: Image.asset(
                            'assets/images/logoPlace.png',
                            width: 14,
                            height: 20,
                          ),
                          title: Text (
                            '${addressesList.items[index].streetName}, ${addressesList.items[index].streetNumber}',
                            style: const TextStyle (
                              fontWeight: FontWeight.bold,
                              fontSize: 20.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Container (
                            padding: const EdgeInsets.all(0.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  addressesList.items[index].flatDoor,
                                  style: const TextStyle (
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  '${addressesList.items[index].postalCode} ${addressesList.items[index].locality}',
                                  style: const TextStyle (
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 10.0),
                                Text(
                                  addressesList.items[index].optional,
                                  style: const TextStyle (
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: PopupMenuButton (
                            icon: const Icon(Icons.more_horiz),
                            onSelected: (int result) async {
                              if (result == 1) {
                                // selected as default address
                                debugPrint ('He seleccionado la direccion por defecto');
                                try {
                                  _showPleaseWait (true);
                                  final Uri url = Uri.parse('$SERVER_IP/updateAddress/${addressesList.items[index].addrId}');
                                  final http.Response res = await http.put (
                                      url,
                                      headers: <String, String>{
                                        'Content-Type': 'application/json; charset=UTF-8',
                                        //'Authorization': jwt
                                      },
                                      body: jsonEncode(<String, String>{
                                        'status_id': 'D',
                                        'addr_id_default': defaultAddressList.getItem(0).addrId.toString(), //defaultAddressList has always one element (0)
                                        'user_id': widget.userId
                                      })
                                  ).timeout(TIMEOUT);
                                  if (res.statusCode == 200) {
                                    _showPleaseWait(false);
                                    debugPrint ('Entro en el selected as default address por el 200');
                                    final Address addressListTmp = Address(
                                        addrId: addressesList.getItem(index).addrId,
                                        streetName: addressesList.getItem(index).streetName,
                                        streetNumber: addressesList.getItem(index).streetNumber,
                                        flatDoor: addressesList.getItem(index).flatDoor,
                                        postalCode: addressesList.getItem(index).postalCode,
                                        locality: addressesList.getItem(index).locality,
                                        province: addressesList.getItem(index).province,
                                        country: addressesList.getItem(index).country,
                                        state: addressesList.getItem(index).state,
                                        optional: addressesList.getItem(index).optional,
                                        district: addressesList.getItem(index).district,
                                        suburb: addressesList.getItem(index).suburb,
                                        statusId: addressesList.getItem(index).statusId
                                    );
                                    Address defaultAddressListTmp = Address(
                                        addrId: defaultAddressList.getItem(0).addrId,
                                        streetName: defaultAddressList.getItem(0).streetName,
                                        streetNumber: defaultAddressList.getItem(0).streetNumber,
                                        flatDoor: defaultAddressList.getItem(0).flatDoor,
                                        postalCode: defaultAddressList.getItem(0).postalCode,
                                        locality: defaultAddressList.getItem(0).locality,
                                        province: defaultAddressList.getItem(0).province,
                                        country: defaultAddressList.getItem(0).country,
                                        state: defaultAddressList.getItem(0).state,
                                        optional: defaultAddressList.getItem(0).optional,
                                        district: defaultAddressList.getItem(0).district,
                                        suburb: defaultAddressList.getItem(0).suburb,
                                        statusId: defaultAddressList.getItem(0).statusId);
                                        for (var element in defaultAddressList.items) {
                                          // there always is only one element
                                          defaultAddressListTmp = Address(
                                          addrId: element.addrId,
                                          streetName: element.streetName,
                                          streetNumber: element.streetNumber,
                                          flatDoor: element.flatDoor,
                                          postalCode: element.postalCode,
                                          locality: element.locality,
                                          province: element.province,
                                          country: element.country,
                                          state: element.state,
                                          optional: element.optional,
                                          district: element.district,
                                          suburb: element.suburb,
                                          statusId: element.statusId
                                      );
                                    }
                                    defaultAddressList.clearDefaultAddressList();
                                    defaultAddressList.add(addressListTmp);
                                    addressesList.add(defaultAddressListTmp);
                                    addressesList.remove(addressesList.getItem(index));
                                  } else if (res.statusCode == 404) {
                                    // The user couldn't update because of it wasn't found
                                    _showPleaseWait(false);
                                    if (!context.mounted) return;
                                    ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'], error: true);
                                  } else {
                                    if (!context.mounted) return;
                                    _showPleaseWait(false);
                                    ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'], error: true);
                                  }
                                } catch (e) {
                                  _showPleaseWait (false);
                                  debugPrint ('El error es: $e');
                                  if (!context.mounted) return;
                                  ShowSnackBar.showSnackBar(context, e.toString(), error: true);
                                }
                              }
                              if (result == 2) {
                                // delete address
                                debugPrint ('He seleccionado el borrado de la dirección');
                                try {
                                  _showPleaseWait (true);
                                  final Uri url = Uri.parse('$SERVER_IP/deleteAddress/${addressesList.items[index].addrId}');
                                  final http.Response res = await http.delete (
                                      url,
                                      headers: <String, String>{
                                        'Content-Type': 'application/json; charset=UTF-8',
                                        //'Authorization': jwt
                                      }
                                  ).timeout(TIMEOUT);
                                  if (res.statusCode == 200) {
                                    _showPleaseWait(false);
                                    debugPrint ('Entro en el selected as default address por el 200');
                                    addressesList.remove(addressesList.getItem(index));
                                  } else if (res.statusCode == 400) {
                                    // The user couldn't update because of it wasn't found
                                    _showPleaseWait(false);
                                    if (!context.mounted) return;
                                    ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'], error: true);
                                  } else {
                                    _showPleaseWait(false);
                                    if (!context.mounted) return;
                                    ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'], error: true);
                                  }
                                } catch (e) {
                                  _showPleaseWait (false);
                                  debugPrint ('El error es: $e');
                                  if (!context.mounted) return;
                                  ShowSnackBar.showSnackBar(context, e.toString(), error: true);
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem (
                                value: 1,
                                child: Row (
                                  children: [
                                    Image.asset(
                                      'assets/images/logoDefaultAddress.png',
                                      width: 20,
                                      height: 16,
                                    ),
                                    const SizedBox(width: 10.0,),
                                    const Text(
                                        'Seleccionar'
                                    )
                                  ],
                                ),
                              ),
                              PopupMenuItem (
                                value: 2,
                                child: Row (
                                  children: [
                                    Image.asset (
                                      'assets/images/logoDelete.png',
                                      width: 20,
                                      height: 20,
                                    ),
                                    const SizedBox(width: 10.0,),
                                    const Text(
                                        'Eliminar dirección'
                                    )
                                  ],
                                ),
                              )
                            ],
                          )
                      ),
                    );
                  },
                  childCount: addressesList.numItems
              ),
            ),
          ],
        )
    )
        : SafeArea (
        child: Center (
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/emptyAddress.png'),
              const SizedBox(height: 30.0,),
              const Text(
                'No hay dirección',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                  fontFamily: 'SF Pro Display',
                  fontStyle: FontStyle.normal,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10.0,),
              const Text(
                'Añade donde quieres recibir tu pedido',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  fontFamily: 'SF Pro Display',
                  fontStyle: FontStyle.normal,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20.0,),
              Row(
                children: [
                  Flexible(flex: 1,child: Container(),),
                  Flexible(
                    flex: 2,
                    child: TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                              builder: (context) => AddressView(widget.personeId, widget.userId, COME_FROM_DRAWER)
                            // const COME_FROM_DRAWER = 1;
                            // const COME_FROM_ANOTHER = 2;
                            // 2: ist called from purchase management; 1: ist called from the Drawer option
                          ));
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
                              'Añadir dirección',
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
                  ),
                  Flexible(flex: 1,child: Container(),)
                ],
              ),
            ],
          ),
        )
    );
  }
}
class _MediumScreenView extends StatefulWidget {
  final List<Address> itemsAddress;
  final String personeId;
  final String userId;
  const _MediumScreenView (this.itemsAddress, this.personeId, this.userId);
  @override
  _MediumScreenViewState createState() {
    return _MediumScreenViewState();
  }
}
class _MediumScreenViewState extends State<_MediumScreenView> {
  bool _pleaseWait = false;
  final PleaseWaitWidget _pleaseWaitWidget = const PleaseWaitWidget(key: ObjectKey("pleaseWaitWidget"));

  _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }
  @override
  void initState() {
    super.initState();
    _pleaseWait = false;
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build (BuildContext context) {
    var addressesList = context.watch<AddressesList>();
    var defaultAddressList = context.watch<DefaultAddressList>();
    return (defaultAddressList.numItems + addressesList.numItems > 0)
        ? SafeArea (
        child: CustomScrollView (
          slivers: <Widget>[
            SliverList(
                delegate: SliverChildBuilderDelegate (
                        (BuildContext context, int index) {
                      return Card (
                          elevation: 4.0,
                          child: ListTile (
                            leading: Image.asset (
                              'assets/images/logoDefaultAddress.png',
                              width: 20,
                              height: 16,
                            ),
                            title: Text (
                              '${defaultAddressList.getItem(index).streetName}, ${defaultAddressList.getItem(index).streetNumber}',
                              style: const TextStyle (
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
                                    defaultAddressList.getItem(index).flatDoor,
                                    style: const TextStyle (
                                      fontWeight: FontWeight.normal,
                                      fontSize: 16.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    '${defaultAddressList.getItem(index).postalCode} ${defaultAddressList.getItem(index).locality}',
                                    style: const TextStyle (
                                      fontWeight: FontWeight.normal,
                                      fontSize: 16.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 10.0),
                                  Text(
                                    defaultAddressList.getItem(index).optional,
                                    style: const TextStyle (
                                      fontWeight: FontWeight.normal,
                                      fontSize: 16.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.black38,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                      );
                    },
                    childCount: defaultAddressList.numItems
                )
            ),
            SliverList (
              delegate: SliverChildBuilderDelegate (
                      (BuildContext context, int index) {
                    return Card (
                      elevation: 4.0,
                      child: ListTile (
                          leading: Image.asset(
                            'assets/images/logoPlace.png',
                            width: 14,
                            height: 20,
                          ),
                          title: Text (
                            '${addressesList.items[index].streetName}, ${addressesList.items[index].streetNumber}',
                            style: const TextStyle (
                              fontWeight: FontWeight.bold,
                              fontSize: 20.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Container (
                            padding: const EdgeInsets.all(0.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  addressesList.items[index].flatDoor,
                                  style: const TextStyle (
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  '${addressesList.items[index].postalCode} ${addressesList.items[index].locality}',
                                  style: const TextStyle (
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 10.0),
                                Text(
                                  addressesList.items[index].optional,
                                  style: const TextStyle (
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: PopupMenuButton (
                            icon: const Icon(Icons.more_horiz),
                            onSelected: (int result) async {
                              if (result == 1) {
                                // selected as default address
                                debugPrint ('He seleccionado la direccion por defecto');
                                try {
                                  _showPleaseWait (true);
                                  final Uri url = Uri.parse('$SERVER_IP/updateAddress/${addressesList.items[index].addrId}');
                                  final http.Response res = await http.put (
                                      url,
                                      headers: <String, String>{
                                        'Content-Type': 'application/json; charset=UTF-8',
                                        //'Authorization': jwt
                                      },
                                      body: jsonEncode(<String, String>{
                                        'status_id': 'D',
                                        'addr_id_default': defaultAddressList.getItem(0).addrId.toString(), //defaultAddressList has always one element (0)
                                        'user_id': widget.userId
                                      })
                                  ).timeout(TIMEOUT);
                                  if (res.statusCode == 200) {
                                    _showPleaseWait(false);
                                    debugPrint ('Entro en el selected as default address por el 200');
                                    final Address addressListTmp = Address(
                                        addrId: addressesList.getItem(index).addrId,
                                        streetName: addressesList.getItem(index).streetName,
                                        streetNumber: addressesList.getItem(index).streetNumber,
                                        flatDoor: addressesList.getItem(index).flatDoor,
                                        postalCode: addressesList.getItem(index).postalCode,
                                        locality: addressesList.getItem(index).locality,
                                        province: addressesList.getItem(index).province,
                                        country: addressesList.getItem(index).country,
                                        state: addressesList.getItem(index).state,
                                        optional: addressesList.getItem(index).optional,
                                        district: addressesList.getItem(index).district,
                                        suburb: addressesList.getItem(index).suburb,
                                        statusId: addressesList.getItem(index).statusId
                                    );
                                    Address defaultAddressListTmp = Address(
                                        addrId: defaultAddressList.getItem(0).addrId,
                                        streetName: defaultAddressList.getItem(0).streetName,
                                        streetNumber: defaultAddressList.getItem(0).streetNumber,
                                        flatDoor: defaultAddressList.getItem(0).flatDoor,
                                        postalCode: defaultAddressList.getItem(0).postalCode,
                                        locality: defaultAddressList.getItem(0).locality,
                                        province: defaultAddressList.getItem(0).province,
                                        country: defaultAddressList.getItem(0).country,
                                        state: defaultAddressList.getItem(0).state,
                                        optional: defaultAddressList.getItem(0).optional,
                                        district: defaultAddressList.getItem(0).district,
                                        suburb: defaultAddressList.getItem(0).suburb,
                                        statusId: defaultAddressList.getItem(0).statusId);
                                    for (var element in defaultAddressList.items) {
                                      // there always is only one element
                                      defaultAddressListTmp = Address(
                                          addrId: element.addrId,
                                          streetName: element.streetName,
                                          streetNumber: element.streetNumber,
                                          flatDoor: element.flatDoor,
                                          postalCode: element.postalCode,
                                          locality: element.locality,
                                          province: element.province,
                                          country: element.country,
                                          state: element.state,
                                          optional: element.optional,
                                          district: element.district,
                                          suburb: element.suburb,
                                          statusId: element.statusId
                                      );
                                    }
                                    defaultAddressList.clearDefaultAddressList();
                                    defaultAddressList.add(addressListTmp);
                                    addressesList.add(defaultAddressListTmp);
                                    addressesList.remove(addressesList.getItem(index));
                                  } else if (res.statusCode == 404) {
                                    // The user couldn't update because of it wasn't found
                                    _showPleaseWait(false);
                                    if (!context.mounted) return;
                                    ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'], error: true);
                                  } else {
                                    if (!context.mounted) return;
                                    _showPleaseWait(false);
                                    ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'], error: true);
                                  }
                                } catch (e) {
                                  _showPleaseWait (false);
                                  debugPrint ('El error es: $e');
                                  if (!context.mounted) return;
                                  ShowSnackBar.showSnackBar(context, e.toString(), error: true);
                                }
                              }
                              if (result == 2) {
                                // delete address
                                debugPrint ('He seleccionado el borrado de la dirección');
                                try {
                                  _showPleaseWait (true);
                                  final Uri url = Uri.parse('$SERVER_IP/deleteAddress/${addressesList.items[index].addrId}');
                                  final http.Response res = await http.delete (
                                      url,
                                      headers: <String, String>{
                                        'Content-Type': 'application/json; charset=UTF-8',
                                        //'Authorization': jwt
                                      }
                                  ).timeout(TIMEOUT);
                                  if (res.statusCode == 200) {
                                    _showPleaseWait(false);
                                    debugPrint ('Entro en el selected as default address por el 200');
                                    addressesList.remove(addressesList.getItem(index));
                                  } else if (res.statusCode == 400) {
                                    // The user couldn't update because of it wasn't found
                                    _showPleaseWait(false);
                                    if (!context.mounted) return;
                                    ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'], error: true);
                                  } else {
                                    _showPleaseWait(false);
                                    if (!context.mounted) return;
                                    ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'], error: true);
                                  }
                                } catch (e) {
                                  _showPleaseWait (false);
                                  debugPrint ('El error es: $e');
                                  if (!context.mounted) return;
                                  ShowSnackBar.showSnackBar(context, e.toString(), error: true);
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem (
                                value: 1,
                                child: Row (
                                  children: [
                                    Image.asset(
                                      'assets/images/logoDefaultAddress.png',
                                      width: 20,
                                      height: 16,
                                    ),
                                    const SizedBox(width: 10.0,),
                                    const Text(
                                        'Seleccionar'
                                    )
                                  ],
                                ),
                              ),
                              PopupMenuItem (
                                value: 2,
                                child: Row (
                                  children: [
                                    Image.asset (
                                      'assets/images/logoDelete.png',
                                      width: 20,
                                      height: 20,
                                    ),
                                    const SizedBox(width: 10.0,),
                                    const Text(
                                        'Eliminar dirección'
                                    )
                                  ],
                                ),
                              )
                            ],
                          )
                      ),
                    );
                  },
                  childCount: addressesList.numItems
              ),
            ),
          ],
        )
    )
        : SafeArea (
        child: Center (
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/emptyAddress.png'),
              const SizedBox(height: 30.0,),
              const Text(
                'No hay dirección',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                  fontFamily: 'SF Pro Display',
                  fontStyle: FontStyle.normal,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10.0,),
              const Text(
                'Añade donde quieres recibir tu pedido',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  fontFamily: 'SF Pro Display',
                  fontStyle: FontStyle.normal,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20.0,),
              Row(
                children: [
                  Flexible(flex: 1,child: Container(),),
                  Flexible(
                    flex: 2,
                    child: TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                              builder: (context) => AddressView(widget.personeId, widget.userId, COME_FROM_DRAWER)
                            // const COME_FROM_DRAWER = 1;
                            // const COME_FROM_ANOTHER = 2;
                            // 2: ist called from purchase management; 1: ist called from the Drawer option
                          ));
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
                              'Añadir dirección',
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
                  ),
                  Flexible(flex: 1,child: Container(),)
                ],
              ),
            ],
          ),
        )
    );
  }
}
class _LargeScreenView extends StatefulWidget {
  final List<Address> itemsAddress;
  final String personeId;
  final String userId;
  const _LargeScreenView (this.itemsAddress, this.personeId, this.userId);
  @override
  _LargeScreenViewState createState() {
    return _LargeScreenViewState();
  }
}
class _LargeScreenViewState extends State<_LargeScreenView> {
  bool _pleaseWait = false;
  final PleaseWaitWidget _pleaseWaitWidget = const PleaseWaitWidget(key: ObjectKey("pleaseWaitWidget"));

  _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }
  @override
  void initState() {
    super.initState();
    _pleaseWait = false;
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build (BuildContext context) {
    var addressesList = context.watch<AddressesList>();
    var defaultAddressList = context.watch<DefaultAddressList>();
    return (defaultAddressList.numItems + addressesList.numItems > 0)
        ? SafeArea (
        child: CustomScrollView (
          slivers: <Widget>[
            SliverList(
                delegate: SliverChildBuilderDelegate (
                        (BuildContext context, int index) {
                      return Card (
                          elevation: 4.0,
                          child: ListTile (
                            leading: Image.asset (
                              'assets/images/logoDefaultAddress.png',
                              width: 20,
                              height: 16,
                            ),
                            title: Text (
                              '${defaultAddressList.getItem(index).streetName}, ${defaultAddressList.getItem(index).streetNumber}',
                              style: const TextStyle (
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
                                    defaultAddressList.getItem(index).flatDoor,
                                    style: const TextStyle (
                                      fontWeight: FontWeight.normal,
                                      fontSize: 16.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    '${defaultAddressList.getItem(index).postalCode} ${defaultAddressList.getItem(index).locality}',
                                    style: const TextStyle (
                                      fontWeight: FontWeight.normal,
                                      fontSize: 16.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 10.0),
                                  Text(
                                    defaultAddressList.getItem(index).optional,
                                    style: const TextStyle (
                                      fontWeight: FontWeight.normal,
                                      fontSize: 16.0,
                                      fontFamily: 'SF Pro Display',
                                      fontStyle: FontStyle.normal,
                                      color: Colors.black38,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                      );
                    },
                    childCount: defaultAddressList.numItems
                )
            ),
            SliverList (
              delegate: SliverChildBuilderDelegate (
                      (BuildContext context, int index) {
                    return Card (
                      elevation: 4.0,
                      child: ListTile (
                          leading: Image.asset(
                            'assets/images/logoPlace.png',
                            width: 14,
                            height: 20,
                          ),
                          title: Text (
                            '${addressesList.items[index].streetName}, ${addressesList.items[index].streetNumber}',
                            style: const TextStyle (
                              fontWeight: FontWeight.bold,
                              fontSize: 20.0,
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Container (
                            padding: const EdgeInsets.all(0.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  addressesList.items[index].flatDoor,
                                  style: const TextStyle (
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  '${addressesList.items[index].postalCode} ${addressesList.items[index].locality}',
                                  style: const TextStyle (
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 10.0),
                                Text(
                                  addressesList.items[index].optional,
                                  style: const TextStyle (
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16.0,
                                    fontFamily: 'SF Pro Display',
                                    fontStyle: FontStyle.normal,
                                    color: Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: PopupMenuButton (
                            icon: const Icon(Icons.more_horiz),
                            onSelected: (int result) async {
                              if (result == 1) {
                                // selected as default address
                                debugPrint ('He seleccionado la direccion por defecto');
                                try {
                                  _showPleaseWait (true);
                                  final Uri url = Uri.parse('$SERVER_IP/updateAddress/${addressesList.items[index].addrId}');
                                  final http.Response res = await http.put (
                                      url,
                                      headers: <String, String>{
                                        'Content-Type': 'application/json; charset=UTF-8',
                                        //'Authorization': jwt
                                      },
                                      body: jsonEncode(<String, String>{
                                        'status_id': 'D',
                                        'addr_id_default': defaultAddressList.getItem(0).addrId.toString(), //defaultAddressList has always one element (0)
                                        'user_id': widget.userId
                                      })
                                  ).timeout(TIMEOUT);
                                  if (res.statusCode == 200) {
                                    _showPleaseWait(false);
                                    debugPrint ('Entro en el selected as default address por el 200');
                                    final Address addressListTmp = Address(
                                        addrId: addressesList.getItem(index).addrId,
                                        streetName: addressesList.getItem(index).streetName,
                                        streetNumber: addressesList.getItem(index).streetNumber,
                                        flatDoor: addressesList.getItem(index).flatDoor,
                                        postalCode: addressesList.getItem(index).postalCode,
                                        locality: addressesList.getItem(index).locality,
                                        province: addressesList.getItem(index).province,
                                        country: addressesList.getItem(index).country,
                                        state: addressesList.getItem(index).state,
                                        optional: addressesList.getItem(index).optional,
                                        district: addressesList.getItem(index).district,
                                        suburb: addressesList.getItem(index).suburb,
                                        statusId: addressesList.getItem(index).statusId
                                    );
                                    Address defaultAddressListTmp = Address(
                                        addrId: defaultAddressList.getItem(0).addrId,
                                        streetName: defaultAddressList.getItem(0).streetName,
                                        streetNumber: defaultAddressList.getItem(0).streetNumber,
                                        flatDoor: defaultAddressList.getItem(0).flatDoor,
                                        postalCode: defaultAddressList.getItem(0).postalCode,
                                        locality: defaultAddressList.getItem(0).locality,
                                        province: defaultAddressList.getItem(0).province,
                                        country: defaultAddressList.getItem(0).country,
                                        state: defaultAddressList.getItem(0).state,
                                        optional: defaultAddressList.getItem(0).optional,
                                        district: defaultAddressList.getItem(0).district,
                                        suburb: defaultAddressList.getItem(0).suburb,
                                        statusId: defaultAddressList.getItem(0).statusId);
                                    for (var element in defaultAddressList.items) {
                                      // there always is only one element
                                      defaultAddressListTmp = Address(
                                          addrId: element.addrId,
                                          streetName: element.streetName,
                                          streetNumber: element.streetNumber,
                                          flatDoor: element.flatDoor,
                                          postalCode: element.postalCode,
                                          locality: element.locality,
                                          province: element.province,
                                          country: element.country,
                                          state: element.state,
                                          optional: element.optional,
                                          district: element.district,
                                          suburb: element.suburb,
                                          statusId: element.statusId
                                      );
                                    }
                                    defaultAddressList.clearDefaultAddressList();
                                    defaultAddressList.add(addressListTmp);
                                    addressesList.add(defaultAddressListTmp);
                                    addressesList.remove(addressesList.getItem(index));
                                  } else if (res.statusCode == 404) {
                                    // The user couldn't update because of it wasn't found
                                    _showPleaseWait(false);
                                    if (!context.mounted) return;
                                    ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'], error: true);
                                  } else {
                                    if (!context.mounted) return;
                                    _showPleaseWait(false);
                                    ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'], error: true);
                                  }
                                } catch (e) {
                                  _showPleaseWait (false);
                                  debugPrint ('El error es: $e');
                                  if (!context.mounted) return;
                                  ShowSnackBar.showSnackBar(context, e.toString(), error: true);
                                }
                              }
                              if (result == 2) {
                                // delete address
                                debugPrint ('He seleccionado el borrado de la dirección');
                                try {
                                  _showPleaseWait (true);
                                  final Uri url = Uri.parse('$SERVER_IP/deleteAddress/${addressesList.items[index].addrId}');
                                  final http.Response res = await http.delete (
                                      url,
                                      headers: <String, String>{
                                        'Content-Type': 'application/json; charset=UTF-8',
                                        //'Authorization': jwt
                                      }
                                  ).timeout(TIMEOUT);
                                  if (res.statusCode == 200) {
                                    _showPleaseWait(false);
                                    debugPrint ('Entro en el selected as default address por el 200');
                                    addressesList.remove(addressesList.getItem(index));
                                  } else if (res.statusCode == 400) {
                                    // The user couldn't update because of it wasn't found
                                    _showPleaseWait(false);
                                    if (!context.mounted) return;
                                    ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'], error: true);
                                  } else {
                                    _showPleaseWait(false);
                                    if (!context.mounted) return;
                                    ShowSnackBar.showSnackBar(context, json.decode(res.body)['message'], error: true);
                                  }
                                } catch (e) {
                                  _showPleaseWait (false);
                                  debugPrint ('El error es: $e');
                                  if (!context.mounted) return;
                                  ShowSnackBar.showSnackBar(context, e.toString(), error: true);
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem (
                                value: 1,
                                child: Row (
                                  children: [
                                    Image.asset(
                                      'assets/images/logoDefaultAddress.png',
                                      width: 20,
                                      height: 16,
                                    ),
                                    const SizedBox(width: 10.0,),
                                    const Text(
                                        'Seleccionar'
                                    )
                                  ],
                                ),
                              ),
                              PopupMenuItem (
                                value: 2,
                                child: Row (
                                  children: [
                                    Image.asset (
                                      'assets/images/logoDelete.png',
                                      width: 20,
                                      height: 20,
                                    ),
                                    const SizedBox(width: 10.0,),
                                    const Text(
                                        'Eliminar dirección'
                                    )
                                  ],
                                ),
                              )
                            ],
                          )
                      ),
                    );
                  },
                  childCount: addressesList.numItems
              ),
            ),
          ],
        )
    )
        : SafeArea (
        child: Center (
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/emptyAddress.png'),
              const SizedBox(height: 30.0,),
              const Text(
                'No hay dirección',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                  fontFamily: 'SF Pro Display',
                  fontStyle: FontStyle.normal,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10.0,),
              const Text(
                'Añade donde quieres recibir tu pedido',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  fontFamily: 'SF Pro Display',
                  fontStyle: FontStyle.normal,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20.0,),
              Row(
                children: [
                  Flexible(flex: 1,child: Container(),),
                  Flexible(
                    flex: 2,
                    child: TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                              builder: (context) => AddressView(widget.personeId, widget.userId, COME_FROM_DRAWER)
                            // const COME_FROM_DRAWER = 1;
                            // const COME_FROM_ANOTHER = 2;
                            // 2: ist called from purchase management; 1: ist called from the Drawer option
                          ));
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
                              'Añadir dirección',
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
                  ),
                  Flexible(flex: 1,child: Container(),)
                ],
              ),
            ],
          ),
        )
    );
  }
}
