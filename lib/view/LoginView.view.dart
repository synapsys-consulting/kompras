import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kompras/View/SignInView.view.dart';
import 'package:kompras/View/SignUpView.view.dart';
import 'package:kompras/util/PleaseWaitWidget.util.dart';
import 'package:kompras/util/ResponsiveWidget.util.dart';
import 'package:kompras/util/ShowSnackBar.util.dart';
import 'package:kompras/util/color.util.dart';

import 'package:kompras/util/configuration.util.dart';

class LoginView extends StatelessWidget {
  final int reason;           //  1 the call comes from the drawer. 2 the call comes from cart.view.dart

  const LoginView({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      appBar: AppBar (
        elevation: 0.0,
        leading: IconButton (
          icon: Image.asset('assets/images/leftArrow.png'),
          onPressed: () {
            Navigator.popUntil(context, ModalRoute.withName('/'));
          },
        ),
        actions: <Widget>[
          IconButton(
              icon: Image.asset ('assets/images/logoQuestion.png'),
              onPressed: null
          )
        ],
      ),
      body: ResponsiveWidget (
        smallScreen: _SmallScreenView (reason),
        mediumScreen: _MediumScreenView (reason),
        largeScreen: _LargeScreenView (reason),
      ),
    );
  }
}
class _SmallScreenView extends StatefulWidget {
  final int reason;           //  1 the call comes from the drawer. 2 the call comes from cart.view.dart
  const _SmallScreenView (this.reason);
  @override
  _SmallScreenViewState createState() {
    return _SmallScreenViewState();
  }
}
class _SmallScreenViewState extends State<_SmallScreenView> {
  bool _pleaseWait = false;
  final PleaseWaitWidget _pleaseWaitWidget = const PleaseWaitWidget(key: ObjectKey("pleaseWaitWidget"));
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();

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
    _email.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final Widget tmpBuilder = GestureDetector (
      onTap: () async {
        if (_formKey.currentState!.validate()) {
          try {
            _showPleaseWait(true);
            final Uri url = Uri.parse('$SERVER_IP/loginWithoutPass');
            final http.Response res = await http.post (
                url,
                headers: <String, String>{
                  'Content-Type': 'application/json; charset=UTF-8',
                  //'Authorization': jwt
                },
                body: jsonEncode(<String, String>{
                  'user_name': _email.text
                })
            );
            _showPleaseWait(false);
            if (res.statusCode == 200) {
              // Sign in
              debugPrint ('El valor de _email.text es: ${_email.text}');
              debugPrint ('El valor de res.body[user_name] es: ${json.decode(res.body)['user_name']}');
              if (!context.mounted) return;
              Navigator.push (
                  context,
                  MaterialPageRoute (
                      builder: (context) => (SignInView(_email.text, widget.reason))
                  )
              );
            } else if (res.statusCode == 404) {
              // Sign up
              debugPrint ('El valor de _email.text es: ${_email.text}');
              debugPrint ('El valor de res.body[user_name] es: ${json.decode(res.body)['user_name']}');
              if (!context.mounted) return;
              Navigator.push (
                  context,
                  MaterialPageRoute (
                      builder: (context) => (SignUpView(_email.text, widget.reason))  //  1 the call comes from the drawer. 2 the call comes from cart.view.dart
                  )
              );
            } else {
              // Error
              if (!context.mounted) return;
              ShowSnackBar.showSnackBar (context, json.decode(res.body)['message'].toString());
            }
          } catch (e) {
            if (!context.mounted) return;
            ShowSnackBar.showSnackBar(context, e.toString(), error: true);
          }
        }
      },
      child: Container (
        height: 64.0,
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
            ),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26,
                  offset: Offset (5,5),
                  blurRadius: 10
              )
            ]
        ),
        child: const Center (
          child: Text (
            'Entrar',
            style: TextStyle(
                fontSize: 24.0,
                color: tanteLadenBackgroundWhite
            ),
          ),
        ),
      ),
    );
    return SafeArea(
        child: Center(
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text (
                      'Identifícate',
                      style: TextStyle (
                        fontWeight: FontWeight.w900,
                        fontSize: 36.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox (height: 30.0,),
              Container (
                padding: EdgeInsets.zero,
                child: const Center (
                  child: Text (
                      'Introduce tu email para continuar con tu pedido.',
                      style: TextStyle (
                        fontWeight: FontWeight.w500,
                        fontSize: 16.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.justify,
                      maxLines: 2,
                      softWrap: true
                  ),
                ),
              ),
              const SizedBox (height: 20.0,),
              Form (
                autovalidateMode: AutovalidateMode.always,
                key: _formKey,
                child: Column (
                  children: [
                    TextFormField(
                      controller: _email,
                      decoration: InputDecoration (
                        labelText: 'Email',
                        labelStyle: const TextStyle (
                          color: tanteLadenIconBrown,
                        ),
                        suffixIcon: IconButton (
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _email.clear();
                            }
                        ),
                      ),
                      validator: (String? value) {
                        Pattern pattern =
                            r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]"
                            r"{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]"
                            r"{0,253}[a-zA-Z0-9])?)*$";
                        RegExp regexp = RegExp(pattern.toString());
                        if (!regexp.hasMatch(value ?? "") || value == null) {
                          return 'Introduce un email válido';
                        } else {
                          return null;
                        }
                      },
                    ),
                    const SizedBox(height: 40.0,),
                    _pleaseWait
                        ? Stack (
                            key:  const ObjectKey("stack"),
                            alignment: AlignmentDirectional.center,
                            children: [tmpBuilder, _pleaseWaitWidget],
                    )
                        : Stack (key:  const ObjectKey("stack"), children: [tmpBuilder],)
                  ],
                ),
              )
            ],
          ),
        )
    );
  }
}
class _MediumScreenView extends StatefulWidget {
  final int reason;           //  1 the call comes from the drawer. 2 the call comes from cart.view.dart
  const _MediumScreenView (this.reason);
  @override
  _MediumScreenViewState createState() {
    return _MediumScreenViewState();
  }
}
class _MediumScreenViewState extends State<_SmallScreenView> {
  bool _pleaseWait = false;
  final PleaseWaitWidget _pleaseWaitWidget = const PleaseWaitWidget(key: ObjectKey("pleaseWaitWidget"));
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();

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
    _email.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final Widget tmpBuilder = GestureDetector (
      onTap: () async {
        if (_formKey.currentState!.validate()) {
          try {
            _showPleaseWait(true);
            final Uri url = Uri.parse('$SERVER_IP/loginWithoutPass');
            final http.Response res = await http.post (
                url,
                headers: <String, String>{
                  'Content-Type': 'application/json; charset=UTF-8',
                  //'Authorization': jwt
                },
                body: jsonEncode(<String, String>{
                  'user_name': _email.text
                })
            );
            _showPleaseWait(false);
            if (res.statusCode == 200) {
              // Sign in
              debugPrint ('El valor de _email.text es: ${_email.text}');
              debugPrint ('El valor de res.body[user_name] es: ${json.decode(res.body)['user_name']}');
              if (!context.mounted) return;
              Navigator.push (
                  context,
                  MaterialPageRoute (
                      builder: (context) => (SignInView(_email.text, widget.reason))
                  )
              );
            } else if (res.statusCode == 404) {
              // Sign up
              debugPrint ('El valor de _email.text es: ${_email.text}');
              debugPrint ('El valor de res.body[user_name] es: ${json.decode(res.body)['user_name']}');
              if (!context.mounted) return;
              Navigator.push (
                  context,
                  MaterialPageRoute (
                      builder: (context) => (SignUpView(_email.text, widget.reason))  //  1 the call comes from the drawer. 2 the call comes from cart.view.dart
                  )
              );
            } else {
              // Error
              if (!context.mounted) return;
              ShowSnackBar.showSnackBar (context, json.decode(res.body)['message'].toString());
            }
          } catch (e) {
            if (!context.mounted) return;
            ShowSnackBar.showSnackBar(context, e.toString(), error: true);
          }
        }
      },
      child: Container (
        height: 64.0,
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
            ),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26,
                  offset: Offset (5,5),
                  blurRadius: 10
              )
            ]
        ),
        child: const Center (
          child: Text (
            'Entrar',
            style: TextStyle(
                fontSize: 24.0,
                color: tanteLadenBackgroundWhite
            ),
          ),
        ),
      ),
    );
    return SafeArea(
        child: Center(
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text (
                      'Identifícate',
                      style: TextStyle (
                        fontWeight: FontWeight.w900,
                        fontSize: 36.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox (height: 30.0,),
              Container (
                padding: EdgeInsets.zero,
                child: const Center (
                  child: Text (
                      'Introduce tu email para continuar con tu pedido.',
                      style: TextStyle (
                        fontWeight: FontWeight.w500,
                        fontSize: 16.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.justify,
                      maxLines: 2,
                      softWrap: true
                  ),
                ),
              ),
              const SizedBox (height: 20.0,),
              Form (
                autovalidateMode: AutovalidateMode.always,
                key: _formKey,
                child: Column (
                  children: [
                    TextFormField(
                      controller: _email,
                      decoration: InputDecoration (
                        labelText: 'Email',
                        labelStyle: const TextStyle (
                          color: tanteLadenIconBrown,
                        ),
                        suffixIcon: IconButton (
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _email.clear();
                            }
                        ),
                      ),
                      validator: (String? value) {
                        Pattern pattern =
                            r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]"
                            r"{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]"
                            r"{0,253}[a-zA-Z0-9])?)*$";
                        RegExp regexp = RegExp(pattern.toString());
                        if (!regexp.hasMatch(value ?? "") || value == null) {
                          return 'Introduce un email válido';
                        } else {
                          return null;
                        }
                      },
                    ),
                    const SizedBox(height: 40.0,),
                    _pleaseWait
                        ? Stack (
                      key:  const ObjectKey("stack"),
                      alignment: AlignmentDirectional.center,
                      children: [tmpBuilder, _pleaseWaitWidget],
                    )
                        : Stack (key:  const ObjectKey("stack"), children: [tmpBuilder],)
                  ],
                ),
              )
            ],
          ),
        )
    );
  }
}
class _LargeScreenView extends StatefulWidget {
  final int reason;           //  1 the call comes from the drawer. 2 the call comes from cart.view.dart
  const _LargeScreenView (this.reason);
  @override
  _LargeScreenViewState createState() {
    return _LargeScreenViewState();
  }
}
class _LargeScreenViewState extends State<_LargeScreenView> {
  bool _pleaseWait = false;
  final PleaseWaitWidget _pleaseWaitWidget = const PleaseWaitWidget(key: ObjectKey("pleaseWaitWidget"));
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();

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
    _email.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final Widget tmpBuilder = GestureDetector (
      onTap: () async {
        if (_formKey.currentState!.validate()) {
          try {
            _showPleaseWait(true);
            final Uri url = Uri.parse('$SERVER_IP/loginWithoutPass');
            final http.Response res = await http.post (
                url,
                headers: <String, String>{
                  'Content-Type': 'application/json; charset=UTF-8',
                  //'Authorization': jwt
                },
                body: jsonEncode(<String, String>{
                  'user_name': _email.text
                })
            );
            _showPleaseWait(false);
            if (res.statusCode == 200) {
              // Sign in
              debugPrint ('El valor de _email.text es: ${_email.text}');
              debugPrint ('El valor de res.body[user_name] es: ${json.decode(res.body)['user_name']}');
              if (!context.mounted) return;
              Navigator.push (
                  context,
                  MaterialPageRoute (
                      builder: (context) => (SignInView(_email.text, widget.reason))
                  )
              );
            } else if (res.statusCode == 404) {
              // Sign up
              debugPrint ('El valor de _email.text es: ${_email.text}');
              debugPrint ('El valor de res.body[user_name] es: ${json.decode(res.body)['user_name']}');
              if (!context.mounted) return;
              Navigator.push (
                  context,
                  MaterialPageRoute (
                      builder: (context) => (SignUpView(_email.text, widget.reason))  //  1 the call comes from the drawer. 2 the call comes from cart.view.dart
                  )
              );
            } else {
              // Error
              if (!context.mounted) return;
              ShowSnackBar.showSnackBar (context, json.decode(res.body)['message'].toString());
            }
          } catch (e) {
            if (!context.mounted) return;
            ShowSnackBar.showSnackBar(context, e.toString(), error: true);
          }
        }
      },
      child: Container (
        height: 64.0,
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
            ),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26,
                  offset: Offset (5,5),
                  blurRadius: 10
              )
            ]
        ),
        child: const Center (
          child: Text (
            'Entrar',
            style: TextStyle(
                fontSize: 24.0,
                color: tanteLadenBackgroundWhite
            ),
          ),
        ),
      ),
    );
    return SafeArea(
        child: Center(
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text (
                      'Identifícate',
                      style: TextStyle (
                        fontWeight: FontWeight.w900,
                        fontSize: 36.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox (height: 30.0,),
              Container (
                padding: EdgeInsets.zero,
                child: const Center (
                  child: Text (
                      'Introduce tu email para continuar con tu pedido.',
                      style: TextStyle (
                        fontWeight: FontWeight.w500,
                        fontSize: 16.0,
                        fontFamily: 'SF Pro Display',
                        fontStyle: FontStyle.normal,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.justify,
                      maxLines: 2,
                      softWrap: true
                  ),
                ),
              ),
              const SizedBox (height: 20.0,),
              Form (
                autovalidateMode: AutovalidateMode.always,
                key: _formKey,
                child: Column (
                  children: [
                    TextFormField(
                      controller: _email,
                      decoration: InputDecoration (
                        labelText: 'Email',
                        labelStyle: const TextStyle (
                          color: tanteLadenIconBrown,
                        ),
                        suffixIcon: IconButton (
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _email.clear();
                            }
                        ),
                      ),
                      validator: (String? value) {
                        Pattern pattern =
                            r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]"
                            r"{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]"
                            r"{0,253}[a-zA-Z0-9])?)*$";
                        RegExp regexp = RegExp(pattern.toString());
                        if (!regexp.hasMatch(value ?? "") || value == null) {
                          return 'Introduce un email válido';
                        } else {
                          return null;
                        }
                      },
                    ),
                    const SizedBox(height: 40.0,),
                    _pleaseWait
                        ? Stack (
                      key:  const ObjectKey("stack"),
                      alignment: AlignmentDirectional.center,
                      children: [tmpBuilder, _pleaseWaitWidget],
                    )
                        : Stack (key:  const ObjectKey("stack"), children: [tmpBuilder],)
                  ],
                ),
              )
            ],
          ),
        )
    );
  }
}