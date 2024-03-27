import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kompras/util/PleaseWaitWidget.util.dart';
import 'package:kompras/util/ResponsiveWidget.util.dart';
import 'package:kompras/util/ShowSnackBar.util.dart';
import 'package:kompras/util/color.util.dart';
import 'package:kompras/util/configuration.util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class _Password {
  late String password;
}
class UpdatePassword extends StatefulWidget {
  final int userId;
  const UpdatePassword (this.userId, {super.key});
  @override
  UpdatePasswordState createState() {
    return UpdatePasswordState();
  }
}
class UpdatePasswordState extends State<UpdatePassword> {
  bool _pleaseWait = false;
  final _Password _passwordOut = _Password();
  final PleaseWaitWidget _pleaseWaitWidget = const PleaseWaitWidget(key: ObjectKey("pleaseWaitWidget"));
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

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
            _showPleaseWait (true);
            final Uri url = Uri.parse('$SERVER_IP/changePasswordWithPersoneId/${widget.userId}');
            final http.Response res = await http.put (
                url,
                headers: <String, String>{
                  'Content-Type': 'application/json; charset=UTF-8',
                  //'Authorization': jwt
                },
                body: jsonEncode(<String, String>{
                  'password': _passwordOut.password,
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
              Navigator.pop (context);
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
            Navigator.pop (context);  // if click on the <- of the AppBar return the same email that came
          },
        ),
        title: const Text (
          'Cambiar password',
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
        smallScreen: _SmallScreenView (widget.userId, _passwordOut),
        mediumScreen: _MediumScreenView(widget.userId, _passwordOut),
        largeScreen: _LargeScreenView (widget.userId, _passwordOut),
      ),
    );
  }
}
class _SmallScreenView extends StatefulWidget {
  final int userId;
  final _Password passwordOut;
  const _SmallScreenView (this.userId, this.passwordOut);
  @override
  _SmallScreenViewState createState() {
    return _SmallScreenViewState();
  }
}
class _SmallScreenViewState extends State<_SmallScreenView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _passwordNoVisible = true;

  @override
  void initState() {
    super.initState();
    _passwordNoVisible = true;
    widget.passwordOut.password = _newPasswordController.text;
    _newPasswordController.addListener(_onNewPasswordChanged);
  }
  @override
  void dispose() {
    super.dispose();
  }
  _onNewPasswordChanged() {
    widget.passwordOut.password = _newPasswordController.text;
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center (
        child: ListView (
          padding: const EdgeInsets.all(20.0),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  child: const Text (
                    'Cambio de contraseña',
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
            const SizedBox (height: 15.0),
            const Text(
              'Introduzca su nueva contraseña.',
              style: TextStyle(
                fontSize: 16.0,
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.normal,
                color: tanteLadenOnPrimary,
              ),
              textAlign: TextAlign.justify,
              maxLines: 2,
              softWrap: true,
            ),
            const SizedBox (height: 20.0,),
            Form(
                autovalidateMode: AutovalidateMode.always,
                key: _formKey,
                child: Column (
                  children: [
                    TextFormField (
                      controller: _newPasswordController,
                      obscureText: _passwordNoVisible,
                      decoration: InputDecoration (
                        labelText: 'Nueva password',
                        labelStyle: const TextStyle (
                          color: tanteLadenIconBrown,
                        ),
                        suffixIcon: IconButton (
                            icon: Icon(_passwordNoVisible ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _passwordNoVisible = ! _passwordNoVisible;
                              });
                            }
                        ),
                      ),
                      validator: (String? value) {
                        if (value!.isEmpty) {
                          return 'Introduce una nueva contraseña.';
                        } else {
                          if (value.length < 5) {
                            return 'La contraseña debe tener al menos 5 caracteres o números';
                          } else {
                            return null;
                          }
                        }
                      },
                    ),
                  ],
                )
            ),
          ],
        ),
      ),
    );
  }
}
class _MediumScreenView extends StatefulWidget {
  final int userId;
  final _Password passwordOut;
  const _MediumScreenView (this.userId, this.passwordOut);
  @override
  _MediumScreenViewState createState() {
    return _MediumScreenViewState();
  }
}
class _MediumScreenViewState extends State<_MediumScreenView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _passwordNoVisible = true;

  @override
  void initState() {
    super.initState();
    _passwordNoVisible = true;
    widget.passwordOut.password = _newPasswordController.text;
    _newPasswordController.addListener(_onNewPasswordChanged);
  }
  @override
  void dispose() {
    super.dispose();
  }
  _onNewPasswordChanged() {
    widget.passwordOut.password = _newPasswordController.text;
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center (
        child: ListView (
          padding: const EdgeInsets.all(20.0),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  child: const Text (
                    'Cambio de contraseña',
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
            const SizedBox (height: 15.0),
            const Text(
              'Introduzca su nueva contraseña.',
              style: TextStyle(
                fontSize: 16.0,
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.normal,
                color: tanteLadenOnPrimary,
              ),
              textAlign: TextAlign.justify,
              maxLines: 2,
              softWrap: true,
            ),
            const SizedBox (height: 20.0,),
            Form(
                autovalidateMode: AutovalidateMode.always,
                key: _formKey,
                child: Column (
                  children: [
                    TextFormField (
                      controller: _newPasswordController,
                      obscureText: _passwordNoVisible,
                      decoration: InputDecoration (
                        labelText: 'Nueva password',
                        labelStyle: const TextStyle (
                          color: tanteLadenIconBrown,
                        ),
                        suffixIcon: IconButton (
                            icon: Icon(_passwordNoVisible ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _passwordNoVisible = ! _passwordNoVisible;
                              });
                            }
                        ),
                      ),
                      validator: (String? value) {
                        if (value!.isEmpty) {
                          return 'Introduce una nueva contraseña.';
                        } else {
                          if (value.length < 5) {
                            return 'La contraseña debe tener al menos 5 caracteres o números';
                          } else {
                            return null;
                          }
                        }
                      },
                    ),
                  ],
                )
            ),
          ],
        ),
      ),
    );
  }
}
class _LargeScreenView extends StatefulWidget {
  final int userId;
  final _Password passwordOut;
  const _LargeScreenView (this.userId, this.passwordOut);
  @override
  _LargeScreenViewState createState() {
    return _LargeScreenViewState();
  }
}
class _LargeScreenViewState extends State<_LargeScreenView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _passwordNoVisible = true;

  @override
  void initState() {
    super.initState();
    _passwordNoVisible = true;
    widget.passwordOut.password = _newPasswordController.text;
    _newPasswordController.addListener(_onNewPasswordChanged);
  }
  @override
  void dispose() {
    super.dispose();
  }
  _onNewPasswordChanged() {
    widget.passwordOut.password = _newPasswordController.text;
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center (
        child: ListView (
          padding: const EdgeInsets.all(20.0),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  child: const Text (
                    'Cambio de contraseña',
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
            const SizedBox (height: 15.0),
            const Text(
              'Introduzca su nueva contraseña.',
              style: TextStyle(
                fontSize: 16.0,
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.normal,
                color: tanteLadenOnPrimary,
              ),
              textAlign: TextAlign.justify,
              maxLines: 2,
              softWrap: true,
            ),
            const SizedBox (height: 20.0,),
            Form(
                autovalidateMode: AutovalidateMode.always,
                key: _formKey,
                child: Column (
                  children: [
                    TextFormField (
                      controller: _newPasswordController,
                      obscureText: _passwordNoVisible,
                      decoration: InputDecoration (
                        labelText: 'Nueva password',
                        labelStyle: const TextStyle (
                          color: tanteLadenIconBrown,
                        ),
                        suffixIcon: IconButton (
                            icon: Icon(_passwordNoVisible ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _passwordNoVisible = ! _passwordNoVisible;
                              });
                            }
                        ),
                      ),
                      validator: (String? value) {
                        if (value!.isEmpty) {
                          return 'Introduce una nueva contraseña.';
                        } else {
                          if (value.length < 5) {
                            return 'La contraseña debe tener al menos 5 caracteres o números';
                          } else {
                            return null;
                          }
                        }
                      },
                    ),
                  ],
                )
            ),
          ],
        ),
      ),
    );
  }
}