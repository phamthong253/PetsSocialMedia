// lib/features/5_post/presentation/functions/edit_post_function.dart

import 'package:flutter/material.dart';

// Hàm này sẽ điều hướng đến màn hình EditPostScreen
// và truyền vào dữ liệu của bài đăng cần sửa.
void navigateToEditPostScreen(
  BuildContext context,
  Map<String, dynamic> postData,
) {
  // Giả sử bạn có một route tên là '/edit_post' đã được định nghĩa
  // và màn hình EditPostScreen có thể nhận 'postData' làm argument.
  Navigator.pushNamed(context, '/edit_post', arguments: postData);
}
