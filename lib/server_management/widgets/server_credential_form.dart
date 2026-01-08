import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/auth/bloc/auth_bloc.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/server_management/bloc/server_management_bloc.dart';
import 'package:playcado/services/logger_service.dart';
import 'package:playcado/widgets/widgets.dart';

class ServerCredentialForm extends StatefulWidget {
  const ServerCredentialForm({required this.initialState, super.key});
  final ServerManagementState initialState;

  @override
  State<ServerCredentialForm> createState() => _ServerCredentialFormState();
}

class _ServerCredentialFormState extends State<ServerCredentialForm> {
  late final TextEditingController _serverCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passCtrl;
  bool _rememberCredentials = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _serverCtrl = TextEditingController(text: widget.initialState.serverUrl);
    _userCtrl = TextEditingController(text: widget.initialState.username);
    _passCtrl = TextEditingController(text: widget.initialState.password);
  }

  @override
  void didUpdateWidget(covariant ServerCredentialForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync text controllers with state from Bloc
    if (widget.initialState != oldWidget.initialState) {
      if (_serverCtrl.text != widget.initialState.serverUrl) {
        _serverCtrl.text = widget.initialState.serverUrl;
      }
      if (_userCtrl.text != widget.initialState.username) {
        _userCtrl.text = widget.initialState.username;
      }
      if (_passCtrl.text != widget.initialState.password) {
        _passCtrl.text = widget.initialState.password;
      }
    }
  }

  @override
  void dispose() {
    _serverCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final serverUrl = _serverCtrl.text.trim();

    if (_isInsecurePublicUrl(serverUrl)) {
      final confirmed = await _showHttpWarning();
      if (!confirmed) return;
    }

    if (!mounted) return;
    context.read<AuthBloc>().add(
      AuthLoginRequested(
        serverUrl,
        _userCtrl.text,
        _passCtrl.text,
        rememberCredentials: _rememberCredentials,
      ),
    );
  }

  /// Returns true if the URL explicitly uses HTTP and targets a non-local host.
  bool _isInsecurePublicUrl(String url) {
    if (!url.startsWith('http://')) return false;

    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      if (host.isEmpty) return false;
      if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
        return false;
      }

      final ip = InternetAddress.tryParse(host);
      if (ip != null) {
        final bytes = ip.rawAddress;
        if (bytes.length == 4) {
          // 10.0.0.0/8
          if (bytes[0] == 10) return false;
          // 172.16.0.0/12
          if (bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31) return false;
          // 192.168.0.0/16
          if (bytes[0] == 192 && bytes[1] == 168) return false;
        }
      }
      return true;
    } on Exception catch (e) {
      LoggerService.ui.warning('Failed to parse URL for security check', e);
      return false;
    }
  }

  Future<bool> _showHttpWarning() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.l10n.httpWarningTitle),
            content: Text(context.l10n.httpWarningMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(context.l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(context.l10n.httpWarningContinue),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final authLoading = context.watch<AuthBloc>().state.user.isLoading;

    return Column(
      children: [
        TextField(
          controller: _serverCtrl,
          enabled: !authLoading,
          autocorrect: false,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: context.l10n.serverUrlLabel,
            border: const OutlineInputBorder(),
            prefixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: PlaycadoIcon(PlaycadoIcons.smartTv),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _userCtrl,
          enabled: !authLoading,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: context.l10n.username,
            border: const OutlineInputBorder(),
            prefixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: PlaycadoIcon(PlaycadoIcons.person),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passCtrl,
          enabled: !authLoading,
          obscureText: _obscurePassword,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _onLogin(),
          decoration: InputDecoration(
            labelText: context.l10n.password,
            border: const OutlineInputBorder(),
            prefixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: PlaycadoIcon(PlaycadoIcons.lock),
            ),
            suffixIcon: IconButton(
              icon: PlaycadoIcon(
                _obscurePassword ? PlaycadoIcons.viewOff : PlaycadoIcons.view,
              ),
              onPressed: authLoading
                  ? null
                  : () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Checkbox(
              value: _rememberCredentials,
              onChanged: authLoading
                  ? null
                  : (value) {
                      setState(() {
                        _rememberCredentials = value ?? false;
                      });
                    },
            ),
            Text(context.l10n.rememberCredentials),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
          onPressed: authLoading ? null : _onLogin,
          child: authLoading
              ? const LoadingIndicator(size: 20)
              : Text(context.l10n.login),
        ),
      ],
    );
  }
}
