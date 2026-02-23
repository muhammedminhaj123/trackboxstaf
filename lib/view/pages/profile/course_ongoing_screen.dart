import 'package:breffini_staff/controller/course_module_controler.dart';
import 'package:breffini_staff/controller/student_course_controller.dart';
import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/http/http_urls.dart';
import 'package:breffini_staff/view/pages/chats/widgets/loading_circle.dart';
import 'package:breffini_staff/view/pages/courses/course_category_screen.dart';
import 'package:breffini_staff/view/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CourseOngoingScreen extends StatefulWidget {
  final String studentId;
  final bool isFromBatch;
  final String? batchId;
  const CourseOngoingScreen(
      {super.key,
      required this.studentId,
      required this.isFromBatch,
      this.batchId});

  @override
  State<CourseOngoingScreen> createState() => _CourseOngoingScreenState();
}

class _CourseOngoingScreenState extends State<CourseOngoingScreen> {
  final StudentCourseController studentCourseController =
      Get.find<StudentCourseController>();
  final courseInfoController = Get.find<CourseModuleController>();

  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized().scheduleFrameCallback(
      (timeStamp) {
        // studentCourseController.getCourseOfStudent(widget.studentId);
      },
    );
    super.initState();
  }

  String formatDate(String date) {
    // Parse the date from the input string
    DateTime parsedDate = DateTime.parse(date);

    // Format the date in dd/mm/yyyy format
    String formattedDate = "${parsedDate.day.toString().padLeft(2, '0')}-"
        "${parsedDate.month.toString().padLeft(2, '0')}-"
        "${parsedDate.year}";

    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResources.colorgrey200,
      body: Obx(() {
        return studentCourseController.studentCourseList.isNotEmpty
            ? studentCourseController.isStudentCourseLoading.value
                ? const Center(
                    child: const LoadingCircle(),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: studentCourseController.studentCourseList.length,
                    itemBuilder: (context, index) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                //         .studentCourseList[index].courseId);
                                // await courseInfoController.getCoursesModules(
                                //     courseId: studentCourseController
                                //         .studentCourseList[index].courseId
                                //         .toString());
                                Get.to(() => CourseCategoryDetailsScreen(
                                      isFromBatch: widget.isFromBatch,
                                      batchId: widget.batchId,
                                      courseId: studentCourseController
                                          .studentCourseList[index].courseId,
                                    ));
                              },
                              child: courseProfileWidget(
                                  showBatchEnd:
                                      studentCourseController.studentCourseList[index].batchID != 0
                                          ? true
                                          : false,
                                  isProfile: true,
                                  batchTeacher: studentCourseController.studentCourseList[index].batchID != 0 &&
                                          studentCourseController
                                              .studentCourseList[index]
                                              .batchTeacher
                                              .trim()
                                              .isNotEmpty
                                      ? 'Teacher : ${studentCourseController.studentCourseList[index].batchTeacher}'
                                      : '',
                                  oneOnOneTeacher: studentCourseController.studentCourseList[index].batchID == 0 &&
                                          studentCourseController
                                              .studentCourseList[index]
                                              .oneToOneTeacher
                                              .trim()
                                              .isNotEmpty
                                      ? 'Teacher : ${studentCourseController.studentCourseList[index].oneToOneTeacher}'
                                      : '',
                                  courseName: studentCourseController
                                      .studentCourseList[index].courseName,
                                  batchName: "",
                                  image: HttpUrls.imgBaseUrl + studentCourseController.studentCourseList[index].imagePath,
                                  batchStart: studentCourseController.studentCourseList[index].batchID != 0 ? "Batch start : ${formatDate(studentCourseController.studentCourseList[index].batchStart)}" : '',
                                  batchEnd: studentCourseController.studentCourseList[index].batchID != 0 ? "Batch End : ${formatDate(studentCourseController.studentCourseList[index].batchEnd)}" : 'Batch End : ',
                                  expiryDate: ''),
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
