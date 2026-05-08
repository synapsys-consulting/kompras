import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kompras/controller/PurchaseController.controller.dart';
import 'package:kompras/model/Purchase.model.dart';
import 'package:kompras/model/PurchaseStatus.model.dart';
import 'package:kompras/util/PleaseWaitWidget.util.dart';
import 'package:kompras/util/ResponsiveWidget.util.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kompras/util/ShowSnackBar.util.dart';
import 'package:kompras/util/configuration.util.dart';
import 'package:http/http.dart' as http;
import 'package:kompras/view/PurchaseDetailView.view.dart';

bool _isClosed(Purchase p) => p.statusId == 'A' || p.statusId == 'N';

class PurchaseView extends StatefulWidget {
  final int userId;
  final int partnerId;
  final String userRole;

  const PurchaseView(
      {super.key,
      required this.userId,
      required this.partnerId,
      required this.userRole});

  @override
  State<PurchaseView> createState() => _PurchaseViewState();
}

class _PurchaseViewState extends State<PurchaseView> {
  final PurchaseController _controller = PurchaseController();
  late Future<List<Purchase>> _future;
  List<Purchase>? _master;
  late DateTime _dateFrom;
  late DateTime _dateTo;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _dateTo = DateTime(now.year, now.month, now.day);
    _dateFrom = _dateTo.subtract(const Duration(days: 60));
    _future = _load();
  }

  Future<List<Purchase>> _load() async {
    final list = await _controller.getPurchasesByUserId(
      widget.userId,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );
    _master = list;
    return list;
  }

  Future<void> _refresh() async {
    final list = await _controller.getPurchasesByUserId(
      widget.userId,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );
    if (!mounted) return;
    setState(() {
      _master = list;
      _future = Future.value(list);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          leading: IconButton(
            icon: Image.asset('assets/images/leftArrow.png'),
            onPressed: () {
              Navigator.popUntil(context, ModalRoute.withName('/'));
            },
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'En flujo'),
              Tab(text: 'Servidos/Anulados'),
            ],
          ),
        ),
        body: FutureBuilder<List<Purchase>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final all = _master ?? snapshot.data!;
                final open = all.where((p) => !_isClosed(p)).toList();
                final closed = all.where(_isClosed).toList();
                return TabBarView(
                  children: [
                    _buildTab(open, 'No hay compras en flujo.'),
                    _buildClosedTab(closed),
                  ],
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text('Error. ${snapshot.error}')]),
                );
              } else {
                return const Center(
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            }),
      ),
    );
  }

  Widget _buildTab(List<Purchase> items, String emptyMessage) {
    if (items.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return ResponsiveWidget(
      largeScreen: _LargeScreen(
          items, widget.userId, widget.partnerId, widget.userRole, _refresh),
      mediumScreen: _MediumScreen(
          items, widget.userId, widget.partnerId, widget.userRole, _refresh),
      smallScreen: _SmallScreen(
          items, widget.userId, widget.partnerId, widget.userRole, _refresh),
    );
  }

  Widget _buildClosedTab(List<Purchase> closed) {
    return Column(
      children: [
        _DateRangeBar(
          from: _dateFrom,
          to: _dateTo,
          onSearch: (DateTime f, DateTime t) async {
            setState(() {
              _dateFrom = f;
              _dateTo = t;
            });
            await _refresh();
          },
        ),
        Expanded(
          child: closed.isEmpty
              ? const Center(child: Text('No hay compras servidas en ese rango.'))
              : ResponsiveWidget(
                  largeScreen: _LargeScreen(closed, widget.userId, widget.partnerId, widget.userRole, _refresh),
                  mediumScreen: _MediumScreen(closed, widget.userId, widget.partnerId, widget.userRole, _refresh),
                  smallScreen: _SmallScreen(closed, widget.userId, widget.partnerId, widget.userRole, _refresh),
                ),
        ),
      ],
    );
  }
}

class _DateRangeBar extends StatefulWidget {
  final DateTime from;
  final DateTime to;
  final Future<void> Function(DateTime from, DateTime to) onSearch;
  const _DateRangeBar({required this.from, required this.to, required this.onSearch});

  @override
  State<_DateRangeBar> createState() => _DateRangeBarState();
}

