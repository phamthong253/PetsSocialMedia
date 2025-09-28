import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quanlythucung/main.dart';
// Import 'package:quanlythucung/core/utils/utils.dart'; // Giả định chứa SnackBar utilities

// Hằng số khoảng cách
const formSpacer = SizedBox(height: 16);

class EditPetScreen extends StatefulWidget {
  final Map<String, dynamic> pet;
  const EditPetScreen({super.key, required this.pet});

  @override
  State<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends State<EditPetScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _weightController;
  // Giả sử 'bio' ở đây tương đương với 'introduction' trong màn hình Add
  late final TextEditingController _bioController;

  late String _selectedGender;
  late String _selectedVaccinationStatus; // <<< TRƯỜNG MỚI
  String? _imageUrl;
  XFile? _selectedImage;
  bool _isLoading = false;

  // Hàm hiển thị SnackBar (thay thế cho showSuccessSnackBar, showErrorSnackBar nếu không có file utils)
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Khởi tạo Controllers với dữ liệu hiện tại
    _nameController = TextEditingController(text: widget.pet['name']);
    _weightController = TextEditingController(text: widget.pet['weight']?.toString() ?? '');
    _bioController = TextEditingController(text: widget.pet['bio'] ?? widget.pet['introduction'] ?? '');

    _selectedGender = widget.pet['gender'] ?? 'Đực';
    _imageUrl = widget.pet['image_url'];
    // <<< KHỞI TẠO TRẠNG THÁI TIÊM CHỦNG
    _selectedVaccinationStatus = widget.pet['vaccination_status'] ?? 'Chưa tiêm chủng';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _updatePet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final petId = widget.pet['id'];
      final userId = supabase.auth.currentUser!.id;
      String? newImageUrl = _imageUrl;

      // 1. Xử lý tải ảnh mới lên Storage (nếu có)
      if (_selectedImage != null) {
        final imageFile = File(_selectedImage!.path);
        final imageExtension = _selectedImage!.path.split('.').last.toLowerCase();
        final path = '$userId/pets/$petId/avatar.$imageExtension';

        await supabase.storage
            .from('pet_images')
            .upload(
          path,
          imageFile,
          fileOptions: const FileOptions(upsert: true),
        );
        newImageUrl = supabase.storage.from('pet_images').getPublicUrl(path);
      }

      // 2. Cập nhật thông tin vào bảng 'pets'
      final updatedData = {
        'name': _nameController.text.trim(),
        'weight': double.tryParse(_weightController.text.trim()),
        'gender': _selectedGender,
        'bio': _bioController.text.trim(), // Giữ lại 'bio' nếu database dùng nó
        // Nếu database dùng 'introduction'
        'introduction': _bioController.text.trim(),
        'image_url': newImageUrl,
        'vaccination_status': _selectedVaccinationStatus, // <<< TRƯỜNG MỚI
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase
          .from('pets')
          .update(updatedData)
          .eq('id', petId);

      // Lấy dữ liệu thú cưng đã cập nhật
      final updatedPet = await supabase
          .from('pets')
          .select()
          .eq('id', petId)
          .single();

      if (mounted) {
        _showSnackBar('Cập nhật thông tin thú cưng thành công!');
        // Trả về đối tượng Map đã cập nhật cho màn hình PetDetailScreen
        Navigator.pop(context, updatedPet);
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        _showSnackBar('Lỗi cập nhật dữ liệu: ${e.message}', isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Đã xảy ra lỗi không mong muốn.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa thông tin thú cưng')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Avatar/Ảnh thú cưng ---
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _selectedImage != null
                          ? FileImage(File(_selectedImage!.path))
                          : (_imageUrl != null
                          ? NetworkImage(_imageUrl!)
                          : null)
                      as ImageProvider?,
                      child: _imageUrl == null && _selectedImage == null
                          ? const Icon(Icons.pets, size: 60)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              formSpacer,
              // --- Tên thú cưng ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên thú cưng'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên';
                  }
                  return null;
                },
              ),
              formSpacer,
              // --- Cân nặng ---
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Cân nặng (kg)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (double.tryParse(value) == null) {
                    return 'Vui lòng nhập số hợp lệ';
                  }
                  return null;
                },
              ),
              formSpacer,
              // --- Giới tính ---
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Giới tính'),
                value: _selectedGender,
                items: ['Đực', 'Cái']
                    .map((label) => DropdownMenuItem(
                  value: label,
                  child: Text(label),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Vui lòng chọn giới tính';
                  }
                  return null;
                },
              ),
              formSpacer,
              // <<< TRƯỜNG LỰA CHỌN TIÊM CHỦNG MỚI
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Trạng thái tiêm chủng'),
                value: _selectedVaccinationStatus,
                items: ['Đã tiêm chủng', 'Chưa tiêm chủng']
                    .map((label) => DropdownMenuItem(
                  value: label,
                  child: Text(label),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedVaccinationStatus = value!;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Vui lòng chọn trạng thái tiêm chủng';
                  }
                  return null;
                },
              ),
              formSpacer,
              // <<< KẾT THÚC TRƯỜNG LỰA CHỌN TIÊM CHỦNG
              // --- Giới thiệu / Tiểu sử ---
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Giới thiệu / Tiểu sử (tùy chọn)',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              formSpacer,
              // --- Nút lưu ---
              ElevatedButton(
                onPressed: _updatePet,
                child: const Text('Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}