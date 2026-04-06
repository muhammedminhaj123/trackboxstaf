import 'dart:async';
import 'package:breffini_staff/controller/course_content_controller.dart';
import 'package:breffini_staff/controller/course_enrol_controller.dart';
import 'package:breffini_staff/controller/course_module_controler.dart';
import 'package:breffini_staff/controller/home_controller.dart';
import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/core/theme/custom_text_style.dart';
import 'package:breffini_staff/core/theme/theme_helper.dart';
import 'package:breffini_staff/http/http_urls.dart';
import 'package:breffini_staff/view/pages/chats/widgets/custom_icon_button.dart';
import 'package:breffini_staff/view/pages/chats/widgets/loading_circle.dart';
import 'package:breffini_staff/view/pages/courses/pdf_viewer_page.dart';
import 'package:breffini_staff/view/pages/courses/widgets/course_curricculum_widget.dart';
import 'package:breffini_staff/view/pages/courses/widgets/customs_app_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/get_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pod_player/pod_player.dart';
import 'package:video_player/video_player.dart';

class CourseDetailsPage1Screen extends StatefulWidget {
  const CourseDetailsPage1Screen(
      {super.key,
      this.courseId,
      this.moduleId,
      this.sectionId,
      this.dayId,
      required this.appBarTitle,
      required this.isFromBatch,
      this.batchId,
      required this.isLibrary});
  final String? courseId;
  final String? moduleId;
  final String appBarTitle;
  final String? sectionId;
  final String? dayId;
  final bool isFromBatch;
  final bool isLibrary;
  final String? batchId;
  @override
  State<CourseDetailsPage1Screen> createState() =>
      _CourseDetailsPage1ScreenState();
}

class _CourseDetailsPage1ScreenState extends State<CourseDetailsPage1Screen> {
  HomeController homeController = Get.put(HomeController());
  CourseContentController courseContentController =
      Get.put(CourseContentController());

  CourseModuleController videoController = Get.put(CourseModuleController());

  CourseEnrolController enrolController = Get.put(CourseEnrolController());

  // late FlickManager flickManager;
  late PodPlayerController podPlayerController;

  final ScrollController _scrollController = ScrollController();
  late Future<void> _initializeVideoPlayerFuture;
  int? bufferDelay;
  final bool _showControls = false;
  String? _videoUrl;

  Timer? _hideControlsTimer;

  int currPlayIndex = 0;

  @override
  void initState() {
    print(courseContentController.courseContent.contents);
    print(widget.moduleId);
    WidgetsFlutterBinding.ensureInitialized().scheduleFrameCallback(
      (timeStamp) {
        getData();
      },
    );

    super.initState();
  }

  getData() async {
    try {
      courseContentController.isLoading.value = true;

      await courseContentController
          .getCourseContent(
              isLibrary: widget.isLibrary,
              courseId: widget.courseId!,
              moduleId: widget.moduleId!,
              batchId: widget.batchId!,
              dayId: widget.dayId.toString(),
              sectionId: widget.sectionId.toString())
          .then((v) {
        _initializeVideoPlayerFuture = Future.value();
        homeController.setTitle(
            courseContentController.courseContent.contents?[0].contentName ??
                courseContentController
                    .courseContent.contents?[0].exams![0].examName ??
                '');
        homeController.getSelectedCourseCategory(
            courseContentController.courseContent.contents?[0].fileType ??
                courseContentController
                    .courseContent.contents?[0].exams?[0].fileType ??
                '');
        if (courseContentController.courseContent.contents != null &&
            courseContentController.courseContent.contents?[0].file != null &&
            courseContentController.courseContent.contents?[0].fileType ==
                'video/mp4') {
          print('sdgvrfb  1');
          courseContentController.isLoading.value = true;

          _videoUrl =
              '${HttpUrls.imgBaseUrl}${courseContentController.courseContent.contents?[0].file}';
          print('sdgvrfb  1$_videoUrl');
          // flickManager = FlickManager(
          //   videoPlayerController:
          //       VideoPlayerController.networkUrl(Uri.parse(_videoUrl ?? '')),
          // );
          podPlayerController = PodPlayerController(
            playVideoFrom: PlayVideoFrom.network(
              _videoUrl ?? '',
            ),
          )..initialise().then((v) {
              setState(() {});
            }).catchError((e, s) {
              print('POD PLAYER ERROR : $e $s');
            });
        } else {
          print('sdgvrfb ${courseContentController.courseContent.contents} 3');
          _videoUrl = null;
          podPlayerController = PodPlayerController(
            playVideoFrom: PlayVideoFrom.network(
              '',
            ),
          )..initialise().then((v) {
              setState(() {});
            }).catchError((e, s) {
              print('POD PLAYER ERROR : $e $s');
            });
          // flickManager = FlickManager(
          //   videoPlayerController:
          //       VideoPlayerController.networkUrl(Uri.parse('')),
          // );
        }
        // flickManager = FlickManager(
        //     videoPlayerController: VideoPlayerController.networkUrl(
        //   Uri.parse(courseContentController.courseContent.contents?[0].file ??
        //       homeController.videoURL),
        // ));
        initializePlayer();
        courseContentController.isLoading.value = false;
      });
    } catch (e) {}
    // }
  }

