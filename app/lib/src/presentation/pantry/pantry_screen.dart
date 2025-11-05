/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/pantry.dart';
import '../providers/pantry_provider.dart';

class PantryScreen extends HookConsumerWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = useState<String?>(null);

    final pantryAsync = selectedCategory.value == null
        ? ref.watch(pantryItemsProvider)
        : ref.watch(pantryItemsByCategoryProvider(selectedCategory.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantry'),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              selectedCategory.value = value;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Categories'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'Grains',
                child: Text('Grains'),
              ),
              const PopupMenuItem(
                value: 'Vegetables',
                child: Text('Vegetables'),
              ),
              const PopupMenuItem(
                value: 'Fruits',
                child: Text('Fruits'),
              ),
              const PopupMenuItem(
                value: 'Dairy',
                child: Text('Dairy'),
              ),
              const PopupMenuItem(
                value: 'Meat',
                child: Text('Meat'),
              ),
              const PopupMenuItem(
                value: 'Spices',
                child: Text('Spices'),
              ),
              const PopupMenuItem(
                value: 'Other',
                child: Text('Other'),
              ),
            ],
          ),
        ],
      ),
      body: pantryAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.kitchen_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    selectedCategory.value == null
                        ? 'Pantry is empty'
                        : 'No items in this category',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add items',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          // Check for items expiring soon (within 7 days)
          final now = DateTime.now();
          final expiringSoon = items.where((item) {
            if (item.expiryDate == null) return false;
            final daysUntilExpiry =
                item.expiryDate!.difference(now).inDays;
            return daysUntilExpiry >= 0 && daysUntilExpiry <= 7;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (expiringSoon.isNotEmpty && selectedCategory.value == null) ...[
                Card(
                  color: Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${expiringSoon.length} item(s) expiring soon',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (selectedCategory.value != null) ...[
                Chip(
                  label: Text(selectedCategory.value!),
                  onDeleted: () => selectedCategory.value = null,
                  deleteIcon: const Icon(Icons.close, size: 18),
                ),
                const SizedBox(height: 16),
              ],
              ...items.map((item) => _PantryItemCard(
                    item: item,
                    onDelete: () => _deleteItem(context, ref, item.id),
                  )),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading pantry',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(pantryItemsProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  Future<void> _deleteItem(
    BuildContext context,
    WidgetRef ref,
    String itemId,
  ) async {
    final repository = ref.read(pantryRepositoryProvider);
    final result = await repository.deletePantryItem(itemId);

    result.fold(
      (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (_) {
        if (context.mounted) {
          ref.invalidate(pantryItemsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted')),
          );
        }
      },
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final unitController = TextEditingController();
    final categoryController = TextEditingController();
    final locationController = TextEditingController();
    final notesController = TextEditingController();
    final barcodeController = TextEditingController();
    DateTime? purchaseDate;
    DateTime? expiryDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Pantry Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name *',
                    hintText: 'e.g., Rice',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          hintText: 'kg',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    hintText: 'e.g., Grains',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'e.g., Shelf 1',
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Purchase Date'),
                  subtitle: Text(
                    purchaseDate?.toString().split(' ')[0] ?? 'Not set',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => purchaseDate = date);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Expiry Date'),
                  subtitle: Text(
                    expiryDate?.toString().split(' ')[0] ?? 'Not set',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() => expiryDate = date);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item name is required')),
                  );
                  return;
                }

                Navigator.pop(context);

                final item = PantryItemCreate(
                  name: nameController.text,
                  quantity: double.tryParse(quantityController.text) ?? 1,
                  unit: unitController.text,
                  category: categoryController.text,
                  location: locationController.text,
                  purchaseDate: purchaseDate,
                  expiryDate: expiryDate,
                  notes: notesController.text,
                  barcode: barcodeController.text,
                );

                final repository = ref.read(pantryRepositoryProvider);
                final result = await repository.createPantryItem(item);

                result.fold(
                  (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  (_) {
                    if (context.mounted) {
                      ref.invalidate(pantryItemsProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Item added')),
                      );
                    }
                  },
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PantryItemCard extends StatelessWidget {
  final PantryItem item;
  final VoidCallback onDelete;

  const _PantryItemCard({
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isExpiringSoon = item.expiryDate != null &&
        item.expiryDate!.difference(now).inDays <= 7 &&
        item.expiryDate!.isAfter(now);
    final isExpired =
        item.expiryDate != null && item.expiryDate!.isBefore(now);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isExpired
          ? Colors.red[50]
          : isExpiringSoon
              ? Colors.orange[50]
              : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isExpired
              ? Colors.red
              : isExpiringSoon
                  ? Colors.orange
                  : Theme.of(context).colorScheme.primary,
          child: Icon(
            _getCategoryIcon(item.category),
            color: Colors.white,
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item.quantity} ${item.unit}'),
            if (item.location.isNotEmpty)
              Text(
                'Location: ${item.location}',
                style: const TextStyle(fontSize: 12),
              ),
            if (item.expiryDate != null)
              Text(
                isExpired
                    ? 'Expired ${_formatDate(item.expiryDate!)}'
                    : 'Expires ${_formatDate(item.expiryDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isExpired ? Colors.red : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (item.category.isNotEmpty)
              Chip(
                label: Text(item.category),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Item'),
                content: Text('Delete "${item.name}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              onDelete();
            }
          },
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'grains':
        return Icons.grain;
      case 'vegetables':
        return Icons.eco;
      case 'fruits':
        return Icons.apple;
      case 'dairy':
        return Icons.water_drop;
      case 'meat':
        return Icons.food_bank;
      case 'spices':
        return Icons.spa;
      default:
        return Icons.inventory_2;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) return 'today';
    if (difference == 1) return 'tomorrow';
    if (difference == -1) return 'yesterday';
    if (difference < 0) return '${-difference} days ago';
    return 'in $difference days';
  }
}
