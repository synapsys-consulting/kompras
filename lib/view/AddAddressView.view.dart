import 'package:flutter/material.dart';
import 'package:kompras/View/AddressView.view.dart';
import 'package:kompras/util/ResponsiveWidget.util.dart';
import 'package:kompras/util/color.util.dart';
import 'package:kompras/util/configuration.util.dart';

class AddAddressView extends StatelessWidget {
  final String personeId;
  final String userId;
  const AddAddressView (this.personeId, this.userId, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold (
      appBar: AppBar (
        elevation: 0.0,
        leading: IconButton(
            icon: Image.asset('assets/images/logoCross.png'),
            onPressed: (){
              Navigator.pop(context);
            }
        ),
        title: const Text(
          'Entrega',
          style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 16.0,
              fontWeight: FontWeight.w500
          ),
          textAlign: TextAlign.left,
        ),
        actions: <Widget>[
          IconButton(
              icon: Image.asset('assets/images/logoQuestion.png'),
              onPressed: null
          )
        ],
      ),
      body: ResponsiveWidget (
        smallScreen: _SmallScreenView(personeId: personeId, userId: userId),
        mediumScreen: _MediumScreenView(personeId: personeId, userId: userId),
        largeScreen: _LargeScreenView(personeId: personeId, userId: userId),
      ),
    );
  }
}
class _SmallScreenView extends StatelessWidget {
  final String personeId;
  final String userId;
  const _SmallScreenView ({required this.personeId, required this.userId});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding (
        padding: const EdgeInsets.all(20.0),
        child: Column (
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/addressMessage.png'),
            const Text(
              'Añade',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 24.0,
                fontFamily: 'SF Pro Display',
                fontStyle: FontStyle.normal,
                color: Colors.black,
              ),
            ),
            const Text(
              'tu dirección',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 24.0,
                fontFamily: 'SF Pro Display',
                fontStyle: FontStyle.normal,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20.0,),
            const Text(
              'Indícanos dónde quieres recibir tu pedido para continuar.',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16.0,
                fontFamily: 'SF Pro Display',
                fontStyle: FontStyle.normal,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 40.0,),
            GestureDetector (
              onTap: () async {
                Navigator.push (
                    context,
                    MaterialPageRoute(
                        builder: (context) => AddressView(personeId, userId, COME_FROM_ANOTHER)
                    )
                );
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
                    'Añadir dirección',
                    style: TextStyle(
                        fontSize: 24.0,
                        color: tanteLadenBackgroundWhite
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _MediumScreenView extends StatelessWidget {
  final String personeId;
  final String userId;
  const _MediumScreenView ({required this.personeId, required this.userId});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding (
        padding: const EdgeInsets.all(20.0),
        child: Column (
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/addressMessage.png'),
            const Text(
              'Añade',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 24.0,
                fontFamily: 'SF Pro Display',
                fontStyle: FontStyle.normal,
                color: Colors.black,
              ),
            ),
            const Text(
              'tu dirección',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 24.0,
                fontFamily: 'SF Pro Display',
                fontStyle: FontStyle.normal,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20.0,),
            const Text(
              'Indícanos dónde quieres recibir tu pedido para continuar.',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16.0,
                fontFamily: 'SF Pro Display',
                fontStyle: FontStyle.normal,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 40.0,),
            GestureDetector (
              onTap: () async {
                Navigator.push (
                    context,
                    MaterialPageRoute(
                        builder: (context) => AddressView(personeId, userId, COME_FROM_ANOTHER)
                    )
                );
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
                    'Añadir dirección',
                    style: TextStyle(
                        fontSize: 24.0,
                        color: tanteLadenBackgroundWhite
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _LargeScreenView extends StatelessWidget {
  final String personeId;
  final String userId;
  const _LargeScreenView ({required this.personeId, required this.userId});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding (
        padding: const EdgeInsets.all(20.0),
        child: Column (
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/addressMessage.png'),
            const Text(
              'Añade',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 24.0,
                fontFamily: 'SF Pro Display',
                fontStyle: FontStyle.normal,
                color: Colors.black,
              ),
            ),
            const Text(
              'tu dirección',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 24.0,
                fontFamily: 'SF Pro Display',
                fontStyle: FontStyle.normal,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20.0,),
            const Text(
              'Indícanos dónde quieres recibir tu pedido para continuar.',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16.0,
                fontFamily: 'SF Pro Display',
                fontStyle: FontStyle.normal,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 40.0,),
            GestureDetector (
              onTap: () async {
                Navigator.push (
                    context,
                    MaterialPageRoute(
                        builder: (context) => AddressView(personeId, userId, COME_FROM_ANOTHER)
                    )
                );
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
                    'Añadir dirección',
                    style: TextStyle(
                        fontSize: 24.0,
                        color: tanteLadenBackgroundWhite
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
