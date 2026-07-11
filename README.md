# P2P Arbitrage Monitor

Aplicación Flutter para monitoreo de precios P2P y detección de oportunidades de arbitraje entre Binance, Bybit y BingX.

## Características

- 📊 **Panel de Precios en Tiempo Real**: Precios de compra/venta USDT en cada exchange con filtro por moneda fiat (VES, ARS, COP, MXN, etc.)
- 🔄 **Detector de Arbitraje**: Cálculo automático de spreads entre exchanges con ganancia potencial y ruta de arbitraje
- 📈 **Historial de Precios**: Gráficos comparativos de los 3 exchanges con exportación CSV
- 🔔 **Notificaciones**: Alertas configurables cuando el spread supera un umbral
- 🌙 **Tema Oscuro/Claro**: Interfaz con soporte para ambos temas

## Capturas de Pantalla

| Precios | Arbitraje | Historial |
|---------|-----------|-----------|
| Panel de precios en tiempo real con filtro fiat | Detección de oportunidades con spread % | Gráficos comparativos entre exchanges |

## Instalación

### Prerrequisitos
- Flutter SDK 3.44+ 
- Android SDK (compileSdk 36, minSdk 24)
- Android NDK 28.2.13676358
- JDK 17

### Compilar

```bash
# Clonar el repositorio
git clone https://github.com/<username>/p2p-arbitrage-monitor.git
cd p2p-arbitrage-monitor

# Instalar dependencias
flutter pub get

# Compilar APK de release
flutter build apk --release

# El APK se encuentra en:
# build/app/outputs/flutter-apk/app-release.apk
```

### Compilar con Android Studio
1. Abrir el proyecto en Android Studio
2. Sincronizar Gradle
3. Seleccionar dispositivo/emulador
4. Ejecutar `flutter run`

## Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada de la aplicación
├── models/
│   └── p2p_models.dart       # Modelos de datos (P2PListing, ArbitrageOpportunity, etc.)
├── services/
│   └── p2p_api_service.dart  # Servicios API de Binance, Bybit, BingX
├── providers/
│   └── p2p_provider.dart     # State management con Provider
├── db/
│   └── database_service.dart # Almacenamiento local con SharedPreferences
├── screens/
│   ├── home_screen.dart      # Pantalla principal con tabs
│   ├── prices_screen.dart    # Panel de precios en tiempo real
│   ├── arbitrage_screen.dart # Detector de arbitraje
│   ├── history_screen.dart   # Historial con gráficos
│   └── settings_screen.dart  # Configuración y ajustes
└── utils/
    └── theme_provider.dart   # Gestión de tema oscuro/claro
```

## APIs Utilizadas

| Exchange | Endpoint | Método |
|----------|----------|--------|
| Binance P2P | `https://p2p.binance.com/bapi/c2c/v2/friendly/c2c/adv/search` | POST |
| Bybit P2P | `https://api2.bybit.com/fiat/otc/item/online` | POST |
| BingX P2P | `https://open-api.bingx.com/api/v1/p2p/adv/search` | POST |

### Limitaciones de las APIs

- **CORS**: Las APIs P2P no tienen habilitado CORS, por lo que no funcionan desde navegador web
- **Rate Limiting**: Se recomienda un intervalo mínimo de 15 segundos entre consultas
- **Autenticación**: Las consultas de listados P2P no requieren autenticación
- **BingX**: El endpoint puede variar; se recomienda verificar la documentación actualizada

## Monedas Fiat Soportadas

VES, ARS, COP, MXN, BRL, CLP, PEN, UYU, CNY, INR, NGN, PKR, RUB, TRY, VND, IDR, THB, PHP, KRW, JPY, EUR, GBP, USD

## ⚠️ Descargo de Responsabilidad

Esta aplicación es una **HERRAMIENTA INFORMATIVA** y no constituye asesoría financiera. El arbitraje P2P conlleva riesgos significativos:

- **Riesgo de contraparte**: El vendedor puede no completar la transacción
- **Riesgo de precio**: Los precios fluctúan entre el momento de compra y venta
- **Riesgo regulatorio**: Las operaciones P2P pueden estar sujetas a regulaciones locales
- **Riesgo de liquidez**: Los montos disponibles pueden no ser suficientes
- **Costos ocultos**: Comisiones de transferencia bancaria, spread cambiario, impuestos

Las ganancias mostradas son **TEÓRICAS** y no garantizadas. Opere bajo su propia responsabilidad.

## Licencia

MIT License
