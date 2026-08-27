import 'package:flutter/material.dart';

import '../services/safety_share_service.dart';

Future<void> showSafetyShareSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _SafetyShareSheet(),
  );
}

class _SafetyShareSheet extends StatefulWidget {
  const _SafetyShareSheet();

  @override
  State<_SafetyShareSheet> createState() => _SafetyShareSheetState();
}

class _SafetyShareSheetState extends State<_SafetyShareSheet> {
  String? _message;
  bool _isPreparing = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _prepareMessage();
  }

  Future<void> _prepareMessage() async {
    final String message = await SafetyShareService.createSafetyMessage();
    if (!mounted) return;
    setState(() {
      _message = message;
      _isPreparing = false;
    });
  }

  Future<void> _share(SafetyShareChannel channel) async {
    if (_message == null || _isSending) return;
    setState(() => _isSending = true);
    final bool opened = await SafetyShareService.share(channel, _message!);
    if (!mounted) return;
    setState(() => _isSending = false);
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir la aplicación seleccionada.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        decoration: const BoxDecoration(
          color: Color(0xFF101B2A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF597082),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: <Widget>[
                Icon(Icons.verified_rounded, color: Color(0xFF56E6DC)),
                SizedBox(width: 9),
                Text(
                  'Estoy a Salvo',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Comparte tu estado y ubicación aproximada con tus contactos.',
              style: TextStyle(color: Color(0xFFB7C6D4), height: 1.35),
            ),
            const SizedBox(height: 18),
            if (_isPreparing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(color: Color(0xFF56E6DC)),
                ),
              )
            else ...<Widget>[
              _ShareAction(
                icon: Icons.chat_rounded,
                label: 'WhatsApp',
                detail: 'Abrir mensaje listo para enviar',
                color: const Color(0xFF25D366),
                onPressed: _isSending
                    ? null
                    : () => _share(SafetyShareChannel.whatsapp),
              ),
              const SizedBox(height: 10),
              _ShareAction(
                icon: Icons.facebook_rounded,
                label: 'Facebook / Messenger',
                detail: 'Abrir interfaz para compartir el estado',
                color: const Color(0xFF1A77F2),
                onPressed: _isSending
                    ? null
                    : () => _share(SafetyShareChannel.facebook),
              ),
              const SizedBox(height: 10),
              _ShareAction(
                icon: Icons.sms_rounded,
                label: 'Mensaje de texto',
                detail: 'Abrir SMS con el aviso preparado',
                color: const Color(0xFFF6B94A),
                onPressed: _isSending
                    ? null
                    : () => _share(SafetyShareChannel.sms),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShareAction extends StatelessWidget {
  const _ShareAction({
    required this.icon,
    required this.label,
    required this.detail,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String detail;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF17293B),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: const TextStyle(
                        color: Color(0xFF9EAFBF),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9EAFBF)),
            ],
          ),
        ),
      ),
    );
  }
}
