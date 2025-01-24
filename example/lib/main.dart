import 'package:flutter/material.dart';
// import 'package:fluttertube/fluttertube.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:media_kit/media_kit.dart'; // Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart' as video;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final player = Player();
  // Create a [VideoController] to handle video output from [Player].
  late final controller = video.VideoController(player);
  String videoUrl = '';
  String audioUrl = '';
  List<VideoOnlyStreamInfo> videoResolutions = [];

  Future getVideo() async {
    var yt = YoutubeExplode();
    var video =
        await yt.videos.get('https://www.youtube.com/watch?v=hs8xM32vGqU');
    final manifest = await yt.videos.streamsClient.getManifest(video.id);

    final videoStreamInfo = manifest.videoOnly.withHighestBitrate();
    final audioStreamInfo = manifest.audioOnly.withHighestBitrate();
    setState(() {
      videoUrl = videoStreamInfo.url.toString();
      audioUrl = audioStreamInfo.url.toString();
      videoResolutions = manifest.videoOnly.toList();
    });
    debugPrint("Videos =====> $videoResolutions");
  }

  @override
  void initState() {
    super.initState();

    getVideo().then((value) {
      player.open(Media(videoUrl));
      player.setAudioTrack(AudioTrack.uri(audioUrl));
      Future.delayed(const Duration(milliseconds: 500));
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width * 9.0 / 16.0,
                // Use [Video] widget to display video output.
                child: video.MaterialVideoControlsTheme(
                  normal: video.MaterialVideoControlsThemeData(
                    seekBarBufferColor: Colors.grey,
                    seekOnDoubleTap: true,
                    seekBarPositionColor: const Color(0xFFFF0000),
                    seekBarThumbColor: const Color(0xFFFF0000),
                    seekBarMargin: EdgeInsets.zero,
                    controlsHoverDuration: Duration(seconds: 5),
                    bottomButtonBarMargin:
                        const EdgeInsets.only(left: 16, right: 8, bottom: 10),
                    seekBarAlignment: Alignment.center,
                    seekBarHeight: 5,
                    seekBarThumbSize: 15,
                    brightnessGesture: true,
                    volumeGesture: true,
                    bottomButtonBar: [
                      const video.MaterialPositionIndicator(),
                      const Spacer(),
                      // video.buildSpeedOption(),
                      // const video.MaterialFullscreenButton()
                    ],
                  ),
                  fullscreen: video.MaterialVideoControlsThemeData(),
                  child: video.Video(controller: controller),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: videoResolutions.length,
                  itemBuilder: (context, index) {
                    final resolution = videoResolutions[index];
                    return ListTile(
                      title: Text(resolution.qualityLabel),
                      onTap: () async {
                        debugPrint("audioUrl =====> $audioUrl");
                        await player.open(Media(resolution.url.toString()),
                            play: false);
                        player.setAudioTrack(AudioTrack.uri(audioUrl,
                            language: "ar", title: "audio"));
                        Future.delayed(const Duration(milliseconds: 500));
                        setState(() {});
                        await player.play();
                      },
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
