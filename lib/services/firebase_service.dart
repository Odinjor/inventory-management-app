import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'items';

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
        .where('itemType', isEqualTo: itemType)
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
          .update({'itemStock': newStock});
    } catch (e) {
      throw Exception('Failed to update item stock: $e');
    }
  }

  /// Stream of items with low stock (less than specified threshold)
  Stream<List<Item>> getLowStockItemsStream(double threshold) {
    return _firestore
        .collection(_collectionName)
        .where('itemStock', isLessThan: threshold)
        .snapshots()
        .map((QuerySnapshot querySnapshot) {
      return querySnapshot.docs
          .map((doc) => Item.fromFirestore(doc))
          .toList();
    });
  }
}
