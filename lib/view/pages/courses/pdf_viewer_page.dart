import 'dart:async';
import 'dart:typed_data';

import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/core/utils/extentions.dart';
import 'package:breffini_staff/http/http_urls.dart';
import 'package:breffini_staff/view/pages/courses/answer_key_page.dart';
import 'package:breffini_staff/view/pages/courses/widgets/size_utils.dart';
import 'package:breffini_staff/view/widgets/player_widget.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';

import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';

class PdfViewerPage extends StatefulWidget {
  final String fileUrl;
  final String? answerKey;
  final String? media;
  final String? answerPdf;
  final bool? isMediaUnlocked;
  final bool? isPdfUnLocked;
  final bool? isExamTest;
  bool showAppBar;

  PdfViewerPage({
    Key? key,
    required this.fileUrl,
    this.media,
    this.answerKey,
    this.answerPdf,
    this.showAppBar = true,
    this.isMediaUnlocked,
    this.isPdfUnLocked,
    this.isExamTest,
  }) : super(key: key);

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late AudioPlayer player;
  final ValueNotifier<double> downloadProgress = ValueNotifier<double>((0.0));
  final ValueNotifier<String> cachedUrl = ValueNotifier<String>("");
  ValueNotifier<bool> isPdfLoaded = ValueNotifier<bool>(false);

  var client = http.Client();
  final ValueNotifier<String> _progressNotifier = ValueNotifier<String>('0');

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    player.setReleaseMode(ReleaseMode.stop);

