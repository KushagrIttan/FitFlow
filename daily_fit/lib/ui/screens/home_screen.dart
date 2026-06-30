import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:drift/drift.dart' as drift;

import '../../data/recommendation_service.dart';
import '../../data/user_profile_service.dart';
import '../../data/database_provider.dart';
import '../../data/database.dart';

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
  List<RecommendedOutfit> _recommendations = [];
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
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _isGenerating = true;
      _recommendations = [];
    });

    final service = ref.read(recommendationServiceProvider);
    final recs = await service.generateRecommendations(
      isGoingOut: _isGoingOut,
      location: _locationController.text,
      vibe: _vibeController.text.isNotEmpty ? _vibeController.text : null,
    );

    if (mounted) {
      setState(() {
        _isGenerating = false;
        _recommendations = recs;
      });
    }
  }

  Future<void> _wearOutfit(RecommendedOutfit outfit) async {
    final db = ref.read(databaseProvider);
    final List<int> ids = [outfit.upper.id, outfit.lower.id, outfit.footwear.id];
    if (outfit.accessory != null) ids.add(outfit.accessory!.id);
    final itemIds = ids.join(',');
    
    await db.into(db.outfitLogs).insert(
      OutfitLogsCompanion.insert(
        date: DateTime.now(),
        items: itemIds,
        wasAiSuggested: const drift.Value(true),
        vibeTag: drift.Value(_vibeController.text),
        destination: drift.Value(_isGoingOut ? _locationController.text : 'Home'),
      )
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
          )
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (_recommendations.isEmpty) 
                Expanded(child: _buildInputForm())
              else 
                Expanded(child: _buildRecommendationsCarousel()),
            ],
          ),
        ),
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
                  subtitle: const Text('Factors in weather and excludes home-only items.', style: TextStyle(fontSize: 12, color: Colors.white60)),
                  value: _isGoingOut,
                  onChanged: (val) => setState(() => _isGoingOut = val),
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
                        filled: true,
                        fillColor: Colors.black26,
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
                    fillColor: Colors.black26,
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
              shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, spreadRadius: -5)
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
                    const Text('Stylist Note', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
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
