import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Hàm formatTimeAgo được chuyển vào đây để giải quyết lỗi import
String formatTimeAgo(DateTime time) {
  final now = DateTime.now();
  final difference = now.difference(time);

  if (difference.inSeconds < 60) {
    return '${difference.inSeconds} giây trước';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} phút trước';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} giờ trước';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} ngày trước';
  } else {
    // Nếu hơn 1 tuần, hiển thị ngày/tháng
    return DateFormat('dd/MM/yyyy').format(time);
  }
}

class CommentCard extends StatelessWidget {
  final Map<String, dynamic> comment;
  const CommentCard({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    final authorName = comment['author_name'] ?? 'Người dùng';
    final authorAvatar = comment['author_avatar'];
    final content = comment['content'];
    final createdAt = DateTime.parse(comment['created_at']);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: authorAvatar != null
                ? NetworkImage(authorAvatar)
                : null,
            child: authorAvatar == null
                ? const Icon(Icons.person, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(content),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatTimeAgo(createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
