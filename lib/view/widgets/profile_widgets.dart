import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/core/utils/image_constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

Widget profileTextFieldWidget({
  required TextEditingController controller,
  required String labelText,
  required ValueChanged<String> onChanged,
}) {
  return SizedBox(
    height: 54,
    child: TextField(
      controller: controller,
      style: GoogleFonts.plusJakartaSans(
        color: ColorResources.colorBlue800,
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.plusJakartaSans(
          color: ColorResources.colorgrey600,
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 10.w, horizontal: 10.h),
        fillColor: ColorResources.colorwhite,
        filled: true,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.w),
          borderSide: const BorderSide(color: ColorResources.colorBlack),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.w),
          borderSide: const BorderSide(color: ColorResources.colorgrey300),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.w),
          borderSide: const BorderSide(color: ColorResources.colorgrey200),
        ),
      ),
      onChanged: onChanged,
    ),
  );
}

class ShowDialogWidget extends StatelessWidget {
  final void Function()? fromGallery;
  final void Function()? fromCamera;
  const ShowDialogWidget(
      {super.key, required this.fromGallery, required this.fromCamera});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: false,
      shadowColor: ColorResources.colorBlack,
      elevation: 15,
      backgroundColor: ColorResources.colorwhite,
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: fromGallery,
                icon: const Icon(Icons.photo_size_select_actual_rounded),
              ),
              Text(
                'Gallery',
                style: GoogleFonts.dmSans(
                  color: ColorResources.colorBlack,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                  onPressed: fromCamera,
                  icon: const Icon(Icons.camera_alt_rounded)),
              Text(
                'Camera',
                style: GoogleFonts.dmSans(
                  color: ColorResources.colorBlack,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget callHistoryWidget(
    {required String name,
    required String subTitle,
    required String image,
    required String date,
    required String time,
    Widget? callIcon,
    Widget? eyeIcon,
    String? callType,
    Color? color}) {
  return SizedBox(
    height: 60.h,
    child: ListTile(
      contentPadding: const EdgeInsets.all(0),
      // tileColor: ColorResources.colorBlack,
      leading: CircleAvatar(
        radius: 23,
        child: CachedNetworkImage(
          imageUrl: image,
          imageBuilder: (context, imageProvider) => Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          placeholder: (context, url) => const CircularProgressIndicator(
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
      title: Text(
        name,
        style: GoogleFonts.plusJakartaSans(
          color: ColorResources.colorBlack,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Row(
        children: [
          const SizedBox(
            width: 5,
          ),
          Text(
            subTitle,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: ColorResources.colorgrey600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(
            width: 5,
          ),
          callIcon ?? const SizedBox()
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                time,
                style: GoogleFonts.plusJakartaSans(
                  color: ColorResources.colorgrey600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                date,
                style: GoogleFonts.plusJakartaSans(
                  color: ColorResources.colorgrey600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(
            width: 7,
          ),
          eyeIcon ?? const SizedBox.shrink()
        ],
      ),
    ),
  );
}

Widget batchOfTeacherWidget({
  required String batchNames,
  required BuildContext context,
  required String studentsName,
  required String studentCount,
  required String batchStart,
  required String batchEnd,
  required String timeSlot,
  required String badgeText,
  required Color? color,
  required Color? txtColor,
  required Color? iconColor,
  required IconData icon,
  required Color? badgeColor,
}) {
  return Stack(
    children: [
      Container(
        padding:
            EdgeInsets.only(top: 14.w, left: 14.w, right: 14.w, bottom: 14.w),
        decoration: BoxDecoration(
          color: ColorResources.colorwhite,
          borderRadius: BorderRadius.circular(10.w),
          border: Border.all(
            color: const Color(0XFFE3E7EE),
            width: 0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // SizedBox(
                //   height: 15.h,
                //   width: 15.w,
                //   child: Image.asset(
                //     ImageConstant.imageBookIcon,
                //     height: 14.h,
                //     width: 14.w,
                //     fit: BoxFit.cover,
                //     color: const Color(0xFF283B52),
                //   ),
                // ),
                const Icon(
                  CupertinoIcons.book,
                  size: 20,
                  color: ColorResources.colorBlack,
                ),
                SizedBox(
                  width: 6.w,
                ),
                Text(
                  batchNames,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ColorResources.colorBlue800,
                    fontSize: 16.sp,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: ColorResources.colorgrey600,
                  size: 20,
                ),
                const SizedBox(
                  width: 4,
                ),
                Expanded(
                  // Wrap text to new line
                  child: Text(
                    studentsName,
                    softWrap: true, // Allow text to wrap
                    style: TextStyle(
                      color: ColorResources.colorBlue800,
                      fontSize: 16.sp,
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 12.w,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 20,
                  color: ColorResources.colorBlack,
                ),
                const SizedBox(
                  width: 4,
                ),
                Text(
                  timeSlot,
                  maxLines: 1,
                  overflow: TextOverflow.visible, // No ellipsis
                  style: TextStyle(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    fontSize: 14.sp,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(
                  width: 6.w,
                ),
                Expanded(
                  // Allow the text to take available space
                  child: Text(
                    studentCount.replaceAll(
                        RegExp(r'[\[\]]'), ''), // Remove square brackets
                    style: TextStyle(
                      color: const Color(0xFF6A7487),
                      fontSize: 15.sp,
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w500,
                    ),
                    softWrap: true, // Allow text to break into a new line
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 8.h,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.calendar_month,
                  size: 20,
                  color: ColorResources.colorgrey600,
                ),
                const SizedBox(
                  width: 4,
                ),
                Text(
                  'Batch start : ',
                  maxLines: 1,
                  overflow: TextOverflow.visible, // No ellipsis
                  style: TextStyle(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    fontSize: 14.sp,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(
                  width: 6.w,
                ),
                Expanded(
                  // Allow the text to take available space
                  child: Text(
                    batchStart, // Remove square brackets
                    style: TextStyle(
                      color: const Color(0xFF6A7487),
                      fontSize: 15.sp,
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w500,
                    ),
                    softWrap: true, // Allow text to break into a new line
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 8.h,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.calendar_month,
                  size: 20,
                  color: ColorResources.colorgrey600,
                ),
                const SizedBox(
                  width: 4,
                ),
                Text(
                  'Batch End : ',
                  maxLines: 1,
                  overflow: TextOverflow.visible, // No ellipsis
                  style: TextStyle(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    fontSize: 14.sp,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(
                  width: 6.w,
                ),
                Expanded(
                  // Allow the text to take available space
                  child: Text(
                    batchEnd, // Remove square brackets
                    style: TextStyle(
                      color: const Color(0xFF6A7487),
                      fontSize: 15.sp,
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w500,
                    ),
                    softWrap: true, // Allow text to break into a new line
                  ),
                ),
              ],
            ),
            SizedBox(
              width: 4.w,
            ),
          ],
        ),
      ),
      Positioned(
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8), topRight: Radius.circular(8)),
              color: badgeColor,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                  child: Text(badgeText,
                      style: const TextStyle(
                          color: ColorResources.colorwhite,
                          fontWeight: FontWeight.w500))),
            ),
          ))
    ],
  );
}
