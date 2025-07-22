import 'package:flutter/material.dart';

class ErrorMessageWidget extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onDismiss;

  const ErrorMessageWidget({super.key, this.errorMessage, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    if (errorMessage == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2d1b1b),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade400, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.red.shade300,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, color: Colors.red.shade400, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}

class ErrorMessageHandler {
  static String getFriendlyMessage(String error, {String context = 'login'}) {
    // Remove prefixos técnicos
    String cleanError = error
        .replaceAll('Exception: ', '')
        .toLowerCase()
        .trim();

    // Mapeamento específico por contexto
    switch (context) {
      case 'login':
        return _getLoginErrorMessage(cleanError);
      case 'register':
        return _getRegisterErrorMessage(cleanError);
      default:
        return _getGenericErrorMessage(cleanError);
    }
  }

  static String _getLoginErrorMessage(String error) {
    // Erros de autenticação
    if (error.contains('bad credentials') ||
        error.contains('invalid credentials') ||
        error.contains('unauthorized') ||
        error.contains('401') ||
        error.contains('incorrect password') ||
        error.contains('wrong password')) {
      return 'E-mail ou senha incorretos. Verifique seus dados e tente novamente.';
    }

    // Usuário não encontrado
    if (error.contains('user not found') ||
        error.contains('email not found') ||
        error.contains('account not found')) {
      return 'Não encontramos uma conta com este e-mail. Verifique o endereço ou crie uma nova conta.';
    }

    // Conta bloqueada ou suspensa
    if (error.contains('account locked') ||
        error.contains('account suspended') ||
        error.contains('account disabled')) {
      return 'Sua conta foi temporariamente bloqueada. Entre em contato com o suporte.';
    }

    // Conta não verificada
    if (error.contains('account not verified') ||
        error.contains('email not verified') ||
        error.contains('user not verified')) {
      return 'Sua conta ainda não foi verificada. Verifique seu e-mail e clique no link de confirmação.';
    }

    // Muitas tentativas
    if (error.contains('too many attempts') ||
        error.contains('rate limit') ||
        error.contains('blocked temporarily')) {
      return 'Muitas tentativas de login. Aguarde alguns minutos antes de tentar novamente.';
    }

    return _getGenericErrorMessage(error);
  }

  static String _getRegisterErrorMessage(String error) {
    // E-mail já existe
    if (error.contains('email already exists') ||
        error.contains('email taken') ||
        error.contains('user already exists') ||
        error.contains('already registered')) {
      return 'Este e-mail já está cadastrado. Tente fazer login ou use outro e-mail.';
    }

    // Nome de usuário já existe
    if (error.contains('username already exists') ||
        error.contains('username taken') ||
        error.contains('username unavailable')) {
      return 'Este nome de usuário já está em uso. Tente outro nome.';
    }

    // Senha fraca
    if (error.contains('weak password') ||
        error.contains('password too short') ||
        error.contains('password requirements') ||
        error.contains('password strength')) {
      return 'Sua senha deve ter pelo menos 8 caracteres, incluindo letras e números.';
    }

    // E-mail inválido
    if (error.contains('invalid email') ||
        error.contains('email format') ||
        error.contains('malformed email')) {
      return 'Por favor, digite um e-mail válido.';
    }

    // Nome de usuário inválido
    if (error.contains('invalid username') ||
        error.contains('username format') ||
        error.contains('username characters')) {
      return 'Nome de usuário deve ter entre 3-20 caracteres e conter apenas letras, números e _.';
    }

    // Campos obrigatórios
    if (error.contains('required field') ||
        error.contains('missing field') ||
        error.contains('field required')) {
      return 'Por favor, preencha todos os campos obrigatórios.';
    }

    // Bio muito longa
    if (error.contains('bio too long') || error.contains('bio length')) {
      return 'A bio deve ter no máximo 150 caracteres.';
    }

    return _getGenericErrorMessage(error);
  }

  static String _getGenericErrorMessage(String error) {
    // Problemas de rede
    if (error.contains('network') ||
        error.contains('connection') ||
        error.contains('timeout') ||
        error.contains('no internet') ||
        error.contains('offline')) {
      return 'Problema de conexão. Verifique sua internet e tente novamente.';
    }

    // Erros do servidor
    if (error.contains('server error') ||
        error.contains('internal server') ||
        error.contains('500') ||
        error.contains('503') ||
        error.contains('server unavailable')) {
      return 'Nossos serviços estão temporariamente indisponíveis. Tente novamente em alguns instantes.';
    }

    // Timeout
    if (error.contains('timeout') || error.contains('request timeout')) {
      return 'A operação demorou mais que o esperado. Tente novamente.';
    }

    // Erro de formato JSON
    if (error.contains('json') ||
        error.contains('parse') ||
        error.contains('format')) {
      return 'Erro na comunicação com o servidor. Tente novamente.';
    }

    // SSL/Certificado
    if (error.contains('certificate') ||
        error.contains('ssl') ||
        error.contains('handshake')) {
      return 'Erro de segurança na conexão. Verifique sua conexão e tente novamente.';
    }

    // Mensagem genérica para erros não mapeados
    return 'Algo deu errado. Por favor, tente novamente ou entre em contato com o suporte.';
  }

  // Método para obter sugestões baseadas no tipo de erro
  static String? getErrorSuggestion(String error, {String context = 'login'}) {
    String cleanError = error.toLowerCase();

    if (context == 'login') {
      if (cleanError.contains('bad credentials') ||
          cleanError.contains('incorrect')) {
        return 'Dica: Verifique se não há espaços extras no e-mail ou se o Caps Lock está ativado.';
      }

      if (cleanError.contains('user not found')) {
        return 'Dica: Verifique se o e-mail está correto ou crie uma nova conta.';
      }

      if (cleanError.contains('network') || cleanError.contains('connection')) {
        return 'Dica: Verifique sua conexão Wi-Fi ou tente usando dados móveis.';
      }
    }

    return null;
  }
}
