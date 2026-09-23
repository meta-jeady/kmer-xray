import 'package:flutter_vless/flutter_vless.dart';

class V2RayConfig {
  final String rawLink;
  final String protocol; // "vmess" | "vless"
  final String remark;

  V2RayConfig({
    required this.rawLink,
    required this.protocol,
    required this.remark,
  });

  static V2RayConfig? fromLink(String input) {
    try {
      final link = input.trim();
      if (link.isEmpty) return null;

      final parsed = FlutterVless.parse(link);
      final protocol = parsed.protocol.toLowerCase();

      if (protocol != 'vmess' && protocol != 'vless') {
        return null;
      }

      return V2RayConfig(
        rawLink: link,
        protocol: protocol,
        remark: parsed.remark.isNotEmpty ? parsed.remark : 'XV Server',
      );
    } catch (_) {
      return null;
    }
  }
}
