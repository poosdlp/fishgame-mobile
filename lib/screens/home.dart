import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../services/game_socket_service.dart';
import '../widgets/QR_Scanner.dart';
import '../widgets/fish_background_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<AuthUser?> _currentUserFuture;
  final AuthService _authService = AuthService();
  final GameSocketService _gameSocket = GameSocketService.instance;

  @override
  void initState() {
    super.initState();
    _gameSocket.addListener(_onGameSocketChanged);
    _loadSession();
  }

  @override
  void dispose() {
    _gameSocket.removeListener(_onGameSocketChanged);
    super.dispose();
  }

  void _onGameSocketChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _loadSession() {
    _currentUserFuture = _authService.getCurrentUser();
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;

    setState(() {
      _loadSession();
    });
  }

  Future<void> _showDeleteAccountUnavailable() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'The mobile app button is ready, but the backend does not have a delete account endpoint yet.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSessionTokenDialog() async {
    final sessionToken = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _SessionTokenDialog(),
    );

    if (sessionToken == null || sessionToken.isEmpty) {
      return;
    }

    final result = await _authService.approveSession(sessionToken: sessionToken);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );

    if (!result.success) {
      return;
    }

    final pollResult = await _authService.pollSessionAccessToken(sessionToken: sessionToken);
    if (!mounted) return;

    if (!pollResult.success || pollResult.accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pollResult.message)),
      );
      return;
    }

    final ready = await _gameSocket.connectAndWaitForReady(pollResult.accessToken!);
    if (!mounted) return;

    if (ready) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game is ready. Press Play.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game client was not ready yet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sw = size.width;
    final sh = size.height;

    final titleStyle = GoogleFonts.pixelifySans(
      fontSize: sw * 0.11,
      fontWeight: FontWeight.w700,
      color: const Color(0xFFFF5F87),
      height: 0.95,
      shadows: const [
        Shadow(color: Color(0x99000000), offset: Offset(3, 3), blurRadius: 0),
      ],
    );

    final messageStyle = GoogleFonts.pixelifySans(
      fontSize: sw * 0.06,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      shadows: const [
        Shadow(color: Color(0x80000000), offset: Offset(2, 2), blurRadius: 0),
      ],
    );

    final usernameStyle = GoogleFonts.pixelifySans(
      fontSize: sw * 0.065,
      fontWeight: FontWeight.w700,
      color: const Color(0xFFFFD54F),
      shadows: const [
        Shadow(color: Color(0xA0000000), offset: Offset(2, 2), blurRadius: 0),
      ],
    );

    final buttonLabelStyle = GoogleFonts.pixelifySans(
      fontSize: sw * 0.05,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );

    final smallStyle = GoogleFonts.pixelifySans(
      fontSize: sw * 0.032,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );

    final topButtonStyle = GoogleFonts.pixelifySans(
      fontSize: sw * 0.034,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );

    final playButtonStyle = GoogleFonts.pixelifySans(
      fontSize: sw * 0.05,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    );

    final deleteButtonStyle = GoogleFonts.pixelifySans(
      fontSize: sw * 0.03,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );

    return FishBackgroundScreen(
      scrollable: false,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: sw * 0.08),
          child: Column(
            children: [
              SizedBox(height: sh * 0.02),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!_gameSocket.isReady)
                    SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: _showSessionTokenDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00695C),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: sw * 0.03),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.paste, size: 16),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('PASTE QR', style: smallStyle),
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  FutureBuilder<AuthUser?>(
                    future: _currentUserFuture,
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      if (user == null || user.username.isEmpty) {
                        return const SizedBox(width: 90);
                      }

                      return SizedBox(
                        width: sw * 0.32,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 42,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _logout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xCC1A237E),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: sw * 0.03),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Log Out', style: topButtonStyle),
                                ),
                              ),
                            ),
                            SizedBox(height: sh * 0.01),
                            SizedBox(
                              height: 42,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _showDeleteAccountUnavailable,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD32F2F),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: sw * 0.02),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Delete Account', style: deleteButtonStyle),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: sh * 0.085),
              Text(
                'Orlando\nFishing\nAdventure',
                textAlign: TextAlign.center,
                style: titleStyle,
              ),
              SizedBox(height: sh * 0.04),
              if (_gameSocket.isReady) ...[
                Text(
                  'Ready to play',
                  textAlign: TextAlign.center,
                  style: messageStyle,
                ),
                SizedBox(height: sh * 0.05),
                SizedBox(
                  width: sw * 0.52,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/game');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                    child: Text('Play', style: playButtonStyle),
                  ),
                ),
              ] else ...[
                Text(
                  'Scan the QR code to Play!',
                  textAlign: TextAlign.center,
                  style: messageStyle,
                ),
                SizedBox(height: sh * 0.075),
                SizedBox(
                  width: sw * 0.3,
                  height: sw * 0.3,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ScanCodePage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBDBDBD),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(color: Colors.black87, width: 2),
                      ),
                    ),
                    child: Icon(Icons.photo_camera, size: sw * 0.175),
                  ),
                ),
              ],
              SizedBox(height: sh * 0.045),
              FutureBuilder<AuthUser?>(
                future: _currentUserFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: sh * 0.12),
                      child: Column(
                        children: [
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: sh * 0.02),
                          Text(
                            'Checking session...',
                            textAlign: TextAlign.center,
                            style: messageStyle,
                          ),
                        ],
                      ),
                    );
                  }

                  final user = snapshot.data;

                  if (user != null && user.username.isNotEmpty) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: sh * 0.11),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: sh * 0.022,
                          horizontal: sw * 0.06,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6EC6FF),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFF1A237E),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x55000000),
                              offset: Offset(2, 2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: messageStyle.copyWith(color: Colors.white),
                            children: [
                              const TextSpan(text: 'Good luck fishing today '),
                              TextSpan(
                                text: user.username,
                                style: usernameStyle,
                              ),
                              const TextSpan(text: '!'),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(height: sh * 0.25),
                          Expanded(
                            child: _RouteButton(
                              label: 'Sign Up',
                              onPressed: () => Navigator.pushNamed(context, '/signup'),
                              labelStyle: buttonLabelStyle,
                            ),
                          ),
                          SizedBox(width: sw * 0.04),
                          Expanded(
                            child: _RouteButton(
                              label: 'Log In',
                              onPressed: () => Navigator.pushNamed(context, '/login'),
                              labelStyle: buttonLabelStyle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionTokenDialog extends StatefulWidget {
  const _SessionTokenDialog();

  @override
  State<_SessionTokenDialog> createState() => _SessionTokenDialogState();
}

class _SessionTokenDialogState extends State<_SessionTokenDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData('text/plain');
    final clipboardText = clipboardData?.text?.trim() ?? '';
    if (!mounted || clipboardText.isEmpty) return;

    _controller.text = clipboardText;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Paste session token'),
      content: SizedBox(
        width: 320,
        child: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.send,
          decoration: const InputDecoration(
            labelText: 'Session token',
            hintText: 'Paste the scanned value here',
          ),
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _pasteFromClipboard,
          child: const Text('Paste'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Send'),
        ),
      ],
    );
  }
}

class _RouteButton extends StatelessWidget {
  const _RouteButton({
    required this.label,
    required this.onPressed,
    required this.labelStyle,
  });

  final String label;
  final VoidCallback onPressed;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xCC1A237E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: labelStyle),
        ),
      ),
    );
  }
}
