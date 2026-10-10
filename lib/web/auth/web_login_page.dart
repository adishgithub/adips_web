import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/http/http_client.dart';
import '../../utils/local_storage/storage_utility.dart';
import '../../utils/validators/validation.dart';

/// Web login. Same endpoint and storage behaviour as the mobile app;
/// the token is later sent in the Authorization header (see
/// AdipsHttpHelper._headers).
class WebLoginPage extends StatefulWidget {
  const WebLoginPage({super.key});

  @override
  State<WebLoginPage> createState() => _WebLoginPageState();
}

class _WebLoginPageState extends State<WebLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AdipsHttpHelper.post('/api/v1/users/login', {
        'email': _email.text.trim(),
        'password': _password.text,
      }, );
      final data = AdipsHttpHelper.data(res);
      final token = data['token'] as String?;
      if (token == null) throw Exception('No token returned by server');
      await AdipsLocalStorage.saveToken(token);
      final user = data['user'] as Map<String, dynamic>? ?? {};
      await AdipsLocalStorage.saveCachedUser(
          (user['name'] ?? '').toString(), _email.text.trim());
      Get.offAllNamed('/dashboard');
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Welcome back',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Sign in to ADIPS', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: AdipsValidator.validateEmail,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: AdipsValidator.validatePassword,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: TextStyle(color: theme.colorScheme.error)),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: Builder(
                              builder: (ctx) => CircularProgressIndicator(
                                strokeWidth: 2,
                                color: IconTheme.of(ctx).color,
                              ),
                            ))
                        : const Text('Sign in'),
                  ),
                  if (_loading) ...[
                    const SizedBox(height: 12),
                    Text(
                        'If the server was idle this can take up to 30 seconds.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('New to ADIPS?'),
                      TextButton(
                        onPressed: () => Get.offAllNamed('/register'),
                        child: const Text('Create account'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
