import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/app_settings.dart';

class ShareRunScreen extends StatefulWidget {
  final List<LatLng> routePoints;
  final double distanceKm;
  final int durationSeconds;
  final int calories;

  const ShareRunScreen({
    super.key,
    this.routePoints = const [],
    required this.distanceKm,
    required this.durationSeconds,
    this.calories = 0,
  });

  @override
  State<ShareRunScreen> createState() => _ShareRunScreenState();
}

class _ShareRunScreenState extends State<ShareRunScreen> {
  final GlobalKey _captureKey = GlobalKey();
  final ScrollController _selectorScrollController = ScrollController();
  int _selectedTemplate = 0;
  File? _backgroundImage;
  bool _isExporting = false;

  static const int _totalTemplates = 10;

  String get _formattedDuration {
    final hours = widget.durationSeconds ~/ 3600;
    final minutes = (widget.durationSeconds % 3600) ~/ 60;
    final seconds = widget.durationSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get _formattedPace {
    if (widget.distanceKm < 0.02 || widget.durationSeconds == 0) {
      return '--:-- /km';
    }
    final paceSecondsTotal =
        (widget.durationSeconds / widget.distanceKm).round();
    final paceMin = paceSecondsTotal ~/ 60;
    final paceSec = paceSecondsTotal % 60;
    return '${paceMin.toString().padLeft(2, '0')}:${paceSec.toString().padLeft(2, '0')} /km';
  }

  String get _formattedDate {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked != null && mounted) {
      setState(() {
        _backgroundImage = File(picked.path);
      });
    }
  }

  void _clearPhoto() {
    setState(() {
      _backgroundImage = null;
    });
  }

