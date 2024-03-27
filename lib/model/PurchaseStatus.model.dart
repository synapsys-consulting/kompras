class PurchaseStatus {
  PurchaseStatus ({
    required this.destinationStateId,
    required this.statusName,
    required this.banPrice,
    required this.banQuantity,
    required this.priority,
    required this.roleName
  });
  final String destinationStateId;
  final String statusName;
  final String banPrice;
  final String banQuantity;
  final int priority;
  final String roleName;
  factory PurchaseStatus.fromJson (Map<String, dynamic> json) {
    return PurchaseStatus (
        destinationStateId: json['DESTINATION_STATUS_ID'],
        statusName: json['STATUS_NAME'],
        banPrice: json['BAN_PRICE'],
        banQuantity: json['BAN_QUANTITY'],
        priority: int.parse(json['PRIORITY'].toString()),
        roleName: json['ROLE_NAME']
    );
  }
}