class _DateRangeBarState extends State<_DateRangeBar> {
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    _from = widget.from;
    _to = widget.to;
  }

  Future<void> _pick(bool isFrom) async {
    final DateTime initial = isFrom ? _from : _to;
    final DateTime picked = (await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          locale: const Locale('es', 'ES'),
        )) ??
        initial;
    setState(() {
      if (isFrom) {
        _from = DateTime(picked.year, picked.month, picked.day);
      } else {
        _to = DateTime(picked.year, picked.month, picked.day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool valid = !_from.isAfter(_to);
    final String fromLabel = DateFormat('dd/MM/yyyy', 'es_ES').format(_from);
    final String toLabel = DateFormat('dd/MM/yyyy', 'es_ES').format(_to);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(child: _DateField(label: 'Desde', value: fromLabel, valid: valid, onTap: () => _pick(true))),
          const SizedBox(width: 8),
          Expanded(child: _DateField(label: 'Hasta', value: toLabel, valid: valid, onTap: () => _pick(false))),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: valid ? () => widget.onSearch(_from, _to) : null,
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final bool valid;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.value, required this.valid, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          errorText: valid ? null : 'Rango inválido',
        ),
        child: Text(value, style: TextStyle(color: valid ? Colors.black : Colors.red)),
      ),
    );
  }
}

class _SmallScreen extends StatefulWidget {
  final List<Purchase> itemsPurchase;
  final int userId;
  final int partnerId;
  final String userRole;
  final Future<void> Function() onChanged;
  const _SmallScreen(this.itemsPurchase, this.userId, this.partnerId,
      this.userRole, this.onChanged);

  @override
  _SmallScreenState createState() => _SmallScreenState();
}

class _SmallScreenState extends State<_SmallScreen> {
  bool _pleaseWait = false;
  final PleaseWaitWidget _pleaseWaitWidget =
      const PleaseWaitWidget(key: ObjectKey("pleaseWaitWidget"));

