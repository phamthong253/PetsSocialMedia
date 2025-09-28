import 'package:flutter/material.dart';
import 'package:quanlythucung/features/5_post/presentation/widgets/post_card_widget.dart';
import 'package:quanlythucung/main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  // <<< THAY ĐỔI: Bỏ 'late final' để cho phép gán lại Stream >>>
  Stream<List<Map<String, dynamic>>>? _myPostsStream;
  // <<< KẾT THÚC THAY ĐỔI >>>
  final String _userId = supabase.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _getProfile();
    // Vẫn gọi khởi tạo lần đầu
    _initializeMyPostsStream();
  }

  // Hàm tạo/tái tạo Stream
  void _initializeMyPostsStream() {
    // Gán lại biến Stream mới
    _myPostsStream = supabase
        .from('posts_with_meta')
        .stream(primaryKey: ['id'])
        .eq('author_id', _userId) // Lọc theo ID của người dùng hiện tại
        .order('created_at', ascending: false); // Sắp xếp từ mới nhất
  }

  Future<void> _getProfile() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', _userId)
          .single();
      setState(() {
        _profile = data;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lấy thông tin: ${error.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (error) {
      // Xử lý lỗi
    }
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  // <<< HÀM REFRESH UI VÀ TÁI TẠO STREAM >>>
  void _refreshPostsList() {
    // Tái tạo stream để buộc StreamBuilder fetch lại dữ liệu
    setState(() {
      _initializeMyPostsStream();
    });
  }
  // <<< KẾT THÚC HÀM REFRESH >>>

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ'),
        actions: [
          IconButton(onPressed: _signOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _profile?['avatar_url'] != null
                          ? NetworkImage(_profile!['avatar_url'])
                          : null,
                      child: _profile?['avatar_url'] == null
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _profile?['name'] ?? 'Chưa có tên',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(_profile?['email'] ?? ''),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/edit_profile',
                        );
                        if (result == true) {
                          _getProfile();
                        }
                      },
                      child: const Text('Chỉnh sửa hồ sơ'),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    Text(
                      'Bài viết của tôi',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: StreamBuilder<List<Map<String, dynamic>>>(
          // Dùng biến đã bỏ 'final'
          stream: _myPostsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Lỗi: ${snapshot.error}'));
            }
            final myPosts = snapshot.data;
            if (myPosts == null || myPosts.isEmpty) {
              return const Center(
                child: Text('Bạn chưa có bài đăng nào.'),
              );
            }
            return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: myPosts.length,
              itemBuilder: (context, index) {
                return PostCard(
                  post: myPosts[index],
                  // <<< TRUYỀN HÀM REFRESH VÀO CALLBACK >>>
                  onPostDeleted: _refreshPostsList,
                  // <<< KẾT THÚC TRUYỀN CALLBACK >>>
                );
              },
            );
          },
        ),
      ),
    );
  }
}