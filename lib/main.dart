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
  final TextEditingController _searchController = TextEditingController();

  final FirebaseService _firebaseService = FirebaseService();

  bool _showLowStockOnly = false;
  static const double LOW_STOCK_THRESHOLD = 10.0;

  @override
  void dispose() {
    _itemNumberController.dispose();
    _itemNameController.dispose();
    _itemStockController.dispose();
    _itemTypeController.dispose();
    _searchController.dispose();
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
      appBar: AppBar(
        title: const Text('Inventory Management'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, type, or ID#...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showLowStockOnly = !_showLowStockOnly;
                          });
                        },
                        icon: Icon(_showLowStockOnly
                            ? Icons.warning
                            : Icons.warning_outlined),
                        label: Text(_showLowStockOnly
                            ? 'Low Stock'
                            : 'Show All'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _showLowStockOnly
                              ? Colors.orange
                              : Colors.grey[300],
                          foregroundColor: _showLowStockOnly
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Items List
          Expanded(
            child: StreamBuilder<List<Item>>(
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

                // Apply filters
                var items = snapshot.data!;

                // Apply search filter
                if (_searchController.text.isNotEmpty) {
                  final query = _searchController.text.toLowerCase();
                  items = items
                      .where((item) =>
                          item.itemName.toLowerCase().contains(query) ||
                          item.itemType.toLowerCase().contains(query) ||
                          item.itemNumber.toString().contains(query))
                      .toList();
                }

                // Apply low stock filter
                if (_showLowStockOnly) {
                  items = items
                      .where((item) =>
                          _firebaseService.isLowStock(item))
                      .toList();
                }

                if (items.isEmpty) {
                  return Center(
                    child: Text(_showLowStockOnly
                        ? 'No low stock items'
                        : 'No items found for your search'),
                  );
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isLow = _firebaseService.isLowStock(item);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      color: isLow ? Colors.orange[50] : null,
                      child: ListTile(
                        leading: isLow
                            ? Tooltip(
                                message: 'Low Stock Alert',
                                child: Icon(Icons.warning_amber_rounded,
                                    color: Colors.orange[700]),
                              )
                            : null,
                        title: Text(
                          item.itemName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isLow ? Colors.orange[900] : null,
                          ),
                        ),
                        subtitle: Text(
                          'ID: ${item.itemNumber.toInt()} | Stock: ${item.itemStock.toInt()} | Type: ${item.itemType}',
                          style: TextStyle(
                            color: isLow ? Colors.orange[700] : null,
                          ),
                        ),
                        trailing: SizedBox(
                          width: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrUpdate(),
        child: const Icon(Icons.add),
      ),
    );
  }
}