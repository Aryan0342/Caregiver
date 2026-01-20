import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

/// Base PIN entry screen with large number buttons.
/// 
/// Provides a reusable PIN entry interface with:
/// - Large number buttons (0-9)
/// - Backspace button
/// - Visual feedback for entered digits
/// - No keyboard typing (buttons only)
class PinEntryScreen extends StatefulWidget {
  final String title;
  final String? subtitle;
  final int minLength;
  final int maxLength;
  final Function(String pin)? onPinComplete;
  final bool showBackButton;
  final String? errorMessage;
  final Function(String)? onError;
  final VoidCallback? onBack;
  final VoidCallback? onForgotPin;

  const PinEntryScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.minLength = 4,
    this.maxLength = 6,
    this.onPinComplete,
    this.showBackButton = true,
    this.errorMessage,
    this.onError,
    this.onBack,
    this.onForgotPin,
  });

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  String _enteredPin = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.errorMessage;
  }

  @override
  void didUpdateWidget(PinEntryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorMessage != oldWidget.errorMessage) {
      setState(() {
        _errorMessage = widget.errorMessage;
      });
    }
  }

  void _onNumberPressed(String number) {
    // Clear error when user starts typing
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
    if (_enteredPin.length < widget.maxLength) {
      setState(() {
        _enteredPin += number;
      });
      
      // Haptic feedback
      HapticFeedback.lightImpact();
      
      // Check if PIN is complete (exactly minLength)
      if (_enteredPin.length == widget.minLength && widget.onPinComplete != null) {
        // Small delay for visual feedback
        Future.delayed(const Duration(milliseconds: 200), () {
          widget.onPinComplete!(_enteredPin);
        });
      }
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
      HapticFeedback.lightImpact();
    }
  }

  void _clearPin() {
    setState(() {
      _enteredPin = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.showBackButton
          ? AppBar(
              title: Text(
                widget.title,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: AppTheme.primaryBlueLight, // Light blue header
              foregroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                color: Colors.white,
                onPressed: widget.onBack ?? () {
                  Navigator.of(context).pop();
                },
              ),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                  MediaQuery.of(context).padding.top - 
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Add top spacing to move content down
                const SizedBox(height: 80),

                // PIN dots display - use same blue as number buttons
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(widget.maxLength, (index) {
                          final isFilled = index < _enteredPin.length;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFilled ? AppTheme.primaryBlue : Colors.transparent,
                              border: Border.all(
                                color: AppTheme.primaryBlue,
                                width: 2,
                              ),
                            ),
                          );
                        }),
                      ),
                      // Error message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Number pad
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1: 1, 2, 3
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNumberButton('1'),
                          _buildNumberButton('2'),
                          _buildNumberButton('3'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Row 2: 4, 5, 6
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNumberButton('4'),
                          _buildNumberButton('5'),
                          _buildNumberButton('6'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Row 3: 7, 8, 9
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNumberButton('7'),
                          _buildNumberButton('8'),
                          _buildNumberButton('9'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Row 4: Trash, 0, Backspace
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            icon: Icons.delete_outline,
                            onPressed: _clearPin,
                            color: AppTheme.primaryBlue,
                          ),
                          _buildNumberButton('0'),
                          _buildActionButton(
                            icon: Icons.backspace_outlined,
                            onPressed: _onBackspacePressed,
                            color: AppTheme.primaryBlue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Forgot PIN link
                if (widget.onForgotPin != null)
                  TextButton(
                    onPressed: widget.onForgotPin,
                    child: const Text(
                      'Pincode vergeten?',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.primaryBlueLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return Material(
      color: AppTheme.surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: () => _onNumberPressed(number),
        borderRadius: BorderRadius.circular(16),
        splashColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
        highlightColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
        child: Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.normal,
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: AppTheme.surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 32,
            color: color,
          ),
        ),
      ),
    );
  }
}
