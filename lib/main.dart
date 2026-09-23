import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/vpn_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await VpnService.initialize();
  runApp(const XvTunnelApp());
}

class XvTunnelApp extends StatelessWidget {
  const XvTunnelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XV TUNNEL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0F17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          secondary: Color(0xFF00E676),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