    if (!widget.media.isNullOrEmpty()) {
      cacheAudio(widget.media!);
    }
    isPdfLoaded.addListener(() {
      if (isPdfLoaded.value && !cachedUrl.value.isNullOrEmpty()) {
        playAudio();
      } else {
        // Actions when loading starts or resets
        print("PDF loading...");
      }
    });
  }

  Future<Uint8List?> cachePdf(Function(int, int) onProgress) async {
    print("DEBUG: cachePdf - Attempting to cache URL: '${widget.fileUrl}'");

    if (widget.fileUrl.isEmpty) {
      print("DEBUG: cachePdf - URL is empty!");
      return null;
    }

    final directory =
        await getApplicationDocumentsDirectory(); // Using app docs dir as it's more reliable
    String fileName = "";
    String filePath = "";

    try {
      fileName = Uri.parse(widget.fileUrl).pathSegments.last;
      print("DEBUG: cachePdf - FileName: $fileName");
    } catch (e) {
      print("DEBUG: cachePdf - Error parsing URL segments: $e");
      fileName = "document_${DateTime.now().millisecondsSinceEpoch}.pdf";
    }

    if (widget.fileUrl.startsWith("http")) {
      filePath = '${directory.path}/$fileName';
    } else {
      filePath = widget.fileUrl;
    }

    print("DEBUG: cachePdf - Local FilePath: $filePath");

    if (File(filePath).existsSync()) {
      print("DEBUG: cachePdf - File already exists locally.");
      return File(filePath).readAsBytesSync();
    }

    print("DEBUG: cachePdf - File does not exist locally. Downloading...");
    final dio = Dio();
    try {
      final response = await dio.get<List<int>>(
        (widget.fileUrl),
        options: Options(
          responseType: ResponseType.bytes,
        ),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress(received, total); // Report progress
          }
        },
      );

      if (response.statusCode == 200) {
        print("DEBUG: cachePdf - Download successful.");
        File file = File(filePath);
        await file.writeAsBytes(response.data!);
        return File(filePath).readAsBytesSync(); // Return the bytes
      } else {
        print(
            "DEBUG: cachePdf - Download failed with status: ${response.statusCode}");
        throw Exception('Failed to load PDF: ${response.statusMessage}');
      }
    } catch (e) {
      print("DEBUG: cachePdf - Dio error: $e");
      return null;
    }
  }

  Future<String?> cacheAudio(String url) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = Uri.parse(url).pathSegments.last;
    final filePath = '${directory.path}/$fileName';

    if (File(filePath).existsSync()) {
      downloadProgress.value = (1.0); // Update progress
      cachedUrl.value = (filePath); // Update progress
      await player.setSource(DeviceFileSource(cachedUrl.value));
      if (isPdfLoaded.value) {
        playAudio();
      }

      return filePath;
    }

    try {
      final request = http.Request('GET', Uri.parse(HttpUrls.imgBaseUrl + url));

      // final response = await request.send();
      http.StreamedResponse response = await client.send(request);

      final bytes = <int>[];
      int downloaded = 0;
      downloadProgress.value = (0.0);

      // Track download progress, keeping value below 1.0 until complete
      await for (var chunk in response.stream) {
        bytes.addAll(chunk);
        downloaded += chunk.length;

        // Cap progress at 0.99 during download
        double progress =
            (downloaded / response.contentLength!).clamp(0.0, 0.99);
        downloadProgress.value = (progress);
        // print(downloadProgress.value.toString()+"/////////");
      }
      File file = File(filePath);
      await file.writeAsBytes(bytes);
      downloadProgress.value = (1.0); // Update progress
      cachedUrl.value = (file.path); // Update progress
      await player.setSource(DeviceFileSource(cachedUrl.value));
      if (isPdfLoaded.value) {
        Future.delayed(const Duration(seconds: 2), () {
          playAudio();
        });
      }

      return filePath;
    } catch (e) {
      downloadProgress.value = (-1);

      print('Error caching audio: $e');
      return null;
    }
  }

  void playAudio() async {
    if (!widget.media.isNullOrEmpty()) {
      try {
        // final audioPath = await cachedAudioPath;
        await player.setSource(DeviceFileSource(cachedUrl.value));
        await player.resume();
      } catch (e) {
        print('Error setting audio source: $e');
      }
    }
  }

  @override
  void dispose() {
    client.close();
    player.stop();
    player.dispose();
    super.dispose();
  }

  Future<void> downloadAndOpenPdf(BuildContext context) async {
    try {
      // Show loading dialog with circular progress indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            DownloadDialog(fileUrl: widget.fileUrl),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print("DEBUG: PdfViewerPage - Building for URL: '${widget.fileUrl}'");
    return Scaffold(
      appBar: (widget.showAppBar)
          ? AppBar(
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: InkWell(
                  onTap: () {
                    Get.back();
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: ColorResources.colorBlue100,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: ColorResources.colorBlack.withOpacity(.8),
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => downloadAndOpenPdf(context),
                ),
              ],
            )
          : null,
      body: FutureBuilder<Uint8List?>(
        future: cachePdf((received, total) {
          if (total > 0) {
            // Update the progress in the notifier
            _progressNotifier.value =
                (received / total * 100).toStringAsFixed(0);
          }
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: ColorResources.colorBlue600,
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<String>(
                    valueListenable: _progressNotifier,
                    builder: (context, value, child) {
                      return Text('Loading PDF: $value%'); // Percentage text
                    },
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError || snapshot.data == null) {
            print("DEBUG: PdfViewerPage - Error snapshot: ${snapshot.error}");
            return const Center(child: Text('Error loading PDF'));
          }

          print(
              "DEBUG: PdfViewerPage - Snapshot data received, length: ${snapshot.data?.length}");

          // Support for viewing images
          final String url = widget.fileUrl.toLowerCase();
          final bool isImage = url.endsWith(".png") ||
              url.endsWith(".jpg") ||
              url.endsWith(".jpeg") ||
              url.endsWith(".webp") ||
              url.endsWith(".gif");

          if (isImage) {
            print("DEBUG: PdfViewerPage - Displaying as Image.");
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Center(
                child: Image.memory(
                  snapshot.data!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print("DEBUG: PdfViewerPage - Image memory error: $error");
                    return const Center(child: Text("Error displaying image"));
                  },
                ),
              ),
            );
          }

          print("DEBUG: PdfViewerPage - Displaying as PDF.");
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 3,
            child: PdfPreview(
              allowPrinting: false,
              allowSharing: false,
              enableScrollToPage: false,
              useActions: true,
              previewPageMargin: const EdgeInsets.all(0),
              canChangeOrientation: false,
              canChangePageFormat: false,
              pdfFileName: "document.pdf",
              dynamicLayout: false,
              shouldRepaint: false,
              actions: [],
              pdfPreviewPageDecoration:
                  const BoxDecoration(color: Colors.white),
              build: (PdfPageFormat format) {
                isPdfLoaded.value = true;
                return snapshot.data!;
              },
              maxPageWidth: double.infinity,
              initialPageFormat: PdfPageFormat.a4,
              canDebug: false,
            ),
          );
        },
      ),
      floatingActionButton: widget.answerPdf == ''
          ? const SizedBox.shrink()
          : Container(
              width: 140,
              height: 40,
              child: FloatingActionButton.extended(
                backgroundColor: ColorResources.colorBlack,
                onPressed: widget.answerKey != null
                    ? () {
                        Get.to(() => AnswerKeyPage(
                              answerKey: widget.answerKey!,
                            ));
                      }
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('No answer key to show')),
                        );
                      },
                label: Text(
                  'View answer key',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: ColorResources.colorwhite),
                ),
              ),
            ),
      bottomNavigationBar: widget.media.isNullOrEmpty()
          ? const SizedBox.shrink()
          : (widget.isExamTest == true && widget.isMediaUnlocked != true)
              ? Container(
                  height: 70,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Center(
                        child: Text(
                      "Audio is Locked",
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: ColorResources.colorBlack),
                    )),
                  ))
              : Container(
                  height: 70,
                  color: Colors.white,
                  child: ValueListenableBuilder<double>(
                      valueListenable: downloadProgress,
                      builder: (context, value, child) {
                        return value < 1.0
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  downloadProgress.value == -1
                                      ? const Text("Retry")
                                      : Container(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            value: value,
                                            color: Colors.blue,
                                            backgroundColor:
                                                Colors.lightBlueAccent,
                                          ),
                                        ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text("Loading Audio"),
                                  )
                                ],
                              )
                            : PlayerWidget(player: player);
                      }),
                ),
    );
  }
}

