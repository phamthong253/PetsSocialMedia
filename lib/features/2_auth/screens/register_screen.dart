import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quanlythucung/main.dart';
import 'package:quanlythucung/core/utils/utils.dart';

// Đây là một hằng số giả định cho khoảng cách (formSpacer),
// vì nó không được định nghĩa trong file bạn cung cấp.
const formSpacer = SizedBox(height: 20);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rePasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          data: {'name': _nameController.text.trim()},
        );

        if (mounted) {
          if (response.user != null) {
            showSuccessSnackBar(
              context,
              'Đăng ký thành công! Vui lòng kiểm tra email để xác thực.',
            );
            Navigator.of(context).pop();
          }
        }
      } on AuthException catch (error) {
        if (mounted) {
          showErrorSnackBar(context, error.message);
        }
      } catch (error) {
        if (mounted) {
          showErrorSnackBar(context, 'Đã xảy ra lỗi không mong muốn.');
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
    _emailController.dispose();
    _passwordController.dispose();
    _rePasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // --- TÊN (Cập nhật validation) ---
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Tên hiển thị'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên của bạn';
                      }
                      if (value.trim().length < 2) {
                        return 'Tên phải có ít nhất 2 ký tự';
                      }

                      // *** QUY TẮC MỚI: Cấm ký tự đặc biệt ***
                      final nameRegex = RegExp(r'^[a-zA-Z0-9\s]+$');
                      if (!nameRegex.hasMatch(value.trim())) {
                        return 'Tên không được chứa ký tự đặc biệt';
                      }

                      return null;
                    },
                  ),
                  formSpacer,
                  // --- EMAIL ---
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập địa chỉ email';
                      }
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Địa chỉ email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  formSpacer,
                  // --- MẬT KHẨU ---
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Mật khẩu'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      if (value.length < 8) {
                        return 'Mật khẩu phải có ít nhất 8 ký tự';
                      }
                      if (!value.contains(RegExp(r'[0-9]'))) {
                        return 'Mật khẩu cần ít nhất 1 chữ số';
                      }
                      if (!value.contains(RegExp(r'[A-Z]'))) {
                        return 'Mật khẩu cần ít nhất 1 chữ cái in hoa';
                      }
                      return null;
                    },
                  ),
                  formSpacer,
                  // --- NHẬP LẠI MẬT KHẨU ---
                  TextFormField(
                    controller: _rePasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Nhập lại mật khẩu',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập lại mật khẩu';
                      }
                      if (value != _passwordController.text) {
                        return 'Mật khẩu xác nhận không khớp';
                      }
                      return null;
                    },
                  ),
                  formSpacer,
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _signUp,
                    child: const Text('Đăng ký'),
                  ),
                  formSpacer,
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Đã có tài khoản? Đăng nhập'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}