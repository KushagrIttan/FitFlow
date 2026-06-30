import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/wardrobe_repository.dart';
import '../../models/enums.dart';
import '../../data/database.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  BodyZone? _filterZone;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(wardrobeItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wardrobe'),
        actions: [
          PopupMenuButton<BodyZone?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (zone) => setState(() => _filterZone = zone),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All')),
              ...BodyZone.values.map(
                (z) => PopupMenuItem(value: z, child: Text(z.name.toUpperCase()))
              )
            ],
          )
        ],
      ),
      body: itemsAsync.when(
        data: (items) {
          final filtered = _filterZone == null 
              ? items 
              : items.where((i) => i.bodyZone == _filterZone).toList();
              
          if (filtered.isEmpty) {
            return const Center(child: Text('No items found.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final item = filtered[index];
              return _buildItemCard(item, ref);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildItemCard(ClothingItem item, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () => _showItemOptions(item, ref),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.photo.isNotEmpty)
              Image.file(File(item.photo), fit: BoxFit.cover)
            else
              Container(color: Colors.grey[900]),
            
            // Overlay gradient for text readability
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black87, Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name ?? item.category.name.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.color != null)
                      Text(
                        item.color!,
                        style: const TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                  ],
                ),
              ),
            ),
            
            // Badges
            Positioned(
              top: 8, right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.homeOnly)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.blueGrey, borderRadius: BorderRadius.circular(4)),
                      child: const Text('HOME', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  if (item.inLaundry)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)),
                      child: const Text('LAUNDRY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemOptions(ClothingItem item, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(item.inLaundry ? Icons.checkroom : Icons.local_laundry_service),
              title: Text(item.inLaundry ? 'Mark as Clean' : 'Send to Laundry'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(wardrobeRepositoryProvider).toggleLaundry(item.id, !item.inLaundry);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Item', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(wardrobeRepositoryProvider).deleteItem(item.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
