
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kompras/util/ResponsiveWidget.util.dart';
import 'package:kompras/view/UpdateEmail.view.dart';
import 'package:kompras/view/UpdateNameSurnameUser.view.dart';
import 'package:kompras/view/UpdatePassword.view.dart';

class PersonalData extends StatelessWidget {
  final String token;
  const PersonalData (this.token, {super.key});
  @override
  Widget build (BuildContext context) {
    return Scaffold (
      appBar: AppBar (
        elevation: 0.0,
        leading: IconButton (
          icon: Image.asset ('assets/images/leftArrow.png'),
          onPressed: () {
            //Navigator.pop (context);
            Navigator.popUntil(context, ModalRoute.withName('/'));
          },
        ),
      ),
      body: ResponsiveWidget(
        smallScreen: _SmallScreenView(token),
        mediumScreen: _MediumScreenView(token),
        largeScreen: _LargeScreenView(token),
      ),
    );
  }
}
class _SmallScreenView extends StatefulWidget {
  final String token;
  const _SmallScreenView(this.token);
  @override
  _SmallScreenViewState createState() {
    return _SmallScreenViewState();
  }
}
class _SmallScreenViewState extends State<_SmallScreenView> {
  late String _firstNameLastName;
  late String _firstName;
  late String _lastName;
  late int _userId;
  late String _email;
  @override
  void initState() {
    super.initState();
    Map<String, dynamic> payload;
    payload = json.decode(
        utf8.decode(
            base64.decode (base64.normalize(widget.token.split(".")[1]))
        )
    );
    _firstName = payload['user_firstname'];
    _lastName = payload['user_lastname'];
    _firstNameLastName = '$_firstName $_lastName';
    _userId = payload['user_id'];
    _email = payload['email'];
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {

    return SafeArea (
        child: ListView (
          padding: const EdgeInsets.all(15.0),
          children: [
            const Text (
              'Datos personales',
              style: TextStyle (
                  fontFamily: 'SF Pro Display',
                  fontSize: 24,
                  fontWeight: FontWeight.bold
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text(
                'Nombre',
                style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.w500
                ),
              ),
              subtitle: Text (
                _firstNameLastName,
                style: const TextStyle (
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.normal
                ),
              ),
              onTap: () async {
                final String firstNameLastNameOut = await Navigator.push(context, MaterialPageRoute(
                    builder: (context) => UpdateNameSurnameUser (_firstName, _lastName, _userId)
                ));
                debugPrint ('He vuelto de UpdateNameSurnameUser');
                debugPrint ('El valor devuelto es: $firstNameLastNameOut');
                setState(() {
                  _firstNameLastName = firstNameLastNameOut;
                });
              },
            ),
            const Divider(),
            ListTile (
              title: const Text (
                'Email',
                style: TextStyle (
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.w500
                ),
              ),
              subtitle: Text (
                _email,
                style: const TextStyle (
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.normal
                ),
              ),
              onTap: () async {
                final String email = await Navigator.push (context, MaterialPageRoute(
                    builder: (context) => UpdateEmail (_email, _userId)
                ));
                debugPrint ('He vuelto de UpdateEmail');
                debugPrint ('El valor devuelto es: $email');
                setState(() {
                  _email = email;
                });
              },
            ),
            const Divider(),
            ListTile(
              title: const Text(
                'Contraseña',
                style: TextStyle (
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.w500
                ),
              ),
              subtitle: const Text (
                'Configura tu contraseña',
                style: TextStyle (
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.normal
                ),
              ),
              onTap: () {
                Navigator.push (context, MaterialPageRoute(
                    builder: (context) => UpdatePassword (_userId)
                ));
                debugPrint ('He vuelto de UpdatePasswod');
              },
            )
          ],
        )
    );
  }
}
class _MediumScreenView extends StatefulWidget {
  final String token;
  const _MediumScreenView(this.token);
  @override
  _MediumScreenViewState createState() {
    return _MediumScreenViewState();
  }
}
class _MediumScreenViewState extends State<_MediumScreenView> {
  late String _firstNameLastName;
  late String _firstName;
  late String _lastName;
  late int _userId;
  late String _email;
  @override
  void initState() {
    super.initState();
    Map<String, dynamic> payload;
    payload = json.decode(
        utf8.decode(
            base64.decode (base64.normalize(widget.token.split(".")[1]))
        )
    );
    _firstName = payload['user_firstname'];
    _lastName = payload['user_lastname'];
    _firstNameLastName = '$_firstName $_lastName';
    _userId = payload['user_id'];
    _email = payload['email'];
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {

    return SafeArea (
        child: ListView (
          padding: const EdgeInsets.all(15.0),
          children: [
            const Text (
              'Datos personales',
              style: TextStyle (
                  fontFamily: 'SF Pro Display',
                  fontSize: 24,
                  fontWeight: FontWeight.bold
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text(
                'Nombre',
                style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.w500
                ),
              ),
              subtitle: Text (
                _firstNameLastName,
                style: const TextStyle (
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.normal
                ),
              ),
              onTap: () async {
                final String firstNameLastNameOut = await Navigator.push(context, MaterialPageRoute(
                    builder: (context) => UpdateNameSurnameUser (_firstName, _lastName, _userId)
                ));
                debugPrint ('He vuelto de UpdateNameSurnameUser');
                debugPrint ('El valor devuelto es: $firstNameLastNameOut');
                setState(() {
                  _firstNameLastName = firstNameLastNameOut;
                });
              },
            ),
            const Divider(),
            ListTile (
              title: const Text (
                'Email',
                style: TextStyle (
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.w500
                ),
              ),
              subtitle: Text (
                _email,
                style: const TextStyle (
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.normal
                ),
              ),
              onTap: () async {
                final String email = await Navigator.push (context, MaterialPageRoute(
                    builder: (context) => UpdateEmail (_email, _userId)
                ));
                debugPrint ('He vuelto de UpdateEmail');
                debugPrint ('El valor devuelto es: $email');
                setState(() {
                  _email = email;
                });
              },
            ),
            const Divider(),
            ListTile(
              title: const Text(
                'Contraseña',
                style: TextStyle (
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.w500
                ),
              ),
              subtitle: const Text (
                'Configura tu contraseña',
                style: TextStyle (
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.normal
                ),
              ),
              onTap: () {
                Navigator.push (context, MaterialPageRoute(
                    builder: (context) => UpdatePassword (_userId)
                ));
                debugPrint ('He vuelto de UpdatePasswod');
              },
            )
          ],
        )
    );
  }
}
class _LargeScreenView extends StatefulWidget {
  final String token;
  const _LargeScreenView(this.token);
  @override
  _LargeScreenViewState createState() {
    return _LargeScreenViewState();
  }
}
class _LargeScreenViewState extends State<_LargeScreenView> {
  late String _firstNameLastName;
  late String _firstName;
  late String _lastName;
  late int _userId;
  late String _email;
  @override
  void initState() {
    super.initState();
    Map<String, dynamic> payload;
    payload = json.decode(
        utf8.decode(
            base64.decode (base64.normalize(widget.token.split(".")[1]))
        )
    );
    _firstName = payload['user_firstname'];
    _lastName = payload['user_lastname'];
    _firstNameLastName = '$_firstName $_lastName';
    _userId = payload['user_id'];
    _email = payload['email'];
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {

    return SafeArea (
        child: ListView (
          padding: const EdgeInsets.all(15.0),
          children: [
            const Text (
              'Datos personales',
              style: TextStyle (
                  fontFamily: 'SF Pro Display',
                  fontSize: 24,
                  fontWeight: FontWeight.bold
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text(
                'Nombre',
                style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.w500
                ),
              ),
              subtitle: Text (
                _firstNameLastName,
                style: const TextStyle (
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.normal
                ),
              ),
              onTap: () async {
                final String firstNameLastNameOut = await Navigator.push(context, MaterialPageRoute(
                    builder: (context) => UpdateNameSurnameUser (_firstName, _lastName, _userId)
                ));
                debugPrint ('He vuelto de UpdateNameSurnameUser');
                debugPrint ('El valor devuelto es: $firstNameLastNameOut');
                setState(() {
                  _firstNameLastName = firstNameLastNameOut;
                });
              },
            ),
            const Divider(),
            ListTile (
              title: const Text (
                'Email',
                style: TextStyle (
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.w500
                ),
              ),
              subtitle: Text (
                _email,
                style: const TextStyle (
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.normal
                ),
              ),
              onTap: () async {
                final String email = await Navigator.push (context, MaterialPageRoute(
                    builder: (context) => UpdateEmail (_email, _userId)
                ));
                debugPrint ('He vuelto de UpdateEmail');
                debugPrint ('El valor devuelto es: $email');
                setState(() {
                  _email = email;
                });
              },
            ),
            const Divider(),
            ListTile(
              title: const Text(
                'Contraseña',
                style: TextStyle (
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.w500
                ),
              ),
              subtitle: const Text (
                'Configura tu contraseña',
                style: TextStyle (
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.normal
                ),
              ),
              onTap: () {
                Navigator.push (context, MaterialPageRoute(
                    builder: (context) => UpdatePassword (_userId)
                ));
                debugPrint ('He vuelto de UpdatePasswod');
              },
            )
          ],
        )
    );
  }
}