import 'package:flutter/material.dart';
import 'package:quanlythucung/features/5_post/presentation/widgets/post_card_widget.dart';
import 'package:quanlythucung/main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Stream<List<Map<String, dynamic>>> _postStream;

  @override
  void initState() {
    super.initState();
    _postStream = supabase
        .from('posts_with_meta')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bảng tin'), centerTitle: true),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _postStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final posts = snapshot.data;
          if (posts == null || posts.isEmpty) {
            return const Center(
              child: Text('Chưa có bài đăng nào. Hãy là người đầu tiên!'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              // The stream will automatically handle refreshing the data
              setState(() {});
            },
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return PostCard(post: posts[index]);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // === PHẦN CHỈNH SỬA QUAN TRỌNG NẰM Ở ĐÂY ===
          // 1. Đợi kết quả trả về từ màn hình add_post
          final result = await Navigator.pushNamed(context, '/add_post');

          // 2. Nếu kết quả trả về là 'true' (tức là đăng bài thành công)
          if (result == true) {
            // 3. Gọi setState để build lại UI, đảm bảo StreamBuilder lấy dữ liệu mới nhất
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