class DownloadDialog extends StatefulWidget {
  final String fileUrl;

  const DownloadDialog({Key? key, required this.fileUrl}) : super(key: key);

  @override
  _DownloadDialogState createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<DownloadDialog> {
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _startDownload(true);
  }

  Future<void> _startDownload(bool showCompleteMsg) async {
    print("DEBUG: DownloadDialog - Starting download for: ${widget.fileUrl}");
    try {
      Directory? directory = await getApplicationDocumentsDirectory();

      final fileName = Uri.parse(widget.fileUrl).pathSegments.last;
      final filePath = '${directory.path}/$fileName';
      print("DEBUG: DownloadDialog - Target Path: $filePath");

      File file = File(filePath);

      if (!file.existsSync()) {
        print("DEBUG: DownloadDialog - File does not exist, downloading...");
        final response = await http.Client()
            .send(http.Request('GET', Uri.parse(widget.fileUrl)));

        if (response.statusCode != 200) {
          print(
              "DEBUG: DownloadDialog - Download failed with status: ${response.statusCode}");
          throw Exception("Failed to download file: ${response.statusCode}");
        }

        final contentLength = response.contentLength;
        int bytesReceived = 0;

        await for (final chunk in response.stream) {
          bytesReceived += chunk.length;
          file.writeAsBytesSync(chunk, mode: FileMode.append);
          setState(() {
            _progress = (contentLength != null && contentLength > 0)
                ? (bytesReceived / contentLength)
                : 0.5; // Fallback if content length is unknown
          });
        }
        print("DEBUG: DownloadDialog - Download complete.");
      } else {
        print("DEBUG: DownloadDialog - File already exists.");
      }

      if (showCompleteMsg) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Download Successful'),
              content: Text(
                  'PDF has been downloaded successfully. Do you want to open it?'),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'No',
                    style: GoogleFonts.plusJakartaSans(
                      color: ColorResources.colorBlack,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(
                    'Yes',
                    style: GoogleFonts.plusJakartaSans(
                      color: ColorResources.colorBlack,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: () async {
                    // if (!await _checkAndRequestPermission()) {
                    //   return;
                    // }

                    Navigator.of(context).pop();
                    try {
                      final result = await OpenFile.open(filePath);
                      if (result.message != 'done') {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Cannot open file: ${result.message}'),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error opening file: $e'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading PDF: $e')),
      );
    }
  }

// Permission check and request function
  Future<bool> _checkAndRequestPermission() async {
    if (await Permission.storage.isGranted) {
      return true;
    }

    final status = await Permission.storage.request();
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enable storage permissions in app settings.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              openAppSettings();
            },
          ),
        ),
      );
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Downloading PDF...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(value: _progress),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}

class PlayerWidget extends StatefulWidget {
  final AudioPlayer player;

  const PlayerWidget({
    required this.player,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  PlayerState? _playerState;
  Duration? _duration;
  Duration? _position;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  bool get _isPlaying => _playerState == PlayerState.playing;
  bool get _isPaused => _playerState == PlayerState.paused;

  String get _durationText =>
      _duration?.toString().split('.').first ?? '00:00:00';
  String get _positionText =>
      _position?.toString().split('.').first ?? '00:00:00';

  AudioPlayer get player => widget.player;

  @override
  void initState() {
    super.initState();
    _playerState = player.state;
    _initStreams();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Colors.blue.shade600;
    return Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isPlaying)
            Container(
              width: 45,
              height: 45,
              margin: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF6A7487),
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: IconButton(
                key: const Key('play_button'),
                onPressed: _isPlaying ? null : _play,
                iconSize: 28.0,
                icon: const Icon(Icons.play_arrow),
                color: const Color(0xFFE3E7EE),
              ),
            ),
          if (_isPlaying)
            Container(
              width: 45,
              height: 45,
              margin: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF6A7487),
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: IconButton(
                key: const Key('pause_button'),
                onPressed: _isPlaying ? _pause : null,
                iconSize: 28.0,
                icon: const Icon(Icons.pause),
                color: const Color(0xFFE3E7EE),
              ),
            ),
          // if (_isPlaying || _isPaused)
          //   IconButton(
          //     key: const Key('stop_button'),
          //     onPressed: _isPlaying || _isPaused ? _stop : null,
          //     iconSize: 48.0,
          //     icon: const Icon(Icons.stop),
          //     color: color,
          //   ),
          Expanded(
            child: Slider(
              thumbColor: const Color(0xFF6A7487),
              activeColor: const Color(0xFF6A7487),
              inactiveColor: const Color(0xFFE3E7EE),
              onChanged: (value) {
                final duration = _duration;
                if (duration == null) return;
                final position = value * duration.inMilliseconds;
                player.seek(Duration(milliseconds: position.round()));
              },
              value: (_position != null &&
                      _duration != null &&
                      _position!.inMilliseconds > 0 &&
                      _position!.inMilliseconds < _duration!.inMilliseconds)
                  ? _position!.inMilliseconds / _duration!.inMilliseconds
                  : 0.0,
            ),
          ),
          Container(
            width: 115,
            child: Text(
              _position != null
                  ? '$_positionText / $_durationText'
                  : _duration != null
                      ? _durationText
                      : '00:00:00',
              style: const TextStyle(fontSize: 12.0),
            ),
          ),
          Container(
            width: 20,
            margin: const EdgeInsets.only(right: 15),
            child: PopupMenuButton(
              color: Colors.white,
              iconColor: Colors.grey.shade600,
              itemBuilder: (c) => [
                PopupMenuItem(
                  onTap: () => _changePlaybackSpeed(0.5),
                  child: const Text(
                    '0.5x',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                PopupMenuItem(
                  onTap: () => _changePlaybackSpeed(1.0),
                  child: const Text(
                    '1x',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                PopupMenuItem(
                  onTap: () => _changePlaybackSpeed(1.5),
                  child: const Text(
                    '1.5x',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                PopupMenuItem(
                  onTap: () => _changePlaybackSpeed(2),
                  child: const Text(
                    '2x',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      )
    ]);
  }

  void _initStreams() {
    _durationSubscription = player.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSubscription = player.onPositionChanged.listen((p) {
      setState(() => _position = p);
    });

    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration.zero;
      });
    });

    _playerStateChangeSubscription =
        player.onPlayerStateChanged.listen((state) {
      setState(() {
        _playerState = state;
      });
    });
  }

  Future<void> _play() async {
    try {
      await player.resume();
      setState(() => _playerState = PlayerState.playing);
    } catch (e) {
      print('Error during playback: $e');
      // Handle error
    }
  }

  Future<void> _pause() async {
    try {
      await player.pause();
      setState(() => _playerState = PlayerState.paused);
    } catch (e) {
      print('Error during pause: $e');
      // Handle error
    }
  }

  Future<void> _stop() async {
    try {
      await player.stop();
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration.zero;
      });
    } catch (e) {
      print('Error during stop: $e');
      // Handle error
    }
  }

  _changePlaybackSpeed(double d) {
    player.setPlaybackRate(d);
  }
}
