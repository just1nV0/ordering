import 'package:flutter/material.dart';
import 'dart:async';

class CheckoutLoadingDialog extends StatefulWidget {
  final VoidCallback onComplete;
  
  const CheckoutLoadingDialog({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  CheckoutLoadingDialogState createState() => CheckoutLoadingDialogState();
  static CheckoutLoadingDialogState? of(BuildContext context) {
    return context.findAncestorStateOfType<CheckoutLoadingDialogState>();
  }
}

class CheckoutLoadingDialogState extends State<CheckoutLoadingDialog>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late AnimationController _checkController;
  late AnimationController _dotsController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isSuccess = false;
  int _countdown = 10;
  Timer? _countdownTimer;
  String _dotsText = '';
  Timer? _dotsTimer;

  @override
  void initState() {
    super.initState();
    
    _loadingController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    ));
    
    _startDotsAnimation();
  }
  
  void _startDotsAnimation() {
    int dots = 0;
    _dotsTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted && !_isSuccess) {
        setState(() {
          dots = (dots + 1) % 4;
          _dotsText = '.' * dots;
        });
      }
    });
  }

  void showSuccess() {
    if (!mounted) return;
    setState(() {
      _isSuccess = true;
    });
    
    _dotsTimer?.cancel();
    _loadingController.stop();
    _checkController.forward();
    
    _startCountdown();
  }
  
  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _countdown--;
        });
      }
      
      if (_countdown <= 0) {
        timer.cancel();
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _checkController.dispose();
    _dotsController.dispose();
    _countdownTimer?.cancel();
    _dotsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: GestureDetector(
        onTap: _isSuccess ? widget.onComplete : null,
        child: Material(
          color: Colors.black54,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.symmetric(horizontal: 20), // Reduced margin for more width
              constraints: const BoxConstraints(
                minWidth: 300, // Ensure minimum width for consistency
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 80,
                    width: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (!_isSuccess)
                          RotationTransition(
                            turns: _loadingController,
                            child: const CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue,
                              ),
                            ),
                          ),
                        if (_isSuccess)
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Container(
                                height: 80,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isSuccess ? 'Order Placed' : 'Loading$_dotsText',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (_isSuccess) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Redirecting in $_countdown seconds',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}