import 'package:breffini_staff/controller/video_attendance_controller.dart';
import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class VideoAttendanceReportScreen extends StatefulWidget {
  final String studentId;
  final String courseId;
  final String studentName;

  const VideoAttendanceReportScreen({
    super.key,
    required this.studentId,
    required this.courseId,
    required this.studentName,
  });

  @override
  State<VideoAttendanceReportScreen> createState() =>
      _VideoAttendanceReportScreenState();
}

class _VideoAttendanceReportScreenState
    extends State<VideoAttendanceReportScreen> {
  final VideoAttendanceController controller =
      Get.put(VideoAttendanceController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getVideoAttendanceReport(
        studentId: widget.studentId,
        courseId: widget.courseId,
      );
    });
  }

  String formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResources.colorgrey200,
      appBar: AppBar(
        backgroundColor: ColorResources.colorwhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: ColorResources.colorBlack,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Attendance Report',
          style: GoogleFonts.plusJakartaSans(
            color: ColorResources.colorBlack,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.attendanceReport.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_turned_in_outlined,
                    size: 60.sp, color: ColorResources.colorgrey400),
                SizedBox(height: 16.h),
                Text(
                  'No attendance records found',
                  style: GoogleFonts.plusJakartaSans(
                    color: ColorResources.colorgrey700,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: controller.attendanceReport.length,
          itemBuilder: (context, index) {
            final report = controller.attendanceReport[index];
            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: ColorResources.colorwhite,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          report.contentName ?? 'Unknown Content',
                          style: GoogleFonts.plusJakartaSans(
                            color: ColorResources.colorBlack,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'Watched',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.green,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  const Divider(height: 1, color: ColorResources.colorgrey200),
                  SizedBox(height: 12.h),
                  _buildInfoRow(Icons.book_outlined, report.courseName ?? ''),
                  SizedBox(height: 6.h),
                  _buildInfoRow(Icons.calendar_today_outlined,
                      'Watched on: ${formatDate(report.updateTime ?? '')}'),
                  SizedBox(height: 6.h),
                  _buildInfoRow(Icons.group_outlined,
                      'Batch: ${report.batchName ?? 'N/A'}'),
                  if (report.teacherName != null &&
                      report.teacherName!.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    _buildInfoRow(
                        Icons.person_outline, 'Teacher: ${report.teacherName}'),
                  ],
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: ColorResources.colorBlue600),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: ColorResources.colorgrey700,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
