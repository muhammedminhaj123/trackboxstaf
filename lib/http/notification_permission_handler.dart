import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationPermissionHandler extends StatefulWidget {
  final Widget child;
  final Function(bool) onPermissionChanged;

  const NotificationPermissionHandler({
    Key? key,
    required this.child,
    required this.onPermissionChanged,
  }) : super(key: key);

  @override
  State<NotificationPermissionHandler> createState() =>
      _NotificationPermissionHandlerState();
}

class _NotificationPermissionHandlerState
    extends State<NotificationPermissionHandler> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    if (Platform.isAndroid) {
      // For Android 13+
      PermissionStatus status = await Permission.notification.status;
      if (status.isDenied) {
        // Automatically request permission if not determined yet
        status = await Permission.notification
            .request(); // Update status after request
      }
      widget.onPermissionChanged(status.isGranted);
    } else {
      // iOS permissions are handled by firebase_messaging usually
      final status = await Permission.notification.status;
      widget.onPermissionChanged(status.isGranted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
