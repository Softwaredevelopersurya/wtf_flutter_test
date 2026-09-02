import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';
import 'providers/trainer_view_model.dart';
import 'presentation/trainer_login_screen.dart';
import 'presentation/trainer_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TrainerApp());
}

class TrainerApp extends StatelessWidget {
  const TrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TrainerViewModel()..initialize(),
      child: Consumer<TrainerViewModel>(
        builder: (context, vm, _) {
          return MaterialApp(
            title: 'WTF Trainer App (Aarav Persona)',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.trainerTheme,
            home: vm.isLoading
                ? const Scaffold(
                    body: Center(child: CircularProgressIndicator(color: AppColors.trainerPrimary)),
                  )
                : (vm.currentUser != null ? const TrainerHomeScreen() : const TrainerLoginScreen()),
          );
        },
      ),
    );
  }
}


