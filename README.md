::: {align="center"}
# 🎵 SGGM - Sistema de Gerenciamento de Grupos Musicais

[![Flutter](https://img.shields.io/badge/Flutter-3.4.0-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.4.0-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Latest-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Sistema móvel de gerenciamento para grupos musicais da IPB Ponta
Porã**

[Sobre](#-sobre) • [Funcionalidades](#-funcionalidades) •
[Tecnologias](#-tecnologias) • [Instalação](#-instalação) •
[Configuração](#-configuração) • [Estrutura do
Projeto](#-estrutura-do-projeto) • [Contribuição](#-como-contribuir)
:::

------------------------------------------------------------------------

## 📖 Sobre

O **SGGM** é um aplicativo móvel desenvolvido em Flutter para gerenciar
grupos musicais da Igreja Presbiteriana do Brasil em Ponta Porã.

O sistema oferece autenticação segura, notificações push em tempo real e
uma interface moderna e intuitiva, proporcionando organização eficiente
das atividades musicais da igreja.

### 🎯 Objetivo

Facilitar a organização, comunicação e gestão de músicos, ensaios,
escalas e eventos musicais.

------------------------------------------------------------------------

## ✨ Funcionalidades

### 🔐 Autenticação e Segurança

-   Login tradicional com usuário e senha
-   Autenticação biométrica (impressão digital / Face ID)
-   Armazenamento seguro de credenciais com criptografia
-   Tokens JWT com refresh automático
-   Auto-login com biometria ao abrir o app

### 🔔 Notificações

-   Push notifications via Firebase Cloud Messaging
-   Notificações locais com alertas personalizados
-   Gerenciamento de tokens FCM por usuário

### 👥 Gestão de Usuários

-   Perfis diferenciados: músicos, líderes e administradores
-   Informações personalizadas por tipo de usuário
-   Controle de permissões por nível de acesso

### 🎨 Interface

-   Material Design 3
-   Tema escuro moderno
-   Fonte personalizada (Inknut Antiqua)
-   Interface fluida e responsiva

------------------------------------------------------------------------

## 🛠️ Tecnologias

### Core

-   Flutter \>= 3.4.0
-   Dart \>= 3.4.0

### Gerenciamento de Estado

-   Provider 6.1.2

### Backend & API

-   Dio 5.9.1
-   REST API (Backend Django)

### Firebase

-   firebase_core 3.8.1
-   firebase_messaging 15.1.5
-   flutter_local_notifications 18.0.1

### Segurança

-   flutter_secure_storage 9.2.2
-   local_auth 2.3.0
-   JWT Tokens

### Utilitários

-   intl 0.20.2
-   url_launcher 6.3.1

------------------------------------------------------------------------

## 📦 Instalação

### ✅ Pré-requisitos

-   Flutter SDK \>= 3.4.0
-   Dart SDK \>= 3.4.0
-   Android Studio ou Xcode
-   Git

------------------------------------------------------------------------

### 🔽 Clone o Repositório

``` bash
git clone https://github.com/EricksonDutra/sggm_mobile.git
cd sggm_mobile
```

------------------------------------------------------------------------

### 📥 Instale as Dependências

``` bash
flutter pub get
```

------------------------------------------------------------------------

### 🔎 Verifique a Instalação

``` bash
flutter doctor
```

------------------------------------------------------------------------

## ⚙️ Configuração

### 1️⃣ Firebase

1.  Crie um projeto no Firebase Console\
2.  Adicione o app Android e/ou iOS\
3.  Baixe os arquivos de configuração:

-   **Android:** `google-services.json` → `android/app/`
-   **iOS:** `GoogleService-Info.plist` → `ios/Runner/`

------------------------------------------------------------------------

### 2️⃣ Configurar Backend

Edite o arquivo:

    lib/util/constants.dart

``` dart
class AppConstants {
  static const String baseUrl = 'https://sua-api.com';
  static const String loginPath = '/api/token/';
}
```

------------------------------------------------------------------------

### 3️⃣ Permissões Android

Arquivo:

    android/app/src/main/AndroidManifest.xml

``` xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
```

------------------------------------------------------------------------

### 4️⃣ Permissões iOS

Arquivo:

    ios/Runner/Info.plist

``` xml
<key>NSFaceIDUsageDescription</key>
<string>Autentique-se usando Face ID para acessar o SGGM</string>
```

------------------------------------------------------------------------

### 5️⃣ MainActivity (Obrigatório para Biometria)

Arquivo:

    android/app/src/main/kotlin/.../MainActivity.kt

``` kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity()
```

------------------------------------------------------------------------

## 🚀 Executando o Projeto

### 🔧 Desenvolvimento

``` bash
flutter run
```

------------------------------------------------------------------------

### 📦 Build de Produção

``` bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

------------------------------------------------------------------------
## Configuração de Ambiente

Este projeto usa `--dart-define` para variáveis de ambiente em compile-time.
Os valores **nunca ficam expostos** no bundle do aplicativo.

### Desenvolvimento
```bash
flutter run \
  --dart-define=BASE_URL=http://SEU_IP:8000 \
  --dart-define=TIMEOUT_SECONDS=15

### Produção
flutter build apk \
  --dart-define=BASE_URL=https://api.ericksondutra.cloud \
  --dart-define=TIMEOUT_SECONDS=10

------------------------------------------------------------------------

## 📱 Funcionalidades por Tela

### 🔑 Tela de Login

-   Login com usuário e senha
-   Login biométrico (quando habilitado)
-   Diálogo de habilitação biométrica após primeiro login
-   Auto-login com biometria
-   Validação de campos

### 🏠 Tela Inicial (Home)

-   Dashboard personalizado por tipo de usuário
-   Acesso rápido às funcionalidades principais
-   Notificações em tempo real

------------------------------------------------------------------------

## 📁 Estrutura do Projeto

    lib/
    ├── controllers/
    │   └── auth_controller.dart
    ├── services/
    │   ├── api_service.dart
    │   ├── biometric_service.dart
    │   ├── notification_service.dart
    │   └── secure_token_service.dart
    ├── views/
    │   └── login_page.dart
    ├── util/
    │   └── constants.dart
    ├── widgets/
    └── main.dart

------------------------------------------------------------------------

## 🔒 Segurança

### Armazenamento de Credenciais

-   Tokens JWT armazenados com criptografia AES
-   Keychain (iOS) e Keystore (Android)
-   Credenciais nunca expostas em texto puro

### Autenticação Biométrica

-   Impressão digital e Face ID
-   Fallback para PIN/senha do dispositivo
-   Autenticação local (dados biométricos não são enviados)

### Comunicação com API

-   HTTPS obrigatório
-   Tokens com expiração
-   Refresh token automático
-   Timeout e retry configurados

------------------------------------------------------------------------

## 📄 Licença

Este projeto está sob a licença MIT.\
Consulte o arquivo `LICENSE` para mais detalhes.

------------------------------------------------------------------------

## 👨‍💻 Autor

**Erickson Dutra**

-   GitHub: @EricksonDutra
-   LinkedIn: Erickson Dutra

------------------------------------------------------------------------

## 🧩 Padrão de Commits

Seguimos o padrão **Conventional Commits**:

-   feat: nova funcionalidade\
-   fix: correção de bug\
-   docs: documentação\
-   style: formatação\
-   refactor: refatoração\
-   test: testes\
-   chore: tarefas gerais

------------------------------------------------------------------------

## 📞 Suporte

Se encontrar algum problema ou tiver sugestões:

-   Abra uma Issue no repositório
-   Entre em contato por e-mail

------------------------------------------------------------------------

## 🙏 Agradecimentos

-   IPB Ponta Porã -- Pelo apoio e inspiração
-   Comunidade Flutter -- Pelos excelentes recursos
-   Todos os contribuidores do projeto

------------------------------------------------------------------------


Desenvolvido com ❤️ e 🎵 para a IPB Ponta Porã

