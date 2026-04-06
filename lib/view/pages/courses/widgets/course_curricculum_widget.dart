import 'package:breffini_staff/controller/calls_page_controller.dart';
import 'package:breffini_staff/controller/home_controller.dart';
import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/core/utils/extentions.dart';
import 'package:breffini_staff/http/http_urls.dart';
import 'package:breffini_staff/model/course_content_by_module.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class CourseCurriculamWidget extends StatefulWidget {
  const CourseCurriculamWidget({
    super.key,
    required this.controllerCourseDetailsController,
    required this.scrollController,
    this.modules,
    required this.toggleVideo,
    required this.sectionName,
    required this.isFromBatch,
    required this.isExamTest,
    this.batchId,
  });
  final HomeController controllerCourseDetailsController;
  final ScrollController scrollController;
  final List<Content>? modules;
  final String sectionName;
  final bool isFromBatch;
  final int? isExamTest;
  final String? batchId;
  final void Function(String) toggleVideo;

  @override
  State<CourseCurriculamWidget> createState() => _CourseCurriculamWidgetState();
}

class _CourseCurriculamWidgetState extends State<CourseCurriculamWidget> {
  @override
  void initState() {
    print("Is Exam Test --- " + widget.isExamTest.toString());
    if (widget.sectionName.toLowerCase().trim() == 'listening') {
      print('EXAMTEST////////////${widget.isExamTest}');
      widget.controllerCourseDetailsController.checkboxStates =
          RxList<RxList<bool>>.from(
        List.generate(
            widget.modules!.length, (i) => RxList<bool>.from([false, false])),
      );
    } else {
      print('fgetg2 ${widget.sectionName}');
      widget.controllerCourseDetailsController.checkboxStates =
          RxList<RxList<bool>>.from(
        List.generate(
            widget.modules!.length, (i) => RxList<bool>.from([false])),
      );
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('dfsdb ${widget.modules![0].contentThumbnailPath}');
    print('rger ${widget.sectionName}');
    return Obx(() {
      print(
          'wrgwr ${widget.controllerCourseDetailsController.checkboxStates[0][0]}');

      print('rger ${widget.sectionName}');
      print(widget.controllerCourseDetailsController.checkboxStates);
      return Column(
        children: widget.modules!.asMap().entries.map((v) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: Material(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  side: widget.controllerCourseDetailsController.selectedIndex
                              .value ==
                          v.key
                      ? const BorderSide(color: Color(0xFF2B83D5))
                      : BorderSide.none,
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () => onTapCourseCard(v),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                dense: true,
                minVerticalPadding: 2,
                visualDensity: VisualDensity.comfortable,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        v.value.contentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                    ),
                    if (!v.value.externalLink.isNullOrEmpty())
                      InkWell(
                        onTap: () {
                          _launchUrl(v.value.externalLink);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8))),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6.0),
                            child: Text(
                              'Link',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      )
                    // if (v.value.file == null) ActionChip(label: Text('exam'))
                  ],
                ),
                leading: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                        color: v.key == 0
                            ? Colors.blue.shade200
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(7)),
                    child: CachedNetworkImage(
                      imageUrl:
                          '${HttpUrls.imgBaseUrl}${v.value.contentThumbnailPath}',
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: ColorResources.colorBlue100,
                          size: 40,
                        ),
                      ),
                      progressIndicatorBuilder:
                          (context, url, downloadProgress) => Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: ColorResources.colorBlue500,
                          value: downloadProgress.progress,
                        ),
                      ),
                    )),
                subtitle: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        getTitle(v),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: ColorResources.colorBlack,
                          fontWeight: FontWeight.w700,
                          fontSize: 8,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    if (widget.isExamTest == 1)
                      if (widget.isFromBatch)
                        if (v.value.exams!.isNotEmpty)
                          Row(
                            children: [
                              const Text('PDF'),
                              Checkbox(
                                visualDensity: VisualDensity.comfortable,
                                value: widget.controllerCourseDetailsController
                                        .checkboxStates[v.key][0] ||
                                    1 == v.value.exams![0].Is_Question_Unlocked,
                                onChanged: (result) {
                                  result ??= false;

                                  // Update PDF checkbox state
                                  widget.controllerCourseDetailsController
                                      .checkboxStates[v.key][0] = result;

                                  v.value.exams![0].Is_Question_Unlocked =
                                      result ? 1 : 0;
                                  // Call unlockExam with the current checkbox state
                                  widget.controllerCourseDetailsController
                                      .unlockExam(
                                    isAnswerUnlocked: (widget
                                                    .controllerCourseDetailsController
                                                    .checkboxStates[v.key]
                                                    .length >
                                                2
                                            ? widget
                                                .controllerCourseDetailsController
                                                .checkboxStates[v.key][2]
                                            : false) ||
                                        (v.value.exams != null &&
                                            v.value.exams!.isNotEmpty &&
                                            v.value.exams![0]
                                                    .isAnswerUnlocked ==
                                                1),
                                    contentId: v.value.contentId.toString(),
                                    examId: v.value.exams![0].examId.toString(),
                                    batchId: widget.batchId.toString(),
                                    isPDFUnlocked:
                                        result, // Use the current checkbox state
                                    isAudioUnlocked: (v.key <
                                                widget
                                                    .controllerCourseDetailsController
                                                    .checkboxStates
                                                    .length &&
                                            widget
                                                    .controllerCourseDetailsController
                                                    .checkboxStates[v.key]
                                                    .length >
                                                1
                                        ? widget.controllerCourseDetailsController
                                                .checkboxStates[v.key][1] ||
                                            (v.value.exams != null &&
                                                v.value.exams!.isNotEmpty &&
                                                v.value.exams![0]
                                                        .Is_Question_Media_Unlocked ==
                                                    1)
                                        : false), // Default to false if index 1 is not found
                                  );
                                },
                              ),
                            ],
                          ),
                    if (widget.isExamTest == 1)
                      if (widget.isFromBatch)
                        if (v.value.exams != null && v.value.exams!.isNotEmpty)
                          if (v.value.exams![0].mainQuestion.isNotEmpty)
                            Row(
                              children: [
                                const Text('Audio'),
                                Checkbox(
                                  visualDensity: VisualDensity.comfortable,
                                  value: widget
                                          .controllerCourseDetailsController
                                          .checkboxStates[v.key][1] ||
                                      1 ==
                                          v.value.exams![0]
                                              .Is_Question_Media_Unlocked,
                                  onChanged: (result) {
                                    result ??= false;

                                    // Update Audio checkbox state
                                    widget.controllerCourseDetailsController
                                        .checkboxStates[v.key][1] = result;

                                    v.value.exams![0]
                                            .Is_Question_Media_Unlocked =
                                        result ? 1 : 0;
                                    // Call unlockExam with the current checkbox state
                                    widget.controllerCourseDetailsController
                                        .unlockExam(
                                      isAnswerUnlocked: (widget
                                                      .controllerCourseDetailsController
                                                      .checkboxStates[v.key]
                                                      .length >
                                                  2
                                              ? widget
                                                  .controllerCourseDetailsController
                                                  .checkboxStates[v.key][2]
                                              : false) ||
                                          (v.value.exams != null &&
                                              v.value.exams!.isNotEmpty &&
                                              v.value.exams![0]
                                                      .isAnswerUnlocked ==
                                                  1),
                                      contentId: v.value.contentId.toString(),
                                      examId:
                                          v.value.exams![0].examId.toString(),
                                      batchId: widget.batchId.toString(),
                                      isPDFUnlocked: widget
                                              .controllerCourseDetailsController
                                              .checkboxStates[v.key][0] ||
                                          (v.value.exams != null &&
                                              v.value.exams!.isNotEmpty &&
                                              v.value.exams![0]
                                                      .Is_Question_Unlocked ==
                                                  1),
                                      isAudioUnlocked:
                                          result, // Use the current checkbox state
                                    );
                                  },
                                ),
                              ],
                            ),
                    if (widget.isExamTest == 1)
                      if (widget.isFromBatch)
                        if (v.value.exams != null && v.value.exams!.isNotEmpty)
                          if (v.value.exams![0].answerKeyPath.isNotEmpty)
                            Row(
                              children: [
                                const Text('Answer'),
                                Checkbox(
                                  visualDensity: VisualDensity.comfortable,
                                  value: (widget
                                                  .controllerCourseDetailsController
                                                  .checkboxStates[v.key]
                                                  .length >
                                              2
                                          ? widget
                                              .controllerCourseDetailsController
                                              .checkboxStates[v.key][2]
                                          : false) ||
                                      1 == v.value.exams![0].isAnswerUnlocked,
                                  onChanged: (result) {
                                    result ??= false;

                                    if (widget.controllerCourseDetailsController
                                            .checkboxStates[v.key].length <
                                        3) {
                                      widget.controllerCourseDetailsController
                                              .checkboxStates[v.key] =
                                          RxList.filled(3, false);
                                    }

                                    // Update Answer Key checkbox state
                                    widget.controllerCourseDetailsController
                                        .checkboxStates[v.key][2] = result;

                                    v.value.exams![0].isAnswerUnlocked =
                                        result ? 1 : 0;

                                    // Call unlockExam with the current checkbox state
                                    widget.controllerCourseDetailsController
                                        .unlockExam(
                                      isAnswerUnlocked: result,
                                      contentId: v.value.contentId.toString(),
                                      examId:
                                          v.value.exams![0].examId.toString(),
                                      batchId: widget.batchId.toString(),

                                      // Safely check PDF unlock state
                                      isPDFUnlocked: (widget
                                                      .controllerCourseDetailsController
                                                      .checkboxStates[v.key]
                                                      .length >
                                                  0
                                              ? widget
                                                  .controllerCourseDetailsController
                                                  .checkboxStates[v.key][0]
                                              : false) ||
                                          (v.value.exams != null &&
                                              v.value.exams!.isNotEmpty &&
                                              v.value.exams![0]
                                                      .Is_Question_Unlocked ==
                                                  1),

                                      // Safely check Audio unlock state
                                      isAudioUnlocked: (widget
                                                      .controllerCourseDetailsController
                                                      .checkboxStates[v.key]
                                                      .length >
                                                  1
                                              ? widget
                                                  .controllerCourseDetailsController
                                                  .checkboxStates[v.key][1]
                                              : false) ||
                                          (v.value.exams != null &&
                                              v.value.exams!.isNotEmpty &&
                                              v.value.exams![0]
                                                      .Is_Question_Media_Unlocked ==
                                                  1),
                                    );
                                  },
                                ),
                              ],
                            ),
                    // Text(
                    //   v.value['content_length'],
                    //   style: GoogleFonts.plusJakartaSans(
                    //       color: Colors.grey.shade500,
                    //       fontWeight: FontWeight.w500,
                    //       fontSize: 12),
                    // ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  String getTitle(MapEntry<int, Content> v) {
    String? fileType = v.value.fileType;
    if (fileType == null &&
        v.value.exams != null &&
        v.value.exams!.isNotEmpty) {
      fileType = v.value.exams![0].fileType;
    }

    print("DEBUG: getTitle - Content: ${v.value.contentName}, Type: $fileType");

    String s = fileType ?? "";
    if (s.contains('audio')) return 'Audio';
    if (s == 'video/mp4') return 'Video';
    if (s.contains('image')) return 'Image';
    return 'PDF';
  }

  onTapCourseCard(MapEntry<int, Content> v) {
    print("DEBUG: onTapCourseCard - Content: ${v.value.contentName}");
    widget.controllerCourseDetailsController.selectedIndex.value = v.key;
    widget.controllerCourseDetailsController.setTitle(v.value.contentName);

    String? fileType = v.value.fileType;
    if (fileType == null &&
        v.value.exams != null &&
        v.value.exams!.isNotEmpty) {
      fileType = v.value.exams![0].fileType;
    }

    print("DEBUG: onTapCourseCard - Setting category: $fileType");
    widget.controllerCourseDetailsController
        .getSelectedCourseCategory(fileType ?? "");

    String fileUrl = '${HttpUrls.imgBaseUrl}${v.value.file}';
    widget.controllerCourseDetailsController.videoURL = fileUrl;

    if (fileType != 'application/pdf') {
      print("DEBUG: onTapCourseCard - Toggling video for: $fileUrl");
      widget.toggleVideo(fileUrl);
    } else {
      print("DEBUG: onTapCourseCard - Item is PDF, skipping video toggle.");
    }

    widget.scrollController.animateTo(0,
        curve: Curves.fastEaseInToSlowEaseOut,
        duration: const Duration(milliseconds: 700));
  }
}
