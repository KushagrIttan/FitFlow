import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/wardrobe_repository.dart';
import '../../models/enums.dart';
import '../widgets/empty_state.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(wardrobeItemsProvider);
    final logsAsync = ref.watch(outfitLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Closet Insights')),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.insights,
              title: 'No data yet',
              subtitle: 'Add some clothing items to unlock your closet insights.',
            );
          }
          return logsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => const Center(child: Text('Error loading history')),
            data: (logs) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSnapshotCards(context, items, logs),
                const SizedBox(height: 24),
                _buildMostWorn(context, items),
                const SizedBox(height: 24),
                _buildNeglected(context, items),
                const SizedBox(height: 24),
                _buildCategoryBreakdown(context, items),
                const SizedBox(height: 24),
                _buildWearDistribution(context, items),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSnapshotCards(BuildContext context, List<ClothingItem> items, List<OutfitLog> logs) {
    final inLaundry = items.where((i) => i.inLaundry).length;

    return Row(
      children: [
        Expanded(
          child: _statCard(context, Icons.checkroom, '${items.length}', 'Items'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(context, Icons.local_laundry_service, '$inLaundry', 'In laundry'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(context, Icons.history, '${logs.length}', 'Outfits worn'),
        ),
      ],
    );
  }

  Widget _statCard(BuildContext context, IconData icon, String value, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: scheme.primary),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: scheme.onSurface.withValues(alpha: 0.6)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildMostWorn(BuildContext context, List<ClothingItem> items) {
    final worn = items.where((i) => i.wearCount > 0).toList()
      ..sort((a, b) => b.wearCount.compareTo(a.wearCount));
    final top = worn.take(5).toList();

    return _sectionCard(
      context,
      title: 'Most Worn',
      icon: Icons.star,
      child: top.isEmpty
          ? Text(
              'You haven\'t worn anything yet. Generate today\'s outfit and log it!',
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            )
          : Column(
              children: top
                  .map((i) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: _miniThumb(i),
                        title: Text(
                          i.name ?? i.category.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('${i.wearCount}x worn'),
                        trailing: Text(
                          '${_daysSince(i.lastWornDate)}d ago',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5)),
                        ),
                      ))
                  .toList(),
            ),
    );
  }

  Widget _buildNeglected(BuildContext context, List<ClothingItem> items) {
    final now = DateTime.now();
    final neverWorn = items.where((i) => i.wearCount == 0).toList();
    final stale = items
        .where((i) {
          if (i.lastWornDate == null) return false;
          return now.difference(i.lastWornDate!).inDays >= 30;
        })
        .toList()
      ..sort((a, b) => (a.lastWornDate ?? now).compareTo(b.lastWornDate ?? now));
    final top = [...neverWorn, ...stale].take(5).toList();

    return _sectionCard(
      context,
      title: 'Needs Love',
      icon: Icons.favorite_border,
      subtitle: 'Never worn or nothing for 30+ days',
      child: top.isEmpty
          ? Text(
              'Nothing neglected — everything\'s getting rotated. \u{1F389}',
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            )
          : Column(
              children: top
                  .map((i) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: _miniThumb(i),
                        title: Text(
                          i.name ?? i.category.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          i.lastWornDate == null
                              ? 'Never worn'
                              : 'Last worn ${now.difference(i.lastWornDate!).inDays} days ago',
                        ),
                      ))
                  .toList(),
            ),
    );
  }

  Widget _miniThumb(ClothingItem item) {
    if (item.photo.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.checkroom, size: 18, color: Colors.white38),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Image.file(
          File(item.photo),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[800],
            child: const Icon(Icons.broken_image, size: 16, color: Colors.white38),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context, List<ClothingItem> items) {
    final zones = BodyZone.values;
    final zoneColors = {
      BodyZone.upper: Colors.blue,
      BodyZone.lower: Colors.green,
      BodyZone.footwear: Colors.orange,
      BodyZone.accessory: Colors.purple,
    };

    return _sectionCard(
      context,
      title: 'Wardrobe Composition',
      icon: Icons.pie_chart_outline,
      child: Column(
        children: zones.map((zone) {
          final count = items.where((i) => i.bodyZone == zone).length;
          final fraction = items.isEmpty ? 0.0 : count / items.length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(zone.name.toUpperCase(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('$count (${(fraction * 100).round()}%)',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 8,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    color: zoneColors[zone],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWearDistribution(BuildContext context, List<ClothingItem> items) {
    final never = items.where((i) => i.wearCount == 0).length;
    final once = items.where((i) => i.wearCount >= 1 && i.wearCount <= 3).length;
    final regular = items.where((i) => i.wearCount > 3).length;

    return _sectionCard(
      context,
      title: 'Rotation Balance',
      icon: Icons.refresh,
      child: Row(
        children: [
          Expanded(child: _donutItem(context, Icons.radio_button_unchecked, never, 'Never worn', Colors.redAccent)),
          Expanded(child: _donutItem(context, Icons.looks_one_outlined, once, '1-3 wears', Colors.amber)),
          Expanded(child: _donutItem(context, Icons.looks_3, regular, 'Regularly worn', Colors.green)),
        ],
      ),
    );
  }

  Widget _donutItem(BuildContext context, IconData icon, int count, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text('$count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
      ],
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    Widget? child,
    String? subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
            const SizedBox(height: 12),
            child ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  int _daysSince(DateTime? date) {
    if (date == null) return 0;
    return DateTime.now().difference(date).inDays;
  }
}