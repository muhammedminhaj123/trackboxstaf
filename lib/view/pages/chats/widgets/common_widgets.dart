import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/core/theme/custom_text_style.dart';
import 'package:breffini_staff/core/utils/extentions.dart';
import 'package:breffini_staff/http/chat_socket.dart';
import 'package:breffini_staff/controller/chat_history_controller.dart';
import 'package:breffini_staff/view/pages/chats/widgets/custom_icon_button.dart';
import 'package:breffini_staff/view/pages/chats/widgets/custom_text_form_field.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Section Widget
Widget buildAppBar({
  required String studentName,
  required String profileUrl,
  required String studentId,
  void Function()? onAvatarTap,
  required String usertype,
}) {
  final ChatHistoryController chatHistoryController =
      Get.find<ChatHistoryController>();
  return Container(
    decoration: const BoxDecoration(color: ColorResources.colorwhite),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: ColorResources.colorBlue100),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () async {
                SharedPreferences preferences =
                    await SharedPreferences.getInstance();
                String teacherId =
                    preferences.getString('breffini_teacher_Id') ?? '';

                if (teacherId.isNotEmpty) {
                  try {
                    chatHistoryController.getChatAndCallHistory(
                        'chat', 'teacher');
                    int parsedTeacherId = int.parse(teacherId);
                    usertype == '2'
                        ? await ChatSocket.leaveConversationRoom(
                            studentId.toString(),
                            parsedTeacherId,
                            'teacher_student')
                        : await ChatSocket.leaveConversationRoom(
                            studentId.toString(),
                            parsedTeacherId,
                            'hod_student');
                    await ChatSocket.getChatLogHistory(teacherId,
                        usertype == '2' ? 'teacher_student' : 'hod_student');
                  } catch (e) {
                    print('Error parsing teacherId: $e');
                  }
                } else {
                  print('teacherId is empty');
                }

                Get.back();
              },
              icon: const Icon(
                CupertinoIcons.back,
                color: ColorResources.colorgrey500,
                size: 20, // Adjust size as needed
              ),
            ),
          ),
          SizedBox(
            width: 12.w,
          ),
          InkWell(
            onTap: onAvatarTap,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20.r,
                  child: CachedNetworkImage(
                    imageUrl: profileUrl,
                    imageBuilder: (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(
                      color: Colors.blue,
                      strokeWidth: 2,
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Icon(
                        Icons.person_rounded,
                        color: ColorResources.colorBlack.withOpacity(.7),
                        size: 25.w,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 8.w,
                ),
                Text(
                  studentName,
                  style: GoogleFonts.plusJakartaSans(
                    color: ColorResources.colorgrey700,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: SizedBox()),
        ],
      ),
    ),
  );
}

