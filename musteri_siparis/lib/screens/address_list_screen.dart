import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({
    super.key,
    this.user,
    this.initialAddresses,
    this.initialSelectedAddressId,
  });

  final User? user;
  final List<Address>? initialAddresses;
  final int? initialSelectedAddressId;

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  static const Color _primaryColor = Color(0xFF2E7D32);
  static const Color _accentColor = Color(0xFF1B5E20);

  User? _user;
  List<Address> _addresses = [];
  bool _isLoading = true;
  bool _saving = false;
  String? _errorMessage;
  int? _selectedAddressId;

  final Map<int, Future<_AddressCardData>> _cardFutureCache = {};

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _addresses = widget.initialAddresses ?? [];
    _selectedAddressId = widget.initialSelectedAddressId;
    _loadAddressData();
  }

  Future<void> _loadAddressData({bool fromRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _cardFutureCache.clear();
    });

    try {
      final currentUser = await ApiService.getProfile();
      final addresses = await ApiService.getAddresses();
      final prefs = await SharedPreferences.getInstance();
      final userId = await _userKey();
      final savedSelectedId = prefs.getInt('default_address_$userId');

      if (!mounted) return;
      setState(() {
        _user = currentUser;
        _addresses = addresses;
        _selectedAddressId =
            savedSelectedId ??
            widget.initialSelectedAddressId ??
            (_addresses.isNotEmpty ? _addresses.first.adresId : null);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadAddressData(fromRefresh: true);
  }

  Future<String> _userKey() async {
    final currentUser = await ApiService.getCurrentUser();
    return currentUser?['userId']?.toString() ?? 'guest';
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _setDefaultAddress(int addressId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await _userKey();
    await prefs.setInt('default_address_$userId', addressId);
    if (!mounted) return;
    setState(() => _selectedAddressId = addressId);
  }

  Future<void> _clearDefaultAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await _userKey();
    await prefs.remove('default_address_$userId');
  }

  Future<void> _onSelectAddress(Address address) async {
    await _setDefaultAddress(address.adresId);
  }

  Future<void> _openAddressForm({
    Address? existingAddress,
    _AddressFormSeed? seed,
  }) async {
    final initial = seed ?? _seedFromAddress(existingAddress);
    final result = await showModalBottomSheet<_AddressFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      builder: (context) {
        return _AddressFormSheet(
          seed: initial,
          title: existingAddress == null ? 'Yeni Adres Ekle' : 'Adresi Düzenle',
        );
      },
    );

    if (result == null) return;
    await _saveAddressResult(result, existingAddress);
  }

  _AddressFormSeed _seedFromAddress(Address? address) {
    final parsed = _parseAddressText(address?.acikAdres ?? '');
    return _AddressFormSeed(
      title: address?.adresTipi ?? parsed.title ?? 'Ev',
      neighborhood: parsed.neighborhood ?? '',
      district: parsed.district ?? '',
      city: parsed.city ?? '',
      detail: parsed.detail,
      buildingNo: parsed.buildingNo ?? '',
      floor: parsed.floor ?? '',
      apartmentNo: parsed.apartmentNo ?? '',
      phone: parsed.phone ?? _user?.uyeTelefon ?? '',
      coordinates: parsed.coordinates,
      deliveryZone: address?.teslimatBolgesindeMi ?? true,
      setDefault: _selectedAddressId == address?.adresId,
    );
  }

  Future<void> _saveAddressResult(
    _AddressFormResult result,
    Address? existingAddress,
  ) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final storedText = _composeStoredAddressText(result);
      final saveResult = await ApiService.addAddress(
        adresTipi: result.title.isEmpty ? result.typeLabel : result.title,
        acikAdres: storedText,
        teslimatBolgesindeMi: result.deliveryZone,
      );

      if (saveResult['success'] != true) {
        _showSnackBar(
          saveResult['message'] ?? 'Adres kaydedilemedi',
          Colors.red,
        );
        return;
      }

      if (existingAddress != null) {
        await ApiService.deleteAddress(existingAddress.adresId);
      }

      await _loadAddressData();
      final match = _findAddressByContent(result.typeLabel, storedText);
      if (result.setDefault && match != null) {
        await _setDefaultAddress(match.adresId);
      }

      if (!mounted) return;
      _showSnackBar('✅ Adres kaydedildi', Colors.green);
    } catch (e) {
      _showSnackBar('Adres kaydedilemedi', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Address? _findAddressByContent(String title, String content) {
    for (final address in _addresses) {
      if (address.adresTipi == title && address.acikAdres == content) {
        return address;
      }
    }
    return _addresses.isNotEmpty ? _addresses.first : null;
  }

  Future<void> _deleteAddress(Address address) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adresi Sil'),
          content: const Text('Bu adresi silmek istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    final result = await ApiService.deleteAddress(address.adresId);
    if (result['success'] == true) {
      if (_selectedAddressId == address.adresId) {
        await _clearDefaultAddress();
      }
      await _loadAddressData();
      _showSnackBar('✅ Adres silindi', Colors.green);
    } else {
      _showSnackBar('❌ Adres silinemedi', Colors.red);
    }
  }

  Future<_AddressCardData> _resolveCardData(Address address) async {
    final parsed = _parseAddressText(address.acikAdres);
    final phone = _maskPhone(parsed.phone ?? _user?.uyeTelefon ?? '');
    LatLng? coordinates = parsed.coordinates;
    Placemark? placemark;

    if (coordinates == null) {
      final query = _geocodeQuery(parsed);
      if (query.isNotEmpty) {
        try {
          final locations = await locationFromAddress(query);
          if (locations.isNotEmpty) {
            final location = locations.first;
            coordinates = LatLng(location.latitude, location.longitude);
            final placemarks = await placemarkFromCoordinates(
              location.latitude,
              location.longitude,
            );
            if (placemarks.isNotEmpty) {
              placemark = placemarks.first;
            }
          }
        } catch (e) {
          debugPrint('Adres geocode edilemedi: $e');
        }
      }
    } else {
      try {
        final placemarks = await placemarkFromCoordinates(
          coordinates.latitude,
          coordinates.longitude,
        );
        if (placemarks.isNotEmpty) {
          placemark = placemarks.first;
        }
      } catch (e) {
        debugPrint('Koordinat reverse geocode edilemedi: $e');
      }
    }

    final neighborhood = parsed.neighborhood ?? placemark?.subLocality;
    final district = parsed.district ?? placemark?.subAdministrativeArea;
    final city = parsed.city ?? placemark?.administrativeArea;
    final locationLine = _joinParts([neighborhood, district, city]);

    return _AddressCardData(
      title: address.adresTipi,
      locationLine: locationLine.isEmpty ? 'Konum bilgisi yok' : locationLine,
      detailLine: parsed.detail.isNotEmpty ? parsed.detail : address.acikAdres,
      buildingLine: _joinParts([
        parsed.buildingNo != null ? 'Bina No: ${parsed.buildingNo}' : null,
        parsed.floor != null ? 'Kat: ${parsed.floor}' : null,
        parsed.apartmentNo != null ? 'Daire No: ${parsed.apartmentNo}' : null,
      ], separator: ', '),
      phoneMasked: phone,
      coordinates: coordinates,
    );
  }

  Future<_AddressCardData> _cardDataFor(Address address) {
    return _cardFutureCache.putIfAbsent(
      address.adresId,
      () => _resolveCardData(address),
    );
  }

  _AddressParsedText _parseAddressText(String raw) {
    final lines = raw
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    String? title;
    String? neighborhood;
    String? district;
    String? city;
    String detail = '';
    String? buildingNo;
    String? floor;
    String? apartmentNo;
    String? phone;
    LatLng? coordinates;

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.startsWith('başlık:')) {
        title = _valueAfterColon(line);
      } else if (lower.startsWith('mahalle:')) {
        neighborhood = _valueAfterColon(line);
      } else if (lower.startsWith('ilçe:') || lower.startsWith('ilce:')) {
        district = _valueAfterColon(line);
      } else if (lower.startsWith('il:')) {
        city = _valueAfterColon(line);
      } else if (lower.startsWith('açık adres:') ||
          lower.startsWith('acik adres:')) {
        detail = _valueAfterColon(line);
      } else if (lower.startsWith('bina no:')) {
        buildingNo = _valueAfterColon(line);
      } else if (lower.startsWith('kat:')) {
        floor = _valueAfterColon(line);
      } else if (lower.startsWith('daire no:')) {
        apartmentNo = _valueAfterColon(line);
      } else if (lower.startsWith('telefon:')) {
        phone = _valueAfterColon(line);
      } else if (lower.startsWith('konum:')) {
        final value = _valueAfterColon(line);
        final parts = value.split(',').map((e) => e.trim()).toList();
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0]);
          final lng = double.tryParse(parts[1]);
          if (lat != null && lng != null) {
            coordinates = LatLng(lat, lng);
          }
        }
      }
    }

    if (neighborhood == null || district == null || city == null) {
      final fallback = _parseQuickFallback(raw);
      neighborhood ??= fallback.neighborhood;
      district ??= fallback.district;
      city ??= fallback.city;
      title ??= fallback.title;
      if (detail.isEmpty) {
        detail = fallback.detail;
      }
      buildingNo ??= fallback.buildingNo;
      floor ??= fallback.floor;
      apartmentNo ??= fallback.apartmentNo;
      phone ??= fallback.phone;
      coordinates ??= fallback.coordinates;
    }

    return _AddressParsedText(
      title: title,
      neighborhood: neighborhood,
      district: district,
      city: city,
      detail: detail,
      buildingNo: buildingNo,
      floor: floor,
      apartmentNo: apartmentNo,
      phone: phone,
      coordinates: coordinates,
    );
  }

  _AddressParsedText _parseQuickFallback(String raw) {
    final parts = raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return _AddressParsedText(
      title: parts.isNotEmpty ? parts.first : null,
      neighborhood: parts.length > 1 ? parts[0] : null,
      district: parts.length > 2 ? parts[1] : null,
      city: parts.length > 3 ? parts[2] : null,
      detail: raw,
      buildingNo: null,
      floor: null,
      apartmentNo: null,
      phone: null,
      coordinates: null,
    );
  }

  String _geocodeQuery(_AddressParsedText parsed) {
    final parts = <String>[
      if (parsed.detail.isNotEmpty) parsed.detail,
      if (parsed.neighborhood != null && parsed.neighborhood!.isNotEmpty)
        parsed.neighborhood!,
      if (parsed.district != null && parsed.district!.isNotEmpty)
        parsed.district!,
      if (parsed.city != null && parsed.city!.isNotEmpty) parsed.city!,
    ];
    return parts.join(', ');
  }

  String _composeStoredAddressText(_AddressFormResult result) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Başlık: ${result.title.isEmpty ? result.typeLabel : result.title}',
    );
    buffer.writeln('Mahalle: ${result.neighborhood}');
    buffer.writeln('İlçe: ${result.district}');
    buffer.writeln('İl: ${result.city}');
    buffer.writeln('Açık Adres: ${result.detail}');
    if (result.buildingNo.isNotEmpty) {
      buffer.writeln('Bina No: ${result.buildingNo}');
    }
    if (result.floor.isNotEmpty) {
      buffer.writeln('Kat: ${result.floor}');
    }
    if (result.apartmentNo.isNotEmpty) {
      buffer.writeln('Daire No: ${result.apartmentNo}');
    }
    if (result.phone.isNotEmpty) {
      buffer.writeln('Telefon: ${result.phone}');
    }
    if (result.coordinates != null) {
      buffer.writeln(
        'Konum: ${result.coordinates!.latitude},${result.coordinates!.longitude}',
      );
    }
    return buffer.toString().trim();
  }

  String _valueAfterColon(String text) {
    final index = text.indexOf(':');
    if (index == -1) return text.trim();
    return text.substring(index + 1).trim();
  }

  String _maskPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 5) return raw.isEmpty ? '-' : raw;
    final prefix = digits.substring(0, 3);
    final suffix = digits.substring(digits.length - 2);
    final stars = '*' * (digits.length - 5);
    return '$prefix$stars$suffix';
  }

  String _joinParts(List<String?> parts, {String separator = ' / '}) {
    return parts
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(separator);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.close,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        title: Text(
          'Adreslerim',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : _errorMessage != null
          ? _buildErrorState()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1C1C1C)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Düzenle butonuna basarak adres bilgilerini düzenleyebilir veya adresini silebilirsin.',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade300 : Colors.grey,
                            height: 1.4,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openAddressForm(),
                          icon: const Icon(Icons.add),
                          label: const Text('Yeni Adres Ekle'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _accentColor,
                            side: const BorderSide(color: _primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: RefreshIndicator(
                    color: _primaryColor,
                    onRefresh: _refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _addresses.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final address = _addresses[index];
                        return _AddressCard(
                          address: address,
                          isSelected: _selectedAddressId == address.adresId,
                          selectedAddressId: _selectedAddressId,
                          isDark: isDark,
                          onSelect: () => _onSelectAddress(address),
                          onEdit: () =>
                              _openAddressForm(existingAddress: address),
                          onDelete: () => _deleteAddress(address),
                          cardDataFuture: _cardDataFor(address),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 52),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Adresler yüklenemedi',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.isSelected,
    required this.selectedAddressId,
    required this.isDark,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    required this.cardDataFuture,
  });

  final Address address;
  final bool isSelected;
  final int? selectedAddressId;
  final bool isDark;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Future<_AddressCardData> cardDataFuture;

  static const Color _primaryColor = Color(0xFF2E7D32);
  static const Color _accentColor = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AddressCardData>(
      future: cardDataFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Radio<int>(
                      value: address.adresId,
                      groupValue: selectedAddressId,
                      activeColor: Colors.black,
                      fillColor: MaterialStateProperty.resolveWith(
                        (states) => Colors.black,
                      ),
                      onChanged: (_) => onSelect(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  data?.title ?? address.adresTipi,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: onEdit,
                                borderRadius: BorderRadius.circular(8),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: _accentColor,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Düzenle',
                                      style: TextStyle(
                                        color: _accentColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            data?.locationLine ?? '-',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data?.detailLine ?? address.acikAdres,
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              height: 1.4,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if ((data?.buildingLine ?? '').isNotEmpty)
                            Text(
                              data!.buildingLine,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            data?.phoneMasked != null &&
                                    data!.phoneMasked.isNotEmpty
                                ? data.phoneMasked
                                : '-',
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isSelected) ...[const SizedBox(height: 4)],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onSelect,
                        icon: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: _primaryColor,
                        ),
                        label: const Text('Varsayılan Yap'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: BorderSide(
                            color: _primaryColor.withValues(alpha: 0.45),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AddressFormSheet extends StatefulWidget {
  const _AddressFormSheet({required this.seed, required this.title});

  final _AddressFormSeed seed;
  final String title;

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  static const Color _primaryColor = Color(0xFF2E7D32);

  late final TextEditingController _titleController;
  late final TextEditingController _neighborhoodController;
  late final TextEditingController _districtController;
  late final TextEditingController _cityController;
  late final TextEditingController _detailController;
  late final TextEditingController _buildingNoController;
  late final TextEditingController _floorController;
  late final TextEditingController _apartmentNoController;
  late final TextEditingController _phoneController;

  late String _typeLabel;
  late bool _setDefault;
  LatLng? _coordinates;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.seed.title);
    _neighborhoodController = TextEditingController(
      text: widget.seed.neighborhood,
    );
    _districtController = TextEditingController(text: widget.seed.district);
    _cityController = TextEditingController(text: widget.seed.city);
    _detailController = TextEditingController(text: widget.seed.detail);
    _buildingNoController = TextEditingController(text: widget.seed.buildingNo);
    _floorController = TextEditingController(text: widget.seed.floor);
    _apartmentNoController = TextEditingController(
      text: widget.seed.apartmentNo,
    );
    _phoneController = TextEditingController(text: widget.seed.phone);
    _typeLabel = widget.seed.title.isEmpty ? 'Ev' : widget.seed.title;
    _setDefault = widget.seed.setDefault;
    _coordinates = widget.seed.coordinates;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _neighborhoodController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _detailController.dispose();
    _buildingNoController.dispose();
    _floorController.dispose();
    _apartmentNoController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Material(
      color: Colors.white,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Ev', 'İş', 'Diğer'].map((label) {
                      final selected = _typeLabel == label;
                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        selectedColor: _primaryColor.withValues(alpha: 0.14),
                        onSelected: (_) => setState(() => _typeLabel = label),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _field(
                    _titleController,
                    'Adres Başlığı',
                    Icons.label_outline,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          _neighborhoodController,
                          'Mahalle',
                          Icons.home_work_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          _districtController,
                          'İlçe',
                          Icons.map_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _field(_cityController, 'İl', Icons.location_city_outlined),
                  const SizedBox(height: 12),
                  _field(
                    _detailController,
                    'Açık Adres',
                    Icons.location_on_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          _buildingNoController,
                          'Bina No',
                          Icons.apartment_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          _floorController,
                          'Kat',
                          Icons.layers_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          _apartmentNoController,
                          'Daire No',
                          Icons.meeting_room_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _phoneController,
                    'Telefon',
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Varsayılan adres yap'),
                    value: _setDefault,
                    activeThumbColor: _primaryColor,
                    activeTrackColor: _primaryColor.withValues(alpha: 0.35),
                    onChanged: (value) => setState(() => _setDefault = value),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final result = _AddressFormResult(
                          typeLabel: _typeLabel,
                          title: _titleController.text.trim(),
                          neighborhood: _neighborhoodController.text.trim(),
                          district: _districtController.text.trim(),
                          city: _cityController.text.trim(),
                          detail: _detailController.text.trim(),
                          buildingNo: _buildingNoController.text.trim(),
                          floor: _floorController.text.trim(),
                          apartmentNo: _apartmentNoController.text.trim(),
                          phone: _phoneController.text.trim(),
                          coordinates: _coordinates,
                          deliveryZone: widget.seed.deliveryZone,
                          setDefault: _setDefault,
                        );
                        Navigator.pop(context, result);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Kaydet'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.22)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
      ),
    );
  }
}

class _AddressCardData {
  const _AddressCardData({
    required this.title,
    required this.locationLine,
    required this.detailLine,
    required this.buildingLine,
    required this.phoneMasked,
    required this.coordinates,
  });

  final String title;
  final String locationLine;
  final String detailLine;
  final String buildingLine;
  final String phoneMasked;
  final LatLng? coordinates;
}

class _AddressParsedText {
  const _AddressParsedText({
    required this.title,
    required this.neighborhood,
    required this.district,
    required this.city,
    required this.detail,
    required this.buildingNo,
    required this.floor,
    required this.apartmentNo,
    required this.phone,
    required this.coordinates,
  });

  final String? title;
  final String? neighborhood;
  final String? district;
  final String? city;
  final String detail;
  final String? buildingNo;
  final String? floor;
  final String? apartmentNo;
  final String? phone;
  final LatLng? coordinates;
}

class _AddressFormSeed {
  const _AddressFormSeed({
    required this.title,
    required this.neighborhood,
    required this.district,
    required this.city,
    required this.detail,
    required this.buildingNo,
    required this.floor,
    required this.apartmentNo,
    required this.phone,
    required this.coordinates,
    required this.deliveryZone,
    required this.setDefault,
  });

  final String title;
  final String neighborhood;
  final String district;
  final String city;
  final String detail;
  final String buildingNo;
  final String floor;
  final String apartmentNo;
  final String phone;
  final LatLng? coordinates;
  final bool deliveryZone;
  final bool setDefault;
}

class _AddressFormResult {
  const _AddressFormResult({
    required this.typeLabel,
    required this.title,
    required this.neighborhood,
    required this.district,
    required this.city,
    required this.detail,
    required this.buildingNo,
    required this.floor,
    required this.apartmentNo,
    required this.phone,
    required this.coordinates,
    required this.deliveryZone,
    required this.setDefault,
  });

  final String typeLabel;
  final String title;
  final String neighborhood;
  final String district;
  final String city;
  final String detail;
  final String buildingNo;
  final String floor;
  final String apartmentNo;
  final String phone;
  final LatLng? coordinates;
  final bool deliveryZone;
  final bool setDefault;
}
