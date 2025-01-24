import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'enums/fluttertube_status.dart';
import 'fluttertube_controller.dart';
import 'types/fluttertube_progress_callback.dart';
import 'types/fluttertube_state_callback.dart';

/// A customizable YouTube video player widget.
///
/// This widget provides a flexible way to embed and control YouTube videos
/// in a Flutter application, with options for customization and event handling.
class FlutterTube extends StatefulWidget {
  final String? videoTitle;

  /// The URL of the YouTube video to play.
  final String youtubeUrl;

  /// The aspect ratio of the video player. If null, defaults to 16:9.
  final double? aspectRatio;

  /// Whether the video should start playing automatically when loaded.
  final bool autoPlay;

  /// The primary color for the player's UI elements.
  final Color? color;

  /// A widget to display while the video is not yet loaded.
  final Widget? placeholder;

  /// A widget to display while the video is loading.
  final Widget? loadingWidget;

  /// A widget to display if there's an error loading the video.
  final Widget? errorWidget;

  /// A callback that is triggered when the player's state changes.
  final FlutterTubeStateCallback? onStateChanged;

  /// A callback that is triggered when the video's playback progress changes.
  final FlutterTubeProgressCallback? onProgressChanged;

  /// A callback that is triggered when the player controller is ready.
  final Function(FlutterTubeController controller)? onControllerReady;

  /// A callback that is triggered when the player enters full screen mode.
  final Function()? onEnterFullScreen;

  /// A callback that is triggered when the player exits full screen mode.
  final Function()? onExitFullScreen;

  /// The margin around the seek bar.
  final EdgeInsets? seekBarMargin;

  /// The margin around the seek bar in fullscreen mode.
  final EdgeInsets? fullscreenSeekBarMargin;

  /// The margin around the bottom button bar.
  final EdgeInsets? bottomButtonBarMargin;

  /// The margin around the bottom button bar in fullscreen mode.
  final EdgeInsets? fullscreenBottomButtonBarMargin;

  /// Constructs a FlutterTube widget.
  ///
  /// The [youtubeUrl] parameter is required and should be a valid YouTube video URL.
  const FlutterTube({
    super.key,
    required this.youtubeUrl,
    this.aspectRatio,
    this.autoPlay = true,
    this.placeholder,
    this.loadingWidget,
    this.errorWidget,
    this.onStateChanged,
    this.onProgressChanged,
    this.onControllerReady,
    this.color,
    this.onEnterFullScreen,
    this.onExitFullScreen,
    this.seekBarMargin,
    this.fullscreenSeekBarMargin,
    this.bottomButtonBarMargin,
    this.fullscreenBottomButtonBarMargin,
    this.videoTitle,
  });

  @override
  FlutterTubeState createState() => FlutterTubeState();
}

