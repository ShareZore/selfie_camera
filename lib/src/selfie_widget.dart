import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_editor/image_editor.dart';
import 'package:selfie_camera/selfie_camera.dart';
import 'logger.dart';
import 'result_widget.dart';

typedef FlashControlBuilder = Widget Function(
    BuildContext context, CameraFlashType mode);

class SelfieWidget extends StatefulWidget {
  final ImageResolution imageResolution;
  final CameraType defaultCameraType;
  final CameraFlashType defaultFlashType;
  final CameraOrientation? orientation;
  final bool showControls;
  final bool showCaptureControl;
  final bool showFlashControl;
  final bool showCameraTypeControl;
  final bool showCloseControl;
  final void Function(XFile? image)? onCapture;
  final Widget? captureControlIcon;
  final Widget? typeControlIcon;
  final FlashControlBuilder? flashControlBuilder;
  final Widget? closeControlIcon;
  final ImageScale imageScale;

  const SelfieWidget({
    super.key,
    this.imageResolution = ImageResolution.medium,
    this.defaultCameraType = CameraType.front,
    this.showControls = true,
    this.showCaptureControl = true,
    this.showFlashControl = true,
    this.showCameraTypeControl = true,
    this.showCloseControl = true,
    this.defaultFlashType = CameraFlashType.off,
    this.orientation = CameraOrientation.portraitUp,
    this.onCapture,
    this.captureControlIcon,
    this.typeControlIcon,
    this.flashControlBuilder,
    this.closeControlIcon,
    this.imageScale = ImageScale.none,
  });

  @override
  State<SelfieWidget> createState() => _SelfieWidgetState();
}

