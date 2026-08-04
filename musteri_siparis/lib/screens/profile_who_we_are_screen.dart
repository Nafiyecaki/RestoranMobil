import 'package:flutter/material.dart';

class ProfileWhoWeAreScreen extends StatefulWidget {
  const ProfileWhoWeAreScreen({super.key, required this.initialMembers});

  final List<Map<String, String>> initialMembers;

  @override
  State<ProfileWhoWeAreScreen> createState() => _ProfileWhoWeAreScreenState();
}

class _ProfileWhoWeAreScreenState extends State<ProfileWhoWeAreScreen> {
  static const Color _primaryColor = Color(0xFF2E7D32);

  late List<Map<String, String>> _members;

  @override
  void initState() {
    super.initState();
    _members = widget.initialMembers
        .map(
          (member) => {
            'name': member['name'] ?? '',
            'role': member['role'] ?? '',
          },
        )
        .toList();
  }

  Future<void> _openAddMemberDialog() async {
    final nameController = TextEditingController();
    final roleController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Biz Kimiz Üyesi Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'İsim'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roleController,
                decoration: const InputDecoration(labelText: 'Rol / Görev'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final role = roleController.text.trim();
                if (name.isEmpty || role.isEmpty) return;
                Navigator.pop(context, {'name': name, 'role': role});
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    roleController.dispose();

    if (!mounted || result == null) return;

    setState(() {
      _members.add(result);
    });
  }

  Future<void> _removeMember(int index) async {
    setState(() {
      _members.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pop(context, _members);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Biz Kimiz'),
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _members),
          ),
          actions: [
            IconButton(
              onPressed: _openAddMemberDialog,
              icon: const Icon(Icons.add),
              tooltip: 'Üye Ekle',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Restoran otomasyonu deneyimini hızlandırmak için birlikte çalışan 5 kişilik bir ekibiz.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _members.isEmpty
                    ? Center(
                        child: Text(
                          'Henüz ekip üyesi eklenmedi',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _members.length,
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.03)
                                  : Colors.grey.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.grey.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Color(0x142E7D32),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.person,
                                    size: 16,
                                    color: _primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member['name'] ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        member['role'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeMember(index),
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
