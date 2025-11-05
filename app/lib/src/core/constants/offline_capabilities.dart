/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

/// Offline capability levels for features
enum OfflineCapability {
  /// Feature works fully offline with local data
  fullyOffline,

  /// Feature works offline with cached data, syncs when online
  offlineWithCache,

  /// Feature requires sync before working offline
  requiresSync,

  /// Feature requires active internet connection
  requiresOnline;

  /// Check if feature can work offline at all
  bool get canWorkOffline =>
      this == OfflineCapability.fullyOffline ||
      this == OfflineCapability.offlineWithCache ||
      this == OfflineCapability.requiresSync;

  /// Check if feature requires internet
  bool get requiresInternet => this == OfflineCapability.requiresOnline;

  /// Get user-friendly description
  String get description {
    switch (this) {
      case OfflineCapability.fullyOffline:
        return 'Works fully offline';
      case OfflineCapability.offlineWithCache:
        return 'Works offline with cached data';
      case OfflineCapability.requiresSync:
        return 'Requires initial sync';
      case OfflineCapability.requiresOnline:
        return 'Requires internet connection';
    }
  }
}

/// Feature offline capabilities matrix
class FeatureOfflineCapabilities {
  // Recipe features
  static const viewRecipes = OfflineCapability.offlineWithCache;
  static const createRecipe = OfflineCapability.requiresSync;
  static const editRecipe = OfflineCapability.requiresSync;
  static const deleteRecipe = OfflineCapability.requiresSync;
  static const importRecipe = OfflineCapability.requiresOnline;
  static const uploadRecipeImage = OfflineCapability.requiresSync;

  // Meal planning features
  static const viewMealPlans = OfflineCapability.offlineWithCache;
  static const createMealPlan = OfflineCapability.requiresSync;
  static const editMealPlan = OfflineCapability.requiresSync;
  static const deleteMealPlan = OfflineCapability.requiresSync;

  // Pantry features
  static const viewPantry = OfflineCapability.offlineWithCache;
  static const addPantryItem = OfflineCapability.requiresSync;
  static const updatePantryItem = OfflineCapability.requiresSync;
  static const deletePantryItem = OfflineCapability.requiresSync;

  // Shopping list features
  static const viewShoppingList = OfflineCapability.fullyOffline;
  static const addShoppingItem = OfflineCapability.fullyOffline;
  static const toggleShoppingItem = OfflineCapability.fullyOffline;
  static const deleteShoppingItem = OfflineCapability.fullyOffline;

  // Nutrition tracking features
  static const viewNutritionLog = OfflineCapability.offlineWithCache;
  static const addNutritionLog = OfflineCapability.requiresSync;
  static const editNutritionLog = OfflineCapability.requiresSync;
  static const deleteNutritionLog = OfflineCapability.requiresSync;

  // Household features
  static const viewHouseholds = OfflineCapability.offlineWithCache;
  static const createHousehold = OfflineCapability.requiresOnline;
  static const editHousehold = OfflineCapability.requiresOnline;
  static const deleteHousehold = OfflineCapability.requiresOnline;
  static const inviteMember = OfflineCapability.requiresOnline;
  static const removeMember = OfflineCapability.requiresOnline;

  // AI features (all require online)
  static const aiRecipeSuggestions = OfflineCapability.requiresOnline;
  static const aiRecipeVariation = OfflineCapability.requiresOnline;
  static const aiNutritionAnalysis = OfflineCapability.requiresOnline;
  static const aiIngredientSubstitution = OfflineCapability.requiresOnline;
  static const aiMealPlanGeneration = OfflineCapability.requiresOnline;

  // Kitchen mode features
  static const kitchenMode = OfflineCapability.fullyOffline;
  static const kitchenTimers = OfflineCapability.fullyOffline;

  /// Get offline capability for a feature by name
  static OfflineCapability getCapability(String featureName) {
    switch (featureName) {
      // Recipes
      case 'viewRecipes':
        return viewRecipes;
      case 'createRecipe':
        return createRecipe;
      case 'editRecipe':
        return editRecipe;
      case 'deleteRecipe':
        return deleteRecipe;
      case 'importRecipe':
        return importRecipe;

      // Meal planning
      case 'viewMealPlans':
        return viewMealPlans;
      case 'createMealPlan':
        return createMealPlan;
      case 'editMealPlan':
        return editMealPlan;

      // Pantry
      case 'viewPantry':
        return viewPantry;
      case 'addPantryItem':
        return addPantryItem;

      // Shopping list (fully offline)
      case 'viewShoppingList':
        return viewShoppingList;
      case 'addShoppingItem':
        return addShoppingItem;
      case 'toggleShoppingItem':
        return toggleShoppingItem;

      // Nutrition
      case 'viewNutritionLog':
        return viewNutritionLog;
      case 'addNutritionLog':
        return addNutritionLog;

      // Households
      case 'viewHouseholds':
        return viewHouseholds;
      case 'createHousehold':
        return createHousehold;

      // AI features (all online)
      case 'aiRecipeSuggestions':
      case 'aiRecipeVariation':
      case 'aiNutritionAnalysis':
      case 'aiIngredientSubstitution':
      case 'aiMealPlanGeneration':
        return OfflineCapability.requiresOnline;

      // Kitchen mode (fully offline)
      case 'kitchenMode':
        return kitchenMode;
      case 'kitchenTimers':
        return kitchenTimers;

      default:
        return OfflineCapability.requiresOnline;
    }
  }
}
