/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/recipe.dart';
import '../providers/recipe_provider.dart';

class RecipeFormScreen extends HookConsumerWidget {
  final String? recipeId;
  final Recipe? recipe;

  const RecipeFormScreen({
    super.key,
    this.recipeId,
    this.recipe,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);

    // Basic fields
    final titleController = useTextEditingController(text: recipe?.title ?? '');
    final descriptionController =
        useTextEditingController(text: recipe?.description ?? '');
    final instructionsController =
        useTextEditingController(text: recipe?.instructions ?? '');
    final prepTimeController = useTextEditingController(
      text: recipe?.prepTime.toString() ?? '0',
    );
    final cookTimeController = useTextEditingController(
      text: recipe?.cookTime.toString() ?? '0',
    );
    final servingsController = useTextEditingController(
      text: recipe?.servings.toString() ?? '4',
    );
    final sourceController = useTextEditingController(text: recipe?.source ?? '');
    final sourceUrlController =
        useTextEditingController(text: recipe?.sourceUrl ?? '');

    // Difficulty selection
    final difficulty = useState(recipe?.difficulty ?? 'Medium');

    // Categories and tags
    final categories = useState<List<String>>(recipe?.categories ?? []);
    final tags = useState<List<String>>(recipe?.tags ?? []);

    // Ingredients
    final ingredients = useState<List<_IngredientFormData>>(
      recipe?.ingredients
              .map((i) => _IngredientFormData(
                    name: i.name,
                    quantity: i.quantity,
                    unit: i.unit,
                    notes: i.notes,
                    optional: i.optional,
                  ))
              .toList() ??
          [],
    );

    // Image
    final selectedImage = useState<File?>(null);

    final isEditMode = recipe != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Recipe' : 'Create Recipe'),
        actions: [
          TextButton(
            onPressed: isLoading.value
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    if (ingredients.value.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please add at least one ingredient'),
                        ),
                      );
                      return;
                    }

                    isLoading.value = true;

                    try {
                      final recipeCreate = RecipeCreate(
                        title: titleController.text,
                        description: descriptionController.text,
                        instructions: instructionsController.text,
                        prepTime: int.parse(prepTimeController.text),
                        cookTime: int.parse(cookTimeController.text),
                        servings: int.parse(servingsController.text),
                        difficulty: difficulty.value,
                        categories: categories.value,
                        tags: tags.value,
                        ingredients: ingredients.value
                            .asMap()
                            .entries
                            .map(
                              (entry) => IngredientCreate(
                                name: entry.value.name,
                                quantity: entry.value.quantity,
                                unit: entry.value.unit,
                                notes: entry.value.notes,
                                optional: entry.value.optional,
                                order: entry.key,
                              ),
                            )
                            .toList(),
                        source: sourceController.text.isEmpty
                            ? null
                            : sourceController.text,
                        sourceUrl: sourceUrlController.text.isEmpty
                            ? null
                            : sourceUrlController.text,
                      );

                      final repository = ref.read(recipeRepositoryProvider);
                      final result = isEditMode
                          ? await repository.updateRecipe(
                              recipeId!,
                              recipeCreate,
                            )
                          : await repository.createRecipe(recipeCreate);

                      await result.fold(
                        (error) async {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $error'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        (savedRecipe) async {
                          // Upload image if selected
                          if (selectedImage.value != null) {
                            await repository.uploadImage(
                              savedRecipe.id,
                              selectedImage.value!,
                            );
                          }

                          if (context.mounted) {
                            ref.invalidate(recipesProvider);
                            if (isEditMode) {
                              ref.invalidate(recipeProvider(recipeId!));
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditMode
                                      ? 'Recipe updated!'
                                      : 'Recipe created!',
                                ),
                              ),
                            );

                            context.go('/recipes/${savedRecipe.id}');
                          }
                        },
                      );
                    } finally {
                      isLoading.value = false;
                    }
                  },
            child: isLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('SAVE'),
          ),
        ],
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image selection
            _buildImagePicker(context, selectedImage, recipe),
            const SizedBox(height: 24),

            // Basic info
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'Enter recipe title',
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Brief description of the recipe',
              ),
              maxLines: 3,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Time and servings
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: prepTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Prep Time (min) *',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (int.tryParse(value!) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: cookTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Cook Time (min) *',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (int.tryParse(value!) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: servingsController,
                    decoration: const InputDecoration(
                      labelText: 'Servings *',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (int.tryParse(value!) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: difficulty.value,
                    decoration: const InputDecoration(
                      labelText: 'Difficulty *',
                    ),
                    items: ['Easy', 'Medium', 'Hard']
                        .map((level) => DropdownMenuItem(
                              value: level,
                              child: Text(level),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) difficulty.value = value;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Ingredients
            _buildIngredientsSection(context, ingredients),
            const SizedBox(height: 24),

            // Instructions
            Text(
              'Instructions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: instructionsController,
              decoration: const InputDecoration(
                labelText: 'Instructions *',
                hintText: 'Enter each step on a new line',
                alignLabelWithHint: true,
              ),
              maxLines: 10,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 24),

            // Categories
            _buildCategoriesSection(context, categories),
            const SizedBox(height: 24),

            // Tags
            _buildTagsSection(context, tags),
            const SizedBox(height: 24),

            // Source
            Text(
              'Source (Optional)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: sourceController,
              decoration: const InputDecoration(
                labelText: 'Source',
                hintText: 'E.g., Grandma\'s cookbook',
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: sourceUrlController,
              decoration: const InputDecoration(
                labelText: 'Source URL',
                hintText: 'https://example.com/recipe',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(
    BuildContext context,
    ValueNotifier<File?> selectedImage,
    Recipe? recipe,
  ) {
    return GestureDetector(
      onTap: () async {
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          selectedImage.value = File(image.path);
        }
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: selectedImage.value != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  selectedImage.value!,
                  fit: BoxFit.cover,
                ),
              )
            : recipe?.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      recipe!.imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add image',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildIngredientsSection(
    BuildContext context,
    ValueNotifier<List<_IngredientFormData>> ingredients,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ingredients',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton.icon(
              onPressed: () {
                ingredients.value = [
                  ...ingredients.value,
                  _IngredientFormData(
                    name: '',
                    quantity: 0,
                    unit: '',
                    optional: false,
                  ),
                ];
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (ingredients.value.isEmpty)
          Center(
            child: Text(
              'No ingredients added yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
        else
          ...ingredients.value.asMap().entries.map((entry) {
            final index = entry.key;
            final ingredient = entry.value;
            return _IngredientFormField(
              ingredient: ingredient,
              onDelete: () {
                ingredients.value = ingredients.value
                    .where((i) => i != ingredient)
                    .toList();
              },
              onChanged: () {
                // Trigger rebuild
                ingredients.value = [...ingredients.value];
              },
            );
          }),
      ],
    );
  }

  Widget _buildCategoriesSection(
    BuildContext context,
    ValueNotifier<List<String>> categories,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Categories',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton.icon(
              onPressed: () {
                _showAddDialog(
                  context,
                  'Add Category',
                  'Category name',
                  (value) {
                    if (!categories.value.contains(value)) {
                      categories.value = [...categories.value, value];
                    }
                  },
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (categories.value.isEmpty)
          Text(
            'No categories added',
            style: TextStyle(color: Colors.grey[600]),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.value.map((category) {
              return Chip(
                label: Text(category),
                onDeleted: () {
                  categories.value = categories.value
                      .where((c) => c != category)
                      .toList();
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildTagsSection(
    BuildContext context,
    ValueNotifier<List<String>> tags,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tags',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton.icon(
              onPressed: () {
                _showAddDialog(
                  context,
                  'Add Tag',
                  'Tag name',
                  (value) {
                    if (!tags.value.contains(value)) {
                      tags.value = [...tags.value, value];
                    }
                  },
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (tags.value.isEmpty)
          Text(
            'No tags added',
            style: TextStyle(color: Colors.grey[600]),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.value.map((tag) {
              return Chip(
                label: Text(tag),
                onDeleted: () {
                  tags.value = tags.value.where((t) => t != tag).toList();
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  void _showAddDialog(
    BuildContext context,
    String title,
    String hint,
    Function(String) onAdd,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onAdd(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _IngredientFormData {
  String name;
  double quantity;
  String unit;
  String? notes;
  bool optional;

  _IngredientFormData({
    required this.name,
    required this.quantity,
    required this.unit,
    this.notes,
    required this.optional,
  });
}

class _IngredientFormField extends HookWidget {
  final _IngredientFormData ingredient;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _IngredientFormField({
    required this.ingredient,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController(text: ingredient.name);
    final quantityController = useTextEditingController(
      text: ingredient.quantity == 0 ? '' : ingredient.quantity.toString(),
    );
    final unitController = useTextEditingController(text: ingredient.unit);
    final notesController = useTextEditingController(text: ingredient.notes);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Ingredient',
                      isDense: true,
                    ),
                    onChanged: (value) {
                      ingredient.name = value;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      ingredient.quantity = double.tryParse(value) ?? 0;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      isDense: true,
                    ),
                    onChanged: (value) {
                      ingredient.unit = value;
                      onChanged();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                isDense: true,
              ),
              onChanged: (value) {
                ingredient.notes = value.isEmpty ? null : value;
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: ingredient.optional,
                  onChanged: (value) {
                    ingredient.optional = value ?? false;
                    onChanged();
                  },
                ),
                const Text('Optional ingredient'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
