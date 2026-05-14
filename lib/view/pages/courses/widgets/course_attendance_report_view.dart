import 'package:breffini_staff/controller/calls_page_controller.dart';
import 'package:breffini_staff/controller/video_attendance_controller.dart';
import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/model/faculty_batch_student_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CourseAttendanceReportView extends StatefulWidget {
  final String? courseId;

  const CourseAttendanceReportView({
    super.key,
    this.courseId,
  });

  @override
  State<CourseAttendanceReportView> createState() =>
      _CourseAttendanceReportViewState();
}

class _CourseAttendanceReportViewState
    extends State<CourseAttendanceReportView> {
  final VideoAttendanceController attendanceController =
      Get.put(VideoAttendanceController());
  final CallandChatController studentController =
      Get.find<CallandChatController>();

  DateTime selectedDate = DateTime.now();
  FacultyBatchStudentModel? selectedStudent;

  @override
  void initState() {
    super.initState();
    _fetchStudentsIfNeeded().then((_) => _loadStudents());
  }

  Future<void> _fetchStudentsIfNeeded() async {
    if (studentController.facultyBatchStudentsList.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final String teacherId = prefs.getString('breffini_teacher_Id') ?? "0";
      await studentController.getFacultyBatchStudents(teacherId);
    }
  }

  void _loadStudents() {
    List<FacultyBatchStudentModel> students;
    if (widget.courseId != null) {
      students = studentController.facultyBatchStudentsList
          .where((s) => s.courseId.toString() == widget.courseId)
          .toList();
    } else {
      students = studentController.facultyBatchStudentsList;
    }

    if (students.isNotEmpty) {
      // Remove duplicates if same student is in multiple courses but we just want unique ones?
      // Or keep them as they might have different enrollments.
      // For now, let's just pick the first.
      setState(() {
        selectedStudent = students.first;
      });
      _fetchAttendance();
    }
  }

  void _fetchAttendance() {
    if (selectedStudent != null) {
      attendanceController.getVideoAttendanceReport(
        studentId: selectedStudent!.studentId.toString(),
        courseId: selectedStudent!.courseId.toString(),
      );
    }
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select Month',
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          _buildStudentSelector(),
          SizedBox(height: 16.h),
          _buildMonthPicker(),
          SizedBox(height: 24.h),
          Text(
            'Attendance Details',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF1D2939),
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16.h),
          Expanded(child: _buildAttendanceTable()),
        ],
      ),
    );
  }

  Widget _buildStudentSelector() {
    List<FacultyBatchStudentModel> students;
    if (widget.courseId != null) {
      students = studentController.facultyBatchStudentsList
          .where((s) => s.courseId.toString() == widget.courseId)
          .toList();
    } else {
      students = studentController.facultyBatchStudentsList;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FacultyBatchStudentModel>(
          isExpanded: true,
          value: selectedStudent,
          hint: const Text('Select Student'),
          items: students.map((s) {
            return DropdownMenuItem(
              value: s,
              child: Text(
                '${s.firstName} ${s.lastName} (${s.courseName ?? ''})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              selectedStudent = val;
            });
            _fetchAttendance();
          },
        ),
      ),
    );
  }

  Widget _buildMonthPicker() {
    return InkWell(
      onTap: () => _selectMonth(context),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(selectedDate),
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF1D2939),
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(Icons.calendar_today, color: ColorResources.colorBlue600),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              color: const Color(0xFFF2F4F7),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Content Name',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF475467),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Course',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF475467),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Date',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF475467),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (attendanceController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filter by month
                var rawList = attendanceController.attendanceReport;
                var filteredList = rawList.where((record) {
                  try {
                    DateTime recordDate = DateTime.parse(record.watchedDate!);
                    return recordDate.month == selectedDate.month &&
                        recordDate.year == selectedDate.year;
                  } catch (e) {
                    return false;
                  }
                }).toList();

                if (filteredList.isEmpty) {
                  return Center(
                    child: Text(
                      'No reports for this month',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        color: ColorResources.colorgrey500,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filteredList.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final report = filteredList[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 16.h),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              report.contentName ?? '-',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF475467),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              report.courseName ?? '-',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF475467),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _formatTableDate(report.watchedDate ?? ''),
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF475467),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTableDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