  void _selectTemplate(int index) {
    final clamped = index.clamp(0, _totalTemplates - 1);
    setState(() => _selectedTemplate = clamped);
    if (_selectorScrollController.hasClients) {
      _selectorScrollController.animateTo(
        (clamped * 120.0).clamp(
          0.0,
          _selectorScrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _captureAndShare() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      await Future.delayed(const Duration(milliseconds: 50));
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'timelite_run_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = await File('${tempDir.path}/$fileName').create();
      await file.writeAsBytes(pngBytes);

      final shareText =
          '${appSettings.t('share_run_1')} ${widget.distanceKm.toStringAsFixed(2)} km ${appSettings.t('share_run_2')} $_formattedDuration ${appSettings.t('share_run_3')}';

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: shareText,
      );
    } catch (e) {
      debugPrint('Error al exportar imagen: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  void dispose() {
    _selectorScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appSettings.isDarkMode;
    final isEs = appSettings.languageCode == 'es';
    final textColor = isDark ? Colors.white : const Color(0xFF1A237E);

    final templates = [
      {'icon': Icons.layers_clear_rounded, 'label': '1. Sticker PNG'},
      {'icon': Icons.grid_4x4_rounded, 'label': '2. Cyber Grid'},
      {
        'icon': Icons.photo_camera_rounded,
        'label': isEs ? '3. Con Foto' : '3. Photo'
      },
      {'icon': Icons.local_fire_department_rounded, 'label': '4. Blaze Pro'},
      {'icon': Icons.article_rounded, 'label': '5. Editorial'},
      {'icon': Icons.wb_sunny_rounded, 'label': '6. Minimal'},
      {'icon': Icons.nightlight_round, 'label': '7. Vaporwave'},
      {'icon': Icons.workspace_premium_rounded, 'label': '8. Gold Elite'},
      {'icon': Icons.blur_on_rounded, 'label': '9. Aurora'},
      {'icon': Icons.speed_rounded, 'label': '10. Speed HUD'},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${appSettings.t('share_studio')} (${_selectedTemplate + 1}/$_totalTemplates)',
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0C101B), const Color(0xFF1B2340)]
                : [const Color(0xFFF3F2F7), const Color(0xFFE2E6F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Vista previa deslizable 9:15 lista para Instagram Stories
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity < -200 &&
                        _selectedTemplate < _totalTemplates - 1) {
                      _selectTemplate(_selectedTemplate + 1);
                    } else if (velocity > 200 && _selectedTemplate > 0) {
                      _selectTemplate(_selectedTemplate - 1);
                    }
                  },
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 6,
                      ),
                      child: AspectRatio(
                        aspectRatio: 9 / 15,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_selectedTemplate == 0 &&
                                _backgroundImage == null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: CustomPaint(
                                  painter: _CheckerboardPainter(isDark: isDark),
                                ),
                              ),
                            RepaintBoundary(
                              key: _captureKey,
                              child: _buildSelectedCard(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (_selectedTemplate == 0 && _backgroundImage == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    appSettings.t('transparent_hint'),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              // Controles de Cámara / Galería disponibles en todas las plantillas
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _photoSourceChip(
                      icon: Icons.photo_library_rounded,
                      label: appSettings.t('pick_photo'),
                      onTap: () => _pickPhoto(ImageSource.gallery),
                    ),
                    _photoSourceChip(
                      icon: Icons.camera_alt_rounded,
                      label: isEs ? 'Cámara' : 'Camera',
                      onTap: () => _pickPhoto(ImageSource.camera),
                    ),
                    if (_backgroundImage != null)
                      _photoSourceChip(
                        icon: Icons.close_rounded,
                        label: isEs ? 'Quitar' : 'Remove',
                        accentColor: Colors.redAccent,
                        onTap: _clearPhoto,
                      ),
                  ],
                ),
              ),

              // Carrusel de 10 plantillas
              SizedBox(
                height: 50,
                child: ListView.separated(
                  controller: _selectorScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: templates.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final selected = _selectedTemplate == index;
                    return GestureDetector(
                      onTap: () => _selectTemplate(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF8FFF00)
                              : (isDark
                                  ? const Color(0xFF161B2E)
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF8FFF00)
                                : (isDark ? Colors.white12 : Colors.black12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              templates[index]['icon'] as IconData,
                              size: 17,
                              color: selected ? Colors.black : textColor,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              templates[index]['label'] as String,
                              style: TextStyle(
                                color: selected ? Colors.black : textColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Botón principal de compartir
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8FFF00),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 6,
                    ),
                    onPressed: _isExporting ? null : _captureAndShare,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.ios_share_rounded, size: 22),
                    label: Text(
                      _isExporting
                          ? appSettings.t('generating_image')
                          : appSettings.t('share_instagram'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoSourceChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color accentColor = const Color(0xFF00E5FF),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: accentColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoOverlayWrapper({
    required Widget child,
    List<Color>? scrimColors,
    Border? border,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: border,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(_backgroundImage!, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: scrimColors ??
                      [
                        Colors.black.withOpacity(0.55),
                        Colors.black.withOpacity(0.25),
                        Colors.black.withOpacity(0.80),
                      ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedCard() {
    switch (_selectedTemplate) {
      case 0:
        return _buildTemplate1Sticker();
      case 1:
        return _buildTemplate2CyberGrid();
      case 2:
        return _buildTemplate3Photo();
      case 3:
        return _buildTemplate4BlazePro();
      case 4:
        return _buildTemplate5Editorial();
      case 5:
        return _buildTemplate6MinimalSwiss();
      case 6:
        return _buildTemplate7Vaporwave();
      case 7:
        return _buildTemplate8GoldElite();
      case 8:
        return _buildTemplate9AuroraGlass();
      case 9:
      default:
        return _buildTemplate10SpeedHud();
    }
  }

  // ---------------------------------------------------------------------------
  // PLANTILLA 1: STICKER PNG TRANSPARENTE (O CON FOTO)
  // ---------------------------------------------------------------------------
  Widget _buildTemplate1Sticker() {
    final shadows = [
      Shadow(
        color: Colors.black.withOpacity(0.85),
        blurRadius: 12,
        offset: const Offset(0, 2),
      ),
    ];

    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded,
                      color: Color(0xFF8FFF00), size: 22),
                  const SizedBox(width: 4),
                  Text(
                    'TIME LITE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 2,
                      shadows: shadows,
                    ),
                  ),
                ],
              ),
              Text(
                _formattedDate,
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  shadows: shadows,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                appSettings.t('distance_label').toUpperCase(),
                style: TextStyle(
                  color: const Color(0xFF8FFF00),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  shadows: shadows,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${widget.distanceKm.toStringAsFixed(2)} km',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    shadows: shadows,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statColumn(
                label: appSettings.t('pace_label').toUpperCase(),
                value: _formattedPace,
                primaryText: Colors.white,
                secondaryText: Colors.white70,
                shadows: shadows,
              ),
              _statColumn(
                label: appSettings.t('time_label').toUpperCase(),
                value: _formattedDuration,
                primaryText: Colors.white,
                secondaryText: Colors.white70,
                shadows: shadows,
              ),
            ],
          ),
        ],
      ),
    );

    if (_backgroundImage != null) {
      return _photoOverlayWrapper(child: content);
    }
    return Container(color: Colors.transparent, child: content);
  }

  // ---------------------------------------------------------------------------
  // PLANTILLA 2: CYBER GRID
  // ---------------------------------------------------------------------------
  Widget _buildTemplate2CyberGrid() {
    const cyan = Color(0xFF00E5FF);

    final innerContent = CustomPaint(
      painter: _TechGridPainter(lineColor: cyan.withOpacity(0.10)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: cyan.withOpacity(0.6)),
                    borderRadius: BorderRadius.circular(6),
                    color: cyan.withOpacity(0.12),
                  ),
                  child: const Text(
                    'TIME LITE // RUN',
                    style: TextStyle(
                      color: cyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Text(
                  _formattedDate,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appSettings.t('distance_label').toUpperCase(),
                  style: const TextStyle(
                    color: cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        widget.distanceKm.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'KM',
                        style: TextStyle(
                          color: cyan,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0C1524).withOpacity(0.85),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cyan.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statColumn(
                    label: appSettings.t('time_label').toUpperCase(),
                    value: _formattedDuration,
                    primaryText: Colors.white,
                    secondaryText: cyan,
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: cyan.withOpacity(0.25),
                  ),
                  _statColumn(
                    label: appSettings.t('pace_label').toUpperCase(),
                    value: _formattedPace,
                    primaryText: Colors.white,
                    secondaryText: cyan,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (_backgroundImage != null) {
      return _photoOverlayWrapper(
        scrimColors: [
          const Color(0xFF060A12).withOpacity(0.65),
          const Color(0xFF060A12).withOpacity(0.35),
          const Color(0xFF060A12).withOpacity(0.85),
        ],
        child: innerContent,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        color: const Color(0xFF060A12),
        child: innerContent,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PLANTILLA 3: FOTO PERSONALIZADA + OVERLAY
  // ---------------------------------------------------------------------------
  Widget _buildTemplate3Photo() {
    final isEs = appSettings.languageCode == 'es';
    final shadows = [
      Shadow(
        color: Colors.black.withOpacity(0.75),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_backgroundImage != null)
            Image.file(_backgroundImage!, fit: BoxFit.cover)
          else
            Container(
              color: const Color(0xFF161B2E),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_a_photo_rounded,
                      color: Colors.white24,
                      size: 56,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isEs ? 'Elige cámara o galería' : 'Pick camera or gallery',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                  Colors.black.withOpacity(0.82),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded,
                            color: Color(0xFF8FFF00), size: 22),
                        const SizedBox(width: 4),
                        Text(
                          'TIME LITE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 2,
                            shadows: shadows,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formattedDate,
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        shadows: shadows,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      appSettings.t('distance_label').toUpperCase(),
                      style: TextStyle(
                        color: const Color(0xFF8FFF00),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8,
                        shadows: shadows,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${widget.distanceKm.toStringAsFixed(2)} km',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          shadows: shadows,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statColumn(
                          label: appSettings.t('pace_label').toUpperCase(),
                          value: _formattedPace,
                          primaryText: Colors.white,
                          secondaryText: Colors.white70,
                          shadows: shadows,
                        ),
                        _statColumn(
                          label: appSettings.t('time_label').toUpperCase(),
                          value: _formattedDuration,
                          primaryText: Colors.white,
                          secondaryText: Colors.white70,
                          shadows: shadows,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PLANTILLA 4: BLAZE PRO
  // ---------------------------------------------------------------------------
  Widget _buildTemplate4BlazePro() {
    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TIME LITE // RUN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.8,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formattedDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appSettings.t('distance_label').toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${widget.distanceKm.toStringAsFixed(2)} KM',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 50,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.32),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statColumn(
                  label: appSettings.t('time_label').toUpperCase(),
                  value: _formattedDuration,
                  primaryText: Colors.white,
                  secondaryText: Colors.white70,
                ),
                Container(width: 1, height: 32, color: Colors.white24),
                _statColumn(
                  label: appSettings.t('pace_label').toUpperCase(),
                  value: _formattedPace,
                  primaryText: Colors.white,
                  secondaryText: Colors.white70,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (_backgroundImage != null) {
      return _photoOverlayWrapper(
        scrimColors: [
          const Color(0xFFFF5E00).withOpacity(0.55),
          const Color(0xFFE52D27).withOpacity(0.35),
          const Color(0xFF4A0700).withOpacity(0.85),
        ],
        child: content,
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5E00), Color(0xFFE52D27), Color(0xFF8E0E00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: content,
    );
  }

  // ---------------------------------------------------------------------------
  // PLANTILLA 5: EDITORIAL MAGAZINE
  // ---------------------------------------------------------------------------
  Widget _buildTemplate5Editorial() {
    final content = Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF8FFF00),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ACTIVITY REPORT',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                ),
              ),
              const Spacer(),
              Text(
                _formattedDate,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appSettings.t('distance_label').toUpperCase(),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${widget.distanceKm.toStringAsFixed(2)} km',
                  style: const TextStyle(
                    color: Color(0xFF8FFF00),
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF191D26).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statColumn(
                      label: appSettings.t('time_label').toUpperCase(),
                      value: _formattedDuration,
                      primaryText: Colors.white,
                      secondaryText: Colors.white60,
                    ),
                    Container(width: 1, height: 32, color: Colors.white12),
                    _statColumn(
                      label: appSettings.t('pace_label').toUpperCase(),
                      value: _formattedPace,
                      primaryText: Colors.white,
                      secondaryText: Colors.white60,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TIME LITE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 2,
                ),
              ),
              Text(
                _formattedDate,
                style: const TextStyle(
                  color: Color(0xFF8FFF00),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (_backgroundImage != null) {
      return _photoOverlayWrapper(
        border: Border.all(color: Colors.white12),
        child: content,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111318),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white12),
      ),
      child: content,
    );
  }

  // ---------------------------------------------------------------------------
  // PLANTILLA 6: MINIMAL SWISS
  // ---------------------------------------------------------------------------
  Widget _buildTemplate6MinimalSwiss() {
    final hasPhoto = _backgroundImage != null;
    final ink = hasPhoto ? Colors.white : const Color(0xFF101828);
    final muted = hasPhoto ? Colors.white70 : const Color(0xFF667085);
    final accent =
        hasPhoto ? const Color(0xFF8FFF00) : const Color(0xFF3F51B5);
    final dividerColor = hasPhoto ? Colors.white24 : Colors.black12;

    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TIME LITE',
                    style: TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    _formattedDate,
                    style: TextStyle(
                      color: muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Divider(height: 24, color: dividerColor),
            ],
          ),
          Column(
            children: [
              Text(
                appSettings.t('distance_label').toUpperCase(),
                style: TextStyle(
                  color: muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${widget.distanceKm.toStringAsFixed(2)} km',
                  style: TextStyle(
                    color: accent,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
          Column(
            children: [
              Divider(height: 24, color: dividerColor),
              Row(
                children: [
                  Expanded(
                    child: _statColumn(
                      label: appSettings.t('pace_label').toUpperCase(),
                      value: _formattedPace,
                      primaryText: ink,
                      secondaryText: muted,
                    ),
                  ),
                  Container(width: 1, height: 38, color: dividerColor),
                  Expanded(
                    child: _statColumn(
                      label: appSettings.t('time_label').toUpperCase(),
                      value: _formattedDuration,
                      primaryText: ink,
                      secondaryText: muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    if (hasPhoto) {
      return _photoOverlayWrapper(child: content);
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black12),
      ),
      child: content,
    );
  }

  // ---------------------------------------------------------------------------
  // PLANTILLA 7: VAPORWAVE 80S
  // ---------------------------------------------------------------------------
  Widget _buildTemplate7Vaporwave() {
    const pink = Color(0xFFFF2A85);
    const aqua = Color(0xFF00F5D4);

    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [pink, aqua]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'TIME LITE // RUN',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Text(
                _formattedDate,
                style: const TextStyle(
                  color: aqua,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                appSettings.t('distance_label').toUpperCase(),
                style: const TextStyle(
                  color: aqua,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${widget.distanceKm.toStringAsFixed(2)} KM',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    shadows: [
                      Shadow(color: pink, blurRadius: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.42),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: aqua.withOpacity(0.45)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statColumn(
                  label: appSettings.t('pace_label').toUpperCase(),
                  value: _formattedPace,
                  primaryText: Colors.white,
                  secondaryText: pink,
                ),
                Container(width: 1, height: 32, color: aqua.withOpacity(0.3)),
                _statColumn(
                  label: appSettings.t('time_label').toUpperCase(),
                  value: _formattedDuration,
                  primaryText: Colors.white,
                  secondaryText: aqua,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (_backgroundImage != null) {
      return _photoOverlayWrapper(
        border: Border.all(color: pink.withOpacity(0.5), width: 1.5),
        scrimColors: [
          const Color(0xFF140726).withOpacity(0.65),
          const Color(0xFF2E1052).withOpacity(0.35),
          const Color(0xFF140726).withOpacity(0.85),
        ],
        child: content,
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF140726), Color(0xFF2E1052), Color(0xFF6B145A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: pink.withOpacity(0.5), width: 1.5),
      ),
      child: content,
    );
  }

  // ---------------------------------------------------------------------------
  // PLANTILLA 8: GOLD ELITE
  // ---------------------------------------------------------------------------
  Widget _buildTemplate8GoldElite() {
    const gold = Color(0xFFF5D061);
    const goldDark = Color(0xFFB88924);

    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: gold, size: 30),
              const SizedBox(height: 4),
              const Text(
                'TIME LITE PRESTIGE',
                style: TextStyle(
                  color: gold,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formattedDate,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                appSettings.t('distance_label').toUpperCase(),
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${widget.distanceKm.toStringAsFixed(2)} km',
                  style: const TextStyle(
                    color: gold,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gold.withOpacity(0.18),
                  goldDark.withOpacity(0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: gold.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statColumn(
                  label: appSettings.t('pace_label').toUpperCase(),
                  value: _formattedPace,
                  primaryText: Colors.white,
                  secondaryText: Colors.white70,
                ),
                Container(width: 1, height: 32, color: gold.withOpacity(0.3)),
                _statColumn(
                  label: appSettings.t('time_label').toUpperCase(),
                  value: _formattedDuration,
                  primaryText: Colors.white,
                  secondaryText: Colors.white70,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (_backgroundImage != null) {
      return _photoOverlayWrapper(
        border: Border.all(color: gold.withOpacity(0.55), width: 1.5),
        child: content,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0D),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: gold.withOpacity(0.55), width: 1.5),
      ),
      child: content,
    );
  }

  // ---------------------------------------------------------------------------
  // PLANTILLA 9: AURORA GLASS
  // ---------------------------------------------------------------------------
  Widget _buildTemplate9AuroraGlass() {
    const mint = Color(0xFF00FFA3);

    final content = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: mint, size: 20),
                  SizedBox(width: 4),
                  Text(
                    'TIME LITE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.8,
                    ),
                  ),
                ],
              ),
              Text(
                _formattedDate,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: mint.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  appSettings.t('distance_label').toUpperCase(),
                  style: const TextStyle(
                    color: mint,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${widget.distanceKm.toStringAsFixed(2)} km',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statColumn(
                  label: appSettings.t('pace_label').toUpperCase(),
                  value: _formattedPace,
                  primaryText: mint,
                  secondaryText: Colors.white70,
                ),
                Container(width: 1, height: 32, color: Colors.white12),
                _statColumn(
                  label: appSettings.t('time_label').toUpperCase(),
                  value: _formattedDuration,
                  primaryText: Colors.white,
                  secondaryText: Colors.white70,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (_backgroundImage != null) {
      return _photoOverlayWrapper(
        scrimColors: [
          const Color(0xFF041C1B).withOpacity(0.65),
          const Color(0xFF0B3B36).withOpacity(0.35),
          const Color(0xFF041C1B).withOpacity(0.85),
        ],
        child: content,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF041C1B), Color(0xFF0B3B36), Color(0xFF071926)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: content,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PLANTILLA 10: SPEED HUD
  // ---------------------------------------------------------------------------
  Widget _buildTemplate10SpeedHud() {
    const lime = Color(0xFF8FFF00);
    const cyan = Color(0xFF00E5FF);

    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TIME LITE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 2,
                ),
              ),
              Text(
                _formattedDate,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _verticalHudStat(
                accent: lime,
                label: appSettings.t('distance_label').toUpperCase(),
                value: '${widget.distanceKm.toStringAsFixed(2)} km',
                fontSize: 34,
              ),
              const SizedBox(height: 22),
              _verticalHudStat(
                accent: cyan,
                label: appSettings.t('pace_label').toUpperCase(),
                value: _formattedPace,
                fontSize: 26,
              ),
              const SizedBox(height: 22),
              _verticalHudStat(
                accent: Colors.amberAccent,
                label: appSettings.t('time_label').toUpperCase(),
                value: _formattedDuration,
                fontSize: 26,
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );

    if (_backgroundImage != null) {
      return _photoOverlayWrapper(
        border: Border.all(color: Colors.white12),
        child: content,
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0C101B), Color(0xFF182038)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white12),
      ),
      child: content,
    );
  }

  Widget _verticalHudStat({
    required Color accent,
    required String label,
    required String value,
    double fontSize = 22,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 14),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                height: 1.05,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statColumn({
    required String label,
    required String value,
    required Color primaryText,
    required Color secondaryText,
    List<Shadow>? shadows,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: secondaryText,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            shadows: shadows,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
              shadows: shadows,
            ),
          ),
        ),
      ],
    );
  }
}

class _TechGridPainter extends CustomPainter {
  final Color lineColor;
  _TechGridPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    const step = 24.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CheckerboardPainter extends CustomPainter {
  final bool isDark;
  _CheckerboardPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 14.0;
    final paint1 = Paint()
      ..color = isDark ? const Color(0xFF161B2E) : const Color(0xFFE6E9F2);
    final paint2 = Paint()
      ..color = isDark ? const Color(0xFF1F2640) : const Color(0xFFD5DAE8);

    for (double y = 0; y < size.height; y += cellSize) {
      for (double x = 0; x < size.width; x += cellSize) {
        final isEven = ((x ~/ cellSize) + (y ~/ cellSize)) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}