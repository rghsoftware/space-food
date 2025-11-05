// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/food_variety_providers.dart';
import '../../data/models/food_chain_suggestion.dart';

class FoodChainingScreen extends ConsumerStatefulWidget {
  const FoodChainingScreen({super.key});

  @override
  ConsumerState<FoodChainingScreen> createState() => _FoodChainingScreenState();
}

class _FoodChainingScreenState extends ConsumerState<FoodChainingScreen> {
  final _foodNameController = TextEditingController();
  bool _isGenerating = false;

  @override
  void dispose() {
    _foodNameController.dispose();
    super.dispose();
  }

  Future<void> _generateSuggestions() async {
    final foodName = _foodNameController.text.trim();
    if (foodName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a food name')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // TODO: Get actual user ID
      const userId = 'current-user-id';

      await ref
          .read(chainSuggestionGeneratorProvider.notifier)
          .generateSuggestions(
            foodName: foodName,
            userId: userId,
            count: 5,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suggestions generated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Get actual user ID
    const userId = 'current-user-id';

    final suggestionsAsync = ref.watch(chainSuggestionGeneratorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Chaining'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info Card
          Card(
            color: Colors.blue[50],
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'What is Food Chaining?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Food chaining helps you gently expand your diet by suggesting '
                    'foods similar to ones you already enjoy. We match texture, '
                    'flavor, temperature, and complexity.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Input Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find Similar Foods',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _foodNameController,
                    decoration: const InputDecoration(
                      labelText: 'Food name',
                      hintText: 'e.g., Chicken nuggets',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _generateSuggestions(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateSuggestions,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: Text(_isGenerating
                          ? 'Generating...'
                          : 'Get Suggestions'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Suggestions List
          suggestionsAsync.when(
            data: (suggestions) {
              if (suggestions == null || suggestions.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Enter a food above to get suggestions',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suggestions for "${suggestions.first.currentFoodName}"',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...suggestions.map((suggestion) =>
                      _SuggestionCard(suggestion: suggestion)),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends ConsumerWidget {
  final FoodChainSuggestion suggestion;

  const _SuggestionCard({required this.suggestion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final similarityPercent = (suggestion.similarityScore * 100).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    suggestion.suggestedFoodName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSimilarityColor(suggestion.similarityScore),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$similarityPercent% similar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              suggestion.reasoning,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (!suggestion.wasTried)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _recordFeedback(
                          context, ref, suggestion.id, false),
                      icon: const Icon(Icons.thumb_down),
                      label: const Text('Not interested'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _recordFeedback(context, ref, suggestion.id, true),
                      icon: const Icon(Icons.thumb_up),
                      label: const Text('I\'ll try it!'),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Icon(
                    suggestion.wasLiked == true
                        ? Icons.thumb_up
                        : Icons.thumb_down,
                    color: suggestion.wasLiked == true
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    suggestion.wasLiked == true ? 'Liked' : 'Not interested',
                    style: TextStyle(
                      color: suggestion.wasLiked == true
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getSimilarityColor(double score) {
    if (score >= 0.9) return Colors.green;
    if (score >= 0.8) return Colors.lightGreen;
    if (score >= 0.7) return Colors.orange;
    return Colors.blue;
  }

  Future<void> _recordFeedback(
      BuildContext context, WidgetRef ref, String suggestionId, bool liked) async {
    try {
      await ref
          .read(chainFeedbackRecorderProvider.notifier)
          .recordFeedback(suggestionId: suggestionId, wasLiked: liked);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(liked
                ? 'Great! Let us know how it goes!'
                : 'Thanks for the feedback!'),
          ),
        );

        // Refresh the suggestions
        ref.invalidate(chainSuggestionGeneratorProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording feedback: $e')),
        );
      }
    }
  }
}
