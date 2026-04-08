class HttpUrls {
  static String baseUrl = 'https://1hm3rdfr-3515.inc1.devtunnels.ms/';
  // static String baseUrl = 'https://happyenglishapi.ufstech.co.in';

  static String imgBaseUrl =
      'https://pub-11714a99f3bd420ca95f23dda2af714b.r2.dev/';

  static String login = '/Login/Login_Check';
  static String checkOtp = '/Login/Check_OTP';
  static String getTeacherProfile = '/user/Get_User/';
  static String editTeacherProfile = '/user/Save_user'
      '';
  static String getCallsAndChatList = '/user/Get_Calls_And_Chats_List';
  static String saveLiveClass = '/teacher/Save_LiveClass';
  static String getCoursesTeacher = "/teacher/Get_Teacher_courses_With_Batch";
  static String getOngoingCalls = "/user/Get_Ongoing_Calls";
  static String getCompleted = "/teacher/Get_Completed_liveClass";
  // static String stopCall = "/user/Save_Call_History";
  static String upcomingLive = '/teacher/Get_Upcomming_liveClass';
  static String getStudentsTimeSlot =
      "/teacher/Get_Student_TimeSlots_By_TeacherID";
  static String getTeacherChatLog =
      "/user/Get_Calls_And_Chats_List?type=chat&sender=teacher&teacherId=";
  static String saveStudentCall = '/user/Save_Call_History';
  static String generateForgetPassword = '/Login/Generate-forget-Password';
  static String newPassword = '/Login/change_password';
  static String getCourseOfStudent = '/student/Get_Courses_By_StudentId';
  static String getMediaofStudent = '/chat/Get_Chats_Media';
  static String getCallLogOfStudent = '/user/get_call_history';
  static String updateHodStatus = '/user/update_user_status';
  static String changeStudentModuleLockStatus =
      '/Module/Change_Student_Module_Lock_Status';
  static String courseContentLibrary = '/course/Get_course_content';

  static String getCourseInfo = '/course/Get_Course_Info';
  static String getBatchDays = "/Batch/Get_Batch_Days";
  static String getCoursesModules = '/course/Get_Module_Of_Course';
  static String getSecttionsByCourse = "/course/Get_Sections_By_Course";
  static String getCourseContentByDay = '/course/Get_course_content_By_Day';
  static String unlockExam = '/course/Unlock_Exam';

  static String getStudentsLists = "/course/Get_Student_List_By_Batch";
  static String getRecordings = "/course/Get_Student_ClassRecords";
  static String getModulesofMockTests = "/course/Get_Exam_Modules_By_CourseId";
  static String getInvoiceReport = "/user/Search_User_Invoice";
  static String getExploreCourses = '/Search_course';
  static String getStudentCourseList = "/course/Get_Course_Students";
  static String checkCallAvailability = '/user/Check_Call_Availability';
  static String getHodCourse = "/user/Get_Hod_Course";

  static String Update_Call_Status_Accept =
      '/user/Update_Call_Status?newStatus=1&type=connect&callId=';
  static String Update_Call_Status_Failed =
      '/user/Update_Call_Status?newStatus=1&type=call&callId=';

  static String Get_Student_Details = '/student/Get_student/';
  static String getBatchOfTeacher = "/teacher/Get_teacherBatch_of_oneOnOne/";
  static String getCoursesDetailsTeacher = "/teacher/Get_Teacher_courses/";
  // ================= TEACHER PROFILE =================

// Qualification
  static String saveTeacherQualification =
      '/teacher/Save_Teacher_Qualification';

  static String getTeacherQualificationsByTeacherId =
      '/teacher/Get_Teacher_Qualifications_By_TeacherID/';
  static String deleteTeacherQualification =
      '/teacher/Delete_Teacher_Qualification/';
  static String editTeacherQualification =
      '/teacher/Edit_Teacher_Qualification';

// Work Experience
  static String saveTeacherExperience = '/teacher/Save_Teacher_Experience';

  static String getTeacherExperienceByTeacherId =
      '/teacher/Get_Teacher_Experience_By_TeacherID/';
  static String deleteTeacherExperience = '/teacher/Delete_Teacher_Experience/';
  static String editTeacherExperience = '/teacher/Edit_Teacher_Experience';

  // Exam Results
  static String getExamResults = '/student/Get_Exam_Results/';

  static String getFacultyBatchStudents =
      '/teacher/Get_Faculty_Batch_Students/';

  static String getVideoAttendanceReport =
      '/teacher/Get_VideoAttendance_Report';
  
  static String saveStaffAttendance = '/teacher/Save_Staff_Attendance';
}
