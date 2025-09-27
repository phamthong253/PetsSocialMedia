import 'package:flutter/material.dart';

// Một khoảng trống cố định để dùng giữa các widget trong form
const formSpacer = SizedBox(height: 16.0);

// Hiển thị một SnackBar báo lỗi
void showErrorSnackBar(BuildContext context, String message) {
  // Đảm bảo context vẫn còn tồn tại trước khi hiển thị SnackBar
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );
}

// Hiển thị một SnackBar báo thành công
void showSuccessSnackBar(BuildContext context, String message) {
  // Đảm bảo context vẫn còn tồn tại trước khi hiển thị SnackBar
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.green),
  );
}
