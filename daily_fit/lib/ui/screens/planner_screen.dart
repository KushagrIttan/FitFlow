import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/fx.dart';
import '../../data/recommendation_service.dart';
import '../../data/database.dart';

/// Weekly/trip planning: generates N outfits where no item is reused.
class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  int _outfitCount = 3;
  bool _isGenerating = false;
  List<RecommendedOutfit> _plan = [];

  Future<void> _generate() async {
    setState(() {
      _isGenerating = true;
      _plan = [];
    });

    final service = ref.read(recommendationServiceProvider);
    final plan = await service.generateOutfitPlan(
      count: _outfitCount,
      isGoingOut: false,
      location: '',
    );

    if (mounted) {
      Fx.tone(FxTone.swish);
      Fx.medium();
      setState(() {
        _isGenerating = false;
        _plan = plan;
      });
      if (plan.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Not enough clean clothes for that many outfits. '
                  'Add more items or run the laundry.')),
        );
      }
    }
  }

  Future<void> _wearOutfit(RecommendedOutfit outfit) async {
    Fx.tone(FxTone.whoosh);
    Fx.medium();
    final service = ref.read(recommendationServiceProvider);
    await service.logWornOutfit(outfit, destination: 'Home', vibe: 'Plan');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Outfit ${outfit.description.split(' ')[2]} saved to History!',
              style: const TextStyle(color: Colors.black)),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Outfit Plan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Plan your week',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Generate outfits where no item repeats — perfect for trips and busy weeks.',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text('Outfits:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('$_outfitCount',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                  ],
                ),
                Slider(
                  value: _outfitCount.toDouble(),
                  min: 2,
                  max: 7,
                  divisions: 5,
                  label: '$_outfitCount outfits',
                  onChanged: (v) => setState(() => _outfitCount = v.round()),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generate,
                  icon: _isGenerating
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome),
                  label: Text(_isGenerating ? 'Planning…' : 'Generate Plan'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _plan.isEmpty
                ? const Center(
                    child: Text('Your plan will appear here.',
                        style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _plan.length,
                    itemBuilder: (context, index) =>
                        _buildPlanCard(_plan[index], index),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(RecommendedOutfit outfit, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Day ${index + 1}',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildItemThumb(outfit.upper, 'Top')),
                const SizedBox(width: 8),
                Expanded(child: _buildItemThumb(outfit.lower, 'Bottom')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildItemThumb(outfit.footwear, 'Footwear')),
                if (outfit.accessory != null) ...[
                  const SizedBox(width: 8),
                  Expanded(child: _buildItemThumb(outfit.accessory!, 'Accessory')),
                ],
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _wearOutfit(outfit),
                icon: const Icon(Icons.checkroom, size: 18),
                label: const Text('Wear Today'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemThumb(ClothingItem item, String label) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black45,
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.photo.isNotEmpty)
            Image.file(File(item.photo), fit: BoxFit.cover)
          else
            const Center(child: Icon(Icons.checkroom, color: Colors.white30)),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
              color: Colors.black87,
              child: Text(
                item.name ?? label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
