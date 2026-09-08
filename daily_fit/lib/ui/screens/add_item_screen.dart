import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' as drift;
import 'package:go_router/go_router.dart';

import '../../models/enums.dart';
import '../../data/wardrobe_repository.dart';
import '../../data/database.dart';
import '../../core/fx.dart';

/// Dual-mode screen: `initialItem == null` → add a new item,
/// otherwise edit the existing item's details.
class AddItemScreen extends ConsumerStatefulWidget {
  final ClothingItem? initialItem;

  const AddItemScreen({super.key, this.initialItem});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  ItemCategory? _selectedCategory;
  Fit? _selectedFit;
  String? _selectedColor;
  double _warmthLevel = 3;
  bool _homeOnly = false;
  List<File> _imageFiles = [];
  bool _isSaving = false;

  static const int _maxPhotos = 6;

  static const List<String> _palette = [
    'Black', 'White', 'Grey', 'Navy', 'Blue', 'Denim', 'Green', 'Olive',
    'Beige', 'Brown', 'Burgundy', 'Red', 'Yellow', 'Orange', 'Pink', 'Purple',
  ];

  bool get _isEditing => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    if (item != null) {
      _nameController.text = item.name ?? '';
      _selectedCategory = item.category;
      _selectedFit = item.fit;
      _selectedColor = item.color;
      _warmthLevel = item.warmthLevel.toDouble();
      _homeOnly = item.homeOnly;
      _imageFiles = ref
          .read(wardrobeRepositoryProvider)
          .itemPhotoPaths(item)
          .map((path) => File(path))
          .toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImages(ImageSource source) async {
    if (_imageFiles.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Up to $_maxPhotos photos per item')),
      );
      return;
    }
    final picker = ImagePicker();
    if (source == ImageSource.camera) {
      final picked = await picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024);
      if (picked != null) {
        setState(() => _imageFiles.add(File(picked.path)));
      }
      return;
    }

