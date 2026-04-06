import 'dart:developer';

import 'package:breffini_staff/controller/calls_page_controller.dart';
import 'package:breffini_staff/controller/course_enrol_controller.dart';
import 'package:breffini_staff/controller/course_module_controler.dart';
import 'package:breffini_staff/controller/tab_controller.dart';
import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/core/utils/extentions.dart';
import 'package:breffini_staff/core/utils/pref_utils.dart';
import 'package:breffini_staff/http/http_urls.dart';
import 'package:breffini_staff/view/pages/chats/widgets/loading_circle.dart';
import 'package:breffini_staff/view/pages/courses/day_category_screen.dart';
import 'package:breffini_staff/view/pages/courses/widgets/grid_view_day_widget.dart';
import 'package:breffini_staff/view/pages/courses/widgets/read_more_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CourseCategoryDetailsScreen extends StatefulWidget {
  final int courseId;
  final bool isFromBatch;
  final String? batchId;
  final String? startTime;
  final String? endTime;
  final VoidCallback? click;

  const CourseCategoryDetailsScreen({
    super.key,
    required this.courseId,
    required this.isFromBatch,
    this.batchId,
    this.startTime,
    this.endTime,
    this.click,
  });

  @override
  State<CourseCategoryDetailsScreen> createState() =>
      _CourseCategoryDetailsScreenState();

  then(Null Function(dynamic value) param0) {}
}

