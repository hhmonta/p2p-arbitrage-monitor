# P2P Arbitrage Monitor

Monitor de precios P2P USDT y detector de arbitraje entre Binance, Bybit y BingX.

## Características

- **Panel de Precios en Tiempo Real**: Precios de compra/venta USDT en Binance, Bybit y BingX
- **Filtros de Moneda Fiat**: VES, ARS, COP, MXN, BRL, CLP, PEN, USD
- **Detector de Arbitraje**: Calcula spreads entre exchanges y estima ganancia neta
- **Historial de Precios**: Gráficos de línea con datos históricos (24h, 3d, 7d, 30d)
- **Exportar CSV**: Exporta datos históricos a formato CSV
- **Notificaciones Push**: Alertas configurables para oportunidades de arbitraje
- **Tema Oscuro/Claro**: Interfaz con soporte para tema oscuro y claro
- **Auto-actualización**: Actualización automática cada 10-60 segundos
- **Optimización de Batería**: Pausa actualizaciones cuando la app está en segundo plano

## Capturas de Pantalla

| Precios | Arbitraje | Historial |
|---------|-----------|-----------|
| *Panel de precios* | *Oportunidades* | *Gráficos* |

## Requisitos Técnicos

- Flutter 3.22+
- Dart 3.0+
- Android SDK 21+ (Android 5.0 Lollipop)
- iOS 12+ (si se compila para iOS)

## Instalación

### Desde Código Fuente

```bash
# Clonar el repositorio
git clone https://github.com/hhmonta/p2p-arbitrage-monitor.git
cd p2p-arbitrage-monitor

# Instalar dependencias
flutter pub get

# Ejecutar en modo debug
flutter run

# Construir APK de producción
flutter build apk --release
```

### Descargar APK

Descarga el APK más reciente desde [GitHub Releases](https://github.com/hhmonta/p2p-arbitrage-monitor/releases) o desde los artifacts de GitHub Actions.

## APIs Utilizadas

| Exchange | Endpoint | Método | Notas |
|----------|----------|--------|-------|
| **Binance** | `p2p.binance.com/bapi/c2c/v2/friendly/c2c/adv/search` | POST | API interna del frontend web |
| **Bybit** | `api2.bybit.com/fiat/otc/item/online` | POST | API interna del frontend web |
| **BingX** | `api-app.qq-os.com/api/c2c/v3/advert/list` | POST | Requiere headers firmados; puede no funcionar sin autenticación |

## ⚠️ Limitaciones de API

- Los endpoints P2P son **APIs internas** usadas por los frontends web de los exchanges
- Pueden cambiar sin aviso previo
- Tienen rate limits que varían por exchange
- **BingX** requiere un header `sign` generado con HMAC-SHA256; puede no funcionar sin él
- Las restricciones CORS impiden acceso directo desde navegador; se requiere un proxy server o acceso desde app móvil
- La precisión de datos depende de la disponibilidad y tiempo de respuesta de cada API

## ⚠️ Aviso de Riesgo

Las oportunidades de arbitraje mostradas son **estimaciones**. Los costos de transferencia, tiempos de movimiento de fondos, comisiones de retiro, fluctuaciones de precio durante la transferencia, y liquidez disponible pueden afectar significativamente la rentabilidad real. Esta app es **solo para fines informativos** y no constituye asesoramiento financiero. Opera bajo tu propio riesgo.

## Estructura del Proyecto

```
lib/
├── main.dart              # Entry point
├── app.dart               # App widget with theme toggle
├── models/
│   ├── p2p_ad.dart        # P2P advertisement model
│   ├── arbitrage_opportunity.dart  # Arbitrage opportunity model
│   ├── price_record.dart  # Historical price record
│   └── notification_config.dart    # Notification settings
├── services/
│   ├── api_service.dart   # Main API orchestrator
│   ├── binance_service.dart  # Binance P2P API
│   ├── bybit_service.dart    # Bybit P2P API
│   ├── bingx_service.dart    # BingX P2P API
│   ├── arbitrage_service.dart # Arbitrage calculations
│   ├── database_service.dart  # SQLite storage
│   └── notification_service.dart # Local notifications
├── screens/
│   ├── home_screen.dart   # Main screen with tabs
│   ├── prices_screen.dart # Real-time price panel
│   ├── arbitrage_screen.dart # Arbitrage detector
│   ├── history_screen.dart  # Price history & charts
│   └── settings_screen.dart # App configuration
├── widgets/
│   ├── price_card.dart    # P2P ad display card
│   ├── arbitrage_card.dart # Arbitrage opportunity card
│   ├── skeleton_loader.dart # Loading animation
│   ├── fiat_filter_chip.dart # Currency filter chip
│   └── price_chart.dart   # Historical price chart
├── theme/
│   └── app_theme.dart     # Dark/light theme definitions
└── utils/
    ├── constants.dart     # App constants
    └── formatters.dart    # Formatting utilities
```

## Configuración de Notificaciones

1. Ir a **Ajustes** → **Notificaciones**
2. Activar **Alertas de arbitraje**
3. Configurar el **Umbral de spread mínimo** (por defecto 1%)
4. Seleccionar las **Monedas para notificar**
5. Ajustar el **Enfriamiento entre notificaciones** (mínimo 5 minutos)

## Licencia

MIT License - Ver [LICENSE](LICENSE) para más detalles.
