import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/wardrobe_repository.dart';
import '../../models/enums.dart';
import '../../data/database.dart';
import '../widgets/empty_state.dart';
import '../../core/fx.dart';

enum WardrobeSort {
  recent('Recently added', 'date_added'),
  wearCount('Most worn', 'wear_count'),
  leastWorn('Least worn', 'least_worn'),
  lastWorn('Longest unworn', 'last_worn'),
  name('Name (A-Z)', 'name');

  final String label;
  final String id;
  const WardrobeSort(this.label, this.id);
}

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  BodyZone? _filterZone;
  WardrobeSort _sort = WardrobeSort.recent;
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ClothingItem> _applyFilterAndSort(List<ClothingItem> items) {
    var list = items.where((i) {
      if (_filterZone != null && i.bodyZone != _filterZone) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final nameMatch = (i.name ?? '').toLowerCase().contains(q);
      final colorMatch = (i.color ?? '').toLowerCase().contains(q);
      final categoryMatch = i.category.name.toLowerCase().contains(q);
      return nameMatch || colorMatch || categoryMatch;
    }).toList();

    switch (_sort) {
      case WardrobeSort.recent:
        list.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      case WardrobeSort.wearCount:
        list.sort((a, b) => b.wearCount.compareTo(a.wearCount));
        break;
      case WardrobeSort.leastWorn:
        list.sort((a, b) => a.wearCount.compareTo(b.wearCount));
        break;
      case WardrobeSort.lastWorn:
        list.sort((a, b) {
          final aDate = a.lastWornDate ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.lastWornDate ?? DateTime.fromMillisecondsSinceEpoch(0);
          return aDate.compareTo(bDate);
        });
        break;
      case WardrobeSort.name:
        list.sort((a, b) =>
            (a.name ?? a.category.name).toLowerCase().compareTo((b.name ?? b.category.name).toLowerCase()));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(wardrobeItemsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          ),
          PopupMenuButton<WardrobeSort>(
            icon: const Icon(Icons.sort),
            onSelected: (sort) => setState(() => _sort = sort),
            itemBuilder: (context) => WardrobeSort.values.map(
              (s) => PopupMenuItem(
                value: s,
                child: Row(
                  children: [
                    if (_sort == s)
                      Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(s.label),
                  ],
                ),
              ),
            ).toList(),
          ),
        ],
      ),
      body: itemsAsync.when(
        data: (items) {
          final filtered = _applyFilterAndSort(items);

          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.checkroom,
              title: 'No items in your wardrobe yet',
              subtitle: 'Add your first piece to start getting outfit suggestions.',
              action: ElevatedButton.icon(
                onPressed: () {
                              Fx.tone(FxTone.pop);
                              Fx.light();
                              context.go('/add');
                            },
                icon: const Icon(Icons.add),
                label: const Text('Add an Item'),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search by name, color, or category',
                    prefixIcon: _query.isEmpty
                        ? const Icon(Icons.search)
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                    filled: true,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} ${filtered.length == 1 ? 'item' : 'items'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    if (_filterZone != null)
                      Chip(
                        label: Text(_filterZone!.name.toUpperCase(), style: const TextStyle(fontSize: 10)),
                        onDeleted: () => setState(() => _filterZone = null),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off,
                        title: 'No matching items',
                        subtitle: 'Try a different search or clear the filters.',
                      )
                    : GridView.builder(
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
                      ),
              ),
            ],
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
            Hero(
              tag: 'item-cover-${item.id}',
              child: item.photo.isNotEmpty
                  ? Image.file(File(item.photo), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]))
                  : Container(color: Colors.grey[900]),
            ),

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
                    const SizedBox(height: 2),
                    Text(
                      'worn ${item.wearCount}x',
                      style: const TextStyle(fontSize: 9, color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ),

            // Photo-count badge
            if (ref.read(wardrobeRepositoryProvider).itemPhotoPaths(item).length > 1)
              Positioned(
                top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library, size: 10, color: Colors.white),
                      const SizedBox(width: 3),
                      Text(
                        '${ref.read(wardrobeRepositoryProvider).itemPhotoPaths(item).length}',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
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
              leading: const Icon(Icons.edit),
              title: const Text('Edit Item'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/edit', extra: item);
              },
            ),
            ListTile(
              leading: Icon(item.inLaundry ? Icons.checkroom : Icons.local_laundry_service),
              title: Text(item.inLaundry ? 'Mark as Clean' : 'Send to Laundry'),
              onTap: () {
                Navigator.pop(ctx);
                if (item.inLaundry) {
                  Fx.tone(FxTone.pop);
                } else {
                  Fx.tone(FxTone.whoosh);
                }
                Fx.light();
                ref.read(wardrobeRepositoryProvider).toggleLaundry(item.id, !item.inLaundry);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Item', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                Fx.heavy();
                ref.read(wardrobeRepositoryProvider).deleteItem(item.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}