import 'package:flutter/material.dart';
import 'package:quanlythucung/features/5_post/presentation/widgets/comment_cart.dart';
import 'package:quanlythucung/features/5_post/presentation/widgets/post_card_widget.dart';
import 'package:quanlythucung/main.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  late final Stream<List<Map<String, dynamic>>> _commentStream;
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _commentStream = supabase
        .from('comments_with_author')
        .stream(primaryKey: ['id'])
        .eq('post_id', widget.post['id'])
        .order('created_at', ascending: true);
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      return;
    }
    setState(() => _isPostingComment = true);
    try {
      await supabase.from('comments').insert({
        'post_id': widget.post['id'],
        'author_id': supabase.auth.currentUser!.id,
        'content': content,
      });
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi bình luận: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPostingComment = false);
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bài đăng')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  PostCard(post: widget.post),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Bình luận',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _commentStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final comments = snapshot.data;
                      if (comments == null || comments.isEmpty) {
                        return const Center(
                          child: Text('Chưa có bình luận nào.'),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          return CommentCard(comment: comments[index]);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: Colors.grey[800]!)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Viết bình luận...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _isPostingComment
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(),
                  )
                : IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _submitComment,
                    color: Theme.of(context).primaryColor,
                  ),
          ],
        ),
      ),
    );
  }
}
