import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'Items';

  /// Stream that returns a list of typed Items
  Stream<List<Item>> getItemsStream() {
    return _firestore
        .collection(_collectionName)
        .snapshots()
        .map((QuerySnapshot querySnapshot) {
      return querySnapshot.docs
          .map((doc) => Item.fromFirestore(doc))
          .toList();
    });
  }

  /// Stream that returns a specific Item by ID
  Stream<Item?> getItemStream(String itemId) {
    return _firestore
        .collection(_collectionName)
        .doc(itemId)
        .snapshots()
        .map((DocumentSnapshot doc) {
      if (doc.exists) {
        return Item.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Stream that returns Items filtered by itemType
  Stream<List<Item>> getItemsByTypeStream(String itemType) {
    return _firestore
        .collection(_collectionName)
        .where('ItemType', isEqualTo: itemType)
        .snapshots()
        .map((QuerySnapshot querySnapshot) {
      return querySnapshot.docs
          .map((doc) => Item.fromFirestore(doc))
          .toList();
    });
  }

  /// Get the next auto-incremented item number
  Future<double> getNextItemNumber() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection(_collectionName).get();
      if (snapshot.docs.isEmpty) {
        return 1.0;
      }
      double maxNumber = 0;
      for (var doc in snapshot.docs) {
        final item = Item.fromFirestore(doc);
        if (item.itemNumber > maxNumber) {
          maxNumber = item.itemNumber;
        }
      }
      return maxNumber + 1;
    } catch (e) {
      throw Exception('Failed to get next item number: $e');
    }
  }

  /// Create a new Item and return its stream
  Stream<Item?> createItem(Item item) async* {
    try {
      final docRef = await _firestore
          .collection(_collectionName)
          .add(item.toJson());

      // Return a stream of the newly created item
      yield* _firestore
          .collection(_collectionName)
          .doc(docRef.id)
          .snapshots()
          .map((doc) {
        if (doc.exists) {
          return Item.fromFirestore(doc);
        }
        return null;
      });
    } catch (e) {
      throw Exception('Failed to create item: $e');
    }
  }

  /// Update an existing Item
  Future<void> updateItem(Item item) async {
    if (item.id == null) {
      throw Exception('Item ID cannot be null for update operation');
    }
    try {
      await _firestore
          .collection(_collectionName)
          .doc(item.id)
          .update(item.toJson());
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  /// Delete an Item by ID
  Future<void> deleteItem(String itemId) async {
    try {
      await _firestore.collection(_collectionName).doc(itemId).delete();
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  /// Update item stock only
  Future<void> updateItemStock(String itemId, double newStock) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(itemId)
          .update({'ItemStock': newStock});
    } catch (e) {
      throw Exception('Failed to update item stock: $e');
    }
  }

  /// Stream of items with low stock (less than specified threshold)
  Stream<List<Item>> getLowStockItemsStream(double threshold) {
    return _firestore
        .collection(_collectionName)
        .where('ItemStock', isLessThan: threshold)
        .snapshots()
        .map((QuerySnapshot querySnapshot) {
      return querySnapshot.docs
          .map((doc) => Item.fromFirestore(doc))
          .toList();
    });
  }

  /// Search items by name or type - client-side filtering
  Stream<List<Item>> searchItemsStream(String query) {
    return getItemsStream().map((items) {
      if (query.isEmpty) {
        return items;
      }
      final lowerQuery = query.toLowerCase();
      return items
          .where((item) =>
              item.itemName.toLowerCase().contains(lowerQuery) ||
              item.itemType.toLowerCase().contains(lowerQuery) ||
              item.itemNumber.toString().contains(lowerQuery))
          .toList();
    });
  }

  /// Get sorted items by stock level (ascending)
  Stream<List<Item>> getItemsSortedByStock() {
    return getItemsStream().map((items) {
      final sorted = List<Item>.from(items);
      sorted.sort((a, b) => a.itemStock.compareTo(b.itemStock));
      return sorted;
    });
  }

  /// Check if item is low stock (below 10 units)
  bool isLowStock(Item item) {
    return item.itemStock < 10;
  }
}
