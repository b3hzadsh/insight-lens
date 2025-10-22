import 'package:flutter/material.dart';

import '../class/product.dart';

class EditScreen extends StatefulWidget {
  final List<Product> items;

  const EditScreen({super.key, required this.items});

  @override
  _EditScreenState createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late List<String> editableItems;
  final TextEditingController titleTextController = TextEditingController();
  final TextEditingController descTextController = TextEditingController();
  final TextEditingController imageUrlTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    editableItems = List.from(widget.items); // Copy the list for editing
  }

  void _addItem() {
    editableItems.add('Item ${editableItems.length + 1}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () =>
                Navigator.pop(context, editableItems), // Return list
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(hintText: 'عنوان'),
                  controller: titleTextController,
                ),
                const SizedBox(
                  height: 5,
                ),
                TextField(
                  controller: descTextController,
                  decoration: const InputDecoration(hintText: 'توضیحات'),
                ),
                const SizedBox(
                  height: 5,
                ),
                TextField(
                  controller: imageUrlTextController,
                  decoration: const InputDecoration(hintText: 'ادرس عکس'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _addItem,
              child: const Text('Add Item'),
            ),
          ),
        ],
      ),
    );
  }
}
