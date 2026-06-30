import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/user_profile_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _styleNotesController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final service = ref.read(userProfileServiceProvider);
    await service.saveProfile(
      height: _heightController.text,
      weight: _weightController.text,
      styleNotes: _styleNotesController.text,
      defaultLocation: _locationController.text,
    );
    await service.completeOnboarding();
    
    if (mounted) {
      context.go('/add');
    }
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
                  _buildStep(
                    title: 'Welcome to Daily Fit',
                    subtitle: 'Let\'s set up your profile to give you the best outfit recommendations.',
                    content: Column(
                      children: [
                        _buildTextField('Height (e.g. 180cm, 5\'11")', _heightController),
                        const SizedBox(height: 16),
                        _buildTextField('Weight (optional, e.g. 75kg, 165lbs)', _weightController),
                      ],
                    ),
                  ),
                  _buildStep(
                    title: 'Your Style',
                    subtitle: 'Tell us a bit about what you like to wear.',
                    content: _buildTextField('Style Notes (e.g. Minimalist, Streetwear)', _styleNotesController, maxLines: 3),
                  ),
                  _buildStep(
                    title: 'Local Weather',
                    subtitle: 'Where are you usually located?',
                    content: _buildTextField('City (e.g. New York, London)', _locationController),
                  ),
                  _buildStep(
                    title: 'All Set!',
                    subtitle: 'Time to add some clothes to your wardrobe.',
                    content: const Icon(Icons.check_circle_outline, size: 100, color: Color(0xFFFFD60A)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut),
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(_currentPage == 3 ? 'Start Adding Items' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({required String title, required String subtitle, required Widget content}) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(subtitle, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 48),
          content,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}
