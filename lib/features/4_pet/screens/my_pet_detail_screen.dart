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
  String? _ownerPhone;
  bool _isMyPet = false;

  @override
  void initState() {
    super.initState();
    _currentPet = widget.pet;

    final currentUserId = supabase.auth.currentUser?.id;
    final petOwnerId = widget.pet['owner_id'];

    _isMyPet = currentUserId != null && currentUserId == petOwnerId;

    _fetchOwnerInfo(petOwnerId);

    if (_isMyPet) {
      _eventsStream = supabase
          .from('pet_events')
          .stream(primaryKey: ['id'])
          .eq('pet_id', widget.pet['id'])
          .order('event_time', ascending: true);
    } else {
      _eventsStream = const Stream.empty();
    }
  }

  Future<void> _fetchOwnerInfo(String? ownerId) async {
    if (ownerId == null) return;
    try {
      final data = await supabase
          .from('profiles')
          .select('name, phone')
          .eq('id', ownerId)
          .single();
      if (mounted) {
        setState(() {
          _ownerName = data['name'] ?? 'Chủ sở hữu ẩn danh';
          _ownerPhone = data['phone'];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ownerName = 'Không tìm thấy tên';
          _ownerPhone = null;
        });
      }
    }
  }

  void _showContactDialog(BuildContext context) {
    String title;
    String message;

    if (_ownerPhone != null && _ownerPhone!.isNotEmpty) {
      title = 'Thông tin liên hệ';
      message = "Số điện thoại của $_ownerName:\n\n${_ownerPhone!}";
    } else {
      title = 'Không thể liên hệ';
      message = "$_ownerName chưa cung cấp số điện thoại công khai, hoặc thông tin này đã bị ẩn.";
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Đóng'),
            ),
            if (_ownerPhone != null && _ownerPhone!.isNotEmpty)
              TextButton(
                onPressed: () {
                  // TODO: Triển khai chức năng gọi điện thoại
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Gọi điện'),
              ),
          ],
        );
      },
    );
  }

  // <<< HÀM ĐIỀU HƯỚNG SANG MÀN HÌNH CHỈNH SỬA >>>
  Future<void> _navigateToEditScreen() async {
    final result = await Navigator.pushNamed(
      context,
      '/edit_pet', // Giả định route này đã được định nghĩa
      arguments: _currentPet,
    );

    // Nếu kết quả trả về là Map (dữ liệu pet đã cập nhật), refresh UI
    if (result is Map<String, dynamic>) {
      setState(() {
        _currentPet = result;
        // Có thể cần refresh lại stream sự kiện nếu thông tin pet thay đổi
        // Tùy thuộc vào logic của bạn.
      });
    }
  }
  // <<< KẾT THÚC HÀM ĐIỀU HƯỚNG >>>

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _currentPet['name'] ?? 'Chi tiết thú cưng',
          style: const TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        // <<< THÊM NÚT CHỈNH SỬA CHO CHỦ SỞ HỮU >>>
        actions: [
          if (_isMyPet)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
              onPressed: _navigateToEditScreen,
            ),
        ],
        // <<< KẾT THÚC THÊM NÚT >>>
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Ảnh thú cưng ---
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
              _buildNameAndLocation(),
              const SizedBox(height: 30),
              _buildPetInfoRow(),
              const SizedBox(height: 20),
              // --- 4. Thông tin Chủ ---
              _buildOwnerInfo(),
              const SizedBox(height: 20),
              _buildDescription(),
              const SizedBox(height: 20),

              // --- 6 & 7. Lịch hẹn và Nút hành động ---
              if (_isMyPet) ...[
                _buildEventsSection(),
                const SizedBox(height: 20),
                _buildActionButton(),
                const SizedBox(height: 20),
              ] else ...[
                _buildContactButton(), // Nút Liên hệ cho người dùng khác
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildNameAndLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row( // Thêm Row để hiển thị nút Edit nếu là pet của mình
          children: [
            Expanded(
              child: Text(
                _currentPet['name'] ?? 'Pet Name',
                style: const TextStyle(
                  fontSize: 25,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // TÙY CHỌN: Nếu bạn muốn nút Edit ở Body thay vì AppBar, dùng đoạn này:
            // if (_isMyPet)
            //   IconButton(icon: const Icon(Icons.edit, color: Colors.black), onPressed: _navigateToEditScreen),
          ],
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
              Text(
                _isMyPet ? "Bạn là chủ sở hữu" : "Chủ sở hữu thú cưng",
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
        // Nút Chat/Liên hệ
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

  Widget _buildContactButton() {
    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: petAccentColor,
      ),
      child: Center(
        child: TextButton.icon(
          onPressed: () => _showContactDialog(context),
          icon: const Icon(Icons.phone, color: Colors.white),
          label: const Text(
            'Liên hệ Chủ sở hữu',
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