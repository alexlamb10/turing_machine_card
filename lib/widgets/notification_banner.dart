import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../models/notification_state.dart';

class NotificationBanner extends StatefulWidget {
  final Widget child;
  final Function(AppNotification)? onNotificationTap;

  const NotificationBanner({
    super.key,
    required this.child,
    this.onNotificationTap,
  });

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _dismissTimer;
  AppNotification? _currentNotification;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _triggerToast(AppNotification notification) {
    _dismissTimer?.cancel();
    setState(() {
      _currentNotification = notification;
    });
    _controller.forward();

    _dismissTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        _dismissToast();
      }
    });
  }

  void _dismissToast() {
    _dismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        context.read<NotificationState>().dismissToast();
        setState(() {
          _currentNotification = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeToast = context.watch<NotificationState>().activeToast;

    if (activeToast != null && activeToast != _currentNotification) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _triggerToast(activeToast);
        }
      });
    }

    return Stack(
      children: [
        widget.child,
        if (_currentNotification != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: SlideTransition(
                position: _offsetAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _getBannerBgColor(_currentNotification!.type),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getBannerIcon(_currentNotification!.type),
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentNotification!.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currentNotification!.message,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              final notif = _currentNotification!;
                              _dismissToast();
                              widget.onNotificationTap?.call(notif);
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white24,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('View', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                            onPressed: _dismissToast,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getBannerBgColor(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return Colors.orange[800]!;
      case NotificationType.friendAccepted:
        return Colors.green[700]!;
      case NotificationType.newChallenge:
        return Colors.indigo[700]!;
      case NotificationType.challengeCompleted:
        return Colors.teal[700]!;
    }
  }

  IconData _getBannerIcon(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return Icons.person_add;
      case NotificationType.friendAccepted:
        return Icons.check_circle;
      case NotificationType.newChallenge:
        return Icons.emoji_events;
      case NotificationType.challengeCompleted:
        return Icons.military_tech;
    }
  }
}
