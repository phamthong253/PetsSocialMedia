import 'package:flutter/material.dart';
import 'package:quanlythucung/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Luôn gọi hàm _redirect sau khi frame đầu tiên được render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirect();
    });
  }

  Future<void> _redirect() async {
    // Đợi 1 chút để màn hình splash hiển thị (tùy chọn)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final session = supabase.auth.currentSession;

    if (session == null) {
      // Nếu chưa đăng nhập, chuyển đến màn hình đăng nhập
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      // Nếu đã đăng nhập, chuyển đến màn hình chính
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Giao diện đơn giản cho màn hình chờ
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Đang tải...'),
          ],
        ),
      ),
    );
  }
}
