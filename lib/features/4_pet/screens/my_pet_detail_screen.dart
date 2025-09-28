import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quanlythucung/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- HẰNG SỐ MÀU SẮC GIẢ ĐỊNH ---
const Color petPrimaryColor = Color(0xFF5AD498);
const Color petAccentColor = Color(0xFFFF9800);
const Color petDetailBox1 = Color(0xFF63A4FF);
const Color petDetailBox2 = Color(0xFFFFCC80);
const Color petDetailBox3 = Color(0xFF81C784);
const Color petButtonColor = Color(0xFF42A5F5);
// ------------------------------------

class PetDetailScreen extends StatefulWidget {
  final Map<String, dynamic> pet;
  const PetDetailScreen({super.key, required this.pet});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  Map<String, dynamic> _currentPet = {};
  late final Stream<List<Map<String, dynamic>>> _eventsStream;
  String _ownerName = 'Chủ sở hữu';

  @override
  void initState() {
    super.initState();
    _currentPet = widget.pet;

    final user = supabase.auth.currentUser;
    if (user != null && user.userMetadata != null) {
      _ownerName = user.userMetadata!['name'] ?? 'Chủ sở hữu';
    }

    _eventsStream = supabase
        .from('pet_events')
        .stream(primaryKey: ['id'])
        .eq('pet_id', widget.pet['id'])
        .order('event_time', ascending: true);
  }

  // Phương thức navigateToEditScreen đã bị xóa do yêu cầu xóa nút Edit

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      // ĐẶT MÀU NỀN CỦA SCAFFOLD LÀ MÀU TRẮNG
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _currentPet['name'] ?? 'Chi tiết thú cưng',
          style: const TextStyle(color: Colors.black), // Đặt màu chữ cho AppBar
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        // XÓA BỎ NÚT CHỈNH SỬA (ICON BÚT CHÌ) BẰNG CÁCH KHÔNG ĐỊNH NGHĨA 'actions'
        actions: const [],
        // ĐẶT MÀU NỀN CỦA APPBAR LÀ MÀU TRẮNG
        backgroundColor: Colors.white,
        elevation: 0, // Xóa bỏ bóng dưới AppBar
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Ảnh thú cưng (Nằm trực tiếp trong body) ---
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    _currentPet['image_url'] ?? 'placeholder_url',
                    height: size.height * 0.35,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --- 2. Tên và Vị trí ---
              _buildNameAndLocation(),

              const SizedBox(height: 30),

              // --- 3. Thông tin chi tiết (Sex, Weight, Vaccination Status) ---
              _buildPetInfoRow(),

              const SizedBox(height: 20),

              // --- 4. Thông tin Chủ ---
              _buildOwnerInfo(),

              const SizedBox(height: 20),

              // --- 5. Mô tả ---
              _buildDescription(),

              const SizedBox(height: 20),

              // --- 6. Lịch hẹn sắp tới ---
              _buildEventsSection(),

              const SizedBox(height: 20),

              // --- 7. Nút hành động chính ---
              _buildActionButton(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- HÀM HỖ TRỢ ĐÃ ĐƯỢC ĐỊNH NGHĨA LẠI ---

  // Tên và Vị trí (Không có nút Edit)
  Widget _buildNameAndLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentPet['name'] ?? 'Pet Name',
          style: const TextStyle(
            fontSize: 25,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, color: petDetailBox1, size: 20),
            Text(
              _currentPet['location'] ?? 'Vị trí không rõ',
              style: TextStyle(
                color: Colors.black.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Hàng thông tin chi tiết
  Widget _buildPetInfoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMoreInfoBox(
          petDetailBox1,
          petDetailBox1.withOpacity(0.2),
          "Giới tính",
          _currentPet['gender'] ?? 'N/A',
        ),
        _buildMoreInfoBox(
          petDetailBox2,
          petDetailBox2.withOpacity(0.2),
          "Cân nặng",
          '${_currentPet['weight'] ?? 'N/A'} KG',
        ),
        _buildMoreInfoBox(
          petDetailBox3,
          petDetailBox3.withOpacity(0.2),
          "Tiêm chủng",
          _currentPet['vaccination_status'] ?? 'N/A',
        ),
      ],
    );
  }

  // Box thông tin chi tiết
  Widget _buildMoreInfoBox(Color pawColor, Color backgroundColr, String title, String value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Positioned(
            bottom: -20,
            right: 0,
            child: Transform.rotate(
              angle: 12,
              child: Image.network(
                'https://clipart-library.com/images/rTnrpap6c.png',
                color: pawColor.withOpacity(0.4),
                height: 55,
              ),
            ),
          ),
          Container(
            height: 100,
            width: MediaQuery.of(context).size.width * 0.28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: backgroundColr,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Thông tin Chủ (WonerInfo)
  Widget _buildOwnerInfo() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey,
          child: Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _ownerName,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Chủ sở hữu thú cưng",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: petDetailBox3.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.chat_outlined,
            color: petDetailBox1,
            size: 16,
          ),
        ),
      ],
    );
  }

  // Mô tả
  Widget _buildDescription() {
    final descriptionText = _currentPet['introduction'] ?? 'Chưa có mô tả.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Giới thiệu",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black54
          ),
        ),
        const SizedBox(height: 8),
        Text(
          descriptionText,
          textAlign: TextAlign.justify,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  // Lịch hẹn và Nút hành động
  Widget _buildEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lịch hẹn sắp tới',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _eventsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Chưa có lịch hẹn nào.'));
            }
            final events = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final eventTime = DateTime.parse(event['event_time']);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(event['event_name']),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy, hh:mm a').format(eventTime),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: petButtonColor,
      ),
      child: Center(
        child: TextButton.icon(
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/add_pet_event',
              arguments: _currentPet['id'],
            );
          },
          icon: const Icon(Icons.add_circle, color: Colors.white),
          label: const Text(
            'Thêm sự kiện',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}