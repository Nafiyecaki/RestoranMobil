import 'package:flutter/material.dart';

/// Sabit, salt-okunur "Biz Kimiz" sayfası.
/// Ekipte 5 kişi vardır; bu sayfadan ekleme/çıkarma yapılamaz.
class ProfileWhoWeAreScreen extends StatelessWidget {
  const ProfileWhoWeAreScreen({super.key});

  static const Color _primaryColor = Color(0xFF2E7D32);
  static const Color _primaryLight = Color(0xFF4CAF50);
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
          ? const Color(0xFF0B0F0C)
          : const Color(0xFFF3F6F3),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Biz Kimiz',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
      ),
      body: Column(
        children: [
          _buildFixedHeader(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 700;

                if (isWide) {
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 96,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      return _TeamMemberCard(
                        member: member,
                        index: index,
                        isDark: isDark,
                      );
                    },
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
                  itemCount: _members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    return _TeamMemberCard(
                      member: member,
                      index: index,
                      isDark: isDark,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedHeader() {
    return Container(
      height: 150,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryLight, _primaryColor, _primaryDark],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -60,
            top: -50,
            child: _blurredCircle(220, Colors.white, 0.10),
          ),
          Positioned(
            left: -40,
            bottom: -60,
            child: _blurredCircle(180, Colors.white, 0.08),
          ),
          Positioned(
            right: 24,
            bottom: 20,
            child: Icon(
              Icons.restaurant_menu_rounded,
              size: 80,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 16,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _blurredCircle(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
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

class _TeamMemberCard extends StatefulWidget {
  const _TeamMemberCard({
    required this.member,
    required this.index,
    required this.isDark,
  });

  final _TeamMember member;
  final int index;
  final bool isDark;

  @override
  State<_TeamMemberCard> createState() => _TeamMemberCardState();
}

class _TeamMemberCardState extends State<_TeamMemberCard> {
  bool _hovering = false;

  static const List<List<Color>> _avatarGradients = [
    [Color(0xFF4CAF50), Color(0xFF1B5E20)],
    [Color(0xFF26A69A), Color(0xFF004D40)],
    [Color(0xFF8D6E63), Color(0xFF3E2723)],
    [Color(0xFF7E57C2), Color(0xFF311B92)],
    [Color(0xFF26C6DA), Color(0xFF006064)],
  ];

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Widget _buildAvatar(List<Color> gradient) {
    final member = widget.member;
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
          fontSize: 17,
        ),
      ),
    );

    if (member.imagePath == null || member.imagePath!.isEmpty) {
      return fallback;
    }

    return ClipOval(
      child: Image.asset(
        member.imagePath!,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        // Görsel bulunamazsa (yol yanlışsa ya da henüz eklenmediyse)
        // otomatik olarak baş harfli avatara döner, uygulama çökmez.
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final isDark = widget.isDark;
    final gradient = _avatarGradients[widget.index % _avatarGradients.length];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            transform: _hovering
                ? (Matrix4.identity()..translate(0.0, -2.0))
                : Matrix4.identity(),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151916) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _hovering
                    ? gradient.first.withValues(alpha: 0.45)
                    : (isDark
                          ? const Color(0xFF262B27)
                          : const Color(0xFFE7ECE7)),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _hovering
                      ? gradient.first.withValues(alpha: isDark ? 0.18 : 0.14)
                      : Colors.black.withValues(alpha: isDark ? 0.22 : 0.035),
                  blurRadius: _hovering ? 18 : 10,
                  offset: Offset(0, _hovering ? 8 : 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF151916) : Colors.white,
                    ),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: _buildAvatar(gradient),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        member.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF15201A),
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: gradient.first.withValues(
                            alpha: isDark ? 0.18 : 0.10,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          member.role,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? gradient.first
                                : Color.lerp(
                                    gradient.first,
                                    Colors.black,
                                    0.25,
                                  ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        gradient.first.withValues(alpha: isDark ? 0.20 : 0.12),
                        gradient.last.withValues(alpha: isDark ? 0.14 : 0.06),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(member.icon, size: 18, color: gradient.first),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
