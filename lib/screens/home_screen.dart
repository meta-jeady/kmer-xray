import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/v2ray_config.dart';
import '../services/vpn_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _serverController = TextEditingController();
  final TextEditingController _hostController = TextEditingController();

  bool _isConnected = false;
  bool _isConnecting = false;
  final List<String> _logs = ["System Ready. Config loaded."];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _addLog(String msg) {
    setState(() {
      final time = DateTime.now().toString().split(' ')[1].substring(0, 8);
      _logs.add("[$time] $msg");
    });
  }

  void _showSnackBar(String message,
      {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: isError
            ? Colors.redAccent
            : isSuccess
                ? const Color(0xFF00E676)
                : const Color(0xFF1E293B),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _toggleVpn() async {
    if (_isConnecting) return;

    if (_isConnected) {
      setState(() => _isConnecting = true);
      _addLog("Stopping Xray...");
      try {
        await VpnService.stop();
        setState(() {
          _isConnected = false;
          _isConnecting = false;
        });
        _addLog("XV TUNNEL stopped");
        _showSnackBar("🔴 XV TUNNEL déconnecté");
      } catch (e) {
        setState(() => _isConnecting = false);
        _addLog("❌ Erreur d'arrêt : $e");
        _showSnackBar("Erreur de déconnexion", isError: true);
      }
      return;
    }

    final config = V2RayConfig.fromLink(_serverController.text);
    if (config == null) {
      _addLog("❌ Lien invalide. Utilise uniquement vmess:// ou vless://");
      _tabController.animateTo(1);
      _showSnackBar("Lien VMess / VLESS requis", isError: true);
      return;
    }

    setState(() => _isConnecting = true);
    _addLog("Protocole détecté : ${config.protocol.toUpperCase()}");
    _addLog("Remark : ${config.remark}");

    final host = _hostController.text.trim();
    if (host.isNotEmpty) {
      _addLog("Host/SNI forcé : $host");
    }

    _addLog("Demande permission VPN...");
    _addLog("Démarrage Xray core...");

    try {
      final success = await VpnService.start(
        config.rawLink,
        customHost: host.isEmpty ? null : host,
      );

      if (success) {
        setState(() {
          _isConnected = true;
          _isConnecting = false;
        });
        _addLog("✅ Connecté en ${config.protocol.toUpperCase()}");
        _addLog("XV TUNNEL ready to use");
        _showSnackBar("🟢 XV TUNNEL Connecté!", isSuccess: true);
      } else {
        setState(() => _isConnecting = false);
        _addLog("❌ Échec de connexion");
      }
    } catch (e) {
      setState(() => _isConnecting = false);
      _addLog("❌ Connection Failed : $e");
      _showSnackBar("Échec de connexion", isError: true);
    }
  }

  void _importConfig() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController importController = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Import Config",
            style: TextStyle(
                color: Color(0xFF00E676), fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: importController,
            style: const TextStyle(color: Colors.white),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "vmess://... ou vless://...",
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("Annuler", style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                final text = importController.text.trim();
                if (text.isNotEmpty) {
                  setState(() => _serverController.text = text);
                  _addLog("Config importée");
                }
                Navigator.pop(context);
              },
              child: const Text("Importer",
                  style: TextStyle(color: Color(0xFF00E676))),
            ),
          ],
        );
      },
    );
  }

  void _exportConfig() {
    final text = _serverController.text.trim();
    if (text.isEmpty) {
      _showSnackBar("Aucune config à exporter", isError: true);
      return;
    }
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar("Config copiée dans le presse-papiers", isSuccess: true);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _isConnected
        ? const Color(0xFF00E676)
        : _isConnecting
            ? Colors.orangeAccent
            : const Color(0xFFFF2A55);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F17),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFF00E676), size: 24),
            SizedBox(width: 8),
            Text(
              "XV TUNNEL",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white70),
            tooltip: "Import Config",
            onPressed: _importConfig,
          ),
          IconButton(
            icon: const Icon(Icons.upload_rounded, color: Colors.white70),
            tooltip: "Export Config",
            onPressed: _exportConfig,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            onSelected: (value) {
              if (value == 'clear_logs') {
                setState(() => _logs.clear());
                _showSnackBar("Logs effacés");
              } else if (value == 'clear_config') {
                setState(() {
                  _serverController.clear();
                  _hostController.clear();
                });
                _addLog("Configuration cleared");
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'clear_logs', child: Text("Clear Logs")),
              const PopupMenuItem(
                  value: 'clear_config', child: Text("Clear Config")),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00E676),
          labelColor: const Color(0xFF00E676),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: "VLESS / VMESS"),
            Tab(text: "LOGS"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ========== ONGLET PRINCIPAL ==========
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Status
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: statusColor, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isConnected
                            ? "CONNECTED"
                            : _isConnecting
                                ? "CONNECTING..."
                                : "DISCONNECTED",
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Bouton Power
                GestureDetector(
                  onTap: _toggleVpn,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: statusColor, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.power_settings_new_rounded,
                          size: 48,
                          color: statusColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isConnected ? "STOP" : "START",
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Zone de configuration
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lien
                      const Row(
                        children: [
                          Icon(Icons.link_rounded,
                              color: Color(0xFF00E676), size: 18),
                          SizedBox(width: 8),
                          Text(
                            "VLESS / VMESS LINK",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _serverController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                        maxLines: 3,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          hintText: "vmess://... ou vless://...",
                          hintStyle: const TextStyle(color: Colors.white24),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Host / SNI
                      const Row(
                        children: [
                          Icon(Icons.dns_rounded,
                              color: Color(0xFF00E676), size: 18),
                          SizedBox(width: 8),
                          Text(
                            "HOST / SNI (optionnel)",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _hostController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          hintText: "Ex: www.microsoft.com",
                          hintStyle: const TextStyle(color: Colors.white24),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.language,
                              color: Colors.white38, size: 20),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Laisse vide si le lien contient déjà le Host/SNI",
                        style: TextStyle(color: Colors.white30, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                if (!_isConnected && !_isConnecting)
                  const Text(
                    "Colle un lien vmess:// ou vless:// puis appuie sur START",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
              ],
            ),
          ),

          // ========== ONGLET LOGS ==========
          Container(
            color: const Color(0xFF080C14),
            padding: const EdgeInsets.all(14),
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                Color logColor = Colors.white70;
                if (log.contains("Connected") ||
                    log.contains("ready to use") ||
                    log.contains("✅")) {
                  logColor = const Color(0xFF00E676);
                } else if (log.contains("Stopping") ||
                    log.contains("stopped")) {
                  logColor = const Color(0xFFFFD54F);
                } else if (log.contains("Starting") ||
                    log.contains("Démarrage") ||
                    log.contains("Protocole") ||
                    log.contains("Host")) {
                  logColor = Colors.cyanAccent;
                } else if (log.contains("❌")) {
                  logColor = Colors.redAccent;
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    log,
                    style: TextStyle(
                      color: logColor,
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _serverController.dispose();
    _hostController.dispose();
    super.dispose();
  }
}
