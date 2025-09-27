import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quanlythucung/main.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late int _likeCount;
  bool _isLiked =
      false; // Cần một cơ chế để xác định người dùng hiện tại đã thích hay chưa

  String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s trước';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post['like_count'] ?? 0;
    // TODO: Thêm logic để kiểm tra xem người dùng hiện tại đã like bài viết này chưa
    // Ví dụ: final currentUserId = supabase.auth.currentUser!.id;
    // _isLiked = (widget.post['liked_by'] as List?)?.contains(currentUserId) ?? false;
  }

  Future<void> _toggleLike() async {
    try {
      // Gọi RPC function trên Supabase
      await supabase.rpc(
        'toggle_like',
        params: {'post_id_input': widget.post['id']},
      );

      // Cập nhật giao diện ngay lập tức
      setState(() {
        if (_isLiked) {
          _likeCount--;
        } else {
          _likeCount++;
        }
        _isLiked = !_isLiked;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: ${e.toString()}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authorName = widget.post['author_name'] ?? 'Người dùng';
    final authorAvatar = widget.post['author_avatar'];
    final content = widget.post['content'];
    final imageUrl = widget.post['image_url'];
    final createdAt = DateTime.parse(widget.post['created_at']);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar và Tên
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: authorAvatar != null
                      ? NetworkImage(authorAvatar)
                      : null,
                  child: authorAvatar == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      formatTimeAgo(createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Content: Nội dung text
            if (content != null && content.isNotEmpty) Text(content),
            if (content != null && content.isNotEmpty)
              const SizedBox(height: 12),

            // Content: Hình ảnh
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 12),

            // Footer: Like, Comment
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : null,
                  ),
                  onPressed: _toggleLike,
                ),
                Text('$_likeCount'),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () {
                    // TODO: Điều hướng đến trang chi tiết bài đăng
                  },
                ),
                Text(widget.post['comment_count']?.toString() ?? '0'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
