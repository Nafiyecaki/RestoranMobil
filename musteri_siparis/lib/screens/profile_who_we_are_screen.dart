import 'package:flutter/material.dart';

/// Sabit, salt-okunur "Biz Kimiz" sayfası.
/// Ekipte 5 kişi vardır; bu sayfadan ekleme/çıkarma yapılamaz.
class ProfileWhoWeAreScreen extends StatelessWidget {
  const ProfileWhoWeAreScreen({super.key});

  static const Color _primaryColor = Color(0xFF2E7D32);
  static const Color _primaryDark = Color(0xFF1B5E20);

  // Ekip sabit olarak burada tanımlı.
  // Fotoğraf eklemek için: görseli assets/images/team/ klasörüne koy,
  // pubspec.yaml'da assets altında tanımlı olduğundan emin ol,
  // sonra ilgili üyenin imagePath alanına yolunu yaz.
  // Örn: imagePath: 'assets/images/team/naiye.jpg'
  // imagePath null bırakılırsa baş harfli renkli avatar otomatik gösterilir.
  static const List<_TeamMember> _members = [
    _TeamMember(
      name: 'Naiye ÇAKI',
      role: 'Backendçi Teyze',
      icon: Icons.smartphone_rounded,
      imagePath: 'assets/images/nafiye.png',
    ),
    _TeamMember(
      name: 'İlayda DOĞAN',
      role: 'Frontçu Bünyanlı',
      icon: Icons.dns_rounded,
      imagePath: 'assets/images/nafiye.png',
    ),
    _TeamMember(
      name: 'Berat Safa KAHRAMAN',
      role: '...',
      icon: Icons.palette_rounded,
      imagePath: 'assets/images/nafiye.png',
    ),
    _TeamMember(
      name: 'Ahmet Hamdi ÇEÇEN',
      role: 'Backendçi Api',
      icon: Icons.receipt_long_rounded,
      imagePath: 'assets/images/nafiye.png',
    ),
    _TeamMember(
      name: 'Mehmet DURSUN',
      role: 'Memoli Garson',
      icon: Icons.verified_rounded,
      imagePath: 'assets/images/nafiye.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFF6F8F6),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 190,
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'Biz Kimiz',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_primaryColor, _primaryDark],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -20,
                      child: Icon(
                        Icons.restaurant_menu_rounded,
                        size: 160,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      bottom: 56,
                      right: 20,
                      child: Text(
                        'Restoran otomasyonu deneyimini hızlandırmak için '
                        'birlikte çalışan 5 kişilik bir ekibiz.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final member = _members[index];
                return _TeamMemberCard(
                  member: member,
                  index: index,
                  isDark: isDark,
                );
              }, childCount: _members.length),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamMember {
  final String name;
  final String role;
  final IconData icon;
  final String? imagePath;

  const _TeamMember({
    required this.name,
    required this.role,
    required this.icon,
    this.imagePath,
  });
}

class _TeamMemberCard extends StatelessWidget {
  const _TeamMemberCard({
    required this.member,
    required this.index,
    required this.isDark,
  });

  final _TeamMember member;
  final int index;
  final bool isDark;

  static const Color _primaryColor = Color(0xFF2E7D32);

  static const List<List<Color>> _avatarGradients = [
    [Color(0xFF43A047), Color(0xFF1B5E20)],
    [Color(0xFF00897B), Color(0xFF004D40)],
    [Color(0xFF6D4C41), Color(0xFF3E2723)],
    [Color(0xFF5E35B1), Color(0xFF311B92)],
    [Color(0xFF00838F), Color(0xFF006064)],
  ];

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Widget _buildAvatar(List<Color> gradient) {
    final fallback = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(member.name),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );

    if (member.imagePath == null || member.imagePath!.isEmpty) {
      return fallback;
    }

    return ClipOval(
      child: Image.asset(
        member.imagePath!,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        // Görsel bulunamazsa (yol yanlışsa ya da henüz eklenmediyse)
        // otomatik olarak baş harfli avatara döner, uygulama çökmez.
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _avatarGradients[index % _avatarGradients.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171717) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE7EBE7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 52, height: 52, child: _buildAvatar(gradient)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  member.role,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: isDark ? 0.16 : 0.08),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(member.icon, size: 17, color: _primaryColor),
          ),
        ],
      ),
    );
  }
}
