/*
 * Space Food - Self-Hosted Meal Planning Application
 * Copyright (C) 2025 RGH Software
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

class ApiConstants {
  static const String baseUrl = 'http://localhost:8080/api/v1';

  // Auth endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';

  // Recipe endpoints
  static const String recipes = '/recipes';
  static const String recipeSearch = '/recipes/search';

  // Meal plan endpoints
  static const String mealPlans = '/meal-plans';

  // Pantry endpoints
  static const String pantry = '/pantry';

  // Shopping list endpoints
  static const String shoppingList = '/shopping-list';

  // Nutrition endpoints
  static const String nutrition = '/nutrition';
}
