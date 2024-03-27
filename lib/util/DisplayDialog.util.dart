import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat hide TextDirection;

import 'package:kompras/util/color.util.dart';
import 'package:kompras/util/MultiPriceListElement.util.dart';
import 'package:kompras/util/configuration.util.dart';

class DisplayDialog {
  static Future<void> displayDialog (BuildContext context, Widget image, String title, String message) async{
    var heightScreen = MediaQuery.of(context).size.height;
    return await showDialog<void>(
        context: context,
        builder: (context) {
          return ListView(
            children: <Widget>[
              SimpleDialog (
                titlePadding: EdgeInsets.zero,
                title: Container (
                  padding: EdgeInsets.zero,
                  child: Column (
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(0.0),
                        //width: 96.0,
                        //height: 96.0,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                            ),
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFFE0E4EE),
                                offset: Offset(4.0,4.0),
                                spreadRadius: 1.0,
                                blurRadius: 15.0,
                              ),
                              BoxShadow(
                                color: Colors.white,
                                offset: Offset(-4.0, -4.0),
                                spreadRadius: 1.0,
                                blurRadius: 15.0,
                              ),
                            ]
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          width: 96.0,
                          height: 96.0,
                          child: Image.asset(
                              'assets/images/imageDialogBox.png'
                            //'assets/Group8.png'
                          ),
                        ),
                      ),
                      (heightScreen <= 760) ? const SizedBox(height: 5.0,) : const SizedBox(height: 40.0,),
                      image,
                      //Image.asset('assets/images/weightMessage.png'),
                      (heightScreen <= 760) ? const SizedBox(height: 5.0) : const SizedBox(height: 24.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Avenir',
                              fontSize: 24.0,
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      (heightScreen <= 760) ? const SizedBox(height: 5.0) : const SizedBox(height: 24.0),
                      Padding (
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                        child: Center(
                          child: Text(
                            message,
                            style: const TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              fontWeight: FontWeight.normal,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.justify,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            maxLines: 6,
                          ),
                        ),
                      ),
                      (heightScreen <= 760) ? const SizedBox(height: 10.0,) : const SizedBox(height: 40.0,),
                    ],
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: const BorderSide(),
                ),
                elevation: 24.0,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                    child: GestureDetector (
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration (
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(8.0),
                            gradient: const LinearGradient(
                              colors: <Color>[
                                Color (0xFF833C26),
                                Color (0xFF9A541F),
                                Color (0xFFF9B806),
                                Color (0XFFFFC107),
                              ],
                            )
                        ),
                        height: 64,
                        //padding: const EdgeInsets.fromLTRB(145.0, 20.0, 145.0, 20.0),
                        child: const Text(
                            'Entendido',
                            style: TextStyle(
                                fontSize: 24,
                                color: tanteLadenBackgroundWhite
                            )
                        ),
                      ),
                      //elevation: 8.0, // New
                      onTap: () async {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  (heightScreen <= 760) ? const SizedBox(height: 20.0) : const SizedBox(height: 24.0),
                ],
              ),
            ],
          );
        }
    );
  }
  static Future<bool?> displayDialogConfirmCancel (BuildContext context, Widget image, String title, String message) async {
    var heightScreen = MediaQuery.of(context).size.height;
    return await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return ListView(
            children: <Widget>[
              SimpleDialog (
                titlePadding: EdgeInsets.zero,
                title: Container(
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(0.0),
                        //width: 96.0,
                        //height: 96.0,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                            ),
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFFE0E4EE),
                                offset: Offset(4.0,4.0),
                                spreadRadius: 1.0,
                                blurRadius: 15.0,
                              ),
                              BoxShadow(
                                color: Colors.white,
                                offset: Offset(-4.0, -4.0),
                                spreadRadius: 1.0,
                                blurRadius: 15.0,
                              ),
                            ]
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          width: 96.0,
                          height: 96.0,
                          child: Image.asset(
                              'assets/images/imageDialogBox.png'
                            //'assets/Group8.png'
                          ),
                        ),
                      ),
                      (heightScreen <= 760) ? const SizedBox(height: 5.0,) : const SizedBox(height: 40.0,),
                      image,
                      //Image.asset('assets/images/weightMessage.png'),
                      (heightScreen <= 760) ? const SizedBox(height: 5.0) : const SizedBox(height: 24.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Avenir',
                              fontSize: 24.0,
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      (heightScreen <= 760) ? const SizedBox(height: 5.0) : const SizedBox(height: 24.0),
                      Padding (
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                        child: Center(
                          child: Text(
                            message,
                            style: const TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontStyle: FontStyle.normal,
                              fontWeight: FontWeight.normal,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.justify,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            maxLines: 6,
                          ),
                        ),
                      ),
                      (heightScreen <= 760) ? const SizedBox(height: 10.0,) : const SizedBox(height: 40.0,),
                    ],
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: const BorderSide(),
                ),
                elevation: 24.0,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                    child: GestureDetector (
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration (
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(8.0),
                            gradient: const LinearGradient(
                              colors: <Color>[
                                Color (0xFF833C26),
                                Color (0xFF9A541F),
                                Color (0xFFF9B806),
                                Color (0XFFFFC107),
                              ],
                            )
                        ),
                        height: 64,
                        //padding: const EdgeInsets.fromLTRB(145.0, 20.0, 145.0, 20.0),
                        child: const Text(
                            'Confirmar',
                            style: TextStyle(
                                fontSize: 24,
                                color: tanteLadenBackgroundWhite
                            )
                        ),
                      ),
                      //elevation: 8.0, // New
                      onTap: () async {
                        Navigator.pop(context, true);
                      },
                    ),
                  ),
                  (heightScreen <= 760) ? const SizedBox(height: 20.0) : const SizedBox(height: 24.0),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                          child: GestureDetector(
                            child: const Text (
                              'Cancelar',
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            onTap: (){
                              Navigator.pop(context, false);
                            },
                          )
                      ),
                    ],
                  ),
                  (heightScreen <= 760) ? const SizedBox(height: 20.0) : const SizedBox(height: 24.0),
                ],
              ),
            ],
          );
        }
    );
  }
  static Future<void> displayInformationAsATable (BuildContext context, String title, List<MultiPriceListElement> itemsToShow) async {
    var heightScreen = MediaQuery.of(context).size.height;
    return await showDialog<void> (
        context: context,
        builder: (context) {
          return ListView(
            children: <Widget>[
              SimpleDialog (
                titlePadding: EdgeInsets.zero,
                title: Container (
                  padding: EdgeInsets.zero,
                  child: Column (
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(0.0),
                        //width: 96.0,
                        //height: 96.0,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                            ),
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFFE0E4EE),
                                offset: Offset(4.0,4.0),
                                spreadRadius: 1.0,
                                blurRadius: 15.0,
                              ),
                              BoxShadow(
                                color: Colors.white,
                                offset: Offset(-4.0, -4.0),
                                spreadRadius: 1.0,
                                blurRadius: 15.0,
                              ),
                            ]
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          width: 96.0,
                          height: 96.0,
                          child: Image.asset(
                              'assets/images/imageDialogBox.png'
                            //'assets/Group8.png'
                          ),
                        ),
                      ),
                      (heightScreen <= 760) ? const SizedBox(height: 5.0,) : const SizedBox(height: 40.0,),
                      Row (
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text (
                            title,
                            style: const TextStyle (
                              fontFamily: 'Avenir',
                              fontSize: 12.0,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      (heightScreen <= 760) ? const SizedBox(height: 5.0) : const SizedBox(height: 24.0),
                      Padding (
                        padding: const EdgeInsets.only (left: 16.0, right: 16.0),
                        child: Center(
                            child: DataTable (
                              horizontalMargin: 2.0,
                              columnSpacing: 14.0,
                              columns: const <DataColumn>[
                                DataColumn(
                                    label: Text(
                                      'Unds. desde',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 12.0,
                                        fontFamily: 'SF Pro Display',
                                        fontStyle: FontStyle.normal,
                                        color: Color(0xFF6C6D77),
                                      ),
                                    )
                                ),
                                DataColumn(
                                    label: Text(
                                      'Unds. hasta',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 12.0,
                                        fontFamily: 'SF Pro Display',
                                        fontStyle: FontStyle.normal,
                                        color: Color(0xFF6C6D77),
                                      ),
                                    )
                                ),
                                DataColumn(
                                    label: Text(
                                      'Precio',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 12.0,
                                        fontFamily: 'SF Pro Display',
                                        fontStyle: FontStyle.normal,
                                        color: Color(0xFF6C6D77),
                                      ),
                                    )
                                ),
                              ],
                              rows: List<DataRow>.generate(itemsToShow.length,(int index) => DataRow(
                                  cells: <DataCell>[
                                    DataCell(
                                        Text(
                                          itemsToShow[index].unitsFrom.toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w400,
                                            fontSize: 12.0,
                                            fontFamily: 'SF Pro Display',
                                            fontStyle: FontStyle.normal,
                                            color: Color(0xFF6C6D77),
                                          ),
                                        )
                                    ),
                                    DataCell(
                                        Text(
                                          itemsToShow[index].unitsTo.toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w400,
                                            fontSize: 12.0,
                                            fontFamily: 'SF Pro Display',
                                            fontStyle: FontStyle.normal,
                                            color: Color(0xFF6C6D77),
                                          ),
                                        )
                                    ),
                                    DataCell(
                                        Text(
                                          NumberFormat.currency(locale:'en_US', symbol: '€', decimalDigits:2).format(double.parse((itemsToShow[index].price/MULTIPLYING_FACTOR).toString())),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w400,
                                            fontSize: 12.0,
                                            fontFamily: 'SF Pro Display',
                                            fontStyle: FontStyle.normal,
                                            color: Color(0xFF6C6D77),
                                          ),
                                        )
                                    )
                                  ]
                              )),
                            )
                        ),
                      ),
                      (heightScreen <= 760) ? const SizedBox(height: 10.0,) : const SizedBox(height: 40.0,),
                    ],
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: const BorderSide(),
                ),
                elevation: 24.0,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                    child: GestureDetector (
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration (
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(8.0),
                            gradient: const LinearGradient(
                              colors: <Color>[
                                Color (0xFF833C26),
                                Color (0xFF9A541F),
                                Color (0xFFF9B806),
                                Color (0XFFFFC107),
                              ],
                            )
                        ),
                        height: 64,
                        //padding: const EdgeInsets.fromLTRB(145.0, 20.0, 145.0, 20.0),
                        child: const Text(
                            'Entendido',
                            style: TextStyle(
                                fontSize: 24,
                                color: tanteLadenBackgroundWhite
                            )
                        ),
                      ),
                      //elevation: 8.0, // New
                      onTap: () async {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  (heightScreen <= 760) ? const SizedBox(height: 20.0) : const SizedBox(height: 24.0),
                ],
              ),
            ],
          );
        }
    );
  }
}