  void _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget tmpBuilder = ListView.builder(
        itemCount: widget.itemsPurchase.length,
        itemBuilder: (BuildContext context, int index) {
          return Card(
              elevation: 4.0,
              child: ListTile(
                leading: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('dd', 'es_ES')
                          .format(widget.itemsPurchase[index].orderDate),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      DateFormat('MMM', 'es_ES')
                          .format(widget.itemsPurchase[index].orderDate),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      DateFormat('yyyy', 'es_ES')
                          .format(widget.itemsPurchase[index].orderDate),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                title: Text(
                  widget.itemsPurchase[index].showName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                    fontFamily: 'SF Pro Display',
                    fontStyle: FontStyle.normal,
                    color: Colors.black,
                  ),
                ),
                subtitle: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                                text: 'Pedido: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: widget.itemsPurchase[index].orderId
                                          .toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                          RichText(
                            text: TextSpan(
                                text: 'Estado: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text:
                                          widget.itemsPurchase[index].allStatus,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                          RichText(
                            text: TextSpan(
                                text: 'Items: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: widget.itemsPurchase[index].items
                                          .toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                                text: 'Importe: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: NumberFormat.currency(
                                              locale: 'es_ES',
                                              symbol: '€',
                                              decimalDigits: 2)
                                          .format(double.parse((widget
                                                      .itemsPurchase[index]
                                                      .totalBeforeDiscountWithoutTax /
                                                  MULTIPLYING_FACTOR)
                                              .toString())),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                          RichText(
                            text: TextSpan(
                                text: 'Modificación: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: widget.itemsPurchase[index]
                                                      .discountAmount /
                                                  MULTIPLYING_FACTOR >
                                              0
                                          ? '+${NumberFormat.currency(locale: 'es_ES', symbol: '€', decimalDigits: 2).format(double.parse((widget.itemsPurchase[index].discountAmount / MULTIPLYING_FACTOR).toString()))}'
                                          : NumberFormat.currency(
                                                  locale: 'es_ES',
                                                  symbol: '€',
                                                  decimalDigits: 2)
                                              .format(double.parse((widget
                                                          .itemsPurchase[index]
                                                          .discountAmount /
                                                      MULTIPLYING_FACTOR)
                                                  .toString())),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                          RichText(
                            text: TextSpan(
                                text: 'Subtotal: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: NumberFormat.currency(
                                              locale: 'es_ES',
                                              symbol: '€',
                                              decimalDigits: 2)
                                          .format(double.parse((widget
                                                      .itemsPurchase[index]
                                                      .totalAfterDiscountWithoutTax /
                                                  MULTIPLYING_FACTOR)
                                              .toString())),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                          RichText(
                            text: TextSpan(
                                text: 'IVA: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: NumberFormat.currency(
                                              locale: 'es_ES',
                                              symbol: '€',
                                              decimalDigits: 2)
                                          .format(double.parse((widget
                                                      .itemsPurchase[index]
                                                      .taxAmount /
                                                  MULTIPLYING_FACTOR)
                                              .toString())),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                          RichText(
                            text: TextSpan(
                                text: 'Total: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: NumberFormat.currency(
                                              locale: 'es_ES',
                                              symbol: '€',
                                              decimalDigits: 2)
                                          .format(double.parse((widget
                                                      .itemsPurchase[index]
                                                      .totalAmount /
                                                  MULTIPLYING_FACTOR)
                                              .toString())),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: (widget.itemsPurchase[index].numStatus == 1 &&
                              widget.itemsPurchase[index]
                                  .possibleStatusToTransitionTo.isNotEmpty &&
                              widget
                                      .itemsPurchase[index]
                                      .possibleStatusToTransitionTo[0]
                                      .priority ==
                                  1 &&
                              widget.partnerId != DEFAULT_PARTNER_ID)
                          ? IconButton(
                              padding: const EdgeInsets.all(5.0),
                              icon: Image.asset(
                                'assets/images/logoPlay.png',
                                fit: BoxFit.scaleDown,
                              ),
                              onPressed: () async {
                                try {
                                  debugPrint('Estoy en el onPressed');
                                  _showPleaseWait(true);
                                  final Uri url = Uri.parse(
                                      '$SERVER_IP/purchaseStateTransition/${widget.itemsPurchase[index].orderId}/${widget.itemsPurchase[index].providerName}');
                                  final http.Response res = await http
                                      .put(url,
                                          headers: <String, String>{
                                            'Content-Type':
                                                'application/json; charset=UTF-8',
                                            //'Authorization': jwt
                                          },
                                          body: jsonEncode(<String, String>{
                                            'user_id': widget.userId.toString(),
                                            'next_state': widget
                                                .itemsPurchase[index]
                                                .possibleStatusToTransitionTo
                                                .elementAt(0)
                                                .destinationStateId, // Always exists at least the next state if this icon has appeared
                                          }))
                                      .timeout(TIMEOUT);
                                  if (res.statusCode == 200) {
                                    _showPleaseWait(false);
                                    debugPrint('The Rest API has responsed.');
                                    await widget.onChanged();
                                  } else {
                                    _showPleaseWait(false);
                                    if (!context.mounted) return;
                                    ShowSnackBar.showSnackBar(context,
                                        json.decode(res.body)['message'],
                                        error: true);
                                  }
                                } catch (e) {
                                  _showPleaseWait(false);
                                  if (!context.mounted) return;
                                  ShowSnackBar.showSnackBar(
                                      context, e.toString(),
                                      error: true);
                                }
                              },
                            )
                          : Container(
                              width: 20, height: 20, padding: EdgeInsets.zero),
                    ),
                    Expanded(
                      child: (widget.itemsPurchase[index].numStatus == 1 &&
                              widget.itemsPurchase[index]
                                  .possibleStatusToTransitionTo.isNotEmpty &&
                              widget.partnerId != DEFAULT_PARTNER_ID)
                          ? PopupMenuButton(
                              icon: const Icon(
                                Icons.more_horiz,
                                color: Colors.black,
                              ),
                              itemBuilder: (BuildContext context) => widget
                                  .itemsPurchase[index]
                                  .possibleStatusToTransitionTo
                                  .map((e) {
                                return PopupMenuItem(
                                  value: e,
                                  child: Center(
                                    child: Text(e.statusName),
                                  ),
                                );
                              }).toList(),
                              onSelected: (PurchaseStatus result) async {
                                try {
                                  debugPrint('Estoy en el onSelected');
                                  _showPleaseWait(true);
                                  final Uri url = Uri.parse(
                                      '$SERVER_IP/purchaseStateTransition/${widget.itemsPurchase[index].orderId}/${widget.itemsPurchase[index].providerName}');
                                  final http.Response res = await http
                                      .put(url,
                                          headers: <String, String>{
                                            'Content-Type':
                                                'application/json; charset=UTF-8',
                                            //'Authorization': jwt
                                          },
                                          body: jsonEncode(<String, String>{
                                            'user_id': widget.userId.toString(),
                                            'next_state':
                                                result.destinationStateId,
                                          }))
                                      .timeout(TIMEOUT);
                                  if (res.statusCode == 200) {
                                    _showPleaseWait(false);
                                    debugPrint('The Rest API has responsed.');
                                    await widget.onChanged();
                                  } else {
                                    _showPleaseWait(false);
                                    if (!context.mounted) return;
                                    ShowSnackBar.showSnackBar(context,
                                        json.decode(res.body)['message'],
                                        error: true);
                                  }
                                } catch (e) {
                                  _showPleaseWait(false);
                                  if (!context.mounted) return;
                                  ShowSnackBar.showSnackBar(
                                      context, e.toString(),
                                      error: true);
                                }
                              },
                            )
                          : Container(
                              padding: EdgeInsets.zero,
                              width: 20,
                              height: 20,
                            ),
                    )
                  ],
                ),
                onTap: () async {
                  debugPrint(
                      'El partenerId del usuario es: ${widget.partnerId}');
                  final bool purchaseDetailStateChanged = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PurchaseDetailView(
                              widget.userId,
                              widget.itemsPurchase[index],
                              widget.partnerId,
                              widget.userRole)));
                  if (purchaseDetailStateChanged) {
                    await widget.onChanged();
                  }
                },
              ));
        });
    return SafeArea(
        child: _pleaseWait
            ? Stack(
                key: const ObjectKey("stack"),
                alignment: AlignmentDirectional.center,
                children: [tmpBuilder, _pleaseWaitWidget],
              )
            : Stack(
                key: const ObjectKey("stack"),
                children: [tmpBuilder],
              ));
  }
}

class _MediumScreen extends StatefulWidget {
  final List<Purchase> itemsPurchase;
  final int userId;
  final int partnerId;
  final String userRole;
  final Future<void> Function() onChanged;
  const _MediumScreen(this.itemsPurchase, this.userId, this.partnerId,
      this.userRole, this.onChanged);

