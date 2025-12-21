import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../services/image_processing_service.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';

class PhotoEditorScreen extends StatefulWidget {
  final File imageFile;

  const PhotoEditorScreen({super.key, required this.imageFile});

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  late File _currentImageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentImageFile = widget.imageFile;
    _initializeEditor();
  }

  Future<void> _initializeEditor() async {
    setState(() => _isLoading = true);
    // Editor initialization (face detection removed)
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _removeBackground() async {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final processedBytes = await ImageProcessingService.removeBackground(
        _currentImageFile,
      );
      if (mounted) Navigator.pop(context); // Close dialog

      if (processedBytes != null) {
        final newFile = await ImageProcessingService.saveBytesToFile(
          processedBytes,
        );

        if (mounted) {
          setState(() {
            _currentImageFile = newFile;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.editorBackgroundRemoved)));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.editorBackgroundRemoveFailed)),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          ProImageEditor.file(
            _currentImageFile,
            key: ValueKey(_currentImageFile.path),
            callbacks: ProImageEditorCallbacks(
              onImageEditingComplete: (bytes) async {
                Navigator.pop(context, bytes);
              },
              onCloseEditor: (_) {
                Navigator.pop(context);
              },
            ),
            configs: ProImageEditorConfigs(
              // Theme Integration
              theme: theme,
              mainEditor: MainEditorConfigs(
                style: MainEditorStyle(
                  background: theme.scaffoldBackgroundColor,
                  appBarBackground: theme.colorScheme.surface,
                  appBarColor: theme.colorScheme.onSurface,
                  bottomBarBackground: theme.colorScheme.surface,
                  bottomBarColor: theme.colorScheme.onSurface,
                ),
              ),

              // Comprehensive i18n
              i18n: I18n(
                done: l10n.editorDone,
                cancel: l10n.actionCancel,
                undo: l10n.editorUndoShort,
                redo: l10n.editorRedoShort,
                paintEditor: I18nPaintEditor(
                  bottomNavigationBarText: l10n.editorPaint,
                  freestyle: l10n.editorPaintFreestyle,
                  arrow: l10n.editorPaintArrow,
                  line: l10n.editorPaintLine,
                  rectangle: l10n.editorPaintRectangle,
                  circle: l10n.editorPaintCircle,
                  eraser: l10n.editorPaintEraser,
                ),
                textEditor: I18nTextEditor(
                  bottomNavigationBarText: l10n.editorText,
                ),
                cropRotateEditor: I18nCropRotateEditor(
                  bottomNavigationBarText: l10n.editorCrop,
                  rotate: l10n.editorRotate,
                  flip: l10n.editorFlip,
                  ratio: l10n.editorRatio,
                  reset: l10n.editorReset,
                ),
                filterEditor: I18nFilterEditor(
                  bottomNavigationBarText: l10n.editorFilter,
                ),
                tuneEditor: I18nTuneEditor(
                  bottomNavigationBarText: l10n.editorTune,
                  brightness: l10n.editorTuneBrightness,
                  contrast: l10n.editorTuneContrast,
                  saturation: l10n.editorTuneSaturation,
                  exposure: l10n.editorTuneExposure,
                  hue: l10n.editorTuneHue,
                  temperature: l10n.editorTuneTemperature,
                  sharpness: l10n.editorTuneSharpness,
                  fade: l10n.editorTuneFade,
                  luminance: l10n.editorTuneLuminance,
                ),
                blurEditor: I18nBlurEditor(
                  bottomNavigationBarText: l10n.editorBlur,
                ),
              ),

              // textEditor Configuration
              textEditor: TextEditorConfigs(
                customTextStyles: [
                  GoogleFonts.roboto(),
                  GoogleFonts.lato(),
                  GoogleFonts.oswald(),
                  GoogleFonts.merriweather(),
                  GoogleFonts.dancingScript(),
                ],
              ),

              // filterEditor Configuration
              filterEditor: FilterEditorConfigs(
                filterList: [
                  FilterModel(
                    name: 'Sepia',
                    filters: [ColorFilterAddons.sepia(0.8)],
                  ),
                  FilterModel(
                    name: 'Grayscale',
                    filters: [ColorFilterAddons.grayscale()],
                  ),
                  FilterModel(
                    name: 'Vintage',
                    filters: [
                      ColorFilterAddons.sepia(0.4),
                      ColorFilterAddons.brightness(-0.1),
                    ],
                  ),
                ],
              ),

              // Sticker Editor Configs
              stickerEditor: const StickerEditorConfigs(),
            ),
          ),

          // Background Removal Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'remove_bg_btn',
              mini: true,
              onPressed: _removeBackground,
              backgroundColor: Colors.white,
              tooltip: l10n.editorRemoveBackground,
              child: const Icon(Icons.person_remove, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
