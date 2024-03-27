import 'package:flutter/material.dart';
import 'package:kompras/util/color.util.dart';

class PleaseWaitWidget extends StatelessWidget {
  const PleaseWaitWidget({required Key key,}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: tanteLadenOrange900,));
  }
}