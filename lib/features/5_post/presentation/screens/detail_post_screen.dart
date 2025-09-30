import 'package:flutter/material.dart';
import 'package:quanlythucung/core/utils/utils.dart';
import 'package:quanlythucung/features/5_post/presentation/widgets/post_card_widget.dart';
import 'package:quanlythucung/main.dart';
import 'package:intl/intl.dart'; // Cần import intl cho DateFormat

// Giả định PostCardState đã được import đúng

// <<< HÀM TIỆN ÍCH MỚI ĐỂ FORMAT THỜI GIAN >>>
// Thay đổi hàm formatTimeAgo thành hàm mới:
String formatTimeAgo(String? timestamp) {
  if (timestamp == null) return 'Không rõ thời gian';
  try {
    // 1. Parse thời gian từ Supabase và CHUYỂN NÓ VỀ UTC
    final dateTime = DateTime.parse(timestamp).toUtc();

    // 2. Lấy thời gian hiện tại VÀ CHUYỂN NÓ VỀ UTC
    final now = DateTime.now().toUtc();

    final difference = now.difference(dateTime); // Tính toán

    // Nếu thời gian vẫn bị âm sau khi chuẩn hóa, đó là do đồng hồ bị lỗi (hiếm)
    // Ta có thể kiểm tra và trả về 0 giây trước nếu giá trị là âm.
    if (difference.isNegative) {
      return 'Vừa xong';
    }

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} giây trước';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('HH:mm, dd/MM/yyyy').format(dateTime.toLocal());
    }
  } catch (e) {
    return 'Thời gian không hợp lệ';
  }
}
// <<< KẾT THÚC HÀM TIỆN ÍCH MỚI >>>

class DetailPostScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  const DetailPostScreen({super.key, required this.post});

  @override
  State<DetailPostScreen> createState() => _DetailPostScreenState();
}

class _DetailPostScreenState extends State<DetailPostScreen> {
  late Stream<List<Map<String, dynamic>>> _commentsStream;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCommentsStream();
  }

  void _initializeCommentsStream() {
    _commentsStream = supabase
        .from('comments_with_author')
        .stream(primaryKey: ['id'])
        .eq('post_id', widget.post['id'])
        .order('created_at', ascending: true);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _updatePostCommentCount(int count) {
    // Logic cập nhật số comment
    // (Giữ nguyên nếu bạn dùng GlobalKey để cập nhật PostCard)
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      showErrorSnackBar(context, 'Bạn cần đăng nhập để bình luận');
      return;
    }
    try {
      await supabase.from('comments').insert({
        'post_id': widget.post['id'],
        'author_id': userId,
        'content': content,
      });
      _commentController.clear();

      if (mounted) {
        setState(() {
          _initializeCommentsStream(); // Tái tạo Stream
        });
      }

    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Lỗi khi gửi bình luận: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bình luận')),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                PostCard(post: widget.post, onPostDeleted: () {  },),
                const Divider(height: 1, thickness: 1),

                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Bình luận',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _commentsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text("Lỗi tải bình luận: ${snapshot.error}"),
                      );
                    }
                    final comments = snapshot.data;

                    if (snapshot.hasData) {
                      // Gọi hàm cập nhật số comment nếu cần
                    }

                    if (comments == null || comments.isEmpty) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Text('Chưa có bình luận nào.'),
                      ));
                    }

                    return Column(
                      children: comments.map((comment) {

                        // <<< LẤY VÀ FORMAT THỜI GIAN >>>
                        final timeString = formatTimeAgo(comment['created_at'] as String?);
                        // <<< KẾT THÚC FORMAT THỜI GIAN >>>

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                              comment['author_avatar'] ??
                                  'https://i.pravatar.cc/150?u=${comment['author_id']}',
                            ),
                          ),
                          title: Row( // Sử dụng Row để đặt Tên và Thời gian
                            children: [
                              Text(
                                comment['author_name'] ?? 'Anonymous',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              // <<< HIỂN THỊ THỜI GIAN >>>
                              Text(
                                timeString,
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              // <<< KẾT THÚC HIỂN THỊ THỜI GIAN >>>
                            ],
                          ),
                          subtitle: Text(comment['content'] ?? ''),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Viết bình luận...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20.0)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _submitComment,
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}