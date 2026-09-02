import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';
import '../providers/guru_view_model.dart';
import 'guru_home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Profile setup form state (pre-seeded as specified in assessment)
  final TextEditingController _nameController = TextEditingController(text: AppStrings.memberSeedName);
  final TextEditingController _emailController = TextEditingController(text: 'dk.member@wtf.fitness');
  String _selectedTrainerId = AppStrings.trainerSeedId;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    final vm = context.read<GuruViewModel>();
    await vm.completeOnboarding(
      name: name,
      email: email.isNotEmpty ? email : 'member@wtf.fitness',
      trainerId: _selectedTrainerId,
    );

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GuruHomeScreen()),
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
            Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    children: [
                      _buildSlide(
                        title: 'Welcome to WTF Fitness',
                        subtitle: 'Transform your body with AI-powered personalized training and 1-on-1 live video coaching.',
                        icon: Icons.fitness_center_rounded,
                        color: AppColors.guruPrimary,
                      ),
                      _buildSlide(
                        title: 'Real-Time Coaching & Calls',
                        subtitle: 'Direct chat with dedicated master trainers and seamless 100ms HD video sessions anytime.',
                        icon: Icons.video_camera_front_rounded,
                        color: const Color(0xFF00B4D8),
                      ),
                      _buildProfileSetupSlide(),
                    ],
                  ),
                ),

                // Bottom Page Indicators & Action Button
                Padding(
                  padding: AppSpacing.paddingLg,
                  child: Column(
                    children: [
                      if (_currentPage < 2) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            final isSelected = index == _currentPage;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isSelected ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.guruPrimary : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                              ),
                            );
                          }),
                        ),
                        AppSpacing.gapV24,
                        ElevatedButton(
                          onPressed: _nextPage,
                          child: const Text('Continue'),
                        ),
                      ] else ...[
                        ElevatedButton(
                          onPressed: _submitProfile,
                          child: const Text('Start My Journey'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const FloatingDevPanelButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: AppSpacing.paddingXl,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 72, color: color),
          ),
          AppSpacing.gapV32,
          Text(title, style: AppTypography.h1, textAlign: TextAlign.center),
          AppSpacing.gapV16,
          Text(
            subtitle,
            style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSetupSlide() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSpacing.gapV16,
          Text('Create Member Profile', style: AppTypography.h1),
          AppSpacing.gapV8,
          Text(
            'Confirm your profile details. (Pre-seeded as DK persona for assessment review)',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          AppSpacing.gapV24,

          // Name Field (prefilled DK)
          Text('Full Name', style: AppTypography.bodyMediumSemiBold),
          AppSpacing.gapV8,
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline),
              hintText: 'Enter your name',
            ),
          ),

          AppSpacing.gapV16,

          // Email Field
          Text('Email Address', style: AppTypography.bodyMediumSemiBold),
          AppSpacing.gapV8,
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.email_outlined),
              hintText: 'Enter email address',
            ),
          ),

          AppSpacing.gapV16,

          // Assigned Trainer
          Text('Assigned Coach', style: AppTypography.bodyMediumSemiBold),
          AppSpacing.gapV8,
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
                ),
                AppSpacing.gapH12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.trainerSeedName, style: AppTypography.bodyMediumSemiBold),
                      Text('Master Nutrition & Strength Specialist', style: AppTypography.caption),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: AppColors.guruPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