class _SelfieWidgetState extends State<SelfieWidget>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  /// 全局key
  final GlobalKey _cameraWidgetKey = GlobalKey();

  ///是否能点击拍照
  bool _isClick = false;

  bool _isAppInBackground = false;

  CameraController? _controller;

  int _currentFlashMode = 0;
  final List<CameraFlashType> _availableFlashMode = [
    CameraFlashType.off,
    CameraFlashType.auto,
    CameraFlashType.always,
  ];

  int _currentCameraType = 0;
  final List<CameraType> _availableCameraType = [];

  void _getAllAvailableCameraType() {
    for (CameraDescription d in SelfieCamera.cameras) {
      final type = d.lensDirection.cameraType;
      if (type != null && !_availableCameraType.contains(type)) {
        _availableCameraType.add(type);
      }
    }
    try {
      _currentCameraType =
          _availableCameraType.indexOf(widget.defaultCameraType);
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<void> _initCamera() async {
    final cameras = SelfieCamera.cameras
        .where(
          (c) =>
              c.lensDirection ==
              _availableCameraType[_currentCameraType].cameraLensDirection,
        )
        .toList();

    if (cameras.isNotEmpty) {
      _controller = CameraController(
        cameras.first,
        widget.imageResolution.resolutionPreset,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });

      await _changeFlashMode(
          _availableFlashMode.indexOf(widget.defaultFlashType));

      await _controller!
          .lockCaptureOrientation(
        widget.orientation?.deviceOrientation,
      )
          .then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _changeFlashMode(int index) async {
    await _controller!
        .setFlashMode(
      _availableFlashMode[index].flashMode,
    )
        .then((_) {
      if (mounted) setState(() => _currentFlashMode = index);
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _getAllAvailableCameraType();
    _initCamera();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final CameraController? cameraController = _controller;
    if (cameraController != null && cameraController.value.isInitialized) {
      cameraController.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      setState(() {
        _isAppInBackground = true;
      });
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
      setState(() {
        _isAppInBackground = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final CameraController? cameraController = _controller;

    // 设备尺寸
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isAppInBackground
          ? Container(
              color: Colors.black,
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                if (cameraController != null &&
                    cameraController.value.isInitialized) ...[
                  widget.imageScale == ImageScale.none
                      ? Transform.scale(
                          scale: 1.0,
                          child: AspectRatio(
                            aspectRatio: size.aspectRatio,
                            child: OverflowBox(
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.fitHeight,
                                child: SizedBox(
                                  width: size.width,
                                  height: size.width *
                                      cameraController.value.aspectRatio,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: <Widget>[
                                      CameraPreview(cameraController),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : _cameraDisplayWidget(cameraController),
                ] else ...[
                  Container(
                    color: Colors.black,
                  ),
                ],
                if (widget.showControls) ...[
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        color: Colors.transparent,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.showFlashControl) ...[
                              _flashControlWidget()
                            ],
                            if (widget.showCaptureControl) ...[
                              const SizedBox(width: 20),
                              _captureControlWidget(),
                              const SizedBox(width: 20)
                            ],
                            if (widget.showCameraTypeControl) ...[
                              _typeControlWidget()
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                ],
                if (widget.showControls)
                  Align(
                    alignment: Alignment.topLeft,
                    child: _clearWidget(),
                  )
              ],
            ),
    );
  }

  ///预览
  Widget _cameraDisplayWidget(CameraController cameraController) {
    // 相机预览
    final size = MediaQuery.of(context).size;
    // 超出部分裁剪
    Widget area = ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.fitWidth,
          child: SizedBox(
            width: size.width,
            height: size.width * cameraController.value.aspectRatio,
            child: Stack(
              children: [
                CameraPreview(cameraController),
              ],
            ),
          ),
        ),
      ),
    );
    return Center(
      // 指定需要截图的区域
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: widget.imageScale == ImageScale.none
                ? size.aspectRatio
                : widget.imageScale.scale,
            child: RepaintBoundary(
              key: _cameraWidgetKey,
              child: area,
            ),
          ),
        ],
      ),
    );
  }

  Widget _captureControlWidget() {
    final CameraController? cameraController = _controller;
    return GestureDetector(
      onTap: cameraController != null && cameraController.value.isInitialized
          ? _onTakePictureButtonPressed
          : null,
      child: Container(
        color: Colors.transparent,
        width: 80,
        height: 80,
        child: widget.captureControlIcon ??
            ClipOval(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8.0),
                child: const Icon(
                  Icons.camera_alt,
                ),
              ),
            ),
      ),
    );
  }

  Widget _flashControlWidget() {
    final CameraController? cameraController = _controller;
    final icon =
        _availableFlashMode[_currentFlashMode] == CameraFlashType.always
            ? Icons.flash_on
            : _availableFlashMode[_currentFlashMode] == CameraFlashType.off
                ? Icons.flash_off
                : Icons.flash_auto;

    return GestureDetector(
      onTap: cameraController != null && cameraController.value.isInitialized
          ? () => _changeFlashMode(
              (_currentFlashMode + 1) % _availableFlashMode.length)
          : null,
      child: Container(
        color: Colors.transparent,
        width: 60,
        height: 60,
        child: widget.flashControlBuilder
                ?.call(context, _availableFlashMode[_currentFlashMode]) ??
            ClipOval(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                padding: const EdgeInsets.all(2.0),
                child: Icon(
                  icon,
                  color: Colors.white,
                ),
              ),
            ),
      ),
    );
  }

  Widget _typeControlWidget() {
    final CameraController? cameraController = _controller;
    return GestureDetector(
      onTap: cameraController != null && cameraController.value.isInitialized
          ? () {
              _currentCameraType =
                  (_currentCameraType + 1) % _availableCameraType.length;
              _initCamera();
            }
          : null,
      child: Container(
        color: Colors.transparent,
        width: 60,
        height: 60,
        child: widget.typeControlIcon ??
            ClipOval(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Padding(
                  padding: EdgeInsets.all(2.0),
                  child: Icon(
                    Icons.cameraswitch_outlined,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _clearWidget() {
    return IconButton(
      iconSize: 30,
      icon: widget.closeControlIcon ??
          CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.05),
            child: const Padding(
              padding: EdgeInsets.all(2.0),
              child: Icon(
                Icons.clear,
                size: 30,
                color: Colors.white,
              ),
            ),
          ),
      onPressed: () {
        Navigator.pop(context);
      },
    );
  }

  void _onTakePictureButtonPressed() async {
    if (_isClick) return;
    _isClick = true;
    final CameraController? cameraController = _controller;
    try {
      if (cameraController!.value.isStreamingImages) {
        await cameraController.stopImageStream();
      }
      await Future.delayed(const Duration(milliseconds: 100));
      takePicture().then((XFile? file) async {
        if (file != null) {
          _isClick = false;
          var result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) =>
                  ResultWidget(file: File(file.path)),
            ),
          );
          if (result != null && widget.onCapture != null) {
            widget.onCapture!(file);
          }
        }
      });
    } catch (e) {
      _isClick = false;
      logError(e.toString());
    }
  }

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      logError('Error: select a camera first.');
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      return null;
    }

    try {
      XFile file = await cameraController.takePicture();
      String path = file.path;
      Uint8List? bytes = await file.readAsBytes();
      if (widget.imageScale == ImageScale.none) {
        if (cameraController.description.lensDirection ==
            CameraLensDirection.front) {
          ImageEditorOption option = ImageEditorOption();
          option.addOption(const FlipOption(horizontal: true));
          bytes = await ImageEditor.editImage(
              image: bytes, imageEditorOption: option);
          await File(path).delete();
          File(path).writeAsBytesSync(bytes!);
        }
      } else {
        ///截屏
        Uint8List? jpBytes = await _capturePng(_cameraWidgetKey);
        await File(path).delete();
        File(path).writeAsBytesSync(jpBytes!);

        ///裁剪
        // Uint8List? corpBytes = await corpImage(bytes);
        // if (cameraController.description.lensDirection ==
        //     CameraLensDirection.front) {
        //   ImageEditorOption option = ImageEditorOption();
        //   option.addOption(const FlipOption(horizontal: true));
        //   corpBytes = await ImageEditor.editImage(
        //       image: corpBytes, imageEditorOption: option);
        // }
        // await File(path).delete();
        // File(path).writeAsBytesSync(corpBytes!);
      }
      return file;
    } on CameraException catch (e) {
      logError(e.code, e.description);
      return null;
    }
  }

  ///裁剪照片
  Future<Uint8List> corpImage(Uint8List bytes) async {
    ui.Image image = await uint8ListChangeImage(bytes);
    double width = image.width.toDouble();
    double height = image.height.toDouble();
    Paint paint = Paint();
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas2 = Canvas(recorder);
    double realHeight = width / widget.imageScale.scale;
    double topY = (height - realHeight) / 2;
    Rect source = Rect.fromLTWH(0, topY, width, realHeight);
    Rect dest = Rect.fromLTWH(0, 0, width, realHeight);
    canvas2.drawImageRect(image, source, dest, paint);
    var image2 = await recorder
        .endRecording()
        .toImage(dest.width.toInt(), dest.height.toInt());
    ByteData? byteData =
        await image2.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();
    return pngBytes;
  }

  /// Uint8List 转 Image
  Future<ui.Image> uint8ListChangeImage(Uint8List list) async {
    ui.Codec codec = await ui.instantiateImageCodec(list);
    ui.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }

  /// 截图
  Future<Uint8List?> _capturePng(
    GlobalKey globalKey, {
    double pixelRatio = 1.0, //截屏的图片与原图的比例，越大越清晰
  }) async {
    try {
      RenderRepaintBoundary boundary =
          globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: pixelRatio);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List? pngBytes = byteData?.buffer.asUint8List();
      return pngBytes;
    } catch (e) {
      logError(e.toString());
    }
    return null;
  }
}
