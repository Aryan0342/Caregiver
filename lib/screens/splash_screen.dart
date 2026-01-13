import 'package:flutter/material.dart';
import '../theme.dart';
import '../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));

    _animationController.forward();

    // Navigate after animation completes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App title
                  Text(
                    'Dag in beeld',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 42,
                          letterSpacing: 1.2,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  // Subtitle
                  Text(
                    'pictoreeksen',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.accentOrange,
                          fontWeight: FontWeight.w600,
                          fontSize: 28,
                          letterSpacing: 0.5,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 64),
                  
                  // Pictogram sequence
                  _buildPictogramSequence(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPictogramSequence() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // First pictogram - Alarm clock
        _buildPictogramCard(
          icon: Icons.access_time,
          color: Colors.red,
          label: 'Wakker worden',
        ),
        
        // Arrow
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            Icons.arrow_forward,
            color: AppTheme.primaryBlueDark,
            size: 28,
          ),
        ),
        
        // Second pictogram - Brushing teeth
        _buildPictogramCard(
          icon: Icons.cleaning_services,
          color: AppTheme.primaryBlue,
          label: 'Tanden poetsen',
        ),
        
        // Arrow
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            Icons.arrow_forward,
            color: AppTheme.primaryBlueDark,
            size: 28,
          ),
        ),
        
        // Third pictogram - Food
        _buildPictogramCard(
          icon: Icons.restaurant,
          color: Colors.orange,
          label: 'Ontbijten',
        ),
      ],
    );
  }

  Widget _buildPictogramCard({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      width: 110,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pictogram container - light blue rounded square
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueLight,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: 55,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