  @override
  _MediumScreenState createState() => _MediumScreenState();
}

class _MediumScreenState extends State<_MediumScreen> {
  bool _pleaseWait = false;
  final PleaseWaitWidget _pleaseWaitWidget =
      const PleaseWaitWidget(key: ObjectKey("pleaseWaitWidget"));

  void _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget tmpBuilder = ListView.builder(
        itemCount: widget.itemsPurchase.length,
        itemBuilder: (BuildContext context, int index) {
          return Card(
              elevation: 4.0,
              child: ListTile(
                leading: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('dd', 'es_ES')
                          .format(widget.itemsPurchase[index].orderDate),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      DateFormat('MMM', 'es_ES')
                          .format(widget.itemsPurchase[index].orderDate),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      DateFormat('yyyy', 'es_ES')
                          .format(widget.itemsPurchase[index].orderDate),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                title: Text(
                  widget.itemsPurchase[index].showName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                    fontFamily: 'SF Pro Display',
                    fontStyle: FontStyle.normal,
                    color: Colors.black,
                  ),
                ),
                subtitle: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                                text: 'Pedido: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: widget.itemsPurchase[index].orderId
                                          .toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                          RichText(
                            text: TextSpan(
                                text: 'Estado: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text:
                                          widget.itemsPurchase[index].allStatus,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                          RichText(
                            text: TextSpan(
                                text: 'Items: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: widget.itemsPurchase[index].items
                                          .toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                                text: 'Importe: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: NumberFormat.currency(
                                              locale: 'es_ES',
                                              symbol: '€',
                                              decimalDigits: 2)
                                          .format(double.parse((widget
                                                      .itemsPurchase[index]
                                                      .totalBeforeDiscountWithoutTax /
                                                  MULTIPLYING_FACTOR)
                                              .toString())),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                          RichText(
                            text: TextSpan(
                                text: 'Modificación: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: widget.itemsPurchase[index]
                                                      .discountAmount /
                                                  MULTIPLYING_FACTOR >
                                              0
                                          ? '+${NumberFormat.currency(locale: 'es_ES', symbol: '€', decimalDigits: 2).format(double.parse((widget.itemsPurchase[index].discountAmount / MULTIPLYING_FACTOR).toString()))}'
                                          : NumberFormat.currency(
                                                  locale: 'es_ES',
                                                  symbol: '€',
                                                  decimalDigits: 2)
                                              .format(double.parse((widget
                                                          .itemsPurchase[index]
                                                          .discountAmount /
                                                      MULTIPLYING_FACTOR)
                                                  .toString())),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                          RichText(
                            text: TextSpan(
                                text: 'Subtotal: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: NumberFormat.currency(
                                              locale: 'es_ES',
                                              symbol: '€',
                                              decimalDigits: 2)
                                          .format(double.parse((widget
                                                      .itemsPurchase[index]
                                                      .totalAfterDiscountWithoutTax /
                                                  MULTIPLYING_FACTOR)
                                              .toString())),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                          RichText(
                            text: TextSpan(
                                text: 'IVA: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: NumberFormat.currency(
                                              locale: 'es_ES',
                                              symbol: '€',
                                              decimalDigits: 2)
                                          .format(double.parse((widget
                                                      .itemsPurchase[index]
                                                      .taxAmount /
                                                  MULTIPLYING_FACTOR)
                                              .toString())),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                          RichText(
                            text: TextSpan(
                                text: 'Total: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: NumberFormat.currency(
                                              locale: 'es_ES',
                                              symbol: '€',
                                              decimalDigits: 2)
                                          .format(double.parse((widget
                                                      .itemsPurchase[index]
                                                      .totalAmount /
                                                  MULTIPLYING_FACTOR)
                                              .toString())),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: (widget.itemsPurchase[index].numStatus == 1 &&
                              widget.itemsPurchase[index]
                                  .possibleStatusToTransitionTo.isNotEmpty &&
                              widget
                                      .itemsPurchase[index]
                                      .possibleStatusToTransitionTo[0]
                                      .priority ==
                                  1 &&
                              widget.partnerId != DEFAULT_PARTNER_ID)
                          ? IconButton(
                              padding: const EdgeInsets.all(5.0),
                              icon: Image.asset(
                                'assets/images/logoPlay.png',
                                fit: BoxFit.scaleDown,
                              ),
                              onPressed: () async {
                                try {
                                  debugPrint('Estoy en el onPressed');
                                  _showPleaseWait(true);
                                  final Uri url = Uri.parse(
                                      '$SERVER_IP/purchaseStateTransition/${widget.itemsPurchase[index].orderId}/${widget.itemsPurchase[index].providerName}');
                                  final http.Response res = await http
                                      .put(url,
                                          headers: <String, String>{
                                            'Content-Type':
                                                'application/json; charset=UTF-8',
                                            //'Authorization': jwt
                                          },
                                          body: jsonEncode(<String, String>{
                                            'user_id': widget.userId.toString(),
                                            'next_state': widget
                                                .itemsPurchase[index]
                                                .possibleStatusToTransitionTo
                                                .elementAt(0)
                                                .destinationStateId, // Always exists at least the next state if this icon has appeared
                                          }))
                                      .timeout(TIMEOUT);
                                  if (res.statusCode == 200) {
                                    _showPleaseWait(false);
                                    debugPrint('The Rest API has responsed.');
                                    await widget.onChanged();
                                  } else {
                                    _showPleaseWait(false);
                                    if (!context.mounted) return;
                                    ShowSnackBar.showSnackBar(context,
                                        json.decode(res.body)['message'],
                                        error: true);
                                  }
                                } catch (e) {
                                  _showPleaseWait(false);
                                  if (!context.mounted) return;
                                  ShowSnackBar.showSnackBar(
                                      context, e.toString(),
                                      error: true);
                                }
                              },
                            )
                          : Container(
                              width: 20, height: 20, padding: EdgeInsets.zero),
                    ),
                    Expanded(
                      child: (widget.itemsPurchase[index].numStatus == 1 &&
                              widget.itemsPurchase[index]
                                  .possibleStatusToTransitionTo.isNotEmpty &&
                              widget.partnerId != DEFAULT_PARTNER_ID)
                          ? PopupMenuButton(
                              icon: const Icon(
                                Icons.more_horiz,
                                color: Colors.black,
                              ),
                              itemBuilder: (BuildContext context) => widget
                                  .itemsPurchase[index]
                                  .possibleStatusToTransitionTo
                                  .map((e) {
                                return PopupMenuItem(
                                  value: e,
                                  child: Center(
                                    child: Text(e.statusName),
                                  ),
                                );
                              }).toList(),
                              onSelected: (PurchaseStatus result) async {
                                try {
                                  debugPrint('Estoy en el onSelected');
                                  _showPleaseWait(true);
                                  final Uri url = Uri.parse(
                                      '$SERVER_IP/purchaseStateTransition/${widget.itemsPurchase[index].orderId}/${widget.itemsPurchase[index].providerName}');
                                  final http.Response res = await http
                                      .put(url,
                                          headers: <String, String>{
                                            'Content-Type':
                                                'application/json; charset=UTF-8',
                                            //'Authorization': jwt
                                          },
                                          body: jsonEncode(<String, String>{
                                            'user_id': widget.userId.toString(),
                                            'next_state':
                                                result.destinationStateId,
                                          }))
                                      .timeout(TIMEOUT);
                                  if (res.statusCode == 200) {
                                    _showPleaseWait(false);
                                    debugPrint('The Rest API has responsed.');
                                    await widget.onChanged();
                                  } else {
                                    _showPleaseWait(false);
                                    if (!context.mounted) return;
                                    ShowSnackBar.showSnackBar(context,
                                        json.decode(res.body)['message'],
                                        error: true);
                                  }
                                } catch (e) {
                                  _showPleaseWait(false);
                                  if (!context.mounted) return;
                                  ShowSnackBar.showSnackBar(
                                      context, e.toString(),
                                      error: true);
                                }
                              },
                            )
                          : Container(
                              padding: EdgeInsets.zero,
                              width: 20,
                              height: 20,
                            ),
                    )
                  ],
                ),
                onTap: () async {
                  debugPrint(
                      'El partenerId del usuario es: ${widget.partnerId}');
                  final bool purchaseDetailStateChanged = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PurchaseDetailView(
                              widget.userId,
                              widget.itemsPurchase[index],
                              widget.partnerId,
                              widget.userRole)));
                  if (purchaseDetailStateChanged) {
                    await widget.onChanged();
                  }
                },
              ));
        });
    return SafeArea(
        child: _pleaseWait
            ? Stack(
                key: const ObjectKey("stack"),
                alignment: AlignmentDirectional.center,
                children: [tmpBuilder, _pleaseWaitWidget],
              )
            : Stack(
                key: const ObjectKey("stack"),
                children: [tmpBuilder],
              ));
  }
}

class _LargeScreen extends StatefulWidget {
  final List<Purchase> itemsPurchase;
  final int userId;
  final int partnerId;
  final String userRole;
  final Future<void> Function() onChanged;
  const _LargeScreen(this.itemsPurchase, this.userId, this.partnerId,
      this.userRole, this.onChanged);