Widget buildMessageSection({
  // required int studentId,
  void Function()? onTap,
  void Function()? onTapFile,
  void Function()? onTapDocument,
  void Function()? onStopVoice,
  void Function()? onPause,
  void Function()? onResume,
  void Function(String)? onTextChanged,
  double? height,
  required BuildContext context,
  TextEditingController? controller,
  required String fileName,
  required Widget imageWidget,
  required bool isVoiceMessage,
  required bool isRecording,
  required bool isRecordingPaused,
  required String formattedTime,
  required bool isMicOn,
  required bool isMessageTyped,
  required bool isSendingMessage,
}) {
  return Container(
    height: isVoiceMessage ? null : (height ?? 64.h),
    decoration: const BoxDecoration(color: ColorResources.colorwhite),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // SizedBox(height: 12.h),
        imageWidget,
        if (isVoiceMessage)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedTime,
                      style: GoogleFonts.plusJakartaSans(
                        color: ColorResources.colorBlack,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isRecording)
                              Lottie.asset(
                                'assets/lottie/record.json',
                                height: 24.h,
                                animate: isRecording,
                              )
                            else
                              Text(
                                "Recording Paused",
                                style: GoogleFonts.plusJakartaSans(
                                  color: ColorResources.colorgrey500,
                                  fontSize: 12.sp,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.looks_one_outlined,
                      color: ColorResources.colorgrey500,
                      size: 20,
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: onStopVoice,
                      child: const Icon(
                        Icons.delete_outline,
                        color: ColorResources.colorgrey500,
                        size: 24,
                      ),
                    ),
                    InkWell(
                      onTap: isRecording ? onPause : onResume,
                      child: Icon(
                        isRecording
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                        color: Colors.redAccent,
                        size: 32,
                      ),
                    ),
                    isSendingMessage
                        ? SizedBox(
                            height: 32.h,
                            width: 32.h,
                            child: const CircularProgressIndicator(
                              color: ColorResources.colorBlue600,
                              strokeWidth: 2,
                            ),
                          )
                        : InkWell(
                            onTap: onTap,
                            child: Container(
                              height: 36.h,
                              width: 36.h,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF1B1B1B),
                              ),
                              child: const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                  ],
                ),
              ],
            ),
          )
        else
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return Container(
                          decoration: const BoxDecoration(
                            color: ColorResources.colorwhite,
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16)),
                          ),
                          height: 175.h,
                          child: Column(
                            children: [
                              SizedBox(height: 12.h),
                              Container(
                                width: 36.h,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: ColorResources.colorgrey400,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              SizedBox(height: 24.h),
                              ListTile(
                                leading: const Icon(
                                  Icons.image_outlined,
                                  size: 24,
                                  color: ColorResources.colorgrey700,
                                ),
                                title: Text(
                                  'Attach photos & videos',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: ColorResources.colorgrey700,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: onTapFile,
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.upload_file,
                                  size: 24,
                                  color: ColorResources.colorgrey700,
                                ),
                                title: Text(
                                  'Upload file',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: ColorResources.colorgrey700,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: onTapDocument,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    height: 38.h,
                    width: 38.h,
                    decoration: BoxDecoration(
                      color: ColorResources.colorgrey200,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Icon(CupertinoIcons.add),
                  ),
                ),
                SizedBox(width: 10.h),
                Expanded(
                  child: CustomTextFormField(
                    fillColor: ColorResources.colorgrey200,
                    filled: true,
                    height: 40.h,
                    controller: controller,
                    onTextChanged: onTextChanged,
                    hintText: "Type your message",
                    textStyle: CustomTextStyles.bodySmallBlack900.copyWith(
                      fontSize: 14.0,
                    ),
                    hintStyle: CustomTextStyles.bodySmallBluegray40001.copyWith(
                      fontSize: 14.0,
                    ),
                    textInputAction: TextInputAction.done,
                    alignment: Alignment.center,
                  ),
                ),
                SizedBox(width: 10),
                isSendingMessage
                    ? Container(
                        height: 38.h,
                        width: 38.h,
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: CircularProgressIndicator(
                          color: ColorResources.colorBlue600,
                        ),
                      )
                    : (isMicOn && fileName.isEmpty && !isMessageTyped)
                        ? InkWell(
                            onTap: onTap,
                            child: CustomIconButton(
                              height: 38.h,
                              width: 38.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    ColorResources.colorBlue600,
                                    ColorResources.colorBlue600,
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.mic,
                                color: ColorResources.colorwhite,
                                size: 18,
                              ),
                            ),
                          )
                        : InkWell(
                            onTap: onTap,
                            child: CustomIconButton(
                              height: 38.h,
                              width: 38.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    ColorResources.colorBlue600,
                                    ColorResources.colorBlue600
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.send,
                                color: ColorResources.colorwhite,
                                size: 18,
                              ),
                            ),
                          ),
              ],
            ),
          ),
      ],
    ),
  );
}

