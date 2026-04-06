class FacultyBatchStudentModel {
  int? batchId;
  String? batchName;
  String? startDate;
  String? endDate;
  int? courseId;
  String? courseName;
  int? studentId;
  String? firstName;
  String? lastName;
  String? email;
  String? phoneNumber;
  String? profilePhotoPath;
  DateTime? enrollmentDate;
  DateTime? expiryDate;
  String? paymentStatus;

  FacultyBatchStudentModel({
    this.batchId,
    this.batchName,
    this.startDate,
    this.endDate,
    this.courseId,
    this.courseName,
    this.studentId,
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.profilePhotoPath,
    this.enrollmentDate,
    this.expiryDate,
    this.paymentStatus,
  });

  factory FacultyBatchStudentModel.fromJson(Map<String, dynamic> json) {
    return FacultyBatchStudentModel(
      batchId: json['Batch_ID'],
      batchName: json['Batch_Name'],
      startDate: json['Start_Date'],
      endDate: json['End_Date'],
      courseId: json['Course_ID'],
      courseName: json['Course_Name'],
      studentId: json['Student_ID'],
      firstName: json['First_Name'],
      lastName: json['Last_Name'],
      email: json['Email'],
      phoneNumber: json['Phone_Number'],
      profilePhotoPath: json['Profile_Photo_Path'],
      enrollmentDate: json['Enrollment_Date'] != null
          ? DateTime.parse(json['Enrollment_Date'])
          : null,
      expiryDate: json['Expiry_Date'] != null
          ? DateTime.parse(json['Expiry_Date'])
          : null,
      paymentStatus: json['Payment_Status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Batch_ID': batchId,
      'Batch_Name': batchName,
      'Start_Date': startDate,
      'End_Date': endDate,
      'Course_ID': courseId,
      'Course_Name': courseName,
      'Student_ID': studentId,
      'First_Name': firstName,
      'Last_Name': lastName,
      'Email': email,
      'Phone_Number': phoneNumber,
      'Profile_Photo_Path': profilePhotoPath,
      'Enrollment_Date': enrollmentDate?.toIso8601String(),
      'Expiry_Date': expiryDate?.toIso8601String(),
      'Payment_Status': paymentStatus,
    };
  }
}
