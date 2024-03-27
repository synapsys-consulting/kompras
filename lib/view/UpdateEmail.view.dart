import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kompras/util/PleaseWaitWidget.util.dart';
import 'package:kompras/util/ResponsiveWidget.util.dart';
import 'package:kompras/util/ShowSnackBar.util.dart';
import 'package:kompras/util/color.util.dart';
import 'package:kompras/util/configuration.util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class _Email {
  late final String email;
}
class UpdateEmail extends StatefulWidget {
  final String email;
  final int userId;
  const UpdateEmail(this.email, this.userId, {super.key});
  @override
  UpdateEmailState createState() {
    return UpdateEmailState();
  }
}
class UpdateEmailState extends State<UpdateEmail> {
  bool _pleaseWait = false;
  final _Email _emailOut = _Email();
  final PleaseWaitWidget _pleaseWaitWidget = const PleaseWaitWidget(key: ObjectKey("pleaseWaitWidget"));
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late String _emailIn;  // Save the email that come as the input parameter

  _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }
  @override
  void initState() {
    super.initState();
    _pleaseWait = false;
    _emailIn = widget.email;  // Save the value that come as the input parameter
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
            debugPrint ('El valor del email es: ${_emailOut.email}');
            _showPleaseWait (true);
            final Uri url = Uri.parse('$SERVER_IP/updateUserWithPersoneId/${widget.userId}');
            final http.Response res = await http.put (
                url,
                headers: <String, String>{
                  'Content-Type': 'application/json; charset=UTF-8',
                  //'Authorization': jwt
                },
                body: jsonEncode(<String, String>{
                  'user_name': _emailOut.email,
                  'gethash': 'true'
                })
            ).timeout(TIMEOUT);
            if (res.statusCode == 200) {
              _showPleaseWait(false);
              debugPrint ('He retornado del Guardar OK.');
              final String token = json.decode(res.body)['token'].toString();
              final SharedPreferences prefs = await _prefs;
              prefs.setString('token', token);
              if (!context.mounted) return;
              Navigator.pop (context, _emailOut.email);
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
            ShowSnackBar.showSnackBar(context, e.toString(), error: true);
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
            Navigator.pop (context, _emailIn);  // if click on the <- of the AppBar return the same email that came
          },
        ),
        title: const Text (
          'Cambiar email',
          style: TextStyle (
              fontFamily: 'SF Pro Display',
              fontSize: 20.0,
              fontWeight: FontWeight.w300,
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
        smallScreen: _SmallScreenView (widget.email, _emailOut),
        mediumScreen: _MediumScreenView (widget.email, _emailOut),
        largeScreen: _LargeScreenView (widget.email, _emailOut),
      ),
    );
  }
}
class _SmallScreenView extends StatefulWidget {
  final String email;
  final _Email emailOut;
  const _SmallScreenView (this.email, this.emailOut);

  @override
  _SmallScreenViewState createState() {
    return _SmallScreenViewState();
  }
}
class _SmallScreenViewState extends State<_SmallScreenView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.email == 'null') {  // True: The user has still a email. False: The user don't have a email yet.
      _emailController.text = '';
    } else {
      _emailController.text = widget.email;
    }
    widget.emailOut.email = _emailController.text;
    _emailController.addListener(_onEmailChanged);
  }
  _onEmailChanged() {
    widget.emailOut.email = _emailController.text;
  }
  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Center(
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: <Widget>[
              const SizedBox(height: 30.0,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text (
                      'Email',
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
              const SizedBox(height: 15.0,),
              const Text (
                'Tu email es también el usuario de acceso a la cuenta.',
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
              const SizedBox (height: 20.0,),
              Form (
                autovalidateMode: AutovalidateMode.always,
                key: _formKey,
                child: Column (
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration (
                        labelText: 'Email',
                        labelStyle: const TextStyle (
                          color: tanteLadenIconBrown,
                        ),
                        suffixIcon: IconButton (
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _emailController.clear();
                            }
                        ),
                      ),
                      validator: (String? value) {
                        Pattern pattern =
                            r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]"
                            r"{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]"
                            r"{0,253}[a-zA-Z0-9])?)*$";
                        RegExp regexp = RegExp(pattern.toString());
                        if (!regexp.hasMatch(value!)) {
                          return 'Introduce un email válido';
                        } else {
                          return null;
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
    );
  }
}
class _MediumScreenView extends StatefulWidget {
  final String email;
  final _Email emailOut;
  const _MediumScreenView (this.email, this.emailOut);

  @override
  _MediumScreenViewState createState() {
    return _MediumScreenViewState();
  }
}
class _MediumScreenViewState extends State<_MediumScreenView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.email == 'null') {  // True: The user has still a email. False: The user don't have a email yet.
      _emailController.text = '';
    } else {
      _emailController.text = widget.email;
    }
    widget.emailOut.email = _emailController.text;
    _emailController.addListener(_onEmailChanged);
  }
  _onEmailChanged() {
    widget.emailOut.email = _emailController.text;
  }
  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Center(
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: <Widget>[
              const SizedBox(height: 30.0,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text (
                      'Email',
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
              const SizedBox(height: 15.0,),
              const Text (
                'Tu email es también el usuario de acceso a la cuenta.',
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
              const SizedBox (height: 20.0,),
              Form (
                autovalidateMode: AutovalidateMode.always,
                key: _formKey,
                child: Column (
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration (
                        labelText: 'Email',
                        labelStyle: const TextStyle (
                          color: tanteLadenIconBrown,
                        ),
                        suffixIcon: IconButton (
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _emailController.clear();
                            }
                        ),
                      ),
                      validator: (String? value) {
                        Pattern pattern =
                            r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]"
                            r"{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]"
                            r"{0,253}[a-zA-Z0-9])?)*$";
                        RegExp regexp = RegExp(pattern.toString());
                        if (!regexp.hasMatch(value!)) {
                          return 'Introduce un email válido';
                        } else {
                          return null;
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
    );
  }
}
class _LargeScreenView extends StatefulWidget {
  final String email;
  final _Email emailOut;
  const _LargeScreenView (this.email, this.emailOut);

  @override
  _LargeScreenViewState createState() {
    return _LargeScreenViewState();
  }
}
class _LargeScreenViewState extends State<_MediumScreenView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.email == 'null') {  // True: The user has still a email. False: The user don't have a email yet.
      _emailController.text = '';
    } else {
      _emailController.text = widget.email;
    }
    widget.emailOut.email = _emailController.text;
    _emailController.addListener(_onEmailChanged);
  }
  _onEmailChanged() {
    widget.emailOut.email = _emailController.text;
  }
  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Center(
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: <Widget>[
              const SizedBox(height: 30.0,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text (
                      'Email',
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
              const SizedBox(height: 15.0,),
              const Text (
                'Tu email es también el usuario de acceso a la cuenta.',
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
              const SizedBox (height: 20.0,),
              Form (
                autovalidateMode: AutovalidateMode.always,
                key: _formKey,
                child: Column (
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration (
                        labelText: 'Email',
                        labelStyle: const TextStyle (
                          color: tanteLadenIconBrown,
                        ),
                        suffixIcon: IconButton (
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _emailController.clear();
                            }
                        ),
                      ),
                      validator: (String? value) {
                        Pattern pattern =
                            r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]"
                            r"{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]"
                            r"{0,253}[a-zA-Z0-9])?)*$";
                        RegExp regexp = RegExp(pattern.toString());
                        if (!regexp.hasMatch(value!)) {
                          return 'Introduce un email válido';
                        } else {
                          return null;
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
    );
  }
}
