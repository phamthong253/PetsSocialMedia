import 'package:flutter/material.dart';
import 'package:quanlythucung/main.dart'; // Import Supabase client
// Bạn cần import PetDetailScreen ở đây, ví dụ:
// import 'package:quanlythucung/features/pet/screens/pet_detail_screen.dart';
// (Giả định PetDetailScreen của bạn đã được đặt tên là PetDetailScreen)


class UserPetsScreen extends StatelessWidget {
  final String authorId;
  final String authorName;

  const UserPetsScreen({
    super.key,
    required this.authorId,
    required this.authorName,
  });

  // Hàm fetch danh sách thú cưng của tác giả
  Future<List<Map<String, dynamic>>> _fetchUserPets() async {
    final response = await supabase
        .from('pets') // Giả định bảng thú cưng của bạn là 'pets'
        .select('*')
        .eq('owner_id', authorId);

    debugPrint('DEBUG: Author ID being queried: $authorId');
    debugPrint('DEBUG: Total pets received from DB: ${response.length}');
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thú cưng của $authorName'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUserPets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
          }
          final pets = snapshot.data;
          if (pets == null || pets.isEmpty) {
            return Center(
              child: Text('$authorName chưa đăng ký thú cưng nào.'),
            );
          }

          // Hiển thị danh sách thú cưng dạng lưới hoặc danh sách
          return ListView.builder(
            itemCount: pets.length,
            padding: const EdgeInsets.all(16.0),
            itemBuilder: (context, index) {
              final pet = pets[index];
              return PetCardWidget(pet: pet);
            },
          );
        },
      ),
    );
  }
}

// Widget đơn giản để minh họa Pet Card
class PetCardWidget extends StatelessWidget {
  final Map<String, dynamic> pet;
  const PetCardWidget({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: pet['image_url'] != null
              ? NetworkImage(pet['image_url'])
              : null,
          child: pet['image_url'] == null ? const Icon(Icons.pets) : null,
        ),
        title: Text(
          pet['name'] ?? 'Pet',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Giới tính: ${pet['gender'] ?? 'N/A'}, Cân nặng: ${pet['weight'] ?? 'N/A'} kg',
        ),
        // <<< THÊM ĐIỀU HƯỚNG VÀO TRANG CHI TIẾT >>>
        onTap: () {
          // Điều hướng đến PetDetailScreen và truyền dữ liệu thú cưng
          Navigator.pushNamed(
            context,
            '/pet_detail', // Route mà bạn đã định nghĩa cho PetDetailScreen
            arguments: pet,
          );
        },
        // <<< KẾT THÚC THÊM ĐIỀU HƯỚNG >>>
      ),
    );
  }
}