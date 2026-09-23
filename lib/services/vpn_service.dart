import 'dart:convert';
import 'package:flutter_vless/flutter_vless.dart';

class VpnService {
  static final FlutterVless _core = FlutterVless(
    onStatusChanged: (status) {
      // Tu peux logger ou mettre à jour l’UI ici si besoin
      // print('Status: ${status.connectionState}');
    },
  );

  static Future<void> initialize() async {
    await _core.initializeVless(
      notificationIconResourceType: 'mipmap',
      notificationIconResourceName: 'ic_launcher',
    );
  }

  /// Démarre le VPN avec un lien vmess:// ou vless://
  /// [customHost] permet de forcer le Host / SNI
  static Future<bool> start(String shareLink, {String? customHost}) async {
    final link = shareLink.trim().toLowerCase();

    // On vérifie uniquement VMess et VLESS
    if (!link.startsWith('vmess://') && !link.startsWith('vless://')) {
      throw Exception('Seuls les protocoles VMess et VLESS sont supportés');
    }

    final parsed = FlutterVless.parse(shareLink);
    String config = parsed.getFullConfiguration();

    if (customHost != null && customHost.trim().isNotEmpty) {
      config = _injectHost(config, customHost.trim());
    }

    final granted = await _core.requestPermission();
    if (!granted) {
      throw Exception('Permission VPN refusée');
    }

    await _core.startVless(
      remark: parsed.remark.isNotEmpty ? parsed.remark : 'XV TUNNEL',
      config: config,
      proxyOnly: false,
    );

    return true;
  }

  static Future<void> stop() async {
    await _core.stopVless();
  }

  /// Injecte le Host / SNI dans la config Xray
  static String _injectHost(String configJson, String host) {
    try {
      final Map<String, dynamic> config = jsonDecode(configJson);
      final outbounds = config['outbounds'] as List<dynamic>?;
      if (outbounds == null || outbounds.isEmpty) return configJson;

      final outbound = outbounds[0] as Map<String, dynamic>;
      final streamSettings =
          outbound['streamSettings'] as Map<String, dynamic>? ?? {};

      // WebSocket → headers.Host
      if (streamSettings['network'] == 'ws') {
        final wsSettings =
            streamSettings['wsSettings'] as Map<String, dynamic>? ?? {};
        final headers = wsSettings['headers'] as Map<String, dynamic>? ?? {};
        headers['Host'] = host;
        wsSettings['headers'] = headers;
        streamSettings['wsSettings'] = wsSettings;
      }

      // HTTPUpgrade / XHTTP
      if (streamSettings['network'] == 'httpupgrade' ||
          streamSettings['network'] == 'xhttp') {
        final key = streamSettings['network'] == 'httpupgrade'
            ? 'httpupgradeSettings'
            : 'xhttpSettings';
        final httpSettings =
            streamSettings[key] as Map<String, dynamic>? ?? {};
        final headers = httpSettings['headers'] as Map<String, dynamic>? ?? {};
        headers['Host'] = host;
        httpSettings['headers'] = headers;
        streamSettings[key] = httpSettings;
      }

      // TLS → serverName
      if (streamSettings['security'] == 'tls') {
        final tlsSettings =
            streamSettings['tlsSettings'] as Map<String, dynamic>? ?? {};
        tlsSettings['serverName'] = host;
        streamSettings['tlsSettings'] = tlsSettings;
      }

      // Reality → serverName
      if (streamSettings['security'] == 'reality') {
        final realitySettings =
            streamSettings['realitySettings'] as Map<String, dynamic>? ?? {};
        realitySettings['serverName'] = host;
        streamSettings['realitySettings'] = realitySettings;
      }

      outbound['streamSettings'] = streamSettings;
      outbounds[0] = outbound;
      config['outbounds'] = outbounds;

      return jsonEncode(config);
    } catch (e) {
      print('Erreur injection Host: $e');
      return configJson;
    }
  }
}
