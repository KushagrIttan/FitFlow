import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../data/database.dart';
import '../../data/database_provider.dart';

final historyProvider = FutureProvider<List<OutfitLog>>((ref) async {
  final db = ref.watch(databaseProvider);
  return (db.select(db.outfitLogs)..orderBy([(t) => drift.OrderingTerm.desc(t.date)])).get();
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Outfit History')),
      body: historyAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text('No outfits logged yet.'));
          }
          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                title: Text('Date: ${log.date.toLocal().toString().split(' ')[0]}'),
                subtitle: Text('Context: ${log.destination ?? 'Home'}\nVibe: ${log.vibeTag ?? 'N/A'}'),
                trailing: log.wasAiSuggested ? const Icon(Icons.auto_awesome, color: Colors.yellow) : null,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
