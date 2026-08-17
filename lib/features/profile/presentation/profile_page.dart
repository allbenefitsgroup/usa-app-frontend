import 'dart:convert';

import 'package:all_benefits_group/app/theme/app_theme.dart';
import 'package:all_benefits_group/features/auth/data/auth_service.dart';
import 'package:all_benefits_group/features/onboarding/presentation/started_logins_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await AuthService.getUser();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _capitalize(String? value) {
    if (value == null || value.isEmpty) return '-';
    return value[0].toUpperCase() + value.substring(1);
  }

  Future<void> _deleteAccount() async {
    final userId = _user?['id'] ?? _user?['uid'] ?? _user?['_id'];
    if (userId == null) return;

    final baseUrl = dotenv.env['BASE_URL_PROD'];
    if (baseUrl == null || baseUrl.isEmpty) return;

    setState(() => _isDeleting = true);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: AppTheme.accent),
              SizedBox(width: 20),
              Text('Eliminando cuenta...'),
            ],
          ),
        ),
      );
    }

    final token = await AuthService.getToken();
    final url = Uri.parse('$baseUrl/api/admin/users/$userId');

    debugPrint('🗑️ [DeleteAccount] DELETE $url');
    debugPrint('🗑️ [DeleteAccount] Headers: {Content-Type: application/json, Authorization: Bearer ${token != null && token.isNotEmpty ? token.substring(0, 20) + '...' : 'null'}}');

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    debugPrint('🗑️ [DeleteAccount] Response status: ${response.statusCode}');
    debugPrint('🗑️ [DeleteAccount] Response body: ${response.body}');

    if (mounted) Navigator.pop(context);

    setState(() => _isDeleting = false);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (mounted) {
        await AuthService.logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const StartedLoginsPage()),
            (route) => false,
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo eliminar la cuenta. Intenta de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Eliminar cuenta',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar tu cuenta? Esta acción no se puede deshacer.',
          style: GoogleFonts.nunito(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: AppTheme.muted,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteAccount();
            },
            child: Text(
              'Eliminar',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleLabel(String? role) {
    switch (role?.toLowerCase()) {
      case 'client':
      case 'customer':
      case 'usuario':
        return 'Cliente';
      case 'vendor':
      case 'seller':
        return 'Vendedor';
      case 'student':
      case 'estudiante':
        return 'Estudiante';
      case 'agent':
      case 'agents':
        return 'Agente';
      default:
        return _capitalize(role);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _user?['name'] as String? ?? '-';
    final email = _user?['email'] as String? ?? '-';
    final phone = _user?['phone'] as String? ?? '-';
    final role = _getRoleLabel(_user?['role'] as String?);

    return Scaffold(
      backgroundColor: AppTheme.paper,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_back_ios,
                          color: AppTheme.muted,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Atrás',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Mi perfil',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.fg,
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.accent.withValues(alpha: 0.1),
                              border: Border.all(color: AppTheme.accent, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accent.withValues(alpha: 0.25),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Image.asset(
                                  'assets/images/bebe/bebe-user.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Name
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.fredoka(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.fg,
                              letterSpacing: -0.2,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Role badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              role,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.accent,
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Info card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.line, width: 1.5),
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  icon: Icons.email_outlined,
                                  label: 'Correo electrónico',
                                  value: email,
                                ),
                                if (phone.isNotEmpty && phone != '-')
                                  ...[
                                    const Divider(height: 32, color: AppTheme.line),
                                    _buildInfoRow(
                                      icon: Icons.phone_outlined,
                                      label: 'Teléfono',
                                      value: phone,
                                    ),
                                  ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Delete account
                          GestureDetector(
                            onTap: _showDeleteAccountDialog,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Eliminar cuenta',
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.red.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Bebe bubble
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.accent, width: 2.5),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/bebe/bebe-hello.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF9F5),
                                    border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25), width: 1.5),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(18),
                                      topRight: Radius.circular(18),
                                      bottomRight: Radius.circular(18),
                                    ),
                                  ),
                                  child: Text(
                                    'BEBE: "Aquí puedes ver toda tu información personal. Pronto podrás editarla también."',
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.fg,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppTheme.accent,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.fg,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
