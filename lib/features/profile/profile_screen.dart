import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/theme.dart';

const secureStorage = FlutterSecureStorage();
const String _apiKeyKey = 'gemini_api_key';
const String _modelNameKey = 'gemini_model_name';

final apiKeyProvider = FutureProvider<String?>((ref) async {
  return await secureStorage.read(key: _apiKeyKey);
});

final modelNameProvider = FutureProvider<String?>((ref) async {
  return await secureStorage.read(key: _modelNameKey);
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _keyController = TextEditingController();
  final _modelController = TextEditingController(text: 'gemini-1.5-flash');
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final key = await secureStorage.read(key: _apiKeyKey);
    final modelName = await secureStorage.read(key: _modelNameKey);
    
    if (mounted) {
      if (key != null) _keyController.text = key;
      if (modelName != null) _modelController.text = modelName;
    }
  }

  Future<void> _saveKey() async {
    setState(() => _isSaving = true);
    await secureStorage.write(key: _apiKeyKey, value: _keyController.text.trim());
    await secureStorage.write(key: _modelNameKey, value: _modelController.text.trim());
    
    // Invalidate the provider so AI Service picks up the new key and model
    ref.invalidate(apiKeyProvider);
    ref.invalidate(modelNameProvider);
    
    setState(() => _isSaving = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('API Key saved securely!'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.smart_toy, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      Text('Gemini AI Configuration', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'To use the AI Chat Companion, provide your Google Gemini API Key. It will be encrypted and stored locally on your device.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _keyController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      hintText: 'AIzaSy...',
                      prefixIcon: Icon(Icons.key),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'Model Name',
                      hintText: 'gemini-1.5-flash',
                      prefixIcon: Icon(Icons.memory),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveKey,
                      child: _isSaving 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) 
                          : const Text('Save API Key'),
                    ),
                  ),
                ],
              ),
            ).animate().fade().slideY(begin: 0.2),
            
            // Further profile settings (Age, weight, etc) can go here later
          ],
        ),
      ),
    );
  }
}