/// The state for the FlutterTube widget.
///
/// This class manages the lifecycle of the video player and handles
/// initialization, playback control, and UI updates.
class FlutterTubeState extends State<FlutterTube>
    with SingleTickerProviderStateMixin {
  /// The controller for managing the YouTube player.
  late FlutterTubeController _controller;

  /// The controller for the video display.
  late VideoController _videoController;

  /// Flag to indicate whether the controller is fully initialized and ready.
  bool _isControllerReady = false;
  late ValueChanged<double> onSpeedChanged;
  double currentSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    // Initialize the FlutterTubeController with callbacks
    _controller = FlutterTubeController(
      onStateChanged: widget.onStateChanged,
      onProgressChanged: widget.onProgressChanged,
    );
    // Create a VideoController from the player in FlutterTubeController
    _videoController = VideoController(_controller.player);
    // Start the player initialization process
    _initializePlayer();
  }

  /// Initializes the video player with the provided YouTube URL and settings.
  void _initializePlayer() async {
    try {
      // Attempt to initialize the player with the given YouTube URL and settings
      await _controller.initialize(
        widget.youtubeUrl,
        autoPlay: widget.autoPlay,
        aspectRatio: widget.aspectRatio,
      );
      if (mounted) {
        // If the widget is still in the tree, update the state
        setState(() {
          _isControllerReady = true;
        });
        // Notify that the controller is ready, if a callback was provided
        if (widget.onControllerReady != null) {
          widget.onControllerReady!(_controller);
        }
      }
    } catch (e) {
      // Log any errors that occur during initialization
      debugPrint('FlutterTube: Error initializing player: $e');
      if (mounted) {
        // If there's an error, set the controller as not ready
        setState(() {
          _isControllerReady = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Ensure the controller is properly disposed when the widget is removed
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the player dimensions based on the available width and aspect ratio
        final aspectRatio = widget.aspectRatio ?? 16 / 9;
        final playerWidth = constraints.maxWidth;
        final playerHeight = playerWidth / aspectRatio;

        return Container(
          width: playerWidth,
          height: playerHeight,
          color: Colors.transparent,
          child: _buildPlayerContent(playerWidth, playerHeight),
        );
      },
    );
  }

  Widget buildSpeedOption() {
    return PopupMenuButton<double>(
      icon: const Icon(Icons.speed, color: Colors.white),
      initialValue: currentSpeed,
      onSelected: (value) {
        setState(() {
          currentSpeed = value;
          _controller.speed(currentSpeed);
          if (kDebugMode) {
            print("Change speed $currentSpeed");
          }
        });

        // Notify parent widget of the new speed
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 0.5,
          child: Text("0.5x"),
        ),
        const PopupMenuItem(
          value: 1.0,
          child: Text("1.0x (Normal)"),
        ),
        const PopupMenuItem(
          value: 1.5,
          child: Text("1.5x"),
        ),
        const PopupMenuItem(
          value: 2.0,
          child: Text("2.0x"),
        ),
      ],
    );
  }

  /// Builds the main content of the player based on its current state.
  Widget _buildPlayerContent(double width, double height) {
    if (_isControllerReady && _controller.isInitialized) {
      _controller.speed(currentSpeed);
      // If the controller is ready and initialized, show the video player
      return OrientationBuilder(builder: (context, orientation) {
        return MaterialVideoControlsTheme(
          normal: MaterialVideoControlsThemeData(
              seekBarAlignment: Alignment.center,
              seekBarBufferColor: Colors.grey,
              seekOnDoubleTap: true,
              seekBarThumbSize: 15,
              seekBarHeight: 5,
              seekBarPositionColor: widget.color ?? const Color(0xFFFF0000),
              seekBarThumbColor: widget.color ?? const Color(0xFFFF0000),
              seekBarMargin: widget.seekBarMargin ?? EdgeInsets.zero,
              bottomButtonBarMargin: widget.bottomButtonBarMargin ??
                  const EdgeInsets.only(left: 16, right: 8, bottom: 15),
              brightnessGesture: true,
              volumeGesture: true,
              bottomButtonBar: [
                const MaterialPositionIndicator(),
                const Spacer(),
                buildSpeedOption(),
                IconButton(
                  onPressed: () {
                    if (orientation == Orientation.portrait) {
                      SystemChrome.setPreferredOrientations(
                          [DeviceOrientation.landscapeRight]);
                    } else {
                      SystemChrome.setPreferredOrientations(
                          [DeviceOrientation.portraitUp]);
                    }
                  },
                  icon: Icon(
                    Icons.fullscreen_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
              topButtonBar: [
                if (widget.videoTitle != null)
                  Text(
                    widget.videoTitle!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
              ]),
          fullscreen: MaterialVideoControlsThemeData(
            volumeGesture: true,
            brightnessGesture: true,
            seekOnDoubleTap: true,
            seekBarMargin: widget.fullscreenSeekBarMargin ?? EdgeInsets.zero,
            bottomButtonBarMargin: widget.fullscreenBottomButtonBarMargin ??
                const EdgeInsets.only(left: 16, right: 8, bottom: 10),
            seekBarBufferColor: Colors.grey,
            seekBarPositionColor: widget.color ?? const Color(0xFFFF0000),
            seekBarThumbColor: widget.color ?? const Color(0xFFFF0000),
            bottomButtonBar: [
              const MaterialPositionIndicator(),
              const Spacer(),
              buildSpeedOption(),
            ],
          ),
          child: Stack(
            children: [
              Video(
                controller: _videoController,
                controls: MaterialVideoControls,
                width: width,
                height: height,
                onEnterFullscreen: () async {
                  if (widget.onEnterFullScreen != null) {
                    return widget.onEnterFullScreen!();
                  } else {
                    // return flutterTubeDefaultEnterFullscreen();
                  }
                },
                onExitFullscreen: () async {
                  if (widget.onExitFullScreen != null) {
                    return widget.onExitFullScreen!();
                  } else {
                    // return flutterTubeDefaultExitFullscreen();
                  }
                },
              ),
            ],
          ),
        );
      });
    } else if (_controller.status == FlutterTubeStatus.loading) {
      // If the video is still loading, show a loading indicator
      return Center(
        child:
            widget.loadingWidget ?? const CircularProgressIndicator.adaptive(),
      );
    } else if (_controller.status == FlutterTubeStatus.error) {
      // If there was an error, show the error widget
      return Center(
        child: widget.errorWidget ?? const Text('Error loading video'),
      );
    } else {
      // For any other state, show the placeholder or an empty container
      return widget.placeholder ?? Container();
    }
  }
}
