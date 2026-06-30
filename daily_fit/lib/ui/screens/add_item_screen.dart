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

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _colorController = TextEditingController();
  
  ItemCategory? _selectedCategory;
  Fit? _selectedFit;
  double _warmthLevel = 3;
  bool _homeOnly = false;
  File? _imageFile;
  bool _isSaving = false;

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
      // Save image to local app directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await _imageFile!.copy(p.join(appDir.path, fileName));

      final repo = ref.read(wardrobeRepositoryProvider);
      await repo.addItem(
        ClothingItemsCompanion.insert(
          category: _selectedCategory!,
          bodyZone: _selectedCategory!.zone,
          name: drift.Value(_nameController.text.isNotEmpty ? _nameController.text : null),
          color: drift.Value(_colorController.text.isNotEmpty ? _colorController.text : null),
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
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpper = _selectedCategory?.zone == BodyZone.upper;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Item')),
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
              
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'Color (Optional)', border: OutlineInputBorder()),
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
                  : const Text('Save Item'),
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
