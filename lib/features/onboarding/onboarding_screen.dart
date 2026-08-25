import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/database/database.dart';
import '../dashboard/dashboard_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  
  String? _selectedGoal;
  String? _selectedActivityLevel;

  final List<String> _goals = ['Fat Loss', 'Muscle Gain', 'Endurance', 'General Health'];
  final List<String> _activityLevels = ['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active'];

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final db = ref.read(appDatabaseProvider);
    
    await db.into(db.userProfiles).insert(
      UserProfilesCompanion.insert(
        age: drift.Value(int.tryParse(_ageController.text)),
        weight: drift.Value(double.tryParse(_weightController.text)),
        height: drift.Value(double.tryParse(_heightController.text)),
        goals: drift.Value(_selectedGoal),
        activityLevel: drift.Value(_selectedActivityLevel),
      ),
    );

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainDashboardScreen()),
      );
    }
  }

  Widget _buildAgeStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'How old are you?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24),
            decoration: const InputDecoration(hintText: 'e.g. 25'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightHeightStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'What are your measurements?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Weight (kg)'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Height (cm)'),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'What is your primary goal?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ..._goals.map((goal) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedGoal == goal 
                          ? Theme.of(context).primaryColor 
                          : Theme.of(context).cardColor,
                      foregroundColor: _selectedGoal == goal 
                          ? Colors.black 
                          : Colors.white,
                    ),
                    onPressed: () {
                      setState(() => _selectedGoal = goal);
                      Future.delayed(const Duration(milliseconds: 300), _nextPage);
                    },
                    child: Text(goal),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildActivityStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'How active are you?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ..._activityLevels.map((level) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedActivityLevel == level 
                          ? Theme.of(context).primaryColor 
                          : Theme.of(context).cardColor,
                      foregroundColor: _selectedActivityLevel == level 
                          ? Colors.black 
                          : Colors.white,
                    ),
                    onPressed: () {
                      setState(() => _selectedActivityLevel = level);
                      Future.delayed(const Duration(milliseconds: 300), _nextPage);
                    },
                    child: Text(level),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFinalStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/logo.png',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.check_circle, size: 80, color: Colors.greenAccent),
          ),
          const SizedBox(height: 24),
          const Text(
            'All set!',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Arise is ready to be your personal AI health companion.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _completeOnboarding,
              child: const Text('Start My Journey'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  _buildAgeStep(),
                  _buildWeightHeightStep(),
                  _buildGoalStep(),
                  _buildActivityStep(),
                  _buildFinalStep(),
                ],
              ),
            ),
            if (_currentPage < 4 && _currentPage != 2 && _currentPage != 3) // Hide next on goal/activity auto-advance
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    child: const Text('Next'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
