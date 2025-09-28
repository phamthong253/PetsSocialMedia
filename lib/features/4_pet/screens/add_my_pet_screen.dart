import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quanlythucung/main.dart';

class AddEditPetScreen extends StatefulWidget {
  // Thêm tham số pet: null cho Add, có dữ liệu cho Edit
  final Map<String, dynamic>? pet;
  const AddEditPetScreen({super.key, this.pet}); // Cập nhật constructor

  @override
  State<AddEditPetScreen> createState() => _AddEditPetScreenState();
}

class _AddEditPetScreenState extends State<AddEditPetScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedSex;
  String? _selectedVaccinationStatus; // <<< TRƯỜNG MỚI
  XFile? _imageFile;
  String? _existingImageUrl;

  bool get isEditing => widget.pet != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      // Khởi tạo giá trị khi chỉnh sửa
      _nameController.text = widget.pet!['name'] ?? '';
      _ageController.text = widget.pet!['age']?.toString() ?? '';
      _weightController.text = widget.pet!['weight']?.toString() ?? '';
      _locationController.text = widget.pet!['location'] ?? '';
      _descriptionController.text = widget.pet!['introduction'] ?? '';
      _selectedSex = widget.pet!['gender'];
      _existingImageUrl = widget.pet!['image_url'];
      _selectedVaccinationStatus = widget.pet!['vaccination_status'] ?? 'Chưa tiêm chủng'; // Lấy dữ liệu cũ
    } else {
      // Giá trị mặc định khi thêm mới
      _selectedSex = 'Đực';
      _selectedVaccinationStatus = 'Chưa tiêm chủng';
    }
  }

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

    if (!isEditing && _imageFile == null) {
      _showSnackBar('Vui lòng chọn ảnh cho thú cưng.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _existingImageUrl;

      if (_imageFile != null) {
        final userId = supabase.auth.currentUser!.id;
        final imageExtension = _imageFile!.path.split('.').last.toLowerCase();

        // Sử dụng ID thú cưng hoặc timestamp cho đường dẫn
        final petIdentifier = isEditing ? widget.pet!['id'] : DateTime.now().millisecondsSinceEpoch;
        final imagePath = '$userId/pets/$petIdentifier.$imageExtension';

        if (kIsWeb) {
          final imageBytes = await _imageFile!.readAsBytes();
          await supabase.storage.from('pet_images').uploadBinary(imagePath, imageBytes, fileOptions: const FileOptions(upsert: true));
        } else {
          final file = File(_imageFile!.path);
          await supabase.storage.from('pet_images').upload(imagePath, file, fileOptions: const FileOptions(upsert: true));
        }
        imageUrl = supabase.storage.from('pet_images').getPublicUrl(imagePath);
      }

      // Chuẩn bị dữ liệu
      final petData = {
        'owner_id': supabase.auth.currentUser!.id,
        'name': _nameController.text,
        'gender': _selectedSex,
        'age': double.tryParse(_ageController.text) ?? 0.0,
        'weight': double.tryParse(_weightController.text) ?? 0.0,
        'location': _locationController.text,
        'introduction': _descriptionController.text,
        'image_url': imageUrl,
        'vaccination_status': _selectedVaccinationStatus, // <<< TRƯỜNG MỚI
      };

      if (isEditing) {
        // CHẾ ĐỘ CHỈNH SỬA (UPDATE)
        final petId = widget.pet!['id'];
        await supabase.from('pets').update(petData).eq('id', petId);
        _showSnackBar('Cập nhật thú cưng thành công!');

        final updatedPet = await supabase.from('pets').select().eq('id', petId).single();
        Navigator.pop(context, updatedPet);
      } else {
        // CHẾ ĐỘ THÊM MỚI (INSERT)
        await supabase.from('pets').insert(petData);
        _showSnackBar('Thêm thú cưng thành công!');
        Navigator.pop(context, true);
      }

    } on PostgrestException catch (e) {
      _showSnackBar('Lỗi cơ sở dữ liệu: ${e.message}', isError: true);
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
    final title = isEditing ? 'Chỉnh sửa thú cưng' : 'Thêm thú cưng mới';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
                  child: (_imageFile == null && _existingImageUrl == null)
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
                    child: _imageFile != null
                        ? (kIsWeb
                        ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                        : Image.file(File(_imageFile!.path), fit: BoxFit.cover))
                        : Image.network(_existingImageUrl!, fit: BoxFit.cover),
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

              // <<< TRƯỜNG LỰA CHỌN TIÊM CHỦNG MỚI
              DropdownButtonFormField<String>(
                value: _selectedVaccinationStatus,
                items: ['Đã tiêm chủng', 'Chưa tiêm chủng']
                    .map((label) => DropdownMenuItem(
                  child: Text(label),
                  value: label,
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedVaccinationStatus = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Trạng thái tiêm chủng'),
                validator: (value) => value == null ? 'Vui lòng chọn trạng thái tiêm chủng' : null,
              ),
              const SizedBox(height: 16),
              // <<< KẾT THÚC TRƯỜNG LỰA CHỌN TIÊM CHỦNG

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
                child: Text(isEditing ? 'Lưu thay đổi' : 'Thêm thú cưng'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}