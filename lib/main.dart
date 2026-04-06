import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/item.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Product Manager',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _itemNumberController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemStockController = TextEditingController();
  final TextEditingController _itemTypeController = TextEditingController();

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void dispose() {
    _itemNumberController.dispose();
    _itemNameController.dispose();
    _itemStockController.dispose();
    _itemTypeController.dispose();
    super.dispose();
  }

  Future<void> _createOrUpdate([Item? item]) async {
    String action = 'Create';
    if (item != null) {
      action = 'Update';
      _itemNumberController.text = item.itemNumber.toString();
      _itemNameController.text = item.itemName;
      _itemStockController.text = item.itemStock.toString();
      _itemTypeController.text = item.itemType;
    } else {
      // Auto-generate next item number for new items
      try {
        final nextNumber = await _firebaseService.getNextItemNumber();
        _itemNumberController.text = nextNumber.toString();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        return;
      }
    }

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20, left: 20, right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _itemNumberController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                enabled: action == 'Update',
                decoration: InputDecoration(
                  labelText: 'Item #',
                  helperText: action == 'Create' ? 'Auto-generated' : '',
                ),
              ),
              TextField(
                controller: _itemNameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
              ),
              TextField(
                controller: _itemStockController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Item Stock'),
              ),
              TextField(
                controller: _itemTypeController,
                decoration: const InputDecoration(labelText: 'Item Type'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  try {
                    double itemNumber = double.parse(_itemNumberController.text);
                    String itemName = _itemNameController.text;
                    double itemStock = double.parse(_itemStockController.text);
                    String itemType = _itemTypeController.text;

                    if (itemName.isNotEmpty && itemType.isNotEmpty) {
                      if (action == 'Create') {
                        Item newItem = Item(
                          itemNumber: itemNumber,
                          itemName: itemName,
                          itemStock: itemStock,
                          itemType: itemType,
                        );
                        await _firebaseService.createItem(newItem).first;
                      } else if (item != null) {
                        Item updatedItem = Item(
                          id: item.id,
                          itemNumber: itemNumber,
                          itemName: itemName,
                          itemStock: itemStock,
                          itemType: itemType,
                        );
                        await _firebaseService.updateItem(updatedItem);
                      }

                      _itemNumberController.text = '';
                      _itemNameController.text = '';
                      _itemStockController.text = '';
                      _itemTypeController.text = '';
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all fields'),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: Text(action),
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      await _firebaseService.deleteItem(itemId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Management')),
      body: StreamBuilder<List<Item>>(
        stream: _firebaseService.getItemsStream(),
        builder: (context, AsyncSnapshot<List<Item>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No items found'));
          }

          final items = snapshot.data!;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(item.itemName),
                  subtitle: Text(
                    'ID: ${item.itemNumber} | Stock: ${item.itemStock} | Type: ${item.itemType}',
                  ),
                  trailing: SizedBox(
                    width: 100,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _createOrUpdate(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteItem(item.id!),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrUpdate(),
        child: const Icon(Icons.add),
      ),
    );
  }
}