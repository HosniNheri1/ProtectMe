import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:protectme/services/language_service.dart';

class SOSButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isActive;
  final bool isLoading;

  const SOSButton({
    super.key,
    required this.onPressed,
    required this.isActive,
    this.isLoading = false,
  });

  @override
  SOSButtonState createState() => SOSButtonState();
}

class SOSButtonState extends State<SOSButton> {
  bool _isPressed = false;
  Timer? _pressTimer;
  static const int PRESS_DURATION_MS = 2000; // 2 secondes
  int _pressProgress = 0;

  @override
  void dispose() {
    _pressTimer?.cancel();
    super.dispose();
  }

  void _startPress() {
    if (_isPressed) return;

    setState(() {
      _isPressed = true;
      _pressProgress = 0;
    });

    // Timer pour la progression
    _pressTimer?.cancel();
    _pressTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _pressProgress += (100 * 50 / PRESS_DURATION_MS).round();
      });

      if (_pressProgress >= 100) {
        timer.cancel();
        widget.onPressed();
        _resetPress();
      }
    });
  }

  void _cancelPress() {
    _pressTimer?.cancel();
    _resetPress();
  }

  void _resetPress() {
    if (!mounted) return;

    setState(() {
      _isPressed = false;
      _pressProgress = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startPress(),
      onTapUp: (_) => _cancelPress(),
      onTapCancel: _cancelPress,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: widget.isActive
                ? [
                    Color.fromARGB(255, 239, 6, 185),
                    Color.fromARGB(255, 245, 12, 245),
                  ]
                : [Colors.grey.shade400, Colors.grey.shade600],
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isActive
                  ? Color.fromARGB(255, 244, 4, 176).withAlpha(150)
                  : Colors.grey.withAlpha(100),
              blurRadius: 20,
              spreadRadius: 5,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Cercle de progression
            if (_isPressed)
              CircularProgressIndicator(
                value: _pressProgress / 100,
                strokeWidth: 8,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                backgroundColor: Colors.white.withAlpha(100),
              ),

            // Contenu principal
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(Icons.emergency, size: 50, color: Colors.white),

                SizedBox(height: 12),

                Text(
                  Provider.of<LanguageService>(context).t('sos'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  _isPressed
                      ? Provider.of<LanguageService>(context)
                            .t('hold_prompt')
                            .replaceFirst(
                              '{seconds}',
                              (PRESS_DURATION_MS / 1000).toStringAsFixed(0),
                            )
                      : Provider.of<LanguageService>(context).t('long_press'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withAlpha(230),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
