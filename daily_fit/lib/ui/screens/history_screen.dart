import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../data/database.dart';
import '../../data/database_provider.dart';
import '../../data/wardrobe_repository.dart';
import '../widgets/empty_state.dart';

final historyProvider = FutureProvider<List<_HistoryEntry>>((ref) async {
  final db = ref.watch(databaseProvider);
  final logs = await (db.select(db.outfitLogs)
        ..orderBy([(t) => drift.OrderingTerm.desc(t.date)]))
      .get();
  final items = await ref.watch(wardrobeRepositoryProvider).watchAllItems().first;

  return logs.map((log) {
    final ids = log.items
        .split(',')
        .map((e) => int.tryParse(e))
        .whereType<int>()
        .toList();
    final wornItems = items.where((i) => ids.contains(i.id)).toList();
    return _HistoryEntry(log: log, items: wornItems);
  }).toList();
});

class _HistoryEntry {
  final OutfitLog log;
  final List<ClothingItem> items;
  _HistoryEntry({required this.log, required this.items});
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Outfit History')),
      body: historyAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const EmptyState(
              icon: Icons.history,
              title: 'No outfits logged yet',
              subtitle: 'Hit "WEAR THIS" on a recommendation and it will '
                  'show up here.',
            );
          }
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final log = entry.log;
              final date = log.date.toLocal();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${_weekday(date)} · ${date.day}/${date.month}/${date.year}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          if (log.wasAiSuggested)
                            Tooltip(
                              message: 'Styled by AI',
                              child: const Icon(Icons.auto_awesome,
                                  size: 16, color: Colors.amber),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${log.destination ?? 'Home'}'
                        '${log.vibeTag != null && log.vibeTag!.isNotEmpty ? ' · ${log.vibeTag}' : ''}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white60),
                      ),
                      if (entry.items.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 72,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: entry.items.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, i) =>
                                _buildItemChip(entry.items[i]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _weekday(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }

  Widget _buildItemChip(ClothingItem item) {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
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
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              color: Colors.black87,
              child: Text(
                item.name ?? item.category.name.toUpperCase(),
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
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
