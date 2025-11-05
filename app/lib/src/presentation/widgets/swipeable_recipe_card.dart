/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/recipe.dart';

/// Swipeable recipe card with slide actions
class SwipeableRecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAddToMealPlan;
  final VoidCallback? onShare;

  const SwipeableRecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onAddToMealPlan,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(recipe.id),
      // Left-to-right swipe actions (primary)
      startActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          if (onEdit != null)
            SlidableAction(
              onPressed: (_) => onEdit!(),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
            ),
          if (onAddToMealPlan != null)
            SlidableAction(
              onPressed: (_) => onAddToMealPlan!(),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: Icons.calendar_today,
              label: 'Add to Plan',
            ),
        ],
      ),
      // Right-to-left swipe actions (secondary)
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        dismissible: onDelete != null
            ? DismissiblePane(
                onDismissed: () => onDelete!(),
                confirmDismiss: () async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Recipe'),
                          content: const Text(
                            'Are you sure you want to delete this recipe?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                },
              )
            : null,
        children: [
          if (onShare != null)
            SlidableAction(
              onPressed: (_) => onShare!(),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              icon: Icons.share,
              label: 'Share',
            ),
          if (onDelete != null)
            SlidableAction(
              onPressed: (_) => onDelete!(),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
        ],
      ),
      // The card content
      child: _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: SizedBox(
                width: 100,
                height: 100,
                child: recipe.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: recipe.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.restaurant, size: 40),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.restaurant, size: 40),
                      ),
              ),
            ),
            // Recipe details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.timer,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.prepTime + recipe.cookTime} min',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.people,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.servings} servings',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Swipeable shopping list item card
class SwipeableShoppingItemCard extends StatelessWidget {
  final String id;
  final String name;
  final bool completed;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const SwipeableShoppingItemCard({
    super.key,
    required this.id,
    required this.name,
    required this.completed,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        dismissible: DismissiblePane(
          onDismissed: onDelete,
        ),
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: Checkbox(
            value: completed,
            onChanged: (_) => onToggle(),
          ),
          title: Text(
            name,
            style: TextStyle(
              decoration: completed ? TextDecoration.lineThrough : null,
              color: completed
                  ? Theme.of(context).textTheme.bodySmall?.color
                  : null,
            ),
          ),
          onTap: onToggle,
        ),
      ),
    );
  }
}

/// Swipeable pantry item card
class SwipeablePantryItemCard extends StatelessWidget {
  final String id;
  final String name;
  final String quantity;
  final DateTime? expiryDate;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SwipeablePantryItemCard({
    super.key,
    required this.id,
    required this.name,
    required this.quantity,
    this.expiryDate,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = expiryDate != null && expiryDate!.isBefore(DateTime.now());
    final isExpiringSoon = expiryDate != null &&
        expiryDate!.isAfter(DateTime.now()) &&
        expiryDate!.isBefore(DateTime.now().add(const Duration(days: 7)));

    return Slidable(
      key: ValueKey(id),
      startActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        dismissible: DismissiblePane(
          onDismissed: onDelete,
          confirmDismiss: () async {
            return await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Item'),
                    content: const Text(
                      'Are you sure you want to delete this item?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ) ??
                false;
          },
        ),
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: isExpired
            ? Colors.red.withOpacity(0.1)
            : isExpiringSoon
                ? Colors.orange.withOpacity(0.1)
                : null,
        child: ListTile(
          leading: Icon(
            Icons.inventory_2,
            color: isExpired
                ? Colors.red
                : isExpiringSoon
                    ? Colors.orange
                    : Theme.of(context).colorScheme.primary,
          ),
          title: Text(name),
          subtitle: Text(quantity),
          trailing: expiryDate != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Expires:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${expiryDate!.month}/${expiryDate!.day}/${expiryDate!.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isExpired
                            ? Colors.red
                            : isExpiringSoon
                                ? Colors.orange
                                : null,
                        fontWeight: isExpired || isExpiringSoon
                            ? FontWeight.bold
                            : null,
                      ),
                    ),
                  ],
                )
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}
