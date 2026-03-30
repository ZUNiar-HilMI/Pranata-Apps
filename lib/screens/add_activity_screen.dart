import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/activity.dart';
import '../services/firestore_service.dart';
import '../services/image_service.dart';
import '../providers/auth_provider.dart';
import '../config/app_theme.dart';

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _storageService = FirestoreService();
  final ImagePicker _picker = ImagePicker();
  final MapController _mapController = MapController();
  
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  
  // Photo upload state
  File? _photoBeforeFile;
  File? _photoAfterFile;
  String? _photoBeforeWeb;   // blob URL for web preview only
  String? _photoAfterWeb;
  XFile? _photoBeforeXFile;  // web: XFile for actual upload
  XFile? _photoAfterXFile;
  
  // Location state
  double? _latitude;
  double? _longitude;
  String _locationAddress = 'Loading location...';
  bool _isLoadingLocation = true;
  
  // Animation
  late AnimationController _successController;
  late Animation<double> _successScale;
  late Animation<double> _successOpacity;
  bool _showSuccessOverlay = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
    _successOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _successController.dispose();
    super.dispose();
  }

  /// Show animated success overlay then close the screen
  Future<void> _showSuccessAndClose() async {
    setState(() => _showSuccessOverlay = true);
    await _successController.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) Navigator.pop(context, true); // return true = success
  }

  // Get current GPS location
  Future<void> _getCurrentLocation() async {
    // Set default location (Jakarta, Indonesia) initially
    setState(() {
      _latitude = -6.2088;
      _longitude = 106.8456;
      _locationAddress = 'Jakarta, Indonesia (Default)';
      _isLoadingLocation = false;
    });

    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Keep default location
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied. Using default location.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        // Keep default location
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission permanently denied. Using default location.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      setState(() {
        _isLoadingLocation = true;
        _locationAddress = 'Getting your location...';
      });

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Location timeout');
        },
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      // Move map to current location
      _mapController.move(LatLng(_latitude!, _longitude!), 15.0);

      // Get address from coordinates
      await _getAddressFromCoordinates(_latitude!, _longitude!);
    } catch (e) {
      setState(() {
        _locationAddress = 'Jakarta, Indonesia (Default - ${e.toString()})';
        _isLoadingLocation = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using default location: ${e.toString()}'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Reverse geocoding: get address from coordinates
  Future<void> _getAddressFromCoordinates(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _locationAddress = '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _locationAddress = 'Lat: ${lat.toStringAsFixed(6)}, Lon: ${lon.toStringAsFixed(6)}';
        _isLoadingLocation = false;
      });
    }
  }

  // Pick image from camera or gallery
  Future<void> _pickImage(bool isBefore) async {
    try {
      // Pick image - works on both web and mobile
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          // On web, store XFile for upload + blob URL for preview
          setState(() {
            if (isBefore) {
              _photoBeforeXFile = image;
              _photoBeforeWeb = image.path;
              _photoBeforeFile = null;
            } else {
              _photoAfterXFile = image;
              _photoAfterWeb = image.path;
              _photoAfterFile = null;
            }
          });
        } else {
          // On mobile, use File with compression
          final file = File(image.path);
          final fileSize = await file.length();
          if (fileSize > ImageService.maxInputSizeBytes) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Gambar terlalu besar (${ImageService.formatFileSize(fileSize)}). Maksimum 3MB.',
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            return;
          }
          setState(() {
            if (isBefore) {
              _photoBeforeFile = file;
              _photoBeforeWeb = null;
            } else {
              _photoAfterFile = file;
              _photoAfterWeb = null;
            }
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📷 Foto dipilih: ${image.name}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting photo: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      print('Error picking image: $e');
    }
  }

  // Upload foto ke ImgBB, returns URL publik permanen
  Future<String?> _savePhotoToStorage(
    File? photoFile,
    String? photoWeb,
    XFile? photoXFile,
    String fileName,
  ) async {
    if (kIsWeb) {
      // Web: baca bytes dari XFile lalu upload ke ImgBB
      if (photoXFile == null) return null;
      try {
        final bytes = Uint8List.fromList(await photoXFile.readAsBytes());
        final url = await ImageService.uploadToImgBB(bytes, fileName);
        debugPrint('🖼️ Web photo uploaded to ImgBB: $url');
        return url;
      } catch (e) {
        debugPrint('⚠️ Web ImgBB upload failed: $e');
        return null;
      }
    }
    // Mobile: compress lalu upload ke ImgBB
    if (photoFile == null) return null;
    try {
      final url = await ImageService.compressAndUpload(photoFile, fileName);
      debugPrint('🖼️ Mobile photo uploaded to ImgBB: $url');
      return url;
    } catch (e) {
      debugPrint('⚠️ Mobile ImgBB upload failed: $e');
      return photoFile.path; // fallback local
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.navyDark,
          appBar: _buildAppBar(),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateSection(),
                    const SizedBox(height: 20),
                    _buildActivityNameField(),
                    const SizedBox(height: 20),
                    _buildDescriptionField(),
                    const SizedBox(height: 20),
                    _buildBudgetField(),
                    const SizedBox(height: 20),
                    _buildPhotosSection(),
                    const SizedBox(height: 20),
                    _buildLocationSection(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
        // ✅ Success overlay
        if (_showSuccessOverlay)
          AnimatedBuilder(
            animation: _successController,
            builder: (context, _) {
              return Opacity(
                opacity: _successOpacity.value,
                child: Container(
                  color: Colors.black.withOpacity(0.55),
                  child: Center(
                    child: ScaleTransition(
                      scale: _successScale,
                      child: Container(
                        width: 220,
                        padding: const EdgeInsets.symmetric(
                          vertical: 36,
                          horizontal: 24,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.navyCard,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.goldMid.withOpacity(0.4)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF22C55E),
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Berhasil!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.goldLight,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Kegiatan berhasil disimpan',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.navyMid,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.goldLight),
        onPressed: () {},
      ),
      title: const Text(
        'Tambah Kegiatan',
        style: TextStyle(
          color: AppColors.goldLight,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Batal',
            style: TextStyle(
              color: AppColors.goldMid,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldMid.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tanggal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.goldLight,
                  ),
                ),
                Text(
                  _selectedDate.day == DateTime.now().day ? 'Hari ini' : DateFormat('MMM d, yyyy').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.goldMid,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.goldMid),
          Padding(
            padding: const EdgeInsets.all(8),
            child: _buildCalendar(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                  });
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_currentMonth),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.goldLight,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                  });
                },
              ),
            ],
          ),
        ),
        _buildCalendarGrid(),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final startingWeekday = firstDayOfMonth.weekday % 7;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
            return SizedBox(
              width: 36,
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: 42,
          itemBuilder: (context, index) {
            final dayNumber = index - startingWeekday + 1;
            
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox();
            }

            final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
            final isSelected = date.day == _selectedDate.day && 
                              date.month == _selectedDate.month && 
                              date.year == _selectedDate.year;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedDate = date;
                });
              },
              child: Container(
                decoration: isSelected
                    ? BoxDecoration(
                        color: AppColors.goldMid,
                        shape: BoxShape.circle,
                      )
                    : null,
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.navyDark : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nama Kegiatan',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.goldLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'contoh: Rapat Komunitas',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.navyCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.goldMid.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.goldMid.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.goldLight, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Name is required for this activity type.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deskripsi',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.goldLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 5,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Masukkan detail kegiatan...',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.navyCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.goldMid.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.goldMid.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.goldLight, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jumlah Budget',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.goldLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _budgetController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            prefixText: 'Rp ',
            prefixStyle: const TextStyle(
              color: AppColors.goldMid,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: AppColors.navyCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.goldMid.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.goldMid.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.goldLight, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Kegiatan',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.goldLight,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildPhotoUpload('Sebelum', true)),
            const SizedBox(width: 16),
            Expanded(child: _buildPhotoUpload('Sesudah', false)),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoUpload(String label, bool isBefore) {
    final photoFile = isBefore ? _photoBeforeFile : _photoAfterFile;
    final photoWeb = isBefore ? _photoBeforeWeb : _photoAfterWeb;
    final hasPhoto = (kIsWeb && photoWeb != null) || (!kIsWeb && photoFile != null);
    
    return GestureDetector(
      onTap: () => _pickImage(isBefore),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.navyCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasPhoto ? AppColors.success : AppColors.goldMid.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (kIsWeb && photoWeb != null)
                  // Web: Display using NetworkImage (blob URL)
                  Image.network(
                    photoWeb,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$label Selected',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF22C55E),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                else if (!kIsWeb && photoFile != null)
                  // Mobile: Display using FileImage
                  Image.file(
                    photoFile,
                    fit: BoxFit.cover,
                  )
                else
                  // No photo selected
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.navyLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.goldMid.withOpacity(0.4),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate,
                          color: AppColors.goldMid,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ketuk untuk upload',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                // Remove button if photo selected
                if (hasPhoto)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isBefore) {
                            _photoBeforeFile = null;
                            _photoBeforeWeb = null;
                            _photoBeforeXFile = null;
                          } else {
                            _photoAfterFile = null;
                            _photoAfterWeb = null;
                            _photoAfterXFile = null;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Lokasi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.goldLight,
              ),
            ),
            TextButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.my_location, size: 14),
              label: const Text('Refresh'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.goldMid,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.goldMid.withOpacity(0.35)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _latitude != null && _longitude != null
                ? FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(_latitude!, _longitude!),
                      initialZoom: 15.0,
                      onTap: (tapPosition, point) {
                        setState(() {
                          _latitude = point.latitude;
                          _longitude = point.longitude;
                        });
                        _getAddressFromCoordinates(point.latitude, point.longitude);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.my_first_app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(_latitude!, _longitude!),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFFEF4444),
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.near_me, size: 14, color: AppColors.goldMid),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _isLoadingLocation ? 'Mendapatkan lokasi...' : _locationAddress,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            // Validate name field
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter activity name'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Get current user
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final user = authProvider.currentUser;

            if (user == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please login first'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Parse budget
            final budget = double.tryParse(_budgetController.text) ?? 0.0;

            // Generate unique ID
            final activityId = DateTime.now().millisecondsSinceEpoch.toString();

            // Save photos to permanent storage
            final photoBeforePath = await _savePhotoToStorage(
              _photoBeforeFile,
              _photoBeforeWeb,
              _photoBeforeXFile,
              'activity_${activityId}_before.jpg',
            );
            final photoAfterPath = await _savePhotoToStorage(
              _photoAfterFile,
              _photoAfterWeb,
              _photoAfterXFile,
              'activity_${activityId}_after.jpg',
            );

            // Create activity
            final activity = Activity(
              id: activityId,
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              budget: budget,
              date: _selectedDate,
              location: _locationAddress,
              latitude: _latitude,
              longitude: _longitude,
              photoBefore: photoBeforePath,
              photoAfter: photoAfterPath,
              userId: user.id,
              dinasId: user.dinasId ?? '',
              status: 'pending',
              createdAt: DateTime.now(),
            );

            // Save activity
            await _storageService.saveActivity(activity);

            if (mounted) {
              // Show success animation then close
              await _showSuccessAndClose();
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22C55E),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          shadowColor: const Color(0xFF22C55E).withOpacity(0.2),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check, size: 20),
            SizedBox(width: 8),
            Text(
              'Save Activity',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
