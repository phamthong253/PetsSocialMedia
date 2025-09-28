import 'package:flutter/material.dart';
import 'package:quanlythucung/features/1_onboarding/screens/splash_screen.dart';
import 'package:quanlythucung/features/2_auth/screens/login_screen.dart';
import 'package:quanlythucung/features/2_auth/screens/register_screen.dart';
import 'package:quanlythucung/features/3_profile/screens/profile_detail_screen.dart';
import 'package:quanlythucung/features/4_pet/screens/add_edit_event_pet_screen.dart';
import 'package:quanlythucung/features/4_pet/screens/my_pet_detail_screen.dart';
import 'package:quanlythucung/features/4_pet/screens/add_my_pet_screen.dart';
import 'package:quanlythucung/features/4_pet/screens/edit_pet_screen.dart';
import 'package:quanlythucung/features/5_post/presentation/screens/add_post_screen.dart';
import 'package:quanlythucung/features/5_post/presentation/screens/detail_post_screen.dart';
import 'package:quanlythucung/features/5_post/presentation/screens/edit_post_screen.dart';
import 'package:quanlythucung/features/main_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nhdnloaknskxggywhesb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5oZG5sb2FrbnNreGdneXdoZXNiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg4NTQyNDQsImV4cCI6MjA3NDQzMDI0NH0.4Z3Wzx_6h31-uW9OB04fOpewF9l_NmoyxD7i42jF8E0',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Social App',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF121212),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const MainLayout(),
        '/edit_profile': (_) => const EditProfileScreen(),
        //'/add_pet': (_) => const AddEditPetScreen(),
        '/add_post': (_) => const AddPostScreen(),
        // === TUYẾN ĐƯỜNG MỚI ĐỂ CHỈNH SỬA BÀI ĐĂNG ===
        '/edit_post': (context) {
          final post =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return EditPostScreen(post: post);
        },
        // ===========================================
        '/pet_detail': (context) {
          final pet =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return PetDetailScreen(pet: pet);
        },
        '/add_pet_event': (context) {
          final petId = ModalRoute.of(context)!.settings.arguments as int;
          return AddEditEventScreen(petId: petId);
        },
        '/add_pet': (_) => const AddEditPetScreen(),
        '/edit_pet': (context) {
          final pet =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return EditPetScreen(pet: pet);
        },
        '/detail_post': (context) {
          // Lấy dữ liệu bài đăng được truyền từ PostCard
          final post =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          // Trả về màn hình DetailPostScreen và truyền dữ liệu vào
          return DetailPostScreen(post: post);
        },
        'default': (_) =>
            const Scaffold(body: Center(child: Text('Không tìm thấy trang'))),
      },
    );
  }
}
