import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String? id;
  final double itemNumber;
  final String itemName;
  final double itemStock;
  final String itemType;

  Item({
    this.id,
    required this.itemNumber,
    required this.itemName,
    required this.itemStock,
    required this.itemType,
  });

  /// Convert Item to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'itemNumber': itemNumber,
      'itemName': itemName,
      'itemStock': itemStock,
      'itemType': itemType,
    };
  }

  /// Convert Firestore document to Item
  factory Item.fromJson(Map<String, dynamic> json, String documentId) {
    return Item(
      id: documentId,
      itemNumber: (json['itemNumber'] ?? 0).toDouble(),
      itemName: json['itemName'] ?? '',
      itemStock: (json['itemStock'] ?? 0).toDouble(),
      itemType: json['itemType'] ?? '',
    );
  }

  /// Convert DocumentSnapshot to Item
  factory Item.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Item.fromJson(data, doc.id);
  }

  @override
  String toString() =>
      'Item(id: $id, itemNumber: $itemNumber, itemName: $itemName, itemStock: $itemStock, itemType: $itemType)';
}
