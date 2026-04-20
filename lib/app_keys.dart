import 'package:flutter/material.dart';

/// Globaler Key für den Root-ScaffoldMessenger, damit Snackbars z. B. aus den
/// Einstellungen auch auf dem Gerät zuverlässig angezeigt werden.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
