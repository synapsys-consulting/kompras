import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:kompras/View/DetailAddress.view.dart';
import 'package:kompras/model/AddressGeolocation.model.dart';
import 'package:kompras/util/PleaseWaitWidget.util.dart';
import 'package:kompras/util/ShowSnackBar.util.dart';
import 'package:kompras/util/color.util.dart';
import 'package:kompras/util/credentials.util.dart';

class AddressView extends StatefulWidget {
  final String personeId;
  final String userId;
  final int fromWhereCalledIs;  // 2: ist called from purchase management; 1: ist called from the Drawer option
  const AddressView (this.personeId, this.userId, this.fromWhereCalledIs, {super.key});
  @override
  _AddressViewState createState() {
    return _AddressViewState();
  }
}

class _AddressViewState extends State<AddressView> {

  final TextEditingController _searchController = TextEditingController();
  late Timer _throttle;
  List<String> _placeList = [];
  List<AddressGeoLocation> _addressList = [];
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
    _searchController.addListener (_onSearchChanged);
  }
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _placeList.clear();
    _addressList.clear();
    super.dispose();
  }
  _onSearchChanged() {
    if (_throttle.isActive) _throttle.cancel();
    _throttle = Timer (const Duration(microseconds: 100), () {
      _getLocationResults(_searchController.text);
    });
  }
  ///
  /// Get the Autocomplete address
  ///
  Future<AddressGeoLocation> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    AddressGeoLocation address = AddressGeoLocation();
    // Test if location services are enabled.
    debugPrint ('Comienzo con _determinePosition');
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    debugPrint ('Después de acceder al localizador del móvil');
    if (!serviceEnabled) {
      debugPrint ('Paso al If serviceEnabled');
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      //return Future.error('Location services are disabled.');
      return Future.error('El servicio de geolocalización no está abilitado en el aparato. Actívalo.');
    }
    debugPrint ('Antes del checkPermission');
    permission = await Geolocator.checkPermission();
    debugPrint ('Después del checkPermission');
    if (permission == LocationPermission.denied) {
      debugPrint("El permiso está denegado");
      permission = await Geolocator.requestPermission();
      debugPrint("El permiso esta denegado con el valor: ");
      debugPrint("El permiso ha sido solicitado.");
      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately.
        //return Future.error('Location permissions are permanently denied, we cannot request permissions.');
        debugPrint("Los permisos han sido revocados para simepre.");
        return Future.error('Los permisos de geolocalización para la aplicación han sido denegados. Da permisos a la aplicación para usar la geolocalización.');
      }
      debugPrint("Antes de volver a consultar los permisos.");
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error ('Has desautorizado a la aplicación para usar la geolocalización. Autorizala de nuevo en la configuración del teléfono.');
      }
    }
    debugPrint ('Después del LocationPermission.denied');
    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    final myPosition = await Geolocator.getCurrentPosition();
    const String language = 'es';
    const String baseURL = 'https://maps.googleapis.com/maps/api/geocode/json';
    //final String locationType = 'ROOFTOP';
    //final String resultType = 'street_address|political|country|administrative_area_level_1|administrative_area_level_2|locality|sublocality|neighborhood|postal_code';
    final String latLong = '${myPosition.toJson()['latitude']},${myPosition.toJson()['longitude']}';
    final String request = '$baseURL?latlng=$latLong&language=$language&key=$PLACES_APY_KEY';
    Response response = await Dio().get(request);
    final status = response.data['status'];
    debugPrint ('El código de retorno es: $status');
    if (status == 'OK') {
      final List<Map<String, dynamic>> results = response.data['results'].cast<Map<String, dynamic>>(); // Query returns the results
      final List<Map<String, dynamic>> addressComponents = results[0]['address_components'].cast<Map<String, dynamic>>(); // Take the first element [0] because is the most accurated result
      for (var i = 0; i < addressComponents.length; i++) {
        debugPrint ('El valor de address_components es: ${addressComponents[i]['types'][0]}. Con valor: ${addressComponents[i]['long_name']}');
        if (addressComponents[i]['types'][0] == 'street_number') {
          address.streetNumber = addressComponents[i]['long_name'];
        }
        if (addressComponents[i]['types'][0] == 'route') {
          address.streetName = addressComponents[i]['long_name'];
        }
        if (addressComponents[i]['types'][0] == 'locality') {
          address.locality = addressComponents[i]['long_name'];
        }
        if (addressComponents[i]['types'][0] == 'administrative_area_level_2') {
          address.province = addressComponents[i]['long_name'];
        }
        if (addressComponents[i]['types'][0] == 'administrative_area_level_1') {
          address.state = addressComponents[i]['long_name'];
        }
        if (addressComponents[i]['types'][0] == 'country') {
          address.country = addressComponents[i]['long_name'];
        }
        if (addressComponents[i]['types'][0] == 'postal_code') {
          address.postalCode = addressComponents[i]['long_name'];
        }
      }
    } else if (status == 'ZERO_RESULTS') {
      Future.error('ZERO_RESULTS');
    } else if (status == 'OVER_QUERY_LIMIT') {
      Future.error('OVER_QUERY_LIMIT');
    } else if (status == 'REQUEST_DENIED') {
      Future.error('REQUEST_DENIED');
    } else if (status == 'INVALID_REQUEST') {
      Future.error('INVALID_REQUEST');
    }
    return address;
  }
  void _getLocationResults (String input) async {
    if (input.isEmpty) {
      return;
    }
    const String baseURL = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    const String type = 'address';
    const String language = 'es';
    // SPAIN coordinates
    //String locationBias = 'circle:1300000@40.0000000,-4.0000000';
    //String location = '40.0000000,-4.0000000';
    //String radius = '1300000';
    String components = 'country:es';
    String request = '$baseURL?input=$input&type=$type&language=$language&components=$components&key=$PLACES_APY_KEY';
    Response response = await Dio().get(
        request,
        options: Options(
            headers: {
              'Access-Control-Allow-Origin': '*',
            }
        )
    );
    final List<Map<String, dynamic>> predictions = response.data['predictions'].cast<Map<String, dynamic>>();
    final status = response.data['status'];
    if (status == "OK") {
      List<String> displayResults = [];
      List<AddressGeoLocation> tempAddressList = [];
      for (var i = 0; i < predictions.length; i++) {
        String name = predictions[i]['description'];
        displayResults.add(name);
        final List<Map<String, dynamic>> terms = predictions[i]['terms'].cast<Map<String, dynamic>>();
        AddressGeoLocation tmpAddress = AddressGeoLocation();
        if (terms.length == 4) {
          for (var j = 0; j < terms.length; j++) {
            if (j == 0) {
              tmpAddress.streetName = terms[j]['value'];
            } else if (j == 1) {
              tmpAddress.streetNumber = terms[j]['value'];
            } else if (j == 2) {
              tmpAddress.locality = terms[j]['value'];
            } else if (j == 3) {
              tmpAddress.country = terms[j]['value'];
            }
          }
        }
        if (terms.length == 3) {
          for (var j = 0; j < terms.length; j++) {
            if (j == 0) {
              tmpAddress.streetName = terms[j]['value'];
            } else if (j == 1) {
              tmpAddress.locality = terms[j]['value'];
            } else if (j == 2) {
              tmpAddress.country = terms[j]['value'];
            }
          }
        }
        tempAddressList.add(tmpAddress);
      }
      setState(() {
        _placeList = displayResults;
        _addressList = tempAddressList;
      });
    }
  }

  ///
  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  @override
  Widget build(BuildContext context) {
    return Scaffold (
      appBar: AppBar (
        elevation: 0.0,
        //automaticallyImplyLeading: false,   //if false and leading is null, leading space is given to title.
        //leading: null,
        backgroundColor: tanteLadenBackgroundWhite,
        title: _AccentColorOverride (
          color: tanteLadenOnPrimary,
          child: TextField (
            controller: _searchController,
            decoration: InputDecoration (
                prefixIcon: const Icon(Icons.youtube_searched_for_outlined),
                labelText: 'Buscar calle',
                //helperText: 'Teclea el nombre de la calle que quieres buscar',
                suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _placeList.clear();
                      });
                    }
                )
            ),
          ),
        ),
      ),
      body: _buildBody(context),
    );
  }
  Widget _buildBody (BuildContext context) {
    Widget builder = ListView(
      padding: const EdgeInsets.only(top: 15.0),
      children: <Widget>[
        const SizedBox(height: 15.0,),
        ListTile (
          leading: IconButton (
            icon: Image.asset('assets/images/logoGetMyPlace.png'),
            onPressed: null,
          ),
          title: const Text (
            'Ubicación actual',
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 24.0,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.left,
          ),
          onTap: () async {
            try {
              /// Determine the current position of the device.
              ///
              /// When the location services are not enabled or permissions
              /// are denied the `Future` will return an error.
              ///
              _showPleaseWait(true);
              final AddressGeoLocation address = await _determinePosition();
              _showPleaseWait(false);
              debugPrint ('Antes del Push. Imprimo el valor de la ciudad: ');
              Navigator.push (
                  context,
                  MaterialPageRoute (
                      builder: (context) => DetailAddressView (address: address, personeId: widget.personeId, userId: widget.userId, fromWhereCalledIs: widget.fromWhereCalledIs,)
                  )
              );
            } catch (err) {
              _showPleaseWait(false);
              ShowSnackBar.showSnackBar(context, err.toString());
              debugPrint ('El error es: $err');

              //Navigator.push (
              //    context,
              //    MaterialPageRoute(
              //        builder: (context) => DetailAddress(address: null)
              //    )
              //);
            }
          },
        ),
      ],
    );
    Widget buildStack = _pleaseWait
        ? Stack(key: const ObjectKey("stack"), children: [_pleaseWaitWidget, builder])
        : Stack(key: const ObjectKey("stack"), children: [builder]);
    return (_placeList.isEmpty) ?
    buildStack:
    ListView.builder (
        itemCount: _placeList.length,
        itemBuilder: (BuildContext context, int index) => buildPlaceCard(context, index)
    );
  }
  Widget buildPlaceCard(BuildContext context, int index) {
    return Card (
      color: tanteLadenBackgroundWhite,
      child: ListTile(
        //leading: Icon(Icons.where_to_vote),
        leading: Image.asset('assets/images/logoPlace.png'),
        title: Text(
          _placeList[index],
          style: const TextStyle(
            color: tanteLadenOnPrimary,
            fontFamily: 'SF Pro Display',
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.normal,
            fontSize: 16,
          ),
          textAlign: TextAlign.justify,
        ),
        onTap: () {
          Navigator.push (
              context,
              MaterialPageRoute (
                  builder: (context) => DetailAddressView (address: _addressList[index], personeId: widget.personeId, userId: widget.userId, fromWhereCalledIs: widget.fromWhereCalledIs)
              )
          );
        },
      ),
    );
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