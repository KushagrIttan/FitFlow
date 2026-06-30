import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../../data/wardrobe_repository.dart';

class LaundryScreen extends ConsumerWidget {
  const LaundryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(wardrobeItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Laundry')),
      body: itemsAsync.when(
        data: (items) {
          final laundryItems = items.where((i) => i.inLaundry).toList();

          if (laundryItems.isEmpty) {
            return const Center(child: Text('Nothing in the laundry right now.'));
          }

          return ListView.builder(
            itemCount: laundryItems.length,
            itemBuilder: (context, index) {
              final item = laundryItems[index];
              return ListTile(
                leading: item.photo.isNotEmpty
                    ? Image.file(File(item.photo), width: 50, height: 50, fit: BoxFit.cover)
                    : Container(width: 50, height: 50, color: Colors.grey[800]),
                title: Text(item.name ?? item.category.name.toUpperCase()),
                subtitle: Text(item.color ?? ''),
                trailing: ElevatedButton(
                  onPressed: () {
                    ref.read(wardrobeRepositoryProvider).toggleLaundry(item.id, false);
                  },
                  child: const Text('Mark Washed'),
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
}
