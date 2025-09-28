import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quanlythucung/main.dart';
import 'package:quanlythucung/core/utils/utils.dart';

// ĐÃ KHAI BÁO THÊM formSpacer ĐỂ TRÁNH LỖI BIẾN KHÔNG ĐƯỢC ĐỊNH NGHĨA
const formSpacer = SizedBox(height: 20);

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hobbiesController = TextEditingController();

  bool _isLoading = true;
  String? _avatarUrl;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _getInitialProfile();
  }

  Future<void> _getInitialProfile() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      if (mounted) {
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _hobbiesController.text = data['hobbies'] ?? '';
        _avatarUrl = data['avatar_url'];
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, "Không thể tải thông tin");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Chọn ảnh từ thư viện
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

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userId = supabase.auth.currentUser!.id;
        String? newAvatarUrl;

        // 1. Tải ảnh đại diện mới lên Storage nếu người dùng có chọn
        if (_selectedImage != null) {
          final imageFile = File(_selectedImage!.path);
          final imageExtension = _selectedImage!.path
              .split('.')
              .last
              .toLowerCase();
          final path = '$userId/avatar.$imageExtension';

          await supabase.storage
              .from('avatars')
              .upload(
            path,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );
          // Lấy URL công khai của ảnh vừa tải lên
          newAvatarUrl = supabase.storage.from('avatars').getPublicUrl(path);
        }

        // 2. Cập nhật thông tin vào bảng 'profiles'
        await supabase
            .from('profiles')
            .update({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'hobbies': _hobbiesController.text.trim(),
          'avatar_url':
          newAvatarUrl ??
              _avatarUrl, // Dùng URL mới, nếu không thì giữ lại URL cũ
          'updated_at': DateTime.now().toIso8601String(),
        })
            .eq('id', userId);

        if (mounted) {
          showSuccessSnackBar(context, 'Cập nhật thành công!');
          // Trả về `true` để màn hình trước đó biết và tải lại dữ liệu
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          showErrorSnackBar(context, 'Cập nhật thất bại!');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _hobbiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa Hồ sơ')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _selectedImage != null
                        ? FileImage(File(_selectedImage!.path))
                        : (_avatarUrl != null
                        ? NetworkImage(_avatarUrl!)
                        : null)
                    as ImageProvider?,
                    child: _avatarUrl == null && _selectedImage == null
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.black,
                        ),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            formSpacer,
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên'),
              // --- VALIDATION TÊN ĐÃ CẬP NHẬT ---
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Tên không được để trống';
                }
                if (value.trim().length < 2) {
                  return 'Tên phải có ít nhất 2 ký tự';
                }

                // Regex: Chỉ cho phép chữ cái, chữ số và khoảng trắng
                final nameRegex = RegExp(r'^[a-zA-Z0-9\s]+$');
                if (!nameRegex.hasMatch(value.trim())) {
                  return 'Tên không được chứa ký tự đặc biệt';
                }

                return null;
              },
            ),
            formSpacer,
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
              ),
              keyboardType: TextInputType.phone,
            ),
            formSpacer,
            TextFormField(
              controller: _hobbiesController,
              decoration: const InputDecoration(labelText: 'Sở thích'),
            ),
            formSpacer,
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _updateProfile,
              child: const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }
}