    final remaining = _maxPhotos - _imageFiles.length;
    final picked = await picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      limit: remaining,
    );
    if (mounted && picked.isNotEmpty) {
      setState(() => _imageFiles.addAll(picked.map((x) => File(x.path))));
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate() || _imageFiles.isEmpty || _selectedCategory == null || _selectedFit == null) {
      Fx.tone(FxTone.tap);
      Fx.light();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields and add a photo')),
      );
      return;
    }

    Fx.tone(FxTone.pop);
    Fx.light();
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(wardrobeRepositoryProvider);

      if (_isEditing) {
        final original = widget.initialItem!;
        // Compare paths: files picked fresh (not already stored) get copied.
        final stored = repo.itemPhotoPaths(original).toSet();
        var photoPaths = <String>[];
        for (final file in _imageFiles) {
          if (stored.contains(file.path)) {
            photoPaths.add(file.path);
          } else {
            photoPaths.add((await _copyImageToStorage(file)).path);
          }
        }
        final cover = photoPaths.isNotEmpty ? photoPaths.first : original.photo;
        await repo.updateItem(original.copyWith(
          category: _selectedCategory!,
          bodyZone: _selectedCategory!.zone,
          name: drift.Value(_nameController.text.isNotEmpty ? _nameController.text : null),
          color: drift.Value(_selectedColor),
          fit: _selectedFit!,
          photo: cover,
          photos: drift.Value(jsonEncode(photoPaths)),
          homeOnly: _homeOnly,
          warmthLevel: _warmthLevel.toInt(),
        ));
        // Delete any stored photos the user removed from the gallery.
        final kept = photoPaths.toSet();
        for (final path in stored.difference(kept)) {
          try {
            final file = File(path);
            if (await file.exists()) await file.delete();
          } catch (_) {}
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item updated!')));
          context.pop();
        }
      } else {
        final photoPaths = <String>[];
        for (final file in _imageFiles) {
          photoPaths.add((await _copyImageToStorage(file)).path);
        }
        await repo.addItem(
          ClothingItemsCompanion.insert(
            category: _selectedCategory!,
            bodyZone: _selectedCategory!.zone,
            name: drift.Value(_nameController.text.isNotEmpty ? _nameController.text : null),
            color: drift.Value(_selectedColor),
            fit: _selectedFit!,
            photo: photoPaths.first,
            photos: drift.Value(jsonEncode(photoPaths)),
            homeOnly: drift.Value(_homeOnly),
            warmthLevel: drift.Value(_warmthLevel.toInt()),
          )
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item added successfully!')));
          context.go('/wardrobe');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<File> _copyImageToStorage(File source) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_imageFiles.indexOf(source)}.jpg';
    return source.copy(p.join(appDir.path, fileName));
  }

  @override
  Widget build(BuildContext context) {
    final isUpper = _selectedCategory?.zone == BodyZone.upper;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_isEditing ? 'Edit Item' : 'Add Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPhotoPicker(),
              const SizedBox(height: 24),

              DropdownButtonFormField<ItemCategory>(
                decoration: const InputDecoration(labelText: 'Category *', border: OutlineInputBorder()),
                value: _selectedCategory,
                items: ItemCategory.values.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c.name.toUpperCase()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    Fx.tone(FxTone.pluck);
                    Fx.light();
                  }
                  setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<Fit>(
                decoration: const InputDecoration(labelText: 'Fit *', border: OutlineInputBorder()),
                value: _selectedFit,
                items: Fit.values.map((f) {
                  return DropdownMenuItem(value: f, child: Text(f.name.toUpperCase()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    Fx.tone(FxTone.pluck);
                    Fx.light();
                  }
                  setState(() => _selectedFit = val);
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name (Optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              const Text('Color (Optional)', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _palette.map((c) {
                  return ChoiceChip(
                    label: Text(c),
                    selected: _selectedColor == c,
                    onSelected: (_) {
                    Fx.tone(FxTone.pluck);
                    Fx.light();
                    setState(() => _selectedColor = c);
                  },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              if (isUpper) ...[
                const Text('Warmth Level (1: Cool, 5: Very Warm)'),
                Slider(
                  value: _warmthLevel,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: _warmthLevel.round().toString(),
                  onChanged: (val) => setState(() => _warmthLevel = val),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
              ],

              SwitchListTile(
                title: const Text('Home Only'),
                subtitle: const Text('Exclude from "Going Out" recommendations'),
                value: _homeOnly,
                onChanged: (val) => setState(() => _homeOnly = val),
                activeColor: Theme.of(context).colorScheme.primary,
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveItem,
                child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.black)
                  : Text(_isEditing ? 'Save Changes' : 'Save Item'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos * (first photo is the cover)',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileSize = (constraints.maxWidth - 12) / 3;
            return Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < _imageFiles.length; i++)
                  _buildPhotoThumb(_imageFiles[i], i, tileSize),
                if (_imageFiles.length < _maxPhotos)
                  GestureDetector(
                    onTap: () => _showPhotoSourceSheet(),
                    child: Container(
                      width: tileSize,
                      height: tileSize,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 28, color: Colors.white54),
                          SizedBox(height: 4),
                          Text('Add photo', style: TextStyle(fontSize: 10, color: Colors.white54)),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        if (_imageFiles.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '${_imageFiles.length}/$_maxPhotos',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoThumb(File file, int index, double size) {
    final cover = <Widget>[
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(file, fit: BoxFit.cover),
      ),
    ];
    // Animate the cover from the wardrobe card when editing.
    final picture = _isEditing && widget.initialItem != null && index == 0
        ? Hero(tag: 'item-cover-${widget.initialItem!.id}', child: cover[0])
        : cover[0];

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          picture,
          if (index == 0)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('COVER',
                    style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => setState(() => _imageFiles.removeAt(index)),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
          if (index > 0)
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => setState(() {
                  final moved = _imageFiles.removeAt(index);
                  _imageFiles.insert(0, moved);
                }),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star_border, size: 12, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImages(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery (multi-select)'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImages(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}