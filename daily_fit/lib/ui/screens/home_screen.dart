import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

import '../../data/recommendation_service.dart';
import '../../data/location_service.dart';
import '../../data/user_profile_service.dart';
import '../../data/api_key_service.dart';
import '../../data/database.dart';
import '../../core/fx.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isGoingOut = false;
  late TextEditingController _locationController;
  final _vibeController = TextEditingController();
  
  bool _isGenerating = false;
  bool _detectingLocation = false;
  List<RecommendedOutfit> _recommendations = [];
  String? _aiError;
  String? _emptyNote;
  final PageController _pageController = PageController(viewportFraction: 0.9);

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileServiceProvider);
    _locationController = TextEditingController(text: profile.defaultLocation);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _locationController.dispose();
    _vibeController.dispose();
    super.dispose();
  }

  /// Auto-fills the location field from the device's GPS position.
  /// Runs automatically when "Heading Out" is switched on and from the
  /// re-detect pin button. Fails soft with a helpful snackbar.
  Future<void> _detectLocation() async {
    if (_detectingLocation) return;
    final service = ref.read(locationServiceProvider);
    setState(() => _detectingLocation = true);
    try {
      final place = await service.detectCurrentPlace()
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _detectingLocation = false;
        _locationController.text = place.name;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Using your location: ${place.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } on LocationUnavailableException catch (e) {
      if (!mounted) return;
      setState(() => _detectingLocation = false);
      _showSnack(e.message);
    } catch (e) {
      debugPrint('Location detection failed: $e');
      if (!mounted) return;
      setState(() => _detectingLocation = false);
      _showSnack('Could not detect your location — type it manually below.');
    }
  }

  void _toggleGoingOut(bool val) {
    setState(() => _isGoingOut = val);
    if (val) _detectLocation();
  }

  Future<void> _generate() async {
    if (_isGoingOut && _locationController.text.trim().isEmpty) {
      Fx.tone(FxTone.tap);
      Fx.light();
      _showSnack('Enter a location (or tap the pin to detect it) to get '
          'weather-aware picks');
      return;
    }

    Fx.tone(FxTone.swish);
    Fx.medium();
    setState(() {
      _isGenerating = true;
      _recommendations = [];
      _aiError = null;
      _emptyNote = null;
    });

    final service = ref.read(recommendationServiceProvider);
    try {
      final recs = await service.generateRecommendations(
        isGoingOut: _isGoingOut,
        location: _locationController.text,
        vibe: _vibeController.text.isNotEmpty ? _vibeController.text : null,
      );

      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _recommendations = recs;
        // Surface when Gemini failed so users know why local picks appeared.
        _aiError = recs.isNotEmpty
            ? (!recs.first.isAiSuggested && ref.read(geminiApiKeyProvider) != null
                ? service.lastAiError
                : null)
            : service.lastAiError;
        // No outfit could be formed — keep the form hidden and explain why
        // inline instead of dropping back to a silent/transient snackbar.
        if (recs.isEmpty) {
          _emptyNote = service.lastSelectionNote ??
              'Not enough items to build an outfit — add a top, bottom, and shoes.';
        }
      });
    } catch (e, stack) {
      debugPrint('Recommendation failed: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _emptyNote = 'Something went wrong while styling you: $e\nPlease try again.';
      });
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.black)),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  Future<void> _wearOutfit(RecommendedOutfit outfit) async {
    Fx.tone(FxTone.whoosh);
    Fx.medium();
    final service = ref.read(recommendationServiceProvider);
    await service.logWornOutfit(
      outfit,
      destination: _isGoingOut ? _locationController.text : 'Home',
      vibe: _vibeController.text,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Outfit saved to History! You look great! \u2728', style: TextStyle(color: Colors.black)),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )
      );
      // Clear recommendations after wearing one
      setState(() => _recommendations = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Daily Fit', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
            children: [
              if (_recommendations.isEmpty)
                Expanded(
                    child: _emptyNote == null
                        ? _buildInputForm()
                        : _buildEmptyReason())
              else 
                Expanded(child: _buildRecommendationsCarousel()),
            ],
          ),
      ),
    );
  }

  /// Inline "couldn't build an outfit" panel surfaced right in the page —
  /// shows the engine's shortage reason and any AI error, with a way back
  /// to the form or straight to the wardrobe.
  Widget _buildEmptyReason() {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.checkroom,
              size: 56, color: scheme.primary.withValues(alpha: 0.7)),
          const SizedBox(height: 16),
          const Text('No outfits found',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(
            _emptyNote ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: scheme.onSurface.withValues(alpha: 0.75)),
          ),
          if (_aiError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline,
                      size: 18, color: scheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI styling hit an error: $_aiError',
                      style: TextStyle(
                          fontSize: 11,
                          color: scheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => setState(() {
              _emptyNote = null;
              _aiError = null;
            }),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Adjust & try again'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.go('/add'),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add more items to your wardrobe'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Text(
            "What's the vibe today?",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 32),
          
          _buildGlassCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Heading Out?', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Factors in weather and excludes home-only items.',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                  value: _isGoingOut,
                  onChanged: _toggleGoingOut,
                  activeColor: Theme.of(context).colorScheme.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: _isGoingOut ? Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        prefixIcon: const Icon(Icons.location_pin),
                        suffixIcon: _detectingLocation
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                onPressed: _detectLocation,
                                icon: const Icon(Icons.my_location),
                                tooltip: 'Detect my location',
                              ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ) : const SizedBox.shrink(),
                ),
                
                const SizedBox(height: 16),
                
                TextField(
                  controller: _vibeController,
                  decoration: InputDecoration(
                    labelText: 'Style Notes',
                    hintText: 'e.g. Office casual, date night, gym',
                    prefixIcon: const Icon(Icons.style),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 48),
          
          ElevatedButton(
            onPressed: _isGenerating ? null : _generate,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
              shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            child: _isGenerating
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.black),
                    SizedBox(width: 8),
                    Text('STYLE ME', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.black)),
                  ],
                ),
          )
        ],
      ),
    );
  }

  Widget _buildRecommendationsCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_aiError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Material(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI styling hit an error — showing local picks: $_aiError',
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onErrorContainer),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _aiError = null),
                      child: Icon(Icons.close,
                          size: 16,
                          color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Top Picks', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _recommendations = []),
                tooltip: 'Clear suggestions',
              )
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _recommendations.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.2)).clamp(0.8, 1.0);
                  }
                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * MediaQuery.of(context).size.height * 0.7,
                      width: Curves.easeOut.transform(value) * MediaQuery.of(context).size.width,
                      child: child,
                    ),
                  );
                },
                child: _buildOutfitCard(_recommendations[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildOutfitCard(RecommendedOutfit outfit) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: scheme.surface.withValues(alpha: 0.5),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: -5)
        ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Stylist Note',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  outfit.description,
                  style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                
                // Images row
                Row(
                  children: [
                    Expanded(child: _buildItemImage(outfit.upper, 'Top')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildItemImage(outfit.lower, 'Bottom')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildItemImage(outfit.footwear, 'Footwear')),
                    if (outfit.accessory != null) ...[
                      const SizedBox(width: 12),
                      Expanded(child: _buildItemImage(outfit.accessory!, 'Accessory')),
                    ]
                  ],
                ),
                
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _wearOutfit(outfit),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('WEAR THIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemImage(ClothingItem item, String label) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black45,
        border: Border.all(color: Colors.white12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.photo.isNotEmpty)
              Image.file(File(item.photo), fit: BoxFit.cover)
            else
              const Center(child: Icon(Icons.checkroom, color: Colors.white30, size: 32)),
            
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black87, Colors.transparent])
                ),
                child: Text(
                  item.name ?? label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: child,
          ),
        ),
      ),
    );
  }
}
