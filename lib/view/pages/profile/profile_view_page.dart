import 'package:breffini_staff/controller/profile_controller.dart';
import 'package:breffini_staff/controller/student_course_controller.dart';
import 'package:breffini_staff/core/theme/color_resources.dart';

import 'package:breffini_staff/core/utils/extentions.dart';
import 'package:breffini_staff/core/utils/key_center.dart';

import 'package:breffini_staff/http/chat_socket.dart';
import 'package:breffini_staff/http/http_urls.dart';
import 'package:breffini_staff/view/pages/calls/incoming_call_screen.dart';

import 'package:breffini_staff/view/pages/chats/chat_firebase_screen.dart';
import 'package:breffini_staff/view/pages/profile/call_log_screen.dart';
import 'package:breffini_staff/view/pages/profile/course_ongoing_screen.dart';
import 'package:breffini_staff/view/pages/profile/student_media_screen.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileViewPage extends StatefulWidget {
  final String profileUrl;
  final String studentName;
  final String contactDetails;
  final String studentId;
  final String courseId;

  const ProfileViewPage(
      {super.key,
      required this.profileUrl,
      required this.studentName,
      required this.contactDetails,
      required this.studentId,
      required this.courseId});

  @override
  State<ProfileViewPage> createState() => _ProfileViewPageState();
}

class _ProfileViewPageState extends State<ProfileViewPage> {
  final StudentCourseController studentCourseController =
      Get.find<StudentCourseController>();
  final ProfileController profileController =
      Get.find<ProfileController>(); // Added this line

  bool isSwitched = false;

  @override
  void initState() {
    super.initState();

    WidgetsFlutterBinding.ensureInitialized().scheduleFrameCallback(
      (timeStamp) {
        studentCourseController.getCourseOfStudent(widget.studentId).then((_) {
          if (studentCourseController.studentCourseList.isNotEmpty) {
            setState(() {
              isSwitched = studentCourseController
                      .studentCourseList[0].isStudentModuleLocked ==
                  0;
            });
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: ColorResources.colorwhite,
          body: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Get.back();
                      },
                      child: Container(
                        height: 30.h,
                        width: 30.w,
                        decoration: BoxDecoration(
                            color: ColorResources.colorBlue100,
                            borderRadius: BorderRadius.circular(100)),
                        child: Icon(
                          CupertinoIcons.back,
                          size: 18.sp,
                          color: ColorResources.colorgrey500,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Text(
                      'Student details',
                      style: TextStyle(
                          fontSize: 14.w,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xff283B52)),
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              CircleAvatar(
                radius: 35.r,
                child: CachedNetworkImage(
                  imageUrl: widget.profileUrl,
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(
                    color: Colors.blue,
                    strokeWidth: 2,
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: ColorResources.colorBlack.withOpacity(.7),
                      size: 25.w,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 16.h,
              ),
              Text(
                widget.studentName,
                style: GoogleFonts.plusJakartaSans(
                  color: ColorResources.colorBlack,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(
                height: 16.h,
              ),
              //  studentCourseController.studentCourseList.isNotEmpty
              //    ? Padding(
              //         padding: const EdgeInsets.symmetric(horizontal: 16),
              //         child: Container(
              //           height: 48.h,
              //           decoration: BoxDecoration(
              //               color: ColorResources.colorgrey200,
              //               borderRadius: BorderRadius.circular(8.r)),
              //           child: Padding(
              //             padding: EdgeInsets.symmetric(horizontal: 16.w),
              //             child: Row(
              //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //               children: [
              //                 Text('Exam Batch Status',
              //                     style: GoogleFonts.plusJakartaSans(
              //                       color: ColorResources.colorgrey600,
              //                       fontSize: 12.sp,
              //                       fontWeight: FontWeight.w600,
              //                     )),
              //                 Transform.scale(
              //                   scale: .60,
              //                   child: Switch(
              //                     trackOutlineColor:
              //                         const WidgetStatePropertyAll(
              //                             ColorResources.colorwhite),
              //                     thumbIcon: WidgetStateProperty.all(const Icon(
              //                       Icons.circle,
              //                       color: ColorResources.colorwhite,
              //                     )),
              //                     inactiveThumbColor: ColorResources.colorwhite,
              //                     inactiveTrackColor:
              //                         ColorResources.colorgrey400,
              //                     value: isSwitched,
              //                     onChanged: (value) {
              //                       setState(() {
              //                         isSwitched = value;
              //                         int status = value ? 0 : 1;

              //                         profileController
              //                             .changeStudentModuleLockStatus(
              //                                 studentId: studentCourseController
              //                                     .studentCourseList[0]
              //                                     .studentId
              //                                     .toString(),
              //                                 courseId: studentCourseController
              //                                     .studentCourseList[0].courseId
              //                                     .toString(),
              //                                 status: status);
              //                       });
              //                     },
              //                   ),
              //                 ),
              //               ],
              //             ),
              //           ),
              //         ),
              //       )
              //     : const SizedBox(),
              SizedBox(
                height: 16.h,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                child: TabBar(
                  labelColor: ColorResources.colorBlack,
                  unselectedLabelColor: ColorResources.colorgrey500,
                  indicatorPadding: EdgeInsets.symmetric(horizontal: 8.w),
                  indicatorColor: ColorResources.colorBlack,
                  tabAlignment: TabAlignment.start,
                  dividerColor: ColorResources.colorwhite,
                  indicatorWeight: 1,
                  padding: const EdgeInsets.only(bottom: 12),
                  tabs: const [
                    Tab(text: 'Courses'),
                  ],
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  isScrollable: true,
                  indicatorSize: TabBarIndicatorSize.label,
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    CourseOngoingScreen(
                      isFromBatch: false,
                      studentId: widget.studentId,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
