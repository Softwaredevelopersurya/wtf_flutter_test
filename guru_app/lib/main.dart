import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guru_app/shared/shared.dart';
import 'providers/guru_view_model.dart';
import 'presentation/onboarding_screen.dart';
import 'presentation/guru_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GuruApp());
}

class GuruApp extends StatelessWidget {
  const GuruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GuruViewModel()..initialize(),
      child: Consumer<GuruViewModel>(
        builder: (context, vm, _) {
          return MaterialApp(
            title: 'WTF Guru App (Member)',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.guruTheme,
            home: vm.isLoading
                ? const Scaffold(
                    body: Center(child: CircularProgressIndicator(color: AppColors.guruPrimary)),
                  )
                : (vm.isOnboarded ? const GuruHomeScreen() : const OnboardingScreen()),
          );
        },
      ),
    );
  }
}

