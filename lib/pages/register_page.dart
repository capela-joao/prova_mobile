import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../widgets/error_message.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  String _username = '';
  String _email = '';
  String _bio = '';
  String _password = '';
  String? _errorMessage;
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      User user = await _authService.register(
        username: _username,
        email: _email,
        bio: _bio,
        password: _password,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta criada com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = ErrorMessageHandler.getFriendlyMessage(
          e.toString(),
          context: 'register',
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearError() {
    setState(() {
      _errorMessage = null;
    });
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFFc7d5e0),
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontFamily: 'Tahoma',
      ),
      filled: true,
      fillColor: const Color(0xFF2b2f33),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF00c6ff)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101114),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Crie sua conta",
                  style: TextStyle(
                    color: Color(0xFFc7d5e0),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tahoma',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                ErrorMessageWidget(
                  errorMessage: _errorMessage,
                  onDismiss: _clearError,
                ),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        style: const TextStyle(
                          color: Color(0xFFc7d5e0),
                          fontSize: 16,
                        ),
                        decoration: _inputDecoration('Nome de usuário'),
                        onChanged: (value) => _username = value.trim(),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Obrigatório'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        style: const TextStyle(
                          color: Color(0xFFc7d5e0),
                          fontSize: 16,
                        ),
                        decoration: _inputDecoration('E-mail'),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) => _email = value.trim(),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Obrigatório';
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Digite um e-mail válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        style: const TextStyle(
                          color: Color(0xFFc7d5e0),
                          fontSize: 16,
                        ),
                        decoration: _inputDecoration('Bio'),
                        onChanged: (value) => _bio = value.trim(),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        style: const TextStyle(
                          color: Color(0xFFc7d5e0),
                          fontSize: 16,
                        ),
                        decoration: _inputDecoration('Senha'),
                        obscureText: true,
                        onChanged: (value) => _password = value.trim(),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Obrigatório';
                          if (value.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00c6ff),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Tahoma',
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Registrar'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Já tem conta? Faça login',
                          style: TextStyle(
                            color: Color(0xFFc7d5e0),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
