import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:breffini_staff/core/utils/file_utils.dart';
import 'package:breffini_staff/http/http_urls.dart';
import 'package:breffini_staff/http/loader.dart';
import 'package:http/http.dart' as http;

class CloudFlareUpload {
  static Future<String?> uploadToCloudFlare(File file) async {
    Loader.showLoaderChat();
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
      String uploadFilePath = 'Briffni/User/';
      String key = '$uploadFilePath$fileName';

      bool success = await _uploadToR2(
        file: file,
        key: key,
        contentType: 'image/png',
      );
      Loader.stopLoader();

      if (success) {
        final publicUrl = '${HttpUrls.imgBaseUrl}$key';
        print('Public URL: $publicUrl');
        return publicUrl;
      }
      return null;
    } catch (e) {
      Loader.stopLoader();
      print('Error uploading to CloudFlare: $e');
      return null;
    }
  }

  static Future<String?> uploadChatImageToCloudFlare(File selectedFile,
      String studentId, String teacherId, String fileType) async {
    // Loader.showLoaderChat();
    try {
      File fileToUpload = selectedFile;
      if (['png', 'jpg', 'jpeg'].contains(fileType.toLowerCase())) {
        fileToUpload = await FileUtils.compressImage(selectedFile);
      }

      String fileName = "${DateTime.now().millisecondsSinceEpoch}.$fileType";
      String uploadFilePath = 'Briffni/Chat/$studentId-$teacherId/';
      String key = '$uploadFilePath$fileName';

      String contentType = _getContentType(fileType);

      bool success = await _uploadToR2(
        file: fileToUpload,
        key: key,
        contentType: contentType,
      );

      // Loader.stopLoader();

      if (success) {
        return key;
      }
      return null;
    } catch (e) {
      // Loader.stopLoader();
      print('Error uploading to CloudFlare: $e');
      return null;
    }
  }

  static String _getContentType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'pdf':
        return 'application/pdf';
      case 'mp4':
        return 'video/mp4';
      case 'm4a':
        return 'audio/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }

  static Future<bool> _uploadToR2({
    required File file,
    required String key,
    required String contentType,
  }) async {
    final accessKey = dotenv.env['CLOUDFLARE_R2_ACCESS_KEY_ID']!;
    final secretKey = dotenv.env['CLOUDFLARE_R2_SECRET_ACCESS_KEY']!;
    final endpoint = dotenv.env[
        'CLOUDFLARE_R2_ENDPOINT']!; // https://<account_id>.r2.cloudflarestorage.com
    final bucket = dotenv.env['CLOUDFLARE_R2_BUCKET_NAME']!;

    // Ensure endpoint doesn't end with slash
    final cleanEndpoint = endpoint.endsWith('/')
        ? endpoint.substring(0, endpoint.length - 1)
        : endpoint;

    // Construct URL: https://<account_id>.r2.cloudflarestorage.com/<bucket>/<key>
    final url = '$cleanEndpoint/$bucket/$key';
    final uri = Uri.parse(url);

    final bytes = await file.readAsBytes();
    final contentSha256 = sha256.convert(bytes).toString();
    final now = DateTime.now().toUtc();
    final amzDate = _formatAmzDate(now);
    final dateStamp = _formatDateStamp(now);
    final region = 'auto'; // R2 uses 'auto' or 'us-east-1' usually

    // 1. Canonical Request
    final method = 'PUT';
    final canonicalUri =
        '/$bucket/$key'; // Include bucket in path for manual call?
    // Wait, the host is account-id.r2.... The path is /bucket/key.
    // Let's verify R2 path style.
    // Yes, https://<accountid>.r2.cloudflarestorage.com/<bucket>/<key>

    final canonicalQueryString = '';
    final canonicalHeaders =
        'host:${uri.host}\nx-amz-content-sha256:$contentSha256\nx-amz-date:$amzDate\n';
    final signedHeaders = 'host;x-amz-content-sha256;x-amz-date';
    final canonicalRequest =
        '$method\n$canonicalUri\n$canonicalQueryString\n$canonicalHeaders\n$signedHeaders\n$contentSha256';

    // 2. String to Sign
    final algorithm = 'AWS4-HMAC-SHA256';
    final credentialScope = '$dateStamp/$region/s3/aws4_request';
    final stringToSign =
        '$algorithm\n$amzDate\n$credentialScope\n${sha256.convert(utf8.encode(canonicalRequest))}';

    // 3. Signature
    final signingKey = _getSignatureKey(secretKey, dateStamp, region, 's3');
    final signature = _hmacSha256Hex(signingKey, stringToSign);

    // 4. Authorization Header
    final authorizationHeader =
        '$algorithm Credential=$accessKey/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';

    try {
      final response = await http.put(
        uri,
        headers: {
          'Authorization': authorizationHeader,
          'x-amz-date': amzDate,
          'x-amz-content-sha256': contentSha256,
          'Content-Type': contentType,
          'Content-Length': bytes.length.toString(),
        },
        body: bytes,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Upload successful: ${response.statusCode}');
        return true;
      } else {
        print('Upload failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Upload exception: $e');
      return false;
    }
  }

  static String _formatAmzDate(DateTime date) {
    return date
            .toIso8601String()
            .replaceAll('-', '')
            .replaceAll(':', '')
            .split('.')
            .first +
        'Z';
  }

  static String _formatDateStamp(DateTime date) {
    return date.toIso8601String().split('T').first.replaceAll('-', '');
  }

  static List<int> _getSignatureKey(
      String key, String dateStamp, String regionName, String serviceName) {
    final kDate = _hmacSha256(utf8.encode('AWS4$key'), dateStamp);
    final kRegion = _hmacSha256(kDate, regionName);
    final kService = _hmacSha256(kRegion, serviceName);
    final kSigning = _hmacSha256(kService, 'aws4_request');
    return kSigning;
  }

  static List<int> _hmacSha256(List<int> key, String data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(data)).bytes;
  }

  static String _hmacSha256Hex(List<int> key, String data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(data)).toString();
  }
}
