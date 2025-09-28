// lib/features/5_post/presentation/functions/delete_post_function.dart

import 'package:flutter/material.dart';
import 'package:quanlythucung/core/utils/utils.dart';
import 'package:quanlythucung/main.dart';

Future<void> showDeleteConfirmationDialog(
    BuildContext context,
    String postId, // Nhận ID dưới dạng String
    String? imageUrl,
    VoidCallback? onDeleted,
    ) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Bạn có chắc chắn muốn xóa bài đăng này không?'),
              Text('Hành động này không thể hoàn tác.'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Hủy'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
            onPressed: () async {
              // Khởi tạo giá trị ID cần xóa
              final idToDelete = int.tryParse(postId); // <<< CHUYỂN NGƯỢC LẠI SANG INT

              if (idToDelete == null) {
                if (context.mounted) {
                  showErrorSnackBar(context, 'Lỗi: ID bài viết không hợp lệ.');
                }
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                return;
              }

              try {
                // Bước 1: Xóa ảnh khỏi Storage (Nếu có)
                if (imageUrl != null && imageUrl.isNotEmpty) {
                  const bucketName = 'pet_images';
                  final segment = '/storage/v1/object/public/$bucketName/';
                  final startIndex = imageUrl.indexOf(segment);

                  if (startIndex != -1) {
                    final pathInBucket = imageUrl.substring(startIndex + segment.length);
                    await supabase.storage.from(bucketName).remove([pathInBucket]);
                  }
                }

                // Bước 2: Xóa bài đăng khỏi database
                // Dùng giá trị đã chuyển đổi sang INT (idToDelete)
                await supabase.from('posts').delete().match({'id': idToDelete}); // <<< SỬA ĐỔI QUAN TRỌNG

                // Đóng hộp thoại
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }

                // BƯỚC 3: GỌI CALLBACK ĐỂ LÀM MỚI MÀN HÌNH GỐC
                if (onDeleted != null) {
                  onDeleted();
                }

                // Hiển thị thông báo thành công
                if (context.mounted) {
                  showSuccessSnackBar(context, 'Đã xóa bài đăng thành công.');
                }

              } catch (e) {
                if (context.mounted) {
                  showErrorSnackBar(context, 'Lỗi khi xóa bài đăng: $e');
                }
              }
            },
          ),
        ],
      );
    },
  );
}