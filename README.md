# GPS Telemetry - Monitoramento de Telemetria GPS em Tempo Real

Uma aplicação Flutter para monitoramento de telemetria GPS em tempo real, desenvolvida com arquitetura MVVM usando flutter_modular.

## 📱 Sobre o Projeto

Esta aplicação permite o rastreamento e monitoramento de dados de telemetria GPS em tempo real, incluindo:

- **Rastreamento GPS** em tempo real com alta precisão
- **Sensores de movimento** (acelerômetro, giroscópio)
- **Bússola digital** para orientação
- **Mapas interativos** com Google Maps
- **Histórico de sessões** com visualização detalhada
- **Exportação de dados** em formato CSV
- **Armazenamento local** com SQLite

## 🏗️ Arquitetura

O projeto utiliza **arquitetura MVVM (Model-View-ViewModel)** com:

- **flutter_modular** para injeção de dependência e roteamento
- **Provider** para gerenciamento de estado
- **Separação clara** entre camadas de apresentação, lógica de negócio e dados

## 🚀 Tecnologias Utilizadas

### Framework
- **Flutter**: 3.35.6
- **Dart**: 3.9.2

### Principais Dependências

| Dependência | Versão | Descrição |
|-------------|--------|-----------|
| `flutter_modular` | ^6.3.4 | Arquitetura MVVM e injeção de dependência |
| `provider` | ^6.1.2 | Gerenciamento de estado |
| `geolocator` | ^13.0.1 | Localização GPS e velocidade |
| `sensors_plus` | ^6.0.1 | Sensores de aceleração |
| `flutter_compass` | ^0.8.0 | Bússola digital |
| `google_maps_flutter` | ^2.9.0 | Mapas interativos |
| `sqflite` | ^2.4.1 | Banco de dados local |
| `permission_handler` | ^11.3.1 | Gerenciamento de permissões |
| `share_plus` | ^10.1.2 | Compartilhamento de dados |
| `csv` | ^6.0.0 | Exportação em CSV |

## 📋 Pré-requisitos

### Sistema
- **Flutter SDK**: 3.35.6 ou superior
- **Dart SDK**: 3.9.2 ou superior
- **Android Studio** ou **VS Code** com extensões Flutter
- **Git** para controle de versão

### Ferramentas Recomendadas
- **FVM (Flutter Version Management)** para gerenciar versões do Flutter
- **Android SDK** (API level 21+) para desenvolvimento Android
- **Xcode** (para desenvolvimento iOS - apenas macOS)

### APIs Necessárias
- **Google Maps API Key** (obrigatório)
- **Google Services** configurado (Firebase - opcional)

## 🛠️ Configuração do Ambiente

### 1. Instalar Flutter
```bash
# Usando FVM (recomendado)
fvm install 3.35.6
fvm use 3.35.6

# Ou instalar diretamente
# Baixe o Flutter SDK em: https://flutter.dev/docs/get-started/install
```

### 2. Verificar Instalação
```bash
fvm flutter doctor
```

### 3. Configurar Google Maps API

#### Android
1. Obtenha uma API Key no [Google Cloud Console](https://console.cloud.google.com/)
2. Edite `android/app/src/main/AndroidManifest.xml`:
```xml
<application>
    <meta-data android:name="com.google.android.geo.API_KEY"
               android:value="SUA_API_KEY_AQUI"/>
</application>
```

#### iOS
1. Edite `ios/Runner/AppDelegate.swift`:
```swift
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("SUA_API_KEY_AQUI")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## 🚀 Como Executar

### 1. Clonar o Repositório
```bash
git clone https://github.com/PimentelDiogo/gps_telemetry.git
cd gps_telemetry/gps_telemetry
```

### 2. Instalar Dependências
```bash
fvm flutter pub get
```

### 3. Configurar Permissões

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Este app precisa de acesso à localização para rastreamento GPS.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Este app precisa de acesso à localização para rastreamento GPS.</string>
```

### 4. Executar a Aplicação
```bash
# Debug
fvm flutter run

# Release
fvm flutter run --release

# Dispositivo específico
fvm flutter devices
fvm flutter run -d <device_id>
```

## 📱 Funcionalidades

### 🏠 Tela Principal
- Início/parada de sessões de rastreamento
- Visualização de dados em tempo real
- Acesso rápido ao histórico

### 📊 Telemetria em Tempo Real
- **GPS**: Latitude, longitude, altitude, velocidade
- **Sensores**: Aceleração X/Y/Z, rotação
- **Bússola**: Direção magnética
- **Estatísticas**: Distância percorrida, tempo decorrido

### 🗺️ Visualização de Mapas
- Mapa interativo com Google Maps
- Trajetória em tempo real
- Marcadores de início/fim
- Zoom automático

### 📈 Histórico de Sessões
- Lista de todas as sessões gravadas
- Detalhes completos de cada sessão
- Visualização da rota no mapa
- Estatísticas consolidadas

### 💾 Exportação de Dados
- Exportação em formato CSV
- Compartilhamento via apps nativos
- Dados completos de telemetria

## 🏗️ Estrutura do Projeto

```
lib/
├── app/
│   ├── app_module.dart              # Módulo principal
│   ├── modules/
│   │   ├── home/                    # Módulo da tela inicial
│   │   ├── telemetry/              # Módulo de telemetria
│   │   ├── history/                # Módulo de histórico
│   │   └── session_details/        # Módulo de detalhes da sessão
│   └── shared/
│       ├── database/               # Serviços de banco de dados
│       ├── models/                 # Modelos de dados
│       ├── repositories/           # Repositórios
│       ├── services/               # Serviços (GPS, sensores)
│       └── widgets/                # Widgets compartilhados
├── main.dart                       # Ponto de entrada
└── views/                          # Views auxiliares
```

## 🔧 Comandos Úteis

```bash
# Limpar cache
fvm flutter clean && fvm flutter pub get

# Gerar APK
fvm flutter build apk --release

# Gerar Bundle (Google Play)
fvm flutter build appbundle --release

# Executar testes
fvm flutter test

# Analisar código
fvm flutter analyze

# Formatar código
fvm flutter format .
```

## 📱 Compatibilidade

- **Android**: API level 21+ (Android 5.0+)
- **iOS**: iOS 12.0+
- **Testado em**: Android 10+, iOS 14+

## 🤝 Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 👨‍💻 Autor

**Diogo Pimentel**
- GitHub: [@PimentelDiogo](https://github.com/PimentelDiogo)

## 🆘 Suporte

Se você encontrar algum problema ou tiver dúvidas:

1. Verifique se todas as dependências estão instaladas
2. Confirme se a API Key do Google Maps está configurada
3. Execute `fvm flutter doctor` para verificar o ambiente
4. Abra uma issue no GitHub com detalhes do problema

---

⭐ Se este projeto foi útil para você, considere dar uma estrela no repositório!
