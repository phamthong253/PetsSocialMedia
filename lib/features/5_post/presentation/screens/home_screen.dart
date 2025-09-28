import 'package:flutter/material.dart';
import 'package:quanlythucung/features/5_post/presentation/widgets/post_card_widget.dart';
import 'package:quanlythucung/main.dart';

// --- HẰNG SỐ MÀU SẮC GIẢ ĐỊNH ---
const Color primaryTextColor = Colors.black;
const Color accentColor = Color(0xFF42A5F5);
// Màu nền nhạt cho Post Card (Giả định màu xanh nhạt giống pet card)
const Color postCardBackgroundColor = Color(0xFFE8F5E9); // Ví dụ: Màu xanh lá cây nhạt (Green 50)
const Color postCardMarginColor = Colors.white; // Màu nền giữa các card
// ------------------------------------


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Stream<List<Map<String, dynamic>>> _postStream;

  @override
  void initState() {
    super.initState();
    _initializePostStream();
  }

  void _initializePostStream() {
    _postStream = supabase
        .from('posts_with_meta')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: postCardMarginColor, // Nền trắng giữa các post
      appBar: AppBar(
        title: const Text(
            'Bảng tin',
            style: TextStyle(
                color: primaryTextColor,
                fontWeight: FontWeight.bold
            )
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: accentColor),
      ),
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
            color: accentColor,
            onRefresh: () async {
              setState(() {
                _initializePostStream();
              });
            },
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                // <<< CẬP NHẬT GIAO DIỆN MỖI ITEM Ở ĐÂY >>>
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0), // Khoảng cách giữa các bài đăng
                  child: Card(
                    // SỬ DỤNG MÀU NỀN XANH NHẠT
                    color: accentColor,
                    elevation: 0, // Độ nổi
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15), // Bo góc
                    ),
                    child: PostCard(post: posts[index], onPostDeleted: () { setState(() {
                      _initializePostStream(); // Tái tạo Stream để fetch lại dữ liệu mới nhất
                    }); },),
                  ),
                );
                // <<< KẾT THÚC CẬP NHẬT >>>
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add_post');

          if (result == true) {
            setState(() {
              _initializePostStream();
            });
          }
        },
        backgroundColor: accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}