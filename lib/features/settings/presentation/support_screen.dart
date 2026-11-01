import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _launchUPI() async {
    final uri = Uri.parse('upi://pay?pa=raghav5711@ybl&pn=Raghavan%20S&tn=Support%20iReader&cu=INR');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback or message
      await Clipboard.setData(const ClipboardData(text: 'raghav5711@ybl'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrow_left, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Support Project', style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 18, color: onSurface)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  const Text('Donate to iReader', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 12),
                  Text(
                    'Your contribution helps keep this project alive and free for everyone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: onSurface.withValues(alpha: 0.5), fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/payQR.png',
                      width: 240,
                      height: 240,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 240,
                        height: 240,
                        color: onSurface.withValues(alpha: 0.05),
                        child: const Icon(LucideIcons.qr_code, size: 64),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('raghav5711@ybl', style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold, color: const Color(0xFFFF3B3B))),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: 'raghav5711@ybl'));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UPI ID copied to clipboard')));
                    },
                    icon: const Icon(LucideIcons.copy, size: 14),
                    label: const Text('Copy ID'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B3B),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _launchUPI,
              icon: const Icon(LucideIcons.wallet),
              label: const Text('Donate via Payment App', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Text(
              'Detecting installed UPI apps...',
              style: TextStyle(color: onSurface.withValues(alpha: 0.3), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
