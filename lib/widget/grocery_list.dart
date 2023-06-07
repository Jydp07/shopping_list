import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widget/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  var _groceryItems = [];
  var _isLoading = true;
  String? _error;

  Future<void> _loaditems() async {
    final url = Uri.https(
        'grocerylist-f5ead-default-rtdb.firebaseio.com', 'shopping-list.json');
    try {
      final response = await http.get(url);
      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed fetch data.Please try again later';
        });
      }

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final Map<String, dynamic> groceryList = json.decode(response.body);
      final List<GroceryItem> loadedItem = [];
      for (final item in groceryList.entries) {
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;
        loadedItem.add(
          GroceryItem(
              id: item.key,
              name: item.value['name'],
              quantity: item.value['quantity'],
              category: category),
        );
      }
      setState(() {
        _groceryItems = loadedItem;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong!.Please try again later';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewItem()),
    );
    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void removeItem(GroceryItem groceryItem) async {
    final index = _groceryItems.indexOf(groceryItem);
    setState(() {
      _groceryItems.remove(groceryItem);
    });

    final url = Uri.https('grocerylist-f5ead-default-rtdb.firebaseio.com',
        'shopping-list/${groceryItem.id}.json');

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed To Delete'),
        ),
      );
      setState(() {
        _groceryItems.insert(index, groceryItem);
      });
    }
  }

  @override
  void initState() {
    _loaditems();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
        child: Text(
      'Add Some Grocery',
      style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 28),
    ));

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, index) => Dismissible(
            key: ValueKey(_groceryItems[index].id),
            background: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
              ),
              child: const Center(
                child: Icon(
                  Icons.delete,
                  size: 28,
                ),
              ),
            ),
            onDismissed: (direction) {
              removeItem(_groceryItems[index]);
            },
            child: ListTile(
              leading: Container(
                color: _groceryItems[index].category.color,
                height: 24,
                width: 24,
              ),
              title: Text(_groceryItems[index].name),
              trailing: Text(_groceryItems[index].quantity.toString()),
            )),
      );
    }
    if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Your Grocery',
          ),
          actions: [
            IconButton(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
            )
          ],
        ),
        body: content);
  }
}
