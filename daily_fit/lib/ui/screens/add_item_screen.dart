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
  File? _imageFile;
  bool _isSaving = false;

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
      if (item.photo.isNotEmpty) _imageFile = File(item.photo);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate() || _imageFile == null || _selectedCategory == null || _selectedFit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields and add a photo')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(wardrobeRepositoryProvider);

      if (_isEditing) {
        final original = widget.initialItem!;
        // Keep the existing photo unless a new one was picked.
        var photoPath = original.photo;
        if (original.photo != _imageFile!.path) {
          photoPath = (await _copyImageToStorage(_imageFile!)).path;
        }
        await repo.updateItem(original.copyWith(
          category: _selectedCategory!,
          bodyZone: _selectedCategory!.zone,
          name: drift.Value(_nameController.text.isNotEmpty ? _nameController.text : null),
          color: drift.Value(_selectedColor),
          fit: _selectedFit!,
          photo: photoPath,
          homeOnly: _homeOnly,
          warmthLevel: _warmthLevel.toInt(),
        ));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item updated!')));
          context.pop();
        }
      } else {
        final savedImage = await _copyImageToStorage(_imageFile!);
        await repo.addItem(
          ClothingItemsCompanion.insert(
            category: _selectedCategory!,
            bodyZone: _selectedCategory!.zone,
            name: drift.Value(_nameController.text.isNotEmpty ? _nameController.text : null),
            color: drift.Value(_selectedColor),
            fit: _selectedFit!,
            photo: savedImage.path,
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
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    return source.copy(p.join(appDir.path, fileName));
  }

  @override
  Widget build(BuildContext context) {
    final isUpper = _selectedCategory?.zone == BodyZone.upper;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Item' : 'Add Item')),
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
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<Fit>(
                decoration: const InputDecoration(labelText: 'Fit *', border: OutlineInputBorder()),
                value: _selectedFit,
                items: Fit.values.map((f) {
                  return DropdownMenuItem(value: f, child: Text(f.name.toUpperCase()));
                }).toList(),
                onChanged: (val) => setState(() => _selectedFit = val),
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
                    onSelected: (_) => setState(() => _selectedColor = c),
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
    return GestureDetector(
      onTap: () {
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
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          )
        );
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
          image: _imageFile != null 
            ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
            : null,
        ),
        child: _imageFile == null 
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo, size: 48, color: Colors.white54),
                SizedBox(height: 8),
                Text('Tap to add photo *', style: TextStyle(color: Colors.white54)),
              ],
            ))
          : null,
      ),
    );
  }
}
