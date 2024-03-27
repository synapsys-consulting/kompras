import 'package:flutter/material.dart';
import 'package:kompras/model/AddressList.model.dart';
import 'package:kompras/model/DefaultAddressList.model.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import 'package:kompras/model/Cart.model.dart';
import 'package:kompras/util/color.util.dart';
import 'package:kompras/model/Catalog.model.dart';
import 'package:kompras/view/home.view.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        final isValidHost = host == "54.87.206.162";     // PRODUCTION
        //final isValidHost = host == "192.168.2.106";  // DEVELOPMENT
        //final isValidHost = host == "localhost";  // DEVELOPMENT
        //final isValidHost = host == "3.92.229.110";  // PRUEBA
        //final isValidHost = host == "192.168.1.134";
        return isValidHost;
      };
  }
}
void main() {
  //HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<Cart>(create: (context) => Cart(),),
        ChangeNotifierProvider<Catalog>(create: (context) => Catalog()),
        ChangeNotifierProvider<DefaultAddressList>(create: (context) => DefaultAddressList()),
        ChangeNotifierProvider<AddressesList>(create: (context) => AddressesList()
        )

      ],
      child: MaterialApp(
        title: 'Comprando',
        theme: _tanteLadenTheme,
        home: const MyHomePage (title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

final ThemeData _tanteLadenTheme = _buildTanteLadenTheme();
ThemeData _buildTanteLadenTheme() {
  final ThemeData base = ThemeData.from(
    colorScheme: ColorScheme.fromSwatch (
        primarySwatch: Colors.amber,
        //primaryColorDark: tanteLadenAmber500,
        accentColor: tanteLadenOrange900,
        cardColor: tanteLadenBackgroundWhite,
        //backgroundColor: tanteLadenSurfaceWhite,
        backgroundColor: tanteLadenBackgroundWhite,
        errorColor: tanteLadenErrorRed
    ),
  );
  return base.copyWith (
    primaryColor: tanteLadenAmber500,
    primaryIconTheme: base.primaryIconTheme.copyWith(
        color: tanteLadenBrown500
    ),
    buttonTheme: base.buttonTheme.copyWith(
        buttonColor: tanteLadenOrange900,
        colorScheme: base.colorScheme.copyWith(
          secondary: tanteLadenOrange200,
        )
    ),
    buttonBarTheme: base.buttonBarTheme.copyWith(
        buttonTextTheme: ButtonTextTheme.accent
    ),
    scaffoldBackgroundColor: tanteLadenBackgroundWhite,
    cardColor: tanteLadenBackgroundWhite,
    textSelectionTheme: const TextSelectionThemeData(
        cursorColor: tanteLadenOnPrimary,
        selectionColor: tanteLadenAmber100,
        selectionHandleColor: tanteLadenAmber100
    ),
  );
}
