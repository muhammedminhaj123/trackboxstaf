import 'package:breffini_staff/controller/student_course_controller.dart';
import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/core/utils/date_time_utils.dart';
import 'package:breffini_staff/core/widgets/common_widgets.dart';
import 'package:breffini_staff/http/http_urls.dart';
import 'package:breffini_staff/view/widgets/profile_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CallLogScreen extends StatefulWidget {
  final String studentId;
  const CallLogScreen({super.key, required this.studentId});

  @override
  State<CallLogScreen> createState() => _CallLogScreenState();
}

class _CallLogScreenState extends State<CallLogScreen> {
  final StudentCourseController studentCourseController =
      Get.find<StudentCourseController>();

  String formatOrToday(String isoDate) {
    DateTime date = DateTime.parse(isoDate);
    String formattedDate = DateFormat('dd/MM/yyyy').format(date);
    String today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    return (formattedDate == today) ? 'Today' : formattedDate;
  }

  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized().scheduleFrameCallback(
      (timeStamp) {
        studentCourseController.getCallOfStudent(widget.studentId);
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResources.colorgrey200,
      body: Obx(() {
        return studentCourseController.studentCallsList.isNotEmpty
            ? ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: studentCourseController.studentCallsList.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      SizedBox(
                        height: 16.h,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child: callHistoryWidget(
                            color:
                                studentCourseController.studentCallsList[index].isStudent ==
                                        1
                                    ? const Color.fromARGB(255, 0, 122, 20)
                                    : const Color.fromARGB(255, 255, 0, 0),
                            time: formatTimeinAmPm(studentCourseController
                                .studentCallsList[index].callEnd
                                .toString()),
                            image:
                                '${HttpUrls.imgBaseUrl}${studentCourseController.studentCallsList[index].studentProfile}',
                            callType: studentCourseController
                                .studentCallsList[index].callType,
                            subTitle: studentCourseController
                                .studentCallsList[index].callDuration
                                .toString(),
                            name: studentCourseController
                                .studentCallsList[index].studentName,
                            date: formatOrToday(studentCourseController
                                .studentCallsList[index].messageDate
                                .toString())),
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
                    'No Calls',
                    style: GoogleFonts.plusJakartaSans(
                      color: ColorResources.colorgrey700,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ));
      }),
    );
  }
}
