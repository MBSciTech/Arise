import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/database/database.dart';
import '../../core/theme/theme.dart';

class AddMealScreen extends ConsumerStatefulWidget {
  final Meal? mealToEdit;

  const AddMealScreen({super.key, this.mealToEdit});

  @override
  ConsumerState<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends ConsumerState<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _calsController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  
  double _baseCalories = 0;
  double _baseProtein = 0;
  double _baseCarbs = 0;
  double _baseFat = 0;
  
  double _quantity = 1.0;
  
  String _selectedCategory = 'Miscellaneous';
  final List<String> _categories = ['Breakfast', 'Lunch', 'Dinner', 'Snacks', 'Drinks', 'Miscellaneous'];

  List<Meal> _recentMeals = [];

  @override
  void initState() {
    super.initState();
    _loadRecentMeals();
    
    if (widget.mealToEdit != null) {
      _autofillFromMeal(widget.mealToEdit!, isEditing: true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _calsController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentMeals() async {
    final db = ref.read(appDatabaseProvider);
    final meals = await db.mealsDao.getRecentDistinctMeals();
    setState(() => _recentMeals = meals);
  }

  void _autofillFromMeal(Meal meal, {bool isEditing = false}) {
    setState(() {
      _nameController.text = meal.name;
      
      // The DB stores the TOTAL macros consumed. To get the base per 1 quantity:
      final baseCals = meal.calories / meal.quantity;
      final basePro = meal.protein / meal.quantity;
      final baseCarbs = meal.carbs / meal.quantity;
      final baseFat = meal.fats / meal.quantity;
      
      _calsController.text = baseCals.toInt().toString();
      _proteinController.text = basePro.toInt().toString();
      _carbsController.text = baseCarbs.toInt().toString();
      _fatController.text = baseFat.toInt().toString();
      
      _baseCalories = baseCals;
      _baseProtein = basePro;
      _baseCarbs = baseCarbs;
      _baseFat = baseFat;
      
      _quantity = isEditing ? meal.quantity : 1.0; 
      
      if (_categories.contains(meal.category)) {
        _selectedCategory = meal.category;
      }
    });
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final db = ref.read(appDatabaseProvider);
    
    final companion = MealsCompanion.insert(
      name: _nameController.text.trim(),
      calories: _baseCalories * _quantity,
      protein: _baseProtein * _quantity,
      carbs: _baseCarbs * _quantity,
      fats: _baseFat * _quantity,
      quantity: drift.Value(_quantity),
      category: drift.Value(_selectedCategory),
      date: widget.mealToEdit?.date ?? DateTime.now(),
    );

    if (widget.mealToEdit != null) {
      await db.mealsDao.updateMeal(companion.copyWith(id: drift.Value(widget.mealToEdit!.id)));
    } else {
      await db.mealsDao.insertMeal(companion);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Compute totals dynamically for UI feedback
    final totalCals = _baseCalories * _quantity;
    final totalPro = _baseProtein * _quantity;
    final totalCarbs = _baseCarbs * _quantity;
    final totalFat = _baseFat * _quantity;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mealToEdit != null ? 'Edit Meal' : 'Log Meal'),
        actions: [
          TextButton(
            onPressed: _saveMeal,
            child: const Text('Save', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          onChanged: () {
            _formKey.currentState!.save();
            setState(() {});
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What did you eat?',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ).animate().fade().slideY(begin: 0.2),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Meal Name',
                  hintText: 'e.g. Chapati',
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ).animate().fade(delay: 100.ms).slideY(begin: 0.2),
              
              if (_recentMeals.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Recent Foods', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recentMeals.length,
                    itemBuilder: (context, index) {
                      final meal = _recentMeals[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ActionChip(
                          label: Text(meal.name),
                          backgroundColor: theme.colorScheme.surfaceContainerHigh,
                          onPressed: () => _autofillFromMeal(meal),
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              Text(
                'Category',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ).animate().fade(delay: 150.ms).slideY(begin: 0.2),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                    backgroundColor: theme.colorScheme.surfaceContainer,
                    labelStyle: TextStyle(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface),
                    side: BorderSide(color: isSelected ? theme.colorScheme.primary : Colors.transparent),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = category);
                    },
                  );
                }).toList(),
              ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
              
              const SizedBox(height: 32),
              
              Text(
                'Macros (Per 1 Serving)',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ).animate().fade(delay: 250.ms).slideY(begin: 0.2),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _calsController,
                      decoration: const InputDecoration(labelText: 'Calories', suffixText: 'kcal'),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid' : null,
                      onSaved: (val) => _baseCalories = double.tryParse(val ?? '0') ?? 0,
                    ),
                  ),
                ],
              ).animate().fade(delay: 300.ms).slideY(begin: 0.2),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _proteinController,
                      decoration: const InputDecoration(labelText: 'Protein', suffixText: 'g'),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid' : null,
                      onSaved: (val) => _baseProtein = double.tryParse(val ?? '0') ?? 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _carbsController,
                      decoration: const InputDecoration(labelText: 'Carbs', suffixText: 'g'),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid' : null,
                      onSaved: (val) => _baseCarbs = double.tryParse(val ?? '0') ?? 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _fatController,
                      decoration: const InputDecoration(labelText: 'Fat', suffixText: 'g'),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid' : null,
                      onSaved: (val) => _baseFat = double.tryParse(val ?? '0') ?? 0,
                    ),
                  ),
                ],
              ).animate().fade(delay: 400.ms).slideY(begin: 0.2),

              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quantity',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (_quantity > 0.5) setState(() => _quantity -= 0.5);
                          },
                        ),
                        Text(
                          '${_quantity % 1 == 0 ? _quantity.toInt() : _quantity}',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() => _quantity += 0.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fade(delay: 500.ms).slideY(begin: 0.2),

              const SizedBox(height: 32),

              // Dynamic Summary Card
              Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Logged', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
                          Text('${totalCals.toInt()} kcal', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _SummaryMacro('Protein', '${totalPro.toInt()}g', theme),
                          _SummaryMacro('Carbs', '${totalCarbs.toInt()}g', theme),
                          _SummaryMacro('Fat', '${totalFat.toInt()}g', theme),
                        ],
                      )
                    ],
                  ),
                ),
              ).animate().fade(delay: 600.ms).slideY(begin: 0.2),

            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryMacro extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _SummaryMacro(this.label, this.value, this.theme);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7))),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
