import 'package:flutter/material.dart';
import 'package:quanlythucung/Utils/const.dart';
import 'package:quanlythucung/main.dart';

import '../data/models/pet_model.dart';

class MyPetsScreen extends StatefulWidget {
  const MyPetsScreen({super.key});

  @override
  State<MyPetsScreen> createState() => _MyPetsScreenState();
}

class _MyPetsScreenState extends State<MyPetsScreen> {
  int _selectedCategory = 0;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _getUserName();
  }

  // Lấy tên người dùng để hiển thị lời chào
  Future<void> _getUserName() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('profiles')
          .select('name')
          .eq('id', userId)
          .single();
      if (mounted) {
        setState(() {
          _userName = data['name'] ?? 'bạn';
        });
      }
    } catch (e) {
      // Bỏ qua lỗi nếu không lấy được tên
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Sử dụng SingleChildScrollView để tránh lỗi overflow
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildJoinCommunityCard(),
              const SizedBox(height: 30),
              _buildSectionHeader("Danh mục"),
              const SizedBox(height: 25),
              _buildCategoryItems(),
              const SizedBox(height: 20),
              _buildSectionHeader("Thú cưng của tôi"),
              const SizedBox(height: 10),
              _buildPetList(),
              const SizedBox(height: 20), // Thêm khoảng đệm cuối trang
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add_pet');
          if (result == true) {
            setState(() {}); // Làm mới danh sách sau khi thêm
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Widget xây dựng phần Header
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey.shade200,
            child: const Icon(Icons.person, color: Colors.grey),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Xin chào,",
                style: TextStyle(fontSize: 16, color: black.withOpacity(0.6)),
              ),
              Text(
                _userName ?? '...',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: black,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black12.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.search),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black12.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
    );
  }

  // Widget xây dựng thẻ "Join Community"
  Widget _buildJoinCommunityCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: blueBackground,
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tham gia Cộng đồng\nYêu động vật",
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.2,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Chip(
                    label: Text(
                      "Tham gia ngay",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    backgroundColor: Colors.amber,
                  )
                ],
              ),
            ),
            Image.network(
              'assets/pets-image/cat4.png', // Ảnh mèo nền trong suốt
              height: 140,
            )
          ],
        ),
      ),
    );
  }

  // Widget xây dựng tiêu đề cho mỗi phần
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: black,
            ),
          ),
          const Spacer(),
          const Text(
            "Xem tất cả",
            style: TextStyle(fontSize: 12, color: Colors.amber),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Colors.amber,
            ),
            child: const Icon(
              Icons.keyboard_arrow_right_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Widget xây dựng danh sách các danh mục
  Widget _buildCategoryItems() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(
          categories.length,
              (index) => Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(categories[index]),
              selected: _selectedCategory == index,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? index : -1;
                });
              },
              backgroundColor: Colors.black12.withOpacity(0.05),
              selectedColor: buttonColor,
              labelStyle: TextStyle(
                color: _selectedCategory == index ? Colors.white : black,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide.none,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            ),
          ),
        ),
      ),
    );
  }

  // Widget xây dựng danh sách thú cưng từ Supabase
  Widget _buildPetList() {
    final userId = supabase.auth.currentUser!.id;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.from('pets').select().eq('owner_id', userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
        }
        final pets = snapshot.data;
        if (pets == null || pets.isEmpty) {
          // === PHẦN CHỈNH SỬA QUAN TRỌNG NẰM Ở ĐÂY ===
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bạn chưa có thú cưng nào.'),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result =
                      await Navigator.pushNamed(context, '/add_pet');
                      if (result == true) {
                        setState(() {}); // Làm mới danh sách sau khi thêm
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm thú cưng ngay'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return SizedBox(
          height: 280, // Chiều cao cố định cho danh sách ngang
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: pets.length,
            itemBuilder: (context, index) {
              return _buildPetCard(pets[index]);
            },
          ),
        );
      },
    );
  }

  // Widget xây dựng thẻ thông tin cho mỗi thú cưng
  Widget _buildPetCard(Map<String, dynamic> pet) {
    // Lấy màu ngẫu nhiên cho card
    final cardColor =
    Colors.primaries[pet['id'] % Colors.primaries.length].withOpacity(0.2);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/pet_detail', arguments: pet);
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              right: 0,
              child: pet['image_url'] != null
                  ? Image.network(
                pet['image_url'],
                height: 180,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.pets, size: 100, color: Colors.grey),
              )
                  : const Icon(Icons.pets, size: 100, color: Colors.grey),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet['name'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 20,
                      color: black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    pet['gender'] ?? 'N/A',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

