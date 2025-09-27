import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quanlythucung/main.dart';

class AddEditPetScreen extends StatefulWidget {
  // Trong tương lai, chúng ta có thể truyền pet vào đây để chỉnh sửa
  // final Map<String, dynamic>? pet;
  const AddEditPetScreen({super.key});

  @override
  State<AddEditPetScreen> createState() => _AddEditPetScreenState();
}

class _AddEditPetScreenState extends State<AddEditPetScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers cho các trường dựa trên model Cat
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedSex = 'Đực'; // Giá trị mặc định
  XFile? _imageFile;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _submitPet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_imageFile == null) {
      _showSnackBar('Vui lòng chọn ảnh cho thú cưng.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      // 1. Upload ảnh
      final userId = supabase.auth.currentUser!.id;
      final imageExtension = _imageFile!.path.split('.').last.toLowerCase();
      final imagePath = '$userId/pets/${DateTime.now().millisecondsSinceEpoch}.$imageExtension';

      if (kIsWeb) {
        final imageBytes = await _imageFile!.readAsBytes();
        await supabase.storage.from('pet_images').uploadBinary(imagePath, imageBytes);
      } else {
        final file = File(_imageFile!.path);
        await supabase.storage.from('pet_images').upload(imagePath, file);
      }
      imageUrl = supabase.storage.from('pet_images').getPublicUrl(imagePath);

      // 2. Thêm dữ liệu vào bảng 'pets'
      await supabase.from('pets').insert({
        'owner_id': userId,
        'name': _nameController.text,
        'gender': _selectedSex,
        'age': double.tryParse(_ageController.text) ?? 0.0,
        'weight': double.tryParse(_weightController.text) ?? 0.0,
        'location': _locationController.text,
        'introduction': _descriptionController.text,
        'image_url': imageUrl,
      });

      _showSnackBar('Thêm thú cưng thành công!');
      Navigator.pop(context, true); // Trả về true để màn hình trước làm mới
    } catch (e) {
      _showSnackBar('Đã xảy ra lỗi: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm thú cưng mới'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Vùng chọn ảnh ---
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _imageFile == null
                      ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Bấm để chọn ảnh'),
                    ],
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                        : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Các trường nhập liệu ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên thú cưng'),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Tuổi (năm)'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Vui lòng nhập tuổi' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(labelText: 'Cân nặng (kg)'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Vui lòng nhập cân nặng' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSex,
                items: ['Đực', 'Cái']
                    .map((label) => DropdownMenuItem(
                  child: Text(label),
                  value: label,
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSex = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Giới tính'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập mô tả' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitPet,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Thêm thú cưng'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

