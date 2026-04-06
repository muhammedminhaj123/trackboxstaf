import 'package:breffini_staff/controller/calls_page_controller.dart';
import 'package:breffini_staff/controller/course_module_controler.dart';
import 'package:breffini_staff/controller/live_controller.dart';
import 'package:breffini_staff/controller/login_controller.dart';
import 'package:breffini_staff/controller/ongoing_call_controller.dart';
import 'package:breffini_staff/controller/profile_controller.dart';
import 'package:breffini_staff/core/theme/color_resources.dart';

import 'package:breffini_staff/core/utils/image_constants.dart';

import 'package:breffini_staff/view/pages/courses/student_list.dart';
import 'package:breffini_staff/view/pages/home_screen.dart';

import 'package:breffini_staff/view/pages/profile/courses_of_teacher.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  final LiveClassController liveClassController =
      Get.put(LiveClassController());
  final CallOngoingController callOngoingController =
      Get.put(CallOngoingController());
  final LoginController loginController = Get.put(LoginController());
  final ProfileController profileController = Get.put(ProfileController());
  final courseInfoController = Get.find<CourseModuleController>();
  final ScrollController _scrollController = ScrollController();
  final callandChatController = Get.put(CallandChatController());

  @override
  void initState() {
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _initializeData();
    });

    super.initState();
  }

  Future<void> _initializeData() async {
    await Future.wait<void>([
      // liveClassController.getUpcomingLive(),
      // callOngoingController.getCompletedClass(),
    ]);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      if (!callOngoingController.isLoadingMore.value &&
          callOngoingController.hasMoreData.value) {
        callOngoingController.getCompletedClass(isLoadMore: true);
      }
    }
  }

  void showLogoutDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: TextStyle(
                fontSize: 18.w,
                fontWeight: FontWeight.w700,
                color: const Color(0xff283B52)),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: GoogleFonts.plusJakartaSans(),
          ),
          actions: [
            TextButton(
              child: Text(
                'No',
                style: GoogleFonts.plusJakartaSans(
                  color: ColorResources.colorgrey700,
                ),
              ),
              onPressed: () {
                Get.back();
              },
            ),
            TextButton(
              child: Text(
                'Yes',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xffEB4141),
                ),
              ),
              onPressed: () {
                Get.back();
                loginController.logout();
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    // Check if we are already on the HomePage
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => const HomePage(initialIndex: 0),
    ));

    return false;
  }

  String formatTimeToAmPm(String time24Hour) {
    try {
      DateTime time = DateFormat("HH:mm").parse(time24Hour);
      return DateFormat("h:mm a").format(time);
    } catch (e) {
      return "Invalid time";
    }
  }

  void showAlertDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Can't Start",
                style: TextStyle(
                    fontSize: 18.w,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff283B52)),
              ),
            ],
          ),
          content: Text(
            "Live class Allowed Only During Available Hours",
            style: GoogleFonts.plusJakartaSans(),
          ),
          actions: [
            TextButton(
              child: Text(
                'Back',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                Get.back();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: DefaultTabController(
      length: 1,
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: ColorResources.colorwhite,
            title: Text(
              "Course",
              style: GoogleFonts.plusJakartaSans(
                color: ColorResources.colorgrey700,
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(50.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TabBar(
                  padding: EdgeInsets.zero,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: ColorResources.colorgrey300,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  indicatorColor: ColorResources.colorBlack,
                  indicatorPadding: EdgeInsets.all(8.h),
                  labelColor: ColorResources.colorBlue800,
                  unselectedLabelColor: ColorResources.colorgrey400,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    // Tab(text: 'Upcoming Live'),
                    // Tab(text: 'Completed Live'),
                    Tab(text: 'Course Materials'),
                  ],
                ),
              ),
            ),
          ),
          backgroundColor: const Color(0xFFF4F7FA),
          body: const TabBarView(children: [
            // Obx
            //   () => liveClassController.upComingLiveList.isEmpty
            //       ? const Center(
            //           child: Text('No Upcoming lives'),
            //         )
            //       : Padding(
            //           padding: EdgeInsets.symmetric(
            //             horizontal: 10.h,
            //             vertical: 10.w,
            //           ),
            //           child: SingleChildScrollView(
            //             child: Column(
            //               children: [
            //                 ListView.separated(
            //                   separatorBuilder: (context, index) {
            //                     return const SizedBox(
            //                       height: 16,
            //                     );
            //                   },
            //                   shrinkWrap: true,
            //                   physics: const ClampingScrollPhysics(),
            //                   itemCount:
            //                       liveClassController.upComingLiveList.length,
            //                   itemBuilder: (context, index) {
            //                     String startTime = liveClassController
            //                         .upComingLiveList[index].startTime;
            //                     String endTime = liveClassController
            //                         .upComingLiveList[index].endTime;

            //                     return _buildViewhierarchy(
            //                         isupComing: true,
            //                         onDetailsTap: () async {
            //                           print("qqqqqqqqqqqq");

            //                           SharedPreferences prefs =
            //                               await SharedPreferences.getInstance();
            //                           prefs.setString(
            //                               'LiveClass_ID',
            //                               liveClassController
            //                                   .upComingLiveList[index]
            //                                   .onGoing_LiveClass_Id
            //                                   .toString());

            //                           // await courseInfoController.getCourseInfo(
            //                           //     courseId: liveClassController
            //                           //         .upComingLiveList[index]
            //                           //         .courseId);
            //                           // await courseInfoController
            //                           //     .getCoursesModules(
            //                           //         courseId: liveClassController
            //                           //             .upComingLiveList[index]
            //                           //             .courseId
            //                           //             .toString());
            //                           await Get.to(() =>
            //                                   CourseCategoryDetailsScreen(
            //                                     isFromBatch: true,
            //                                     batchId: liveClassController
            //                                         .upComingLiveList[index]
            //                                         .batchId
            //                                         .toString(),
            //                                     courseId: liveClassController
            //                                         .upComingLiveList[index]
            //                                         .courseId,
            //                                     startTime:
            //                                         formatTimeToAmPm(startTime),
            //                                     endTime:
            //                                         formatTimeToAmPm(endTime),
            //                                     click: () async {
            //                                       if (!callandChatController
            //                                               .currentCallModel
            //                                               .value
            //                                               .liveLink
            //                                               .isNullOrEmpty() &&
            //                                           callandChatController
            //                                                   .currentCallModel
            //                                                   .value
            //                                                   .type ==
            //                                               "new_call") {
            //                                         ScaffoldMessenger.of(
            //                                                 context)
            //                                             .showSnackBar(
            //                                                 const SnackBar(
            //                                                     content: Text(
            //                                                         'You are in another call')));
            //                                       } else if (callandChatController
            //                                           .currentCallModel
            //                                           .value
            //                                           .liveLink
            //                                           .isNullOrEmpty()) {
            //                                         Get.to(() => CountDownPage(
            //                                               isEnd: true,
            //                                               slotId: liveClassController
            //                                                   .upComingLiveList[
            //                                                       index]
            //                                                   .slotId
            //                                                   .toString(),
            //                                               batchId:
            //                                                   liveClassController
            //                                                       .upComingLiveList[
            //                                                           index]
            //                                                       .batchId
            //                                                       .toString(),
            //                                               batchName:
            //                                                   liveClassController
            //                                                       .upComingLiveList[
            //                                                           index]
            //                                                       .batchName
            //                                                       .toString(),
            //                                               courseId:
            //                                                   liveClassController
            //                                                       .upComingLiveList[
            //                                                           index]
            //                                                       .courseId
            //                                                       .toString(),
            //                                               courseName:
            //                                                   liveClassController
            //                                                       .upComingLiveList[
            //                                                           index]
            //                                                       .courseName,
            //                                             ));
            //                                       } else if (!callandChatController
            //                                               .currentCallModel
            //                                               .value
            //                                               .liveLink
            //                                               .isNullOrEmpty() &&
            //                                           callandChatController
            //                                                   .currentCallModel
            //                                                   .value
            //                                                   .type ==
            //                                               "new_live") {
            //                                         Get.to(() => LiveCallScreen(
            //                                               liveClassId:
            //                                                   liveClassController
            //                                                       .upComingLiveList[
            //                                                           index]
            //                                                       .onGoing_LiveClass_Id
            //                                                       .toString(),
            //                                               batchId:
            //                                                   liveClassController
            //                                                       .upComingLiveList[
            //                                                           index]
            //                                                       .batchId
            //                                                       .toString(),
            //                                               courseId:
            //                                                   liveClassController
            //                                                       .upComingLiveList[
            //                                                           index]
            //                                                       .courseId
            //                                                       .toString(),
            //                                               slotId: liveClassController
            //                                                   .upComingLiveList[
            //                                                       index]
            //                                                   .slotId
            //                                                   .toString(),
            //                                               liveLink:
            //                                                   liveClassController
            //                                                       .upComingLiveList[
            //                                                           index]
            //                                                       .liveLink
            //                                                       .toString(),
            //                                             ));
            //                                       }
            //                                     },
            //                                   ))!
            //                               .then((value) {
            //                             liveClassController.getUpcomingLive();
            //                           });
            //                         },
            //                         context: context,
            //                         buttonText: '',
            //                         onPressed: () {},
            //                         startTime: formatTimeToAmPm(startTime),
            //                         endTime: formatTimeToAmPm(endTime),
            //                         courseName: liveClassController
            //                             .upComingLiveList[index].courseName,
            //                         batchName: liveClassController
            //                             .upComingLiveList[index].batchName,
            //                         batchId: liveClassController
            //                             .upComingLiveList[index].batchId
            //                             .toString());
            //                   },
            //                 )
            //               ],
            //             ),
            //           )),
            // ),
            // Padding(
            //   padding: EdgeInsets.symmetric(
            //     horizontal: 10.h,
            //     vertical: 10.w,
            //   ),
            //   // Wrap with Container to constrain height and force scrolling
            //   child: Container(
            //     height: MediaQuery.of(context).size.height -
            //         100, // Adjust based on your app's needs
            //     child: Obx(() {
            //       print(
            //           'Total items in displayedCalls: ${callOngoingController.displayedCalls.length}');
            //       print(
            //           'Has more data: ${callOngoingController.hasMoreData.value}');

            //       if (callOngoingController.isLoading.value) {
            //         return const Center(
            //           child: LoadingCircle(),
            //         );
            //       }
            //       if (callOngoingController.displayedCalls.isEmpty) {
            //         return const Center(
            //           child: Text('No Completed Live class'),
            //         );
            //       }

            //       return callOngoingController.displayedCalls.isNotEmpty
            //           ? ListView.separated(
            //               controller: _scrollController,
            //               // Remove any physics restrictions
            //               physics: const AlwaysScrollableScrollPhysics(),
            //               separatorBuilder: (context, index) =>
            //                   const SizedBox(height: 16),
            //               itemCount: callOngoingController
            //                       .displayedCalls.length +
            //                   (callOngoingController.hasMoreData.value ? 1 : 0),
            //               itemBuilder: (context, index) {
            //                 if (index ==
            //                     callOngoingController.displayedCalls.length) {
            //                   print('Rendering loading indicator at bottom');
            //                   return const Center(
            //                     child: Padding(
            //                       padding: EdgeInsets.all(16.0),
            //                       child: CircularProgressIndicator(),
            //                     ),
            //                   );
            //                 }

            //                 final item =
            //                     callOngoingController.displayedCalls[index];

            //                 return _buildViewhierarchy(
            //                   onDetailsTap: () async {
            //                     // await courseInfoController.getCourseInfo(
            //                     //   courseId: item.courseId,
            //                     // );
            //                     // await courseInfoController.getCoursesModules(
            //                     //   courseId: item.courseId.toString(),
            //                     // );
            //                     Get.to(
            //                       () => CourseCategoryDetailsScreen(
            //                         isFromBatch: false,
            //                         batchId: item.batchId.toString(),
            //                         courseId: item.courseId,
            //                       ),
            //                     )?.then((value) => setState(() {}));
            //                   },
            //                   buttonText: '',
            //                   date: item.endTime != ""
            //                       ? DateFormat('dd/MM/yyyy')
            //                           .format(DateTime.parse(item.endTime))
            //                       : "",
            //                   isupComing: false,
            //                   startTime: item.startTime != ""
            //                       ? DateFormat('h:mm a')
            //                           .format(DateTime.parse(item.startTime))
            //                       : '',
            //                   endTime: item.endTime != ""
            //                       ? DateFormat('h:mm a')
            //                           .format(DateTime.parse(item.endTime))
            //                       : '',
            //                   context: context,
            //                   onPressed: () {},
            //                   courseName: item.courseName,
            //                   batchName: item.batchName.toString(),
            //                   batchId: item.batchId.toString(),
            //                 );
            //               },
            //             )
            //           : Center(
            //               child: Text(
            //                 'No Live Class',
            //                 style: TextStyle(
            //                   fontSize: 14.sp,
            //                   color: ColorResources.colorgrey500,
            //                 ),
            //               ),
            //             );
            //     }),
            //   ),
            // ),
            CoursesOfTeacherScreen(
              isFromBatch: false,
            ),
          ]),
        ),
      ),
    ));
  }
}

