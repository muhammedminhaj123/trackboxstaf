import 'package:breffini_staff/http/http_urls.dart';
import 'package:breffini_staff/model/exam_result_model.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExamService {
  late Dio dio;

  ExamService() {
    dio = Dio(
      BaseOptions(
        baseUrl: HttpUrls.baseUrl,
        headers: {
          "Content-Type": "application/json",
        },
      ),
    );
  }

  /// Add token before every request
  Future<void> setAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('breffini_token');

    if (token != null) {
      dio.options.headers["Authorization"] = "Bearer $token";
    }
  }

  /// Get exam results for a specific student
  Future<List<ExamResultResponse>> getExamResults(int studentId) async {
    try {
      await setAuthToken();

      final response = await dio.get(
        "${HttpUrls.getExamResults}$studentId",
      );

      print("DEBUG: Exam Results API Response: ${response.data}");

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => ExamResultResponse.fromJson(json))
            .toList();
      } else {
        print("DEBUG: Unexpected response format: ${response.data}");
        return [];
      }
    } catch (e) {
      print("DEBUG: Error fetching exam results: $e");
      return [];
    }
  }

  /// Get all exam results for all students (for teacher view)
  /// This would need a different endpoint if available
  Future<Map<int, List<ExamResultResponse>>> getAllStudentsExamResults(
      List<int> studentIds) async {
    Map<int, List<ExamResultResponse>> allResults = {};

    for (int studentId in studentIds) {
      try {
        final results = await getExamResults(studentId);
        allResults[studentId] = results;
      } catch (e) {
        print("DEBUG: Error fetching results for student $studentId: $e");
        allResults[studentId] = [];
      }
    }

    return allResults;
  }
}
