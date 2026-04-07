class VideoAttendanceReportModel {
  bool? success;
  List<VideoAttendanceRow>? rows;

  VideoAttendanceReportModel({this.success, this.rows});

  VideoAttendanceReportModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['rows'] != null) {
      rows = <VideoAttendanceRow>[];
      json['rows'].forEach((v) {
        rows!.add(VideoAttendanceRow.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (rows != null) {
      data['rows'] = rows!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class VideoAttendanceRow {
  int? videoAttendanceID;
  int? studentID;
  String? studentName;
  int? courseID;
  int? contentID;
  String? watchedDate;
  String? updateTime;
  String? courseName;
  String? contentName;
  String? teacherName;
  String? batchName;

  VideoAttendanceRow(
      {this.videoAttendanceID,
      this.studentID,
      this.studentName,
      this.courseID,
      this.contentID,
      this.watchedDate,
      this.updateTime,
      this.courseName,
      this.contentName,
      this.teacherName,
      this.batchName});

  VideoAttendanceRow.fromJson(Map<String, dynamic> json) {
    videoAttendanceID = json['VideoAttendance_ID'];
    studentID = json['Student_ID'];
    studentName = json['Student_Name'];
    courseID = json['Course_ID'];
    contentID = json['Content_ID'];
    watchedDate = json['Watched_Date'];
    updateTime = json['Update_Time'];
    courseName = json['Course_Name'];
    contentName = json['Content_Name'];
    teacherName = json['Teacher_Name'];
    batchName = json['Batch_Name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['VideoAttendance_ID'] = videoAttendanceID;
    data['Student_ID'] = studentID;
    data['Student_Name'] = studentName;
    data['Course_ID'] = courseID;
    data['Content_ID'] = contentID;
    data['Watched_Date'] = watchedDate;
    data['Update_Time'] = updateTime;
    data['Course_Name'] = courseName;
    data['Content_Name'] = contentName;
    data['Teacher_Name'] = teacherName;
    data['Batch_Name'] = batchName;
    return data;
  }
}
