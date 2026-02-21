import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:sggm/util/app_logger.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Verificar se o dispositivo suporta biometria
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException catch (e) {
      AppLogger.error('❌ Erro ao verificar biometria: $e');
      return false;
    }
  }

  /// Verificar se há biometria cadastrada
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException catch (e) {
      AppLogger.error('❌ Erro ao verificar dispositivo: $e');
      return false;
    }
  }

  /// Obter tipos de biometria disponíveis
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      AppLogger.error('❌ Erro ao obter biometrias: $e');
      return [];
    }
  }

  /// Verificar se biometria está disponível e configurada
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await canCheckBiometrics();
      final isSupported = await isDeviceSupported();
      final biometrics = await getAvailableBiometrics();

      return canCheck && isSupported && biometrics.isNotEmpty;
    } catch (e) {
      AppLogger.error('❌ Erro ao verificar disponibilidade: $e');
      return false;
    }
  }

  /// Autenticar com biometria
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        AppLogger.warning('⚠️ Biometria não disponível');
        return false;
      }

      AppLogger.info('🔐 Iniciando autenticação biométrica...');

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'SGGM - Autenticação',
            cancelButton: 'Cancelar',
            biometricHint: 'Toque no sensor',
            biometricNotRecognized: 'Biometria não reconhecida',
            biometricRequiredTitle: 'Biometria necessária',
            biometricSuccess: 'Sucesso',
            deviceCredentialsRequiredTitle: 'Autenticação necessária',
            deviceCredentialsSetupDescription: 'Configure a biometria',
            goToSettingsButton: 'Configurações',
            goToSettingsDescription: 'Configure biometria nas configurações',
          ),
          IOSAuthMessages(
            cancelButton: 'Cancelar',
            goToSettingsButton: 'Configurações',
            goToSettingsDescription: 'Configure Face ID ou Touch ID',
            lockOut: 'Autenticação bloqueada. Tente novamente.',
          ),
        ],
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: false,
        ),
      );

      if (authenticated) {
        AppLogger.info('✅ Autenticação biométrica bem-sucedida');
      } else {
        AppLogger.error('❌ Autenticação biométrica falhou');
      }

      return authenticated;
    } on PlatformException catch (e) {
      AppLogger.error('❌ Erro na autenticação biométrica: ${e.code} - ${e.message}');

      switch (e.code) {
        case 'NotAvailable':
          AppLogger.warning('⚠️ Biometria não disponível neste dispositivo');
          break;
        case 'NotEnrolled':
          AppLogger.warning('⚠️ Nenhuma biometria cadastrada');
          break;
        case 'LockedOut':
          AppLogger.warning('⚠️ Muitas tentativas. Dispositivo bloqueado temporariamente');
          break;
        case 'PermanentlyLockedOut':
          AppLogger.warning('⚠️ Dispositivo bloqueado permanentemente');
          break;
        default:
          AppLogger.warning('⚠️ Erro desconhecido: ${e.code}');
      }

      return false;
    } catch (e) {
      AppLogger.error('❌ Exceção na autenticação: $e');
      return false;
    }
  }

  /// Obter descrição dos tipos de biometria disponíveis
  Future<String> getBiometricTypeDescription() async {
    final biometrics = await getAvailableBiometrics();

    if (biometrics.isEmpty) {
      return 'Biometria';
    }

    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    }
    if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Impressão Digital';
    }
    if (biometrics.contains(BiometricType.strong)) {
      return 'Biometria';
    }

    return 'Biometria';
  }

  /// Cancelar autenticação em andamento
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
      AppLogger.info('🛑 Autenticação cancelada');
    } catch (e) {
      AppLogger.error('❌ Erro ao cancelar autenticação: $e');
    }
  }
}