//
// Widget buildMessageSection({
//   void Function()? onTap,
//   void Function()? onTapFile,
//   void Function()? onTapDocument,
//   void Function()? onStopVoice,
//   void Function()? onPause,
//   void Function()? onResume,
//   double? height,
//   required BuildContext context,
//   TextEditingController? controller,
//   required String fileName,
//   required String formattedTime,
//   required Widget fileWidget,
//   required bool isMicOn,
//   required bool isVoiceMessage,
//   required bool isMessageTyped,
//   required bool isRecording,
// }) {
//   return Container(
//     height: height??64.h,
//     decoration: const BoxDecoration(color: ColorResources.colorwhite),
//     child: Column(
//       children: [
//         // Display the file preview (image or PDF)
//         if (fileName.isNotEmpty)
//           Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
//             child: fileWidget,
//           ),
//         SizedBox(height: 12.h),
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: 16.w),
//           child: Row(
//             children: [
//               // Button to show modal bottom sheet for file attachments
//               if (!isVoiceMessage)
//                 InkWell(
//                   onTap: () {
//                     showModalBottomSheet(
//                       context: context,
//                       builder: (BuildContext context) {
//                         return Container(
//                           decoration: const BoxDecoration(
//                             color: ColorResources.colorwhite,
//                             borderRadius: BorderRadius.only(
//                               topLeft: Radius.circular(16),
//                               topRight: Radius.circular(16),
//                             ),
//                           ),
//                           height: 170.h,
//                           child: Column(
//                             children: [
//                               SizedBox(height: 12.h),
//                               Container(
//                                 width: 36.w,
//                                 height: 5,
//                                 decoration: BoxDecoration(
//                                   color: ColorResources.colorgrey400,
//                                   borderRadius: BorderRadius.circular(8.r),
//                                 ),
//                               ),
//                               SizedBox(height: 24.h),
//                               ListTile(
//                                 leading: const Icon(
//                                   Icons.image_outlined,
//                                   size: 24,
//                                   color: ColorResources.colorgrey700,
//                                 ),
//                                 title: Text(
//                                   'Attach photos & videos',
//                                   style: GoogleFonts.plusJakartaSans(
//                                     color: ColorResources.colorgrey700,
//                                     fontSize: 14.sp,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                                 onTap: onTapFile,
//                               ),
//                               ListTile(
//                                 leading: const Icon(
//                                   Icons.upload_file,
//                                   size: 24,
//                                   color: ColorResources.colorgrey700,
//                                 ),
//                                 title: Text(
//                                   'Upload file',
//                                   style: GoogleFonts.plusJakartaSans(
//                                     color: ColorResources.colorgrey700,
//                                     fontSize: 14.sp,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                                 onTap: onTapDocument,
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     );
//                   },
//                   child: Container(
//                     height: 32.h,
//                     width: 32.w,
//                     decoration: BoxDecoration(
//                       color: ColorResources.colorgrey200,
//                       borderRadius: BorderRadius.circular(100),
//                     ),
//                     child: const Icon(CupertinoIcons.add),
//                   ),
//                 ),
//               if (!isVoiceMessage) SizedBox(width: 10.w),
//               // Message input field
//               if (!isVoiceMessage)
//                 Expanded(
//                   child: CustomTextFormField(
//                     fillColor: ColorResources.colorgrey200,
//                     filled: true,
//                     height: 40.h,
//                     controller: controller,
//                     hintText: "Type your message",
//                     textStyle: CustomTextStyles.bodySmallBlack900.copyWith(
//                       height: 1.33,
//                       fontSize: 14.sp,
//                     ),
//                     hintStyle: CustomTextStyles.bodySmallBluegray40001.copyWith(
//                       height: 1.33,
//                       fontSize: 14.sp,
//                     ),
//                     textInputAction: TextInputAction.done,
//                     alignment: Alignment.center,
//                     contentPadding:
//                         EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.w),
//                   ),
//                 )
//               else
//                 InkWell(
//                   onTap: isRecording ? onPause : onResume,
//                   child: CustomIconButton(
//                     height: 38.h,
//                     width: 38.h,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(12),
//                       gradient: const LinearGradient(
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                         colors: [
//                           Color(0xFFF4F7FA),
//                           Color(0xFFF4F7FA),
//                         ],
//                       ),
//                     ),
//                     child: Icon(
//                       isRecording ? Icons.pause : Icons.play_arrow,
//                       color: const Color(0xFF283B52),
//                       size: 20,
//                     ),
//                   ),
//                 ),
//               SizedBox(width: 10.w),
//               if (isVoiceMessage)
//                 Expanded(
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: const Color(
//                           0xFFE3E7EE), // Set the background color (optional)
//                       borderRadius:
//                           BorderRadius.circular(12.0), // Set the border radius
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(5.0),
//                       child: Row(
//                         children: [
//                           if (isRecording)
//                             Lottie.asset('assets/lottie/record.json'),
//                           const SizedBox(
//                             width: 10,
//                           ),
//                           Expanded(
//                               child: Row(
//                             children: [
//                               if (isRecording)
//                                 Text(
//                                   'Recording',
//                                   style: TextStyle(color: Color(0xFF6A7487)),
//                                 ),
//                               if (isRecording)
//                                 Text(
//                                   '...',
//                                   style: TextStyle(color: Color(0xFF6A7487)),
//                                 )
//                                     .animate(
//                                       onPlay: (controller) =>
//                                           controller.repeat(),
//                                     )
//                                     .fadeIn(
//                                         duration: 600.ms,
//                                         delay: 200.ms) // Fade in
//                                     .scale(
//                                         delay: 200.ms,
//                                         curve: Curves
//                                             .easeOut) // Scale after a delay
//                                     .then() // Then
//                                     .fadeOut(duration: 600.ms), // Fade out
//                             ],
//                           )),
//                           Text(formattedTime),
//                           const SizedBox(
//                             width: 10,
//                           ),
//                           InkWell(
//                             onTap: onStopVoice,
//                             child: CustomIconButton(
//                               height: 25.h,
//                               width: 25.h,
//                               decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(50),
//                                   color: const Color(0xFF283B52)),
//                               child: const Icon(
//                                 Icons.close,
//                                 color: Color(0xFFE3E7EE),
//                                 size: 15,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(
//                             width: 5,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               SizedBox(width: 10.w),
//               // Send button
//               if (isMicOn && fileName.isEmpty && !isMessageTyped)
//                 InkWell(
//                   onTap: onTap,
//                   child: CustomIconButton(
//                     height: 38.h,
//                     width: 38.h,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(14),
//                       gradient: const LinearGradient(
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                         colors: [
//                           ColorResources.colorBlue600,
//                           ColorResources.colorBlue600,
//                         ],
//                       ),
//                     ),
//                     child: const Icon(
//                       Icons.mic,
//                       color: ColorResources.colorwhite,
//                       size: 18,
//                     ),
//                   ),
//                 )
//               else
//                 InkWell(
//                   onTap: onTap,
//                   child: CustomIconButton(
//                     height: 38.h,
//                     width: 38.h,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(14),
//                       gradient: const LinearGradient(
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                         colors: [
//                           ColorResources.colorBlue600,
//                           ColorResources.colorBlue600,
//                         ],
//                       ),
//                     ),
//                     child: const Icon(
//                       Icons.send,
//                       color: ColorResources.colorwhite,
//                       size: 18,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ],
//     ),
//   );
// }
