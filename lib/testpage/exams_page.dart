import 'package:breffini_staff/core/utils/pref_utils.dart';
import 'package:breffini_staff/http/exam_service.dart';
import 'package:breffini_staff/model/exam_result_model.dart';
import 'package:breffini_staff/http/http_requests.dart'; // Added
import 'package:breffini_staff/http/http_urls.dart'; // Added
import 'package:breffini_staff/model/get_student_timeslot_model.dart'; // Added
import 'package:breffini_staff/core/widgets/rubiks_cube_loader.dart'; // Added logic for loader
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:breffini_staff/core/theme/color_resources.dart';

class ExamsScreen extends StatefulWidget {
  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  final ExamService _examService = ExamService();
  List<ExamResultResponse> _examResults = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  // TODO: Replace this with actual API call to get teacher's students
  // This is a temporary mapping until backend creates the proper API
  // Map teacher IDs to their assigned student IDs
  // final Map<String, List<int>> _teacherStudents = {
  //   "65": [335, 336], // Teacher ID 65's students
  //   // Add more teacher-student mappings as needed
  // };

  @override
  void initState() {
    super.initState();
    _loadExamResults();
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  List<ExamResultResponse> get _filteredResults {
    if (_startDate == null && _endDate == null) {
      return _examResults;
    }
    return _examResults.where((exam) {
      if (exam.createdAt == null) return false;
      final examDate = exam.createdAt!;
      final start = _startDate != null
          ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day)
          : null;
      final end = _endDate != null
          ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59)
          : null;

      if (start != null && examDate.isBefore(start)) return false;
      if (end != null && examDate.isAfter(end)) return false;
      return true;
    }).toList();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2B3674),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2B3674),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          _fromDateController.text = DateFormat('dd-MM-yyyy').format(picked);
        } else {
          _endDate = picked;
          _toDateController.text = DateFormat('dd-MM-yyyy').format(picked);
        }
      });
    }
  }

  void _clearFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _fromDateController.clear();
      _toDateController.clear();
    });
  }

  Future<void> _loadExamResults() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get the logged-in teacher's ID
      final teacherId = PrefUtils().getTeacherId();

      if (teacherId == '0' || teacherId.isEmpty) {
        setState(() {
          _errorMessage = "Teacher ID not found. Please login again.";
          _isLoading = false;
        });
        return;
      }

      print("DEBUG: Fetching exam results for teacher ID: $teacherId");

      // Get student IDs for this teacher
      List<int> studentIds = [];

      // Try fetching dynamically first
      try {
        studentIds = await _fetchStudentsForTeacher();
        print("DEBUG: Dynamically fetched ${studentIds.length} students");
      } catch (e) {
        print("DEBUG: Dynamic fetch failed, falling back to empty list: $e");
      }

      // Fallback to hardcoded map if dynamic fetch returns empty (optional, for backward compatibility)
      // if (studentIds.isEmpty) {
      //   studentIds = _teacherStudents[teacherId] ?? [];
      // }

      if (studentIds.isEmpty) {
        setState(() {
          _errorMessage =
              "No students assigned to teacher ID $teacherId.\nPlease update the teacher-student mapping.";
          _isLoading = false;
        });
        print("DEBUG: No students found for teacher ID: $teacherId");
        return;
      }

      print(
          "DEBUG: Fetching results for ${studentIds.length} students: $studentIds");

      // Fetch exam results for all assigned students
      List<ExamResultResponse> allResults = [];
      for (int studentId in studentIds) {
        try {
          final results = await _examService.getExamResults(studentId);
          allResults.addAll(results);
          print(
              "DEBUG: Fetched ${results.length} results for student $studentId");
        } catch (e) {
          print("DEBUG: Error fetching results for student $studentId: $e");
          // Continue with other students even if one fails
        }
      }

      setState(() {
        _examResults = allResults;
        _isLoading = false;
      });

      print("DEBUG: Loaded ${allResults.length} total exam results");
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load exam results: $e";
        _isLoading = false;
      });
      print("DEBUG: Error loading exam results: $e");
    }
  }

  Future<List<int>> _fetchStudentsForTeacher() async {
    try {
      final response = await HttpRequest.httpGetRequest(
        endPoint: HttpUrls.getStudentsTimeSlot,
        showLoader: false,
      );

      print(
          "DEBUG: _fetchStudentsForTeacher Response Code: ${response?.statusCode}");

      if (response != null && response.statusCode == 200) {
        final responseData = response.data;
        print(
            "DEBUG: _fetchStudentsForTeacher Raw Data Type: ${responseData.runtimeType}");

        if (responseData is List<dynamic>) {
          final students = responseData
              .map((json) => GetStudentTimeSlotsModel.fromJson(json))
              .map((student) => student.studentId)
              .toSet() // Use Set to avoid duplicates
              .toList();
          print("DEBUG: _fetchStudentsForTeacher Parsed IDs: $students");
          return students;
        } else {
          print(
              "DEBUG: responseData is not a List: ${responseData.runtimeType}");
        }
      } else {
        print("DEBUG: API Error or Null Response: ${response?.statusMessage}");
      }
      return [];
    } catch (e) {
      print("DEBUG: Error fetching students for teacher: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : CustomScrollView(
                  slivers: [
                    _buildAppBar(),
                    SliverToBoxAdapter(child: _buildDateFilter()),
                    SliverToBoxAdapter(child: _buildSummaryHeader()),
                    _filteredResults.isEmpty
                        ? SliverFillRemaining(child: _buildEmptyState())
                        : SliverPadding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 10.h),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) =>
                                    _buildExamCard(_filteredResults[index]),
                                childCount: _filteredResults.length,
                              ),
                            ),
                          ),
                  ],
                ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 80.h,
      floating: true,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 16.w, bottom: 16.h),
        title: Text(
          "Exam Results",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: const Color(0xff283B52),
            fontSize: 16.sp,
          ),
        ),
      ),
      // Refresh button removed as requested
      actions: [],
    );
  }

  Widget _buildDateFilter() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 5.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B3674).withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list_rounded,
                  size: 20.sp, color: const Color(0xFF4318FF)),
              SizedBox(width: 8.w),
              Text(
                "Filter by Date",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: const Color(0xFF2B3674),
                ),
              ),
              const Spacer(),
              if (_startDate != null || _endDate != null)
                InkWell(
                  onTap: _clearFilter,
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEEE),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.close, size: 14.sp, color: Colors.red),
                        SizedBox(width: 4.w),
                        Text(
                          "Clear",
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildModernDateField(
                    "Start Date", _fromDateController, true),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child:
                    _buildModernDateField("End Date", _toDateController, false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernDateField(
      String hint, TextEditingController controller, bool isStart) {
    bool hasValue = controller.text.isNotEmpty;
    return InkWell(
      onTap: () => _selectDate(context, isStart),
      borderRadius: BorderRadius.circular(15.r),
      child: Container(
        height: 50.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: hasValue ? const Color(0xFFF4F7FE) : const Color(0xFFF4F7FE),
          borderRadius: BorderRadius.circular(15.r),
          border: hasValue
              ? Border.all(color: const Color(0xFF4318FF), width: 1)
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: hasValue ? Colors.white : Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 14.sp,
                color: hasValue
                    ? const Color(0xFF4318FF)
                    : const Color(0xFFA3AED0),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasValue)
                    Text(
                      hint,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        color: const Color(0xFFA3AED0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    hasValue ? controller.text : hint,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: hasValue ? 13.sp : 12.sp,
                      fontWeight: hasValue ? FontWeight.bold : FontWeight.w500,
                      color: hasValue
                          ? const Color(0xFF2B3674)
                          : const Color(0xFFA3AED0),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    int total = _filteredResults.length;
    int passed = _filteredResults.where((e) => e.isPassed).length;

    return Container(
      padding: EdgeInsets.all(20.w),
      child: Row(
        children: [
          _buildSummaryItem("Total Exams", total.toString(), Icons.assignment,
              const Color(0xFF4318FF)),
          SizedBox(width: 15.w),
          _buildSummaryItem(
              "Passed", passed.toString(), Icons.check_circle, Colors.green),
          SizedBox(width: 15.w),
          _buildSummaryItem(
              "Pass %",
              total > 0
                  ? "${(passed / total * 100).toStringAsFixed(1)}%"
                  : "0%",
              Icons.trending_up,
              Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20.sp),
            SizedBox(height: 8.h),
            Text(value,
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: const Color(0xFF2B3674))),
            Text(title,
                style: GoogleFonts.dmSans(
                    fontSize: 10.sp, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildExamCard(ExamResultResponse examResult) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showExamDetails(examResult),
        borderRadius: BorderRadius.circular(20.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      examResult.studentFullName,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 17.sp,
                        color: const Color(0xFF2B3674),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(examResult.isPassed),
                ],
              ),
              SizedBox(height: 12.h),
              _buildInfoRow(Icons.school_outlined, "Course",
                  examResult.courseName ?? "N/A"),
              SizedBox(height: 8.h),
              _buildInfoRow(Icons.assignment_outlined, "Exam",
                  examResult.examName ?? "N/A"),
              SizedBox(height: 8.h),
              _buildInfoRow(Icons.calendar_today_outlined, "Date",
                  examResult.formattedDate),
              SizedBox(height: 16.h),
              const Divider(color: Color(0xFFF4F7FE), height: 1),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Final Score",
                          style: GoogleFonts.dmSans(
                              fontSize: 11.sp, color: Colors.grey[500])),
                      Text(
                          "${examResult.obtainedMark} / ${examResult.totalMark}",
                          style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                              color: const Color(0xFF2B3674))),
                    ],
                  ),
                  _buildScoreProgress(examResult.percentage),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: const Color(0xFFA3AED0)),
        SizedBox(width: 8.w),
        Text("$label: ",
            style: GoogleFonts.dmSans(
                fontSize: 12.sp, color: const Color(0xFFA3AED0))),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.dmSans(
                fontSize: 12.sp,
                color: const Color(0xFF2B3674),
                fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isPassed) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: isPassed ? const Color(0xFFE6F6EC) : const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        isPassed ? "PASSED" : "FAILED",
        style: GoogleFonts.dmSans(
          fontWeight: FontWeight.bold,
          fontSize: 10.sp,
          color: isPassed ? const Color(0xFF039855) : const Color(0xFFD92D20),
        ),
      ),
    );
  }

  Widget _buildScoreProgress(double percentage) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 45.r,
          height: 45.r,
          child: CircularProgressIndicator(
            value: percentage / 100,
            strokeWidth: 4,
            backgroundColor: const Color(0xFFF4F7FE),
            color: percentage >= 50 ? Colors.green : Colors.red,
          ),
        ),
        Text(
          "${percentage.toInt()}%",
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.bold,
            fontSize: 11.sp,
            color: const Color(0xFF2B3674),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10)),
              ],
            ),
            // Replaced static icon with 3D Rubik's Loader
            child: const RubiksCubeLoader(
              size: 80,
              key: ValueKey('rubiks_loader_v2'), // Force state recreation
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            _startDate != null || _endDate != null
                ? "No exams found for selected dates"
                : "No Exam Results Found", // Updated text
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
                color: const Color(0xFF2B3674)),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              "It looks like your students haven't taken any exams yet, or the results are currently being processed/uploaded. Please check back later.",
              style:
                  GoogleFonts.dmSans(fontSize: 14.sp, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              if (_startDate != null || _endDate != null) {
                _clearFilter();
              } else {
                _loadExamResults();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4318FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
            child: Text("Refresh List",
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              "Something went wrong",
              style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold, fontSize: 18.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              _errorMessage!,
              style:
                  GoogleFonts.dmSans(fontSize: 14.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: _loadExamResults,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B3674),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExamDetails(ExamResultResponse examResult) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: ColorResources.colorgrey500),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Detailed Report",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: const Color(0xff283B52),
                fontSize: 18.sp,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem(Icons.person_outline, "Student",
                    examResult.studentFullName),
                if (examResult.courseName != null)
                  _buildDetailItem(
                      Icons.school_outlined, "Course", examResult.courseName!),
                if (examResult.examName != null)
                  _buildDetailItem(
                      Icons.assignment_outlined, "Exam", examResult.examName!),
                _buildDetailItem(Icons.calendar_today_outlined, "Date",
                    examResult.formattedDate),
                SizedBox(height: 24.h),
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FE),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: [
                      _buildScoreRow("Total Marks", examResult.totalMark),
                      SizedBox(height: 12.h),
                      _buildScoreRow("Pass Marks", examResult.passMark),
                      SizedBox(height: 12.h),
                      _buildScoreRow("Obtained", examResult.obtainedMark,
                          isHighlight: true),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: const Divider(color: Colors.white, thickness: 2),
                      ),
                      _buildScoreRow(
                          "Result", examResult.isPassed ? "PASSED" : "FAILED",
                          color:
                              examResult.isPassed ? Colors.green : Colors.red),
                    ],
                  ),
                ),
                if (examResult.message.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 24.h),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: const Color(0xFFF3F4F6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Remarks",
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                  color: const Color(0xFF2B3674))),
                          SizedBox(height: 8.h),
                          Text(
                            examResult.message,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: const Color(0xFFA3AED0)),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 10.sp, color: const Color(0xFFA3AED0))),
              Text(value,
                  style: GoogleFonts.dmSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2B3674))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, String value,
      {bool isHighlight = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 13.sp, color: const Color(0xFF2B3674))),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: isHighlight ? 16.sp : 14.sp,
            fontWeight: FontWeight.bold,
            color: color ?? const Color(0xFF4318FF),
          ),
        ),
      ],
    );
  }
}