  @override
  _LargeScreenState createState() => _LargeScreenState();
}

class _LargeScreenState extends State<_LargeScreen> {
  bool _pleaseWait = false;
  final PleaseWaitWidget _pleaseWaitWidget =
      const PleaseWaitWidget(key: ObjectKey("pleaseWaitWidget"));

  void _showPleaseWait(bool b) {
    setState(() {
      _pleaseWait = b;
    });
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget tmpBuilder = ListView.builder(
        itemCount: widget.itemsPurchase.length,
        itemBuilder: (BuildContext context, int index) {
          return Card(
              elevation: 4.0,
              child: ListTile(
                leading: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('dd', 'es_ES')
                          .format(widget.itemsPurchase[index].orderDate),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      DateFormat('MMM', 'es_ES')
                          .format(widget.itemsPurchase[index].orderDate),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      DateFormat('yyyy', 'es_ES')
                          .format(widget.itemsPurchase[index].orderDate),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                title: Text(
                  widget.itemsPurchase[index].showName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                    fontFamily: 'SF Pro Display',
                    fontStyle: FontStyle.normal,
                    color: Colors.black,
                  ),
                ),
                subtitle: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                                text: 'Pedido: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: widget.itemsPurchase[index].orderId
                                          .toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                          RichText(
                            text: TextSpan(
                                text: 'Estado: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text:
                                          widget.itemsPurchase[index].allStatus,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                          RichText(
                            text: TextSpan(
                                text: 'Items: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: widget.itemsPurchase[index].items
                                          .toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                                text: 'Importe: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: NumberFormat.currency(
                                              locale: 'es_ES',
                                              symbol: '€',
                                              decimalDigits: 2)
                                          .format(double.parse((widget
                                                      .itemsPurchase[index]
                                                      .totalBeforeDiscountWithoutTax /
                                                  MULTIPLYING_FACTOR)
                                              .toString())),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                          RichText(
                            text: TextSpan(
                                text: 'Modificación: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: widget.itemsPurchase[index]
                                                      .discountAmount /
                                                  MULTIPLYING_FACTOR >
                                              0
                                          ? '+${NumberFormat.currency(locale: 'es_ES', symbol: '€', decimalDigits: 2).format(double.parse((widget.itemsPurchase[index].discountAmount / MULTIPLYING_FACTOR).toString()))}'
                                          : NumberFormat.currency(
                                                  locale: 'es_ES',
                                                  symbol: '€',
                                                  decimalDigits: 2)
                                              .format(double.parse((widget
                                                          .itemsPurchase[index]
                                                          .discountAmount /
                                                      MULTIPLYING_FACTOR)
                                                  .toString())),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                          RichText(
                            text: TextSpan(
                                text: 'Subtotal: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: NumberFormat.currency(
                                              locale: 'es_ES',
                                              symbol: '€',
                                              decimalDigits: 2)
                                          .format(double.parse((widget
                                                      .itemsPurchase[index]
                                                      .totalAfterDiscountWithoutTax /
                                                  MULTIPLYING_FACTOR)
                                              .toString())),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                          RichText(
                            text: TextSpan(
                                text: 'IVA: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: NumberFormat.currency(
                                              locale: 'es_ES',
                                              symbol: '€',
                                              decimalDigits: 2)
                                          .format(double.parse((widget
                                                      .itemsPurchase[index]
                                                      .taxAmount /
                                                  MULTIPLYING_FACTOR)
                                              .toString())),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                          RichText(
                            text: TextSpan(
                                text: 'Total: ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: NumberFormat.currency(
                                              locale: 'es_ES',
                                              symbol: '€',
                                              decimalDigits: 2)
                                          .format(double.parse((widget
                                                      .itemsPurchase[index]
                                                      .totalAmount /
                                                  MULTIPLYING_FACTOR)
                                              .toString())),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: (widget.itemsPurchase[index].numStatus == 1 &&
                              widget.itemsPurchase[index]
                                  .possibleStatusToTransitionTo.isNotEmpty &&
                              widget
                                      .itemsPurchase[index]
                                      .possibleStatusToTransitionTo[0]
                                      .priority ==
                                  1 &&
                              widget.partnerId != DEFAULT_PARTNER_ID)
                          ? IconButton(
                              padding: const EdgeInsets.all(5.0),
                              icon: Image.asset(
                                'assets/images/logoPlay.png',
                                fit: BoxFit.scaleDown,
                              ),
                              onPressed: () async {
                                try {
                                  debugPrint('Estoy en el onPressed');
                                  _showPleaseWait(true);
                                  final Uri url = Uri.parse(
                                      '$SERVER_IP/purchaseStateTransition/${widget.itemsPurchase[index].orderId}/${widget.itemsPurchase[index].providerName}');
                                  final http.Response res = await http
                                      .put(url,
                                          headers: <String, String>{
                                            'Content-Type':
                                                'application/json; charset=UTF-8',
                                            //'Authorization': jwt
                                          },
                                          body: jsonEncode(<String, String>{
                                            'user_id': widget.userId.toString(),
                                            'next_state': widget
                                                .itemsPurchase[index]
                                                .possibleStatusToTransitionTo
                                                .elementAt(0)
                                                .destinationStateId, // Always exists at least the next state if this icon has appeared
                                          }))
                                      .timeout(TIMEOUT);
                                  if (res.statusCode == 200) {
                                    _showPleaseWait(false);
                                    debugPrint('The Rest API has responsed.');
                                    await widget.onChanged();
                                  } else {
                                    _showPleaseWait(false);
                                    if (!context.mounted) return;
                                    ShowSnackBar.showSnackBar(context,
                                        json.decode(res.body)['message'],
                                        error: true);
                                  }
                                } catch (e) {
                                  _showPleaseWait(false);
                                  if (!context.mounted) return;
                                  ShowSnackBar.showSnackBar(
                                      context, e.toString(),
                                      error: true);
                                }
                              },
                            )
                          : Container(
                              width: 20, height: 20, padding: EdgeInsets.zero),
                    ),
                    Expanded(
                      child: (widget.itemsPurchase[index].numStatus == 1 &&
                              widget.itemsPurchase[index]
                                  .possibleStatusToTransitionTo.isNotEmpty &&
                              widget.partnerId != DEFAULT_PARTNER_ID)
                          ? PopupMenuButton(
                              icon: const Icon(
                                Icons.more_horiz,
                                color: Colors.black,
                              ),
                              itemBuilder: (BuildContext context) => widget
                                  .itemsPurchase[index]
                                  .possibleStatusToTransitionTo
                                  .map((e) {
                                return PopupMenuItem(
                                  value: e,
                                  child: Center(
                                    child: Text(e.statusName),
                                  ),
                                );
                              }).toList(),
                              onSelected: (PurchaseStatus result) async {
                                try {
                                  debugPrint('Estoy en el onSelected');
                                  _showPleaseWait(true);
                                  final Uri url = Uri.parse(
                                      '$SERVER_IP/purchaseStateTransition/${widget.itemsPurchase[index].orderId}/${widget.itemsPurchase[index].providerName}');
                                  final http.Response res = await http
                                      .put(url,
                                          headers: <String, String>{
                                            'Content-Type':
                                                'application/json; charset=UTF-8',
                                            //'Authorization': jwt
                                          },
                                          body: jsonEncode(<String, String>{
                                            'user_id': widget.userId.toString(),
                                            'next_state':
                                                result.destinationStateId,
                                          }))
                                      .timeout(TIMEOUT);
                                  if (res.statusCode == 200) {
                                    _showPleaseWait(false);
                                    debugPrint('The Rest API has responsed.');
                                    await widget.onChanged();
                                  } else {
                                    _showPleaseWait(false);
                                    if (!context.mounted) return;
                                    ShowSnackBar.showSnackBar(context,
                                        json.decode(res.body)['message'],
                                        error: true);
                                  }
                                } catch (e) {
                                  _showPleaseWait(false);
                                  if (!context.mounted) return;
                                  ShowSnackBar.showSnackBar(
                                      context, e.toString(),
                                      error: true);
                                }
                              },
                            )
                          : Container(
                              padding: EdgeInsets.zero,
                              width: 20,
                              height: 20,
                            ),
                    )
                  ],
                ),
                onTap: () async {
                  debugPrint(
                      'El partenerId del usuario es: ${widget.partnerId}');
                  final bool purchaseDetailStateChanged = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PurchaseDetailView(
                              widget.userId,
                              widget.itemsPurchase[index],
                              widget.partnerId,
                              widget.userRole)));
                  if (purchaseDetailStateChanged) {
                    await widget.onChanged();
                  }
                },
              ));
        });
    return SafeArea(
        child: _pleaseWait
            ? Stack(
                key: const ObjectKey("stack"),
                alignment: AlignmentDirectional.center,
                children: [tmpBuilder, _pleaseWaitWidget],
              )
            : Stack(
                key: const ObjectKey("stack"),
                children: [tmpBuilder],
              ));
  }
}
