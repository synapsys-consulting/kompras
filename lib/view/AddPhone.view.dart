import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kompras/util/PleaseWaitWidget.util.dart';
import 'package:kompras/util/ResponsiveWidget.util.dart';
import 'package:kompras/util/ShowSnackBar.util.dart';
import 'package:kompras/util/color.util.dart';
import 'package:kompras/util/configuration.util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Phone {
  late String number;
}
class AddPhone extends StatefulWidget {
  final String phoneNumber;
  final String userId;
  const AddPhone (this.phoneNumber, this.userId, {super.key});
  @override
  _AddPhoneState createState() {
    return _AddPhoneState();
  }
}

class _AddPhoneState extends State<AddPhone> {
  bool _pleaseWait = false;
  final _Phone _phoneOut = _Phone();
  final PleaseWaitWidget _pleaseWaitWidget = const PleaseWaitWidget (key: ObjectKey("pleaseWaitWidget"));
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late String _phoneIn;  // Save the phone that come as the input parameter

  _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }
  @override
  void initState() {
    super.initState();
    _pleaseWait = false;
    _phoneIn = widget.phoneNumber;  // Save the value that come as the input parameter
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final Widget tmpBuilder = Container(
      alignment: Alignment.center,
      child: TextButton(
        child: const Text (
          'Guardar',
          style: TextStyle (
            fontFamily: 'SF Pro Display',
            fontSize: 16.0,
            fontWeight: FontWeight.w900,
            color: tanteLadenIconBrown,
          ),
          textAlign: TextAlign.right,
        ),
        onPressed: () async {
          try {
            debugPrint ('Entro en el Guardar');
            debugPrint ('El valor de userId es: ${widget.userId}');
            debugPrint ('El valor del número de teléfono es: ${_phoneOut.number}');
            _showPleaseWait (true);
            final Uri url = Uri.parse('$SERVER_IP/updateUserWithPersoneId/${widget.userId}');
            final http.Response res = await http.put (
                url,
                headers: <String, String>{
                  'Content-Type': 'application/json; charset=UTF-8',
                  //'Authorization': jwt
                },
                body: jsonEncode(<String, String>{
                  'phone_number': _phoneOut.number,
                  'gethash': 'true'
                })
            ).timeout(TIMEOUT);
            if (res.statusCode == 200) {
              debugPrint ('He retornado del Guardar OK.');
              _showPleaseWait(false);
              final String token = json.decode(res.body)['token'].toString();
              final SharedPreferences prefs = await _prefs;
              prefs.setString('token', token);
              if (!context.mounted) return;
              Navigator.pop (context, _phoneOut.number);
            } else {
              debugPrint ('Entro por else del 200.');
              debugPrint ('El código retornado es: ${res.statusCode}');
              debugPrint ('El mesaje retornado es: ${json.decode(res.body)['message']}');
              _showPleaseWait (false);
            }
          } catch (e) {
            _showPleaseWait (false);
            debugPrint ('El error es: $e');
            if (!context.mounted) return;
            ShowSnackBar.showSnackBar (context, e.toString(), error: true);
          }
        },
      ),
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        leading: IconButton (
          icon: Image.asset ('assets/images/leftArrow.png'),
          onPressed: () {
            Navigator.pop (context, _phoneIn);  // if click on the <- of the AppBar return the same phone that came
          },
        ),
        title: const Text (
          'Cambiar teléfono',
          style: TextStyle (
              fontFamily: 'SF Pro Display',
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: tanteLadenIconBrown
          ),
          textAlign: TextAlign.center,
        ),
        actions: <Widget>[
          _pleaseWait ?
          Stack (
            key:  const ObjectKey("stack"),
            alignment: AlignmentDirectional.center,
            children: [tmpBuilder, _pleaseWaitWidget],
          ) :
          Stack (key:  const ObjectKey("stack"), children: [tmpBuilder],)
        ],
      ),
      body: ResponsiveWidget (
        smallScreen: _SmallScreenView (widget.phoneNumber, _phoneOut),
        mediumScreen: _MediumScreenView (widget.phoneNumber, _phoneOut),
        largeScreen: _LargeScreenView (widget.phoneNumber, _phoneOut),
      ),
    );
  }
}
class _SmallScreenView extends StatefulWidget {
  final String phoneNumber;
  final _Phone phoneOut;
  const _SmallScreenView (this.phoneNumber, this.phoneOut);
  @override
  _SmallScreenViewState createState() {
    return _SmallScreenViewState();
  }
}