class _CourseCategoryDetailsScreenState
    extends State<CourseCategoryDetailsScreen>
    with SingleTickerProviderStateMixin {
  final CourseModuleController controller = Get.find();
  final CourseEnrolController enrolController = Get.find();
  final TabControllerState tabControllerState = Get.put(TabControllerState());
  final CallandChatController callandChatController =
      Get.put(CallandChatController());
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized().scheduleFrameCallback(
      (timeStamp) {
        controller.getCourseInfo(courseId: widget.courseId);
        controller.getSectionByCourse(courseId: widget.courseId.toString());
        // Fetch modules first, then days
        controller
            .getCoursesModules(courseId: widget.courseId.toString())
            .then((_) {
          if (controller.courseModulesList.isNotEmpty) {
            enrolController.getBatchWithDays(widget.courseId.toString(),
                controller.courseModulesList[0].moduleId.toString());
          }
        });
      },
    );

    _tabController = TabController(length: 1, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    tabControllerState.setIndex(_tabController.index);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  // Stream<String> get isLiveFinishStream async* {
  //   final prefs = await SharedPreferences.getInstance();
  //   yield prefs.getString('isLiveFinish') ?? "0";
  //   yield* Stream.periodic(Duration(seconds: 1), (_) async {
  //     final prefs = await SharedPreferences.getInstance();
  //     return prefs.getString('isLiveFinish') ?? "0";
  //   }).asyncMap((event) async => await event);
  // }
  bool isCurrentTimeInRange(String startTime, String endTime) {
    try {
      DateTime now = DateTime.now();

      // Helper function to convert any time format to minutes
      int timeToMinutes(String timeStr) {
        try {
          // Handle 24-hour format (e.g., "14:00")
          if (!timeStr.contains(' ')) {
            List<String> parts = timeStr.split(':');
            int hours = int.parse(parts[0]);
            int minutes = int.parse(parts[1]);
            return hours * 60 + minutes;
          }

          // Handle 12-hour format (e.g., "2:00 PM")
          List<String> parts = timeStr.split(' ');
          String time = parts[0];
          String period = parts[1]; // AM or PM

          List<String> timeParts = time.split(':');
          int hours = int.parse(timeParts[0]);
          int minutes = int.parse(timeParts[1]);

          // Convert to 24-hour format
          if (period.toUpperCase() == 'PM' && hours != 12) {
            hours += 12;
          } else if (period.toUpperCase() == 'AM' && hours == 12) {
            hours = 0;
          }

          return hours * 60 + minutes;
        } catch (e) {
          // log("Error parsing time: $timeStr");
          rethrow;
        }
      }

      // Convert current time to minutes
      int currentMinutes = now.hour * 60 + now.minute;

      // Convert start and end times to minutes
      int startMinutes = timeToMinutes(startTime);
      int endMinutes = timeToMinutes(endTime);

      // log("Raw minutes calculation:");
      // log("Current: $currentMinutes (${now.hour}:${now.minute})");
      // log("Start: $startMinutes");
      // log("End: $endMinutes");

      // Handle overnight range
      if (startMinutes > endMinutes) {
        // log("Overnight range detected");
        int adjustedEnd = endMinutes + (24 * 60);
        int adjustedCurrent = currentMinutes;

        // If current time is after midnight (i.e., less than start time)
        if (currentMinutes < startMinutes) {
          adjustedCurrent = currentMinutes + (24 * 60);
        }

        // log("Adjusted minutes for overnight:");
        // log("Current: $adjustedCurrent");
        // log("Start: $startMinutes");
        // log("End: $adjustedEnd");

        bool isInRange =
            adjustedCurrent >= startMinutes && adjustedCurrent <= adjustedEnd;
        // log("Final result: $isInRange (Current: $adjustedCurrent, Start: $startMinutes, End: $adjustedEnd)");
        return isInRange;
      }

      // Regular (same-day) range check
      bool isInRange =
          currentMinutes >= startMinutes && currentMinutes <= endMinutes;
      // log("Final result: $isInRange (Current: $currentMinutes, Start: $startMinutes, End: $endMinutes)");
      return isInRange;
    } catch (e) {
      // log("Error parsing time: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  'Course details',
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
        backgroundColor: const Color(0xFFF4F7FA),
        body: Obx(() {
          return controller.isCourseLoading.value
              ? const Center(
                  child: LoadingCircle(),
                )
              : controller.courseInfo.isEmpty
                  ? const Center(child: Text('No Course info'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              height: 180,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                    image: CachedNetworkImageProvider(
                                        '${HttpUrls.imgBaseUrl}${controller.courseInfo[0].thumbnailPath ?? ''}'),
                                    fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              controller.courseInfo[0].courseName,
                              style: GoogleFonts.plusJakartaSans(
                                color: ColorResources.colorBlack,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // controller.courseInfo[0].description != ''
                          //     ? Padding(
                          //         padding: const EdgeInsets.symmetric(
                          //             horizontal: 16),
                          //         child: ReadMoreWidget(
                          //           description:
                          //               controller.courseInfo[0].description,
                          //         ),
                          //       )
                          //     : const SizedBox(),
                          // controller.courseInfo[0].description != ''
                          //     ? const SizedBox(height: 32)
                          //     : const SizedBox(
                          //         height: 8,
                          //       ),
                          if (widget.isFromBatch)
                            StreamBuilder(
                                stream:
                                    Stream.periodic(const Duration(seconds: 1)),
                                builder: (context, snapshot) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 15),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        color: Colors.white),
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 2),
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              color: Colors.red),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.circle,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                              Text(
                                                '  Live',
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  color:
                                                      ColorResources.colorwhite,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Ready To Go Live ?",
                                                    style: GoogleFonts
                                                        .plusJakartaSans(
                                                      color: ColorResources
                                                          .colorBlack,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: 5,
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.access_time,
                                                        color:
                                                            Color(0xFF9299A2),
                                                        size: 15,
                                                      ),
                                                      const SizedBox(
                                                        width: 5,
                                                      ),
                                                      Text(
                                                        "${widget.startTime} - ${widget.endTime}",
                                                        style: GoogleFonts
                                                            .plusJakartaSans(
                                                          color: const Color(
                                                              0xFF9299A2),
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                  minimumSize: const Size(
                                                      30, 35.0),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius
                                                          .circular(100.w)),
                                                  backgroundColor:
                                                      isCurrentTimeInRange(
                                                              widget.startTime!,
                                                              widget.endTime!)
                                                          ? const Color
                                                              .fromARGB(
                                                              255, 43, 135, 247)
                                                          : ColorResources
                                                              .colorgrey300),
                                              onPressed: () {
                                                log('endttttttt${widget.endTime!}');
                                                isCurrentTimeInRange(
                                                        widget.startTime!,
                                                        widget.endTime!)
                                                    ? widget.click!()
                                                    : Get.showSnackbar(
                                                        const GetSnackBar(
                                                        message:
                                                            'Live sessions are limited to particular time windows.',
                                                        duration: Duration(
                                                            milliseconds: 2500),
                                                      ));
                                              },
                                              child: Text(
                                                callandChatController
                                                        .currentCallModel
                                                        .value
                                                        .liveLink
                                                        .isNullOrEmpty()
                                                    ? 'Go Live'
                                                    : !callandChatController
                                                                .currentCallModel
                                                                .value
                                                                .liveLink
                                                                .isNullOrEmpty() &&
                                                            callandChatController
                                                                    .currentCallModel
                                                                    .value
                                                                    .type ==
                                                                "new_call"
                                                        ? 'Go Live'
                                                        : 'ReJoin',
                                                // "Go Live",
                                                // PrefUtils().isLiveFinished()
                                                //     ? "Go Live"
                                                //     : "Rejoin",
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  color:
                                                      ColorResources.colorwhite,
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                          const SizedBox(
                            height: 8,
                          ),
                          DefaultTabController(
                            length: 1,
                            child: Column(
                              children: [
                                TabBar(
                                  controller: _tabController,
                                  isScrollable: false,
                                  tabAlignment: TabAlignment.fill,
                                  dividerColor: ColorResources.colorgrey200,
                                  tabs: [
                                    Tab(
                                      child: Text(
                                        'Days',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                  indicatorColor: ColorResources.colorBlue300,
                                  labelColor: ColorResources.colorBlack,
                                  unselectedLabelColor:
                                      ColorResources.colorgrey500,
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: Get.height / 2,
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: controller.courseModulesList.isEmpty
                                            ? const Center(
                                                child: Text('No Days found'),
                                              )
                                            : enrolController.isLoading.value
                                                ? const Center(
                                                    child: LoadingCircle(),
                                                  )
                                                : GridViewDayWidget(
                                                    batchDays: enrolController
                                                        .batchDaysList,
                                                    onDayTapped: (day) {
                                                      Get.to(() => DayCategoryScreen(
                                                          isTab: false,
                                                          isLibrary: false,
                                                          isFromBatch:
                                                              widget.isFromBatch,
                                                          batchId: widget.batchId,
                                                          dayId:
                                                              day.daysId.toString(),
                                                          courseId: widget.courseId
                                                              .toString(),
                                                          moduleId: controller
                                                              .courseModulesList[0]
                                                              .moduleId
                                                              .toString(),
                                                          appBarTitle:
                                                              '${controller.courseInfo[0].courseName}-${day.dayName}'));
                                                    },
                                                  ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
        }),
      ),
    );
  }
}
