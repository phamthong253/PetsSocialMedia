import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quanlythucung/main.dart';

class EditPostScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late final TextEditingController _contentController;
  final _formKey = GlobalKey<FormState>();
  XFile? _imageFile;
  String? _existingImageUrl;
  bool _isLoading = false;

  final formSpacer = const SizedBox(height: 20);

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.post['content']);
    _existingImageUrl = widget.post['image_url'];
  }

  void _showSnackBar(String message) {
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
        _imageFile = pickedFile;
        _existingImageUrl = null; // Xóa ảnh cũ nếu chọn ảnh mới
      });
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _existingImageUrl;

      // Nếu có ảnh mới được chọn, upload nó
      if (_imageFile != null) {
        // (Tùy chọn) Xóa ảnh cũ trong storage trước khi upload ảnh mới
        if (widget.post['image_url'] != null) {
          final oldImagePath = Uri.parse(
            widget.post['image_url'],
          ).pathSegments.last;
          await supabase.storage.from('post_images').remove([oldImagePath]);
        }

        final userId = supabase.auth.currentUser!.id;
        final imageExtension = _imageFile!.path.split('.').last.toLowerCase();
        final imagePath =
            '$userId/posts/${DateTime.now().millisecondsSinceEpoch}.$imageExtension';

        if (kIsWeb) {
          final imageBytes = await _imageFile!.readAsBytes();
          await supabase.storage
              .from('post_images')
              .uploadBinary(imagePath, imageBytes);
        } else {
          await supabase.storage
              .from('post_images')
              .upload(imagePath, File(_imageFile!.path));
        }
        imageUrl = supabase.storage.from('post_images').getPublicUrl(imagePath);
      }

      await supabase
          .from('posts')
          .update({'content': _contentController.text, 'image_url': imageUrl})
          .eq('id', widget.post['id']);

      _showSnackBar('Cập nhật thành công!');
      Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('Lỗi cập nhật: ${e.toString()}');
    } finally {
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
        title: const Text('Chỉnh sửa bài đăng'),
        actions: [
          if (!_isLoading)
            TextButton(onPressed: _submitPost, child: const Text('Lưu')),
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
                    ),
                    formSpacer,
                    // Hiển thị ảnh mới hoặc ảnh cũ
                    if (_imageFile != null)
                      kIsWeb
                          ? Image.network(_imageFile!.path, fit: BoxFit.contain)
                          : Image.file(
                              File(_imageFile!.path),
                              fit: BoxFit.contain,
                            )
                    else if (_existingImageUrl != null)
                      Image.network(_existingImageUrl!, fit: BoxFit.contain),
                    formSpacer,
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Thay đổi ảnh'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
