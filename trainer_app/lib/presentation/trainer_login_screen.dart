import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';
import '../providers/trainer_view_model.dart';
import 'trainer_home_screen.dart';

class TrainerLoginScreen extends StatefulWidget {
  const TrainerLoginScreen({super.key});

  @override
  State<TrainerLoginScreen> createState() => _TrainerLoginScreenState();
}

class _TrainerLoginScreenState extends State<TrainerLoginScreen> {
  final TextEditingController _emailController = TextEditingController(text: 'aarav.trainer@wtf.fitness');
  final TextEditingController _nameController = TextEditingController(text: AppStrings.trainerSeedName);
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    final vm = context.read<TrainerViewModel>();

    const trainerUser = User(
      id: AppStrings.trainerSeedId,
      role: UserRole.trainer,
      name: AppStrings.trainerSeedName,
      email: 'aarav.trainer@wtf.fitness',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    );

    await vm.login(trainerUser);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TrainerHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: AppSpacing.paddingXl,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.trainerPrimary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sports_gymnastics_rounded, size: 40, color: AppColors.trainerPrimary),
                  ),
                  AppSpacing.gapV24,
                  const Text('Trainer Portal', style: AppTypography.h1, textAlign: TextAlign.center),
                  AppSpacing.gapV8,
                  Text(
                    'Lead Coach Management Console',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapV32,

                  // Profile Card
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
                        ),
                        AppSpacing.gapH12,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppStrings.trainerSeedName, style: AppTypography.bodyMediumSemiBold),
                              Text('aarav.trainer@wtf.fitness', style: AppTypography.caption),
                              AppSpacing.gapV4,
                              CustomBadge(text: 'Lead Coach', backgroundColor: AppColors.trainerPrimary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  AppSpacing.gapV32,

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.trainerPrimary),
                    icon: _isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.login_rounded),
                    label: const Text('Access Trainer Dashboard'),
                    onPressed: _isLoading ? null : _handleLogin,
                  ),
                ],
              ),
            ),
            const FloatingDevPanelButton(),
          ],
        ),
      ),
    );
  }
}