class _SmallScreenViewState extends State<_SmallScreenView>{
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.phoneNumber == 'null') {  // True: The user has still a phone number. False: The user don't have a phone number yet.
      _phoneNumberController.text = '';
    } else {
      _phoneNumberController.text = widget.phoneNumber;
    }
    widget.phoneOut.number = _phoneNumberController.text;
    _phoneNumberController.addListener(_onPhoneNumberChanged);
  }
  _onPhoneNumberChanged() {
    widget.phoneOut.number = _phoneNumberController.text;
  }
  @override
  void dispose() {
    _phoneNumberController.removeListener(_onPhoneNumberChanged);
    _phoneNumberController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea (
        child: Center (
          child: ListView (
            padding: const EdgeInsets.all(20.0),
            children: <Widget>[
              const SizedBox (height: 30.0,),
              Row (
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text (
                      'Número de teléfono',
                      style: TextStyle (
                        fontWeight: FontWeight.w700,
                        fontSize: 20.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox (height: 15.0,),
              const Row (
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded (
                    child: Text (
                      'Sólo lo utilizaremos si necesitamos contactar contigo en relación a tu pedido.',
                      style: TextStyle (
                        fontWeight: FontWeight.w500,
                        fontSize: 16.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.justify,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                    TextFormField (
                      controller: _phoneNumberController,
                      decoration: InputDecoration (
                        labelText: 'Teléfono',
                        labelStyle: const TextStyle (
                          color: tanteLadenIconBrown,
                        ),
                        suffixIcon: IconButton (
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _phoneNumberController.clear();
                            }
                        ),
                      ),
                      validator: (String? value) {
                        Pattern pattern = r"(^[0-9+]{9}$)";
                        RegExp regexp = RegExp (pattern.toString());
                        if (!regexp.hasMatch(value!)) {
                          return 'Introduce un teléfono válido';
                        } else {
                          return null;
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox (height: 30.0,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text (
                      'Se guardará este teléfono para futuros pedidos.',
                      style: TextStyle (
                        fontWeight: FontWeight.w500,
                        fontSize: 16.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black38,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  )
                ],
              ),
            ],
          ),
        )
    );
  }
}

class _MediumScreenView extends StatefulWidget {
  final String phoneNumber;
  final _Phone phoneOut;
  const _MediumScreenView (this.phoneNumber, this.phoneOut);
  @override
  _MediumScreenViewState createState() {
    return _MediumScreenViewState();
  }
}
class _MediumScreenViewState extends State<_MediumScreenView>{
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.phoneNumber == 'null') {  // True: The user has still a phone number. False: The user don't have a phone number yet.
      _phoneNumberController.text = '';
    } else {
      _phoneNumberController.text = widget.phoneNumber;
    }
    widget.phoneOut.number = _phoneNumberController.text;
    _phoneNumberController.addListener(_onPhoneNumberChanged);
  }
  _onPhoneNumberChanged() {
    widget.phoneOut.number = _phoneNumberController.text;
  }
  @override
  void dispose() {
    _phoneNumberController.removeListener(_onPhoneNumberChanged);
    _phoneNumberController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea (
        child: Center (
          child: ListView (
            padding: const EdgeInsets.all(20.0),
            children: <Widget>[
              const SizedBox (height: 30.0,),
              Row (
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text (
                      'Número de teléfono',
                      style: TextStyle (
                        fontWeight: FontWeight.w700,
                        fontSize: 20.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox (height: 15.0,),
              const Row (
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded (
                    child: Text (
                      'Sólo lo utilizaremos si necesitamos contactar contigo en relación a tu pedido.',
                      style: TextStyle (
                        fontWeight: FontWeight.w500,
                        fontSize: 16.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.justify,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                    TextFormField (
                      controller: _phoneNumberController,
                      decoration: InputDecoration (
                        labelText: 'Teléfono',
                        labelStyle: const TextStyle (
                          color: tanteLadenIconBrown,
                        ),
                        suffixIcon: IconButton (
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _phoneNumberController.clear();
                            }
                        ),
                      ),
                      validator: (String? value) {
                        Pattern pattern = r"(^[0-9+]{9}$)";
                        RegExp regexp = RegExp (pattern.toString());
                        if (!regexp.hasMatch(value!)) {
                          return 'Introduce un teléfono válido';
                        } else {
                          return null;
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox (height: 30.0,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text (
                      'Se guardará este teléfono para futuros pedidos.',
                      style: TextStyle (
                        fontWeight: FontWeight.w500,
                        fontSize: 16.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black38,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  )
                ],
              ),
            ],
          ),
        )
    );
  }
}

class _LargeScreenView extends StatefulWidget {
  final String phoneNumber;
  final _Phone phoneOut;
  const _LargeScreenView (this.phoneNumber, this.phoneOut);
  @override
  _LargeScreenViewState createState() {
    return _LargeScreenViewState();
  }
}
class _LargeScreenViewState extends State<_LargeScreenView>{
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.phoneNumber == 'null') {  // True: The user has still a phone number. False: The user don't have a phone number yet.
      _phoneNumberController.text = '';
    } else {
      _phoneNumberController.text = widget.phoneNumber;
    }
    widget.phoneOut.number = _phoneNumberController.text;
    _phoneNumberController.addListener(_onPhoneNumberChanged);
  }
  _onPhoneNumberChanged() {
    widget.phoneOut.number = _phoneNumberController.text;
  }
  @override
  void dispose() {
    _phoneNumberController.removeListener(_onPhoneNumberChanged);
    _phoneNumberController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea (
        child: Center (
          child: ListView (
            padding: const EdgeInsets.all(20.0),
            children: <Widget>[
              const SizedBox (height: 30.0,),
              Row (
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text (
                      'Número de teléfono',
                      style: TextStyle (
                        fontWeight: FontWeight.w700,
                        fontSize: 20.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox (height: 15.0,),
              const Row (
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded (
                    child: Text (
                      'Sólo lo utilizaremos si necesitamos contactar contigo en relación a tu pedido.',
                      style: TextStyle (
                        fontWeight: FontWeight.w500,
                        fontSize: 16.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.justify,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                    TextFormField (
                      controller: _phoneNumberController,
                      decoration: InputDecoration (
                        labelText: 'Teléfono',
                        labelStyle: const TextStyle (
                          color: tanteLadenIconBrown,
                        ),
                        suffixIcon: IconButton (
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _phoneNumberController.clear();
                            }
                        ),
                      ),
                      validator: (String? value) {
                        Pattern pattern = r"(^[0-9+]{9}$)";
                        RegExp regexp = RegExp (pattern.toString());
                        if (!regexp.hasMatch(value!)) {
                          return 'Introduce un teléfono válido';
                        } else {
                          return null;
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox (height: 30.0,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text (
                      'Se guardará este teléfono para futuros pedidos.',
                      style: TextStyle (
                        fontWeight: FontWeight.w500,
                        fontSize: 16.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black38,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  )
                ],
              ),
            ],
          ),
        )
    );
  }
}