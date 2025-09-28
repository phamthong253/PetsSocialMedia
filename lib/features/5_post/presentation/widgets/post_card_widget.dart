import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quanlythucung/core/utils/utils.dart';
import 'package:quanlythucung/features/5_post/data/models/delete_post.dart';
import 'package:quanlythucung/features/5_post/data/models/edit_post.dart';
import 'package:quanlythucung/main.dart';

// --- CÁC HÀM HỖ TRỢ AN TOÀN ---
bool _isValidUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  return Uri.tryParse(url)?.hasAbsolutePath ?? false;
}

String _formatTimestamp(String? timestamp) {
  if (timestamp == null) return 'Không rõ thời gian';
  try {
    final dateTime = DateTime.parse(timestamp);
    // Sử dụng logic formatTimeAgo đã được cung cấp trước đó
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
  } catch (e) {
    return timestamp;
  }
}
// ------------------------------------

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onPostDeleted;

  const PostCard({super.key, required this.post, required this.onPostDeleted});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isLiked = false;
  int _currentLikeCount = 0;
  int _currentCommentCount = 0; // <<< BIẾN STATE MỚI CHO COMMENT COUNT
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = supabase.auth.currentUser?.id;
    _currentLikeCount = widget.post['like_count'] ?? 0;
    _currentCommentCount = widget.post['comment_count'] ?? 0; // <<< KHỞI TẠO
    _checkIfLiked();
  }

  // Hàm kiểm tra xem người dùng hiện tại đã like bài đăng này chưa
  Future<void> _checkIfLiked() async {
    if (_currentUserId == null) return;
    try {
      final response = await supabase
          .from('likes')
          .select()
          .eq('post_id', widget.post['id'])
          .eq('user_id', _currentUserId!)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _isLiked = response != null;
        });
      }
    } catch (e) {
      // Bỏ qua lỗi ở đây
    }
  }

  // Hàm refresh dữ liệu bài viết gốc để cập nhật Like/Comment count
  Future<void> _refreshPostData() async {
    try {
      final newPostData = await supabase
          .from('posts_with_meta')
          .select('like_count, comment_count')
          .eq('id', widget.post['id'])
          .single();

      if (mounted) {
        setState(() {
          _currentLikeCount = newPostData['like_count'] ?? _currentLikeCount;
          _currentCommentCount = newPostData['comment_count'] ?? _currentCommentCount;
        });
      }
    } catch (e) {
      // Bỏ qua lỗi ở đây
    }
  }

  // Hàm xử lý khi người dùng bấm nút "tim"
  Future<void> _toggleLike() async {
    if (_currentUserId == null) {
      if (mounted)
        showErrorSnackBar(
          context,
          'Bạn cần đăng nhập để thực hiện hành động này.',
        );
      return;
    }

    // Cập nhật UI ngay lập tức (Optimistic Update)
    setState(() {
      _isLiked = !_isLiked;
      _currentLikeCount += _isLiked ? 1 : -1;
    });

    try {
      if (_isLiked) {
        await supabase.from('likes').insert({
          'post_id': widget.post['id'],
          'user_id': _currentUserId!,
        });
      } else {
        await supabase
            .from('likes')
            .delete()
            .eq('post_id', widget.post['id'])
            .eq('user_id', _currentUserId!);
      }
      // Không cần fetch lại ở đây vì chỉ cần update like count

    } catch (e) {
      // Nếu có lỗi từ Supabase, hoàn tác lại trạng thái UI và hiển thị lỗi
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _currentLikeCount += _isLiked ? 1 : -1;
        });
        showErrorSnackBar(context, 'Lỗi cập nhật lượt thích: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authorId = widget.post['author_id'];
    final bool isAuthor = _currentUserId != null && _currentUserId == authorId;

    final authorAvatarUrl = widget.post['author_avatar'] as String?;
    final authorName = widget.post['author_name'] as String? ?? 'Người dùng ẩn';
    final createdAt = _formatTimestamp(widget.post['created_at'] as String?);
    final content = widget.post['content'] as String? ?? '';
    final imageUrl = widget.post['image_url'] as String?;

    // (DEBUG print code đã được xóa để code gọn hơn)

    return Card(
      // Màu nền trắng và loại bỏ margin cũ
      color: Colors.white,
      margin: EdgeInsets.zero,
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: _isValidUrl(authorAvatarUrl)
                  ? NetworkImage(authorAvatarUrl!)
                  : null,
              child: !_isValidUrl(authorAvatarUrl)
                  ? const Icon(Icons.person, size: 24, color: Colors.grey)
                  : null,
            ),
            title: Text(
              authorName,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            subtitle: Text(
              createdAt,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            trailing: isAuthor
                ? PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onSelected: (value) async {
                if (value == 'edit') {
                  navigateToEditPostScreen(context, widget.post);
                } else if (value == 'delete') {
                  await showDeleteConfirmationDialog(
                    context,
                    widget.post['id'].toString(),
                    imageUrl,
                        () { if (widget.onPostDeleted != null) {
    widget.onPostDeleted!();}},
                  );
                }
              },
              itemBuilder: (BuildContext context) =>
              <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Chỉnh sửa'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: Text(
                      'Xóa',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            )
                : null,
          ),
          if (content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
              child: Text(content, style: const TextStyle(color: Colors.black)),
            ),
          if (_isValidUrl(imageUrl))
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Nút Like
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.grey,
                  ),
                  onPressed: _toggleLike,
                ),
                Text(
                    _currentLikeCount.toString(),
                    style: const TextStyle(color: Colors.black)
                ),
                const SizedBox(width: 16),

                // Nút Comment (Điều hướng và Cập nhật Comment Count)
                InkWell(
                  onTap: () {
                    // Chuyển sang màn hình chi tiết và đợi kết quả
                    Navigator.pushNamed(
                      context,
                      '/detail_post',
                      arguments: widget.post,
                    ).then((_) {
                      // <<< CẬP NHẬT COMMENT COUNT KHI QUAY LẠI >>>
                      _refreshPostData();
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.comment_outlined, color: Colors.grey),
                        const SizedBox(width: 8),
                        // <<< HIỂN THỊ SỐ COMMENT TỪ BIẾN STATE >>>
                        Text(
                            _currentCommentCount.toString(),
                            style: const TextStyle(color: Colors.black)
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}