import 'package:breffini_staff/http/http_requests.dart';
import 'package:breffini_staff/http/http_urls.dart';
import 'package:breffini_staff/model/video_attendance_report_model.dart';
import 'package:get/get.dart';

class VideoAttendanceController extends GetxController {
  var attendanceReport = <VideoAttendanceRow>[].obs;
  RxBool isLoading = false.obs;

  Future<void> getVideoAttendanceReport(
      {required String studentId, required String courseId}) async {
    isLoading.value = true;
    final String endpoint =
        '${HttpUrls.getVideoAttendanceReport}?Course_ID=$courseId&Student_ID=$studentId';

    try {
      final response = await HttpRequest.httpGetRequest(
        endPoint: endpoint,
        showLoader: false,
      );

      if (response != null && response.statusCode == 200) {
        print("attendence:$response");
        final videoAttendanceReportModel =
            VideoAttendanceReportModel.fromJson(response.data);
        attendanceReport.value = videoAttendanceReportModel.rows ?? [];
      } else {
        attendanceReport.clear();
      }
    } catch (e) {
      print('Error fetching video attendance report: $e');
      attendanceReport.clear();
    } finally {
      isLoading.value = false;
      update();
    }
  }
}
