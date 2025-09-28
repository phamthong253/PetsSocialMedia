import 'package:flutter/material.dart';
import 'package:quanlythucung/core/utils/utils.dart';
import 'package:quanlythucung/features/5_post/presentation/widgets/post_card_widget.dart';
import 'package:quanlythucung/main.dart';

class DetailPostScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  const DetailPostScreen({super.key, required this.post});

  @override
  State<DetailPostScreen> createState() => _DetailPostScreenState();
}

class _DetailPostScreenState extends State<DetailPostScreen> {
  // Biến Stream không cần late nếu được khởi tạo trong initState
  late Stream<List<Map<String, dynamic>>> _commentsStream;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Khởi tạo lần đầu
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

      // === FIX: TÁI TẠO STREAM SAU KHI GỬI BÌNH LUẬN THÀNH CÔNG ===
      if (mounted) {
        setState(() {
          _initializeCommentsStream(); // Tái tạo Stream
        });
      }
      // ==========================================================

    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Lỗi khi gửi bình luận: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bình luận')),
      body: Column(
        children: [
          PostCard(post: widget.post, onPostDeleted: () {  },),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
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
                if (comments == null || comments.isEmpty) {
                  return const Center(child: Text('Chưa có bình luận nào.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          comment['author_avatar'] ??
                              'https://i.pravatar.cc/150?u=${comment['author_id']}',
                        ),
                      ),
                      title: Text(
                        comment['author_name'] ?? 'Vô danh',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(comment['content'] ?? ''),
                    );
                  },
                );
              },
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