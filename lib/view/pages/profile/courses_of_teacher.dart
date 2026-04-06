import 'package:breffini_staff/controller/course_module_controler.dart';
import 'package:breffini_staff/controller/student_course_controller.dart';
import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/http/http_urls.dart';
import 'package:breffini_staff/view/pages/courses/course_category_screen.dart';
import 'package:breffini_staff/view/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CoursesOfTeacherScreen extends StatefulWidget {
  final bool isFromBatch;
  const CoursesOfTeacherScreen({super.key, required this.isFromBatch});

  @override
  State<CoursesOfTeacherScreen> createState() => _CoursesOfTeacherScreenState();
}

class _CoursesOfTeacherScreenState extends State<CoursesOfTeacherScreen> {
  final StudentCourseController studentCourseController =
      Get.find<StudentCourseController>();
  final courseInfoController = Get.find<CourseModuleController>();

  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized().scheduleFrameCallback(
      (timeStamp) {
        studentCourseController.getCoursesOfTeacher();
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResources.colorgrey200,
      body: Obx(() {
        return studentCourseController.teacherCourseList.isNotEmpty
            ? ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: studentCourseController.teacherCourseList.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      SizedBox(
                        height: 16.h,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: InkWell(
                          onTap: () async {
                            // await courseInfoController.getCourseInfo(
                            //     courseId: studentCourseController
                            //         .teacherCourseList[index].courseId);
                            // await courseInfoController.getCoursesModules(
                            //     courseId: studentCourseController
                            //         .teacherCourseList[index].courseId
                            //         .toString());
                            Get.to(() => CourseCategoryDetailsScreen(
                                  isFromBatch: widget.isFromBatch,
                                  batchId: '',
                                  courseId: studentCourseController
                                      .teacherCourseList[index].courseId,
                                ));
                          },
                          child: courseProfileWidget(
                            isProfile: false,
                            courseName: studentCourseController
                                .teacherCourseList[index].courseName,
                            image: HttpUrls.imgBaseUrl +
                                studentCourseController
                                    .teacherCourseList[index].thumbnailPath,
                            batchName: studentCourseController
                                        .teacherCourseList[index].batchIDs !=
                                    ''
                                ? studentCourseController
                                    .teacherCourseList[index].batchNames
                                : '',
                          ),
                        ),
                      ),
                    ],
                  );
                },
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No courses',
                      style: GoogleFonts.plusJakartaSans(
                        color: ColorResources.colorgrey700,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
      }),
    );
  }
}