Widget _buildViewhierarchy(
    {required void Function()? onPressed,
    required void Function()? onDetailsTap,
    required String courseName,
    required BuildContext context,
    required bool isupComing,
    required String batchName,
    required String buttonText,
    String? startTime,
    String? endTime,
    String? date,
    required String batchId}) {
  final callandChatController = Get.put(CallandChatController());
  return Container(
    // height: MediaQuery.of(context).size.height * 0.200,
    padding: EdgeInsets.only(top: 14.w, left: 14.w, right: 14.w, bottom: 4.w),
    decoration: BoxDecoration(
      color: ColorResources.colorwhite,
      borderRadius: BorderRadius.circular(10.w),
      border: Border.all(
        color: const Color(0XFFE3E7EE),
        width: 0,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              height: 12.h,
              width: 12.w,
              child: Image.asset(
                ImageConstant.imageBookIcon,
                height: 12.h,
                width: 12.w,
                fit: BoxFit.cover,
                color: const Color(0xFF283B52),
              ),
            ),
            SizedBox(
              width: 6.w,
            ),
            Text(
              courseName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ColorResources.colorBlue800,
                fontSize: 14.sp,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Text(
              'Batch',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF9299A2),
                fontSize: 14.sp,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(
              width: 6.w,
            ),
            // Text(
            //   batchName,
            //   maxLines: 1,
            //   overflow: TextOverflow.ellipsis,
            //   style: TextStyle(
            //     color: const Color(0xFF6A7487),
            //     fontSize: 14.sp,
            //     fontFamily: 'Plus Jakarta Sans',
            //     fontWeight: FontWeight.w500,
            //   ),
            // ),
          ],
        ),
        SizedBox(
          height: 8.h,
        ),
        Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              color: Color(0xFF6A7487),
              size: 16,
            ),
            SizedBox(
              width: 4.w,
            ),
            Text(
              '$startTime-$endTime',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF6A7487),
                fontSize: 12.sp,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        isupComing
            ? const SizedBox()
            : const SizedBox(
                height: 6,
              ),
        isupComing
            ? const SizedBox()
            : Row(
                children: [
                  const Icon(
                    Icons.date_range,
                    color: Color(0xFF6A7487),
                    size: 16,
                  ),
                  SizedBox(
                    width: 4.w,
                  ),
                  Text(
                    '$date',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF6A7487),
                      fontSize: 12.sp,
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
        isupComing
            ? SizedBox(
                height: 8.h,
              )
            : const SizedBox(
                height: 12,
              ),
        // Row(
        //   children: [
        //     SizedBox(
        //       height: 12.h,
        //       width: 12.w,
        //       child: Image.asset(
        //         ImageConstant.imageCalenderIcon,
        //         height: 12.h,
        //         width: 12.w,
        //         fit: BoxFit.cover,
        //       ),
        //     ),
        //     SizedBox(
        //       width: 6.w,
        //     ),
        //     isupComing == true
        //         ? Text(
        //             '$startTime - $endTime',
        //             maxLines: 1,
        //             overflow: TextOverflow.ellipsis,
        //             style: TextStyle(
        //               color: ColorResources.colorgrey700,
        //               fontSize: 12.sp,
        //               fontFamily: 'Plus Jakarta Sans',
        //               fontWeight: FontWeight.w500,
        //             ),
        //           )
        //         : const SizedBox(),
        //   ],
        // ),
        // const Spacer(),
        // SizedBox(
        //   height: 16.h,
        // ),
        // isupComing == true
        //     ? buttonWidget(
        //         backgroundColor: ColorResources.colorBlue600,
        //         txtColor: ColorResources.colorwhite,
        //         context: context,
        //         text: buttonText,
        //         onPressed: onPressed)
        //     : buttonWidget(
        //         backgroundColor: ColorResources.colorBlue600,
        //         txtColor: ColorResources.colorwhite,
        //         context: context,
        //         text: 'Live Completed',
        //         onPressed: null),

        Row(
          children: [
            isupComing
                ? Expanded(
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100.w)),
                          backgroundColor: ColorResources.colorwhite,
                          side: const BorderSide(
                            color: ColorResources
                                .colorBlue600, // Define your border color here
                            width: 1, // Define your border width here
                          ),
                        ),
                        onPressed: () async {
                          callandChatController.getStudentList.clear();

                          await callandChatController
                              .getStudentLists(batchId.toString());
                          callandChatController.getStudentList.isNotEmpty
                              ? Get.to(() => StudentList(batchId: batchId))
                              : ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('No students to show')));
                          // Get.to(() => StudentList(batchId: batchId));
                        },
                        child: Text(
                          'Student List',
                          style: GoogleFonts.plusJakartaSans(
                            color: ColorResources.colorBlue600,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        )),
                  )
                : const SizedBox(),
            SizedBox(
              width: 10.w,
            ),
            Expanded(
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100.w)),
                    backgroundColor: ColorResources.colorBlue500,
                    // side: const BorderSide(
                    //   color: ColorResources
                    //       .colorBlue600, // Define your border color here
                    //   width: 1, // Define your border width here
                    // ),
                  ),
                  onPressed: onDetailsTap,
                  child: Text(
                    'View Course',
                    style: GoogleFonts.plusJakartaSans(
                      color: ColorResources.colorwhite,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  )),
            ),
            // Expanded(
            //   child: buttonWidget(
            //       backgroundColor: ColorResources.colorBlue600,
            //       txtColor: ColorResources.colorwhite,
            //       context: context,
            //       text: 'View Course',
            //       onPressed: onDetailsTap),
            // ),
          ],
        )
      ],
    ),
  ); //---Initializing Zego Cloud Engine
}