  bool isVideoLoading = false;

  void showVideo(String url) async {
    setState(() => isVideoLoading = true);
    // Pause current playback before changing video
    // await flickManager.flickControlManager?.pause();
    try {
      podPlayerController.dispose();
      print('gfsrfgv ');
    } catch (e) {}

    // Dispose the current flick manager
// Update the video URL
    _videoUrl = url;
    print('Updated video URL: $_videoUrl');

    // Initialize the new video player controller
    podPlayerController = PodPlayerController(
      playVideoFrom: PlayVideoFrom.network(_videoUrl ?? ''),
    )..initialise().then((v) {
        setState(() {});
      }).catchError((e, s) {
        print('POD PLAYER ERROR : $e $s');
      });

    // // Update the state after initializing the new manager
    // setState(() {
    //   _initializeVideoPlayerFuture = Future.value();
    // });

    // Play the new video
    // await flickManager.flickControlManager?.play();
    setState(() => isVideoLoading = false);
  }

  @override
  void dispose() {
    podPlayerController.dispose();
    courseContentController.courseContent.contents = null;
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
    );
  }

  Future<void> initializePlayer() async {
    // await Future.wait([]);
    // setState(() {});
  }

  // Future<void> toggleVideo() async {
  //   print('dafwefe');
  //   await initializePlayer();
  // }

  void _fastForward() {}

  void _fastRewind() {}

  @override
  Widget build(BuildContext context) {
    print('<<<<<<<<<<<<<<<<<<<<<<<<course building>>>>>>>>>>>>>>>>>>>>>>>>');
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    Get.back();
                  },
                  child: Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: ColorResources.colorBlue100,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: ColorResources.colorBlack.withOpacity(.4),
                        size: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.appBarTitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: ColorResources.colorBlack,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        // appBar: _buildAppBar(),
        body: Obx(() {
          return courseContentController.isLoading.value
              ? const Center(child: LoadingCircle())
              : courseContentController.courseContent.contents == null
                  ? const Center(
                      child: Text('No Documents Found In This Course'),
                    )
                  : Container(
                      width: double.maxFinite,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 5),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 0),
                                child: Obx(() {
                                  return Column(
                                    children: [
                                      if (homeController
                                              .selectedCourseCategory.value ==
                                          'video/mp4')
                                        isVideoLoading
                                            ? const Center(
                                                child:
                                                    CircularProgressIndicator())
                                            : SizedBox(
                                                height: 200,
                                                child: PodVideoPlayer(
                                                    controller:
                                                        podPlayerController))
                                      //   FlickVideoPlayer(
                                      //       flickManager: flickManager),
                                      // )
                                      else
                                        Container(
                                          height: 200,
                                          decoration: const BoxDecoration(
                                            image: DecorationImage(
                                                image: AssetImage(
                                                    'assets/images/OET Thumbnails 1.png'),
                                                fit: BoxFit.cover),
                                          ),
                                          child: Center(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: Colors.black,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 37,
                                                        vertical: 10),
                                              ),
                                              onPressed: () {
                                                var content =
                                                    courseContentController
                                                            .courseContent
                                                            .contents![
                                                        homeController
                                                            .selectedIndex
                                                            .value];

                                                print(
                                                    "DEBUG: Content Name: ${content.contentName}");
                                                print(
                                                    "DEBUG: Content File: ${content.file}");
                                                print(
                                                    "DEBUG: Content Type: ${content.fileType}");

                                                var pdfurl = "";
                                                if (content.exams
                                                            ?.isNotEmpty ==
                                                        true &&
                                                    content.exams![0]
                                                            .supportingDocumentPath !=
                                                        null &&
                                                    content
                                                        .exams![0]
                                                        .supportingDocumentPath!
                                                        .isNotEmpty) {
                                                  pdfurl = content.exams![0]
                                                      .supportingDocumentPath!;
                                                } else if ((content.fileType ==
                                                            'application/pdf' ||
                                                        content.fileType
                                                                ?.contains(
                                                                    'image') ==
                                                            true) &&
                                                    content.file != null) {
                                                  pdfurl = content.file!;
                                                }

                                                var audiourl = "";
                                                if (content.exams
                                                            ?.isNotEmpty ==
                                                        true &&
                                                    content.exams![0]
                                                            .mainQuestion !=
                                                        null &&
                                                    content
                                                        .exams![0]
                                                        .mainQuestion!
                                                        .isNotEmpty) {
                                                  audiourl = content
                                                      .exams![0].mainQuestion!;
                                                } else if (content.fileType
                                                            ?.contains(
                                                                'audio') ==
                                                        true &&
                                                    content.file != null) {
                                                  audiourl = content.file!;
                                                }

                                                print(
                                                    "DEBUG: Calculated pdfurl: '$pdfurl'");
                                                print(
                                                    "DEBUG: Calculated audiourl: '$audiourl'");

                                                if (homeController.selectedIndex
                                                            .value <
                                                        0 ||
                                                    homeController.selectedIndex
                                                            .value >=
                                                        courseContentController
                                                            .courseContent
                                                            .contents!
                                                            .length) {
                                                  Get.snackbar(
                                                    "Invalid Selection",
                                                    "Please select a valid course",
                                                    snackPosition:
                                                        SnackPosition.BOTTOM,
                                                    backgroundColor: Colors.red,
                                                    colorText: Colors.white,
                                                    duration: const Duration(
                                                        seconds: 2),
                                                  );
                                                  return;
                                                }

                                                if (pdfurl.isEmpty &&
                                                    audiourl.isEmpty) {
                                                  print(
                                                      "DEBUG: Both PDF/Image and Audio URLs are empty. Showing snackbar.");
                                                  Get.snackbar(
                                                    "Content Not Found",
                                                    "Sorry, the requested content is currently unavailable.",
                                                    snackPosition:
                                                        SnackPosition.BOTTOM,
                                                    duration: const Duration(
                                                        seconds: 2),
                                                  );
                                                } else {
                                                  String finalFileUrl = pdfurl
                                                          .isNotEmpty
                                                      ? (pdfurl.startsWith(
                                                              'http')
                                                          ? pdfurl
                                                          : '${HttpUrls.imgBaseUrl}$pdfurl')
                                                      : '';
                                                  print(
                                                      "DEBUG: Navigating to PdfViewerPage with fileUrl: '$finalFileUrl'");
                                                  Get.to(
                                                    () => PdfViewerPage(
                                                      answerKey: (content.exams
                                                                      ?.isNotEmpty ==
                                                                  true &&
                                                              content.exams![0]
                                                                      .answerKeyPath !=
                                                                  null &&
                                                              content
                                                                  .exams![0]
                                                                  .answerKeyPath
                                                                  .isNotEmpty)
                                                          ? (content.exams![0]
                                                                  .answerKeyPath
                                                                  .startsWith(
                                                                      'http')
                                                              ? content
                                                                  .exams![0]
                                                                  .answerKeyPath
                                                              : '${HttpUrls.imgBaseUrl}${content.exams![0].answerKeyPath}')
                                                          : null,
                                                      answerPdf: (content.exams
                                                                  ?.isNotEmpty ==
                                                              true)
                                                          ? content.exams![0]
                                                              .answerKeyPath
                                                          : '',
                                                      media: audiourl,
                                                      fileUrl: finalFileUrl,
                                                    ),
                                                  );
                                                }
                                              },
                                              child: Text(
                                                homeController
                                                            .selectedCourseCategory
                                                            .value ==
                                                        'application/pdf'
                                                    ? 'Open PDF'
                                                    : homeController
                                                            .selectedCourseCategory
                                                            .value
                                                            .contains('image')
                                                        ? 'View Image'
                                                        : 'Start Your Test',
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w700),
                                              ),
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 20),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                homeController.title.value,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  color: ColorResources
                                                      .colorgrey700,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Divider(),
                                      const SizedBox(height: 16),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5),
                                        child: CourseCurriculamWidget(
                                            isExamTest: courseContentController
                                                .courseContent
                                                .contents?[0]
                                                .isExamTest,
                                            sectionName: widget.appBarTitle,
                                            toggleVideo: showVideo,
                                            isFromBatch: widget.isFromBatch,
                                            batchId: widget.batchId ?? '',
                                            modules: courseContentController
                                                .courseContent.contents,
                                            scrollController: _scrollController,
                                            controllerCourseDetailsController:
                                                homeController),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          )
                        ],
                      ),
                    );
        }),
      ),
    );
  }

  // /// Section Widget
  // PreferredSizeWidget _buildAppBar() {
  //   return CustomsAppBar(
  //     height: 80,
  //     leadingWidth: 50,
  //     leading: Container(
  //       margin: EdgeInsets.only(left: 16),
  //       child: InkWell(
  //         onTap: () {
  //           onTapArrowleftone();
  //         },
  //         child: CircleAvatar(
  //           radius: 20,
  //           backgroundColor: ColorResources.colorBlue100,
  //           child: Padding(
  //             padding: EdgeInsets.only(left: 8),
  //             child: Icon(
  //               Icons.arrow_back_ios,
  //               color: ColorResources.colorBlack.withOpacity(.8),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //     title: Padding(
  //       padding: const EdgeInsets.only(left: 8.0),
  //       child: Text(
  //         "lbl_course_details".tr,
  //         style: CustomTextStyles.titleMediumBluegray8000118,
  //       ),
  //     ),
  //   );
  // }

  onTapArrowleftone() {
    Get.back();
  }
}
