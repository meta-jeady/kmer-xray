# XV TUNNEL 2.0

Client Android **VMess & VLESS uniquement** basé sur Xray-core.

## Fonctionnalités

- Support complet `vmess://` et `vless://`
- Champ **Host / SNI** optionnel (forcé si besoin)
- Payload / Transport Xray (WS, gRPC, TCP, XHTTP, Reality, Vision…)
- Mode VPN système (VpnService)
- Interface sombre moderne

## Compilation

```bash
flutter create . --platforms=android --org com.mtech --project-name xv_tunnel
# Puis remplace les fichiers fournis

flutter pub get
flutter build apk --release
