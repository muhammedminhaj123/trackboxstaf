class ExamResultResponse {
  final int examResultMasterId;
  final int studentId;
  final int courseId;
  final int? courseExamId; // New field
  final int examDataId;
  final String totalMark;
  final String passMark;
  final String obtainedMark;
  final String message;

  // Additional fields from API
  final String? examName;
  final String? resultStatus;
  final String? firstName;
  final String? lastName;
  final String? courseName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ExamResultResponse({
    required this.examResultMasterId,
    required this.studentId,
    required this.courseId,
    this.courseExamId,
    required this.examDataId,
    required this.totalMark,
    required this.passMark,
    required this.obtainedMark,
    required this.message,
    this.examName,
    this.resultStatus,
    this.firstName,
    this.lastName,
    this.courseName,
    this.createdAt,
    this.updatedAt,
  });

  factory ExamResultResponse.fromJson(Map<String, dynamic> json) {
    return ExamResultResponse(
      examResultMasterId: json['exam_result_master_id'] ?? 0,
      studentId: json['student_id'] ?? 0,
      courseId: json['course_id'] ?? 0,
      courseExamId: json['course_exam_id'],
      examDataId: json['exam_data_id'] ?? 0,
      totalMark: json['total_mark']?.toString() ?? '0',
      passMark: json['pass_mark']?.toString() ?? '0',
      obtainedMark: json['obtained_mark']?.toString() ?? '0',
      message: json['message'] ?? '',
      examName: json['exam_name'],
      resultStatus: json['result_status'],
      firstName: json['First_Name'],
      lastName: json['Last_Name'],
      courseName: json['Course_Name'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exam_result_master_id': examResultMasterId,
      'student_id': studentId,
      'course_id': courseId,
      'course_exam_id': courseExamId,
      'exam_data_id': examDataId,
      'total_mark': totalMark,
      'pass_mark': passMark,
      'obtained_mark': obtainedMark,
      'message': message,
      'exam_name': examName,
      'result_status': resultStatus,
      'First_Name': firstName,
      'Last_Name': lastName,
      'Course_Name': courseName,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper methods
  double get obtainedMarkDouble => double.tryParse(obtainedMark) ?? 0.0;
  double get totalMarkDouble => double.tryParse(totalMark) ?? 0.0;
  double get passMarkDouble => double.tryParse(passMark) ?? 0.0;

  bool get isPassed => obtainedMarkDouble >= passMarkDouble;

  double get percentage =>
      totalMarkDouble > 0 ? (obtainedMarkDouble / totalMarkDouble) * 100 : 0.0;

  // Get student full name
  String get studentFullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return 'Student #$studentId';
  }

  // Get formatted exam date
  String get formattedDate {
    if (createdAt != null) {
      return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
    }
    return 'N/A';
  }
}
