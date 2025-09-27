import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quanlythucung/main.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _image;
  bool _isLoading = false;

  // Hằng số cho khoảng cách, được định nghĩa cục bộ
  final formSpacer = const SizedBox(height: 20);

  // Hàm hiển thị SnackBar được chuyển vào bên trong State
  void _showSnackBar(String message) {
    // Kiểm tra `mounted` ngay trong hàm để đảm bảo an toàn
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_contentController.text.trim().isEmpty && _image == null) {
      // Sử dụng hàm cục bộ _showSnackBar
      _showSnackBar('Bạn phải nhập nội dung hoặc chọn ảnh.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_image != null) {
        final userId = supabase.auth.currentUser!.id;
        final imageExtension = _image!.path.split('.').last.toLowerCase();
        final imagePath =
            '$userId/posts/${DateTime.now().millisecondsSinceEpoch}.$imageExtension';

        await supabase.storage.from('post_images').upload(imagePath, _image!);
        imageUrl = supabase.storage.from('post_images').getPublicUrl(imagePath);
      }

      await supabase.from('posts').insert({
        'author_id': supabase.auth.currentUser!.id,
        'content': _contentController.text,
        'image_url': imageUrl,
      });

      _showSnackBar('Đăng bài thành công!');
      Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('Lỗi đăng bài: ${e.toString()}');
    } finally {
      // Đảm bảo `mounted` trước khi gọi setState trong finally
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo bài đăng'),
        actions: [
          if (!_isLoading)
            TextButton(onPressed: _submitPost, child: const Text('Đăng')),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        hintText: 'Bạn đang nghĩ gì?',
                        border: InputBorder.none,
                      ),
                      maxLines: 5,
                      validator: (value) => null,
                    ),
                    formSpacer,
                    if (_image != null)
                      Image.file(_image!, fit: BoxFit.contain),
                    formSpacer,
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Chọn ảnh'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
