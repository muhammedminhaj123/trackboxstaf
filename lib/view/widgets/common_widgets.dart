import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';

Widget buttonWidget({
  required BuildContext context,
  required String text,
  required Color? backgroundColor,
  required Color? txtColor,
  required void Function()? onPressed,
  double height = 56,
}) {
  return SizedBox(
    height: height,
    width: MediaQuery.sizeOf(context).width,
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100.w)),
                    backgroundColor: backgroundColor,
                  ),
                  onPressed: onPressed,
                  child: Text(
                    text,
                    style: GoogleFonts.plusJakartaSans(
                      color: txtColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  )),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget commonTextFieldWidget({
  required TextEditingController controller,
  required String labelText,
  required ValueChanged<String> onChanged,
}) {
  return SizedBox(
    height: 54.h,
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

Widget datePickerWidget({
  required TextEditingController? controller,
  required String? labelText,
  required void Function()? onTap,
}) {
  return SizedBox(
    height: 54.h,
    child: TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: GoogleFonts.plusJakartaSans(
        color: ColorResources.colorBlue800,
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        suffixIcon: Icon(
          Icons.calendar_today_outlined,
          size: 18.h,
          color: ColorResources.colorgrey500,
        ),
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
    ),
  );
}

Future<void> selectDate(
    BuildContext context, TextEditingController? controller) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(1900),
    lastDate: DateTime(2100),
    builder: (BuildContext context, Widget? child) {
      return Theme(
        data: ThemeData.light().copyWith(
          primaryColor:
              ColorResources.colorBlue600, // Set your desired primary color
          colorScheme: const ColorScheme.light(
              primary: ColorResources.colorBlue600), // Adjust your color scheme
          buttonTheme:
              const ButtonThemeData(textTheme: ButtonTextTheme.primary),
        ),
        child: child!,
      );
    },
  );
  if (picked != null) {
    // final formattedDate = 'DateFormat('dd-MM-yyyy').format(picked)';
    controller?.text = 'formattedDate';
  }
}

Widget timeAndDurationTextFieldWidget({
  required TextEditingController controller,
  required void Function()? onTap,
}) {
  return Row(
    children: [
      Expanded(
        child: SizedBox(
          height: 54.h,
          child: TextFormField(
            controller: controller,
            readOnly: true,
            onTap: onTap,
            style: GoogleFonts.plusJakartaSans(
              color: ColorResources.colorBlue800,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              suffixIcon: Icon(
                Icons.timelapse,
                size: 18.h,
                color: ColorResources.colorgrey500,
              ),
              labelText: 'Starting Time',
              labelStyle: GoogleFonts.plusJakartaSans(
                color: ColorResources.colorgrey600,
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
              ),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10.w, horizontal: 10.h),
              fillColor: ColorResources.colorwhite,
              filled: true,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.w),
                borderSide: const BorderSide(color: ColorResources.colorBlack),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.w),
                borderSide:
                    const BorderSide(color: ColorResources.colorgrey300),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.w),
                borderSide:
                    const BorderSide(color: ColorResources.colorgrey200),
              ),
            ),
          ),
        ),
      ),
      SizedBox(
        width: 16.w,
      ),
      Expanded(
          child: SizedBox(
        height: 54.h,
        child: DropdownButtonFormField(
          value: 'Option 1',
          onChanged: (value) {},
          items: ['Option 1', 'Option 2', 'Option 3'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          style: GoogleFonts.plusJakartaSans(
            color: ColorResources.colorBlue800,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            labelText: 'Duration',
            labelStyle: GoogleFonts.plusJakartaSans(
              color: ColorResources.colorgrey600,
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
            ),
            contentPadding:
                EdgeInsets.symmetric(vertical: 10.w, horizontal: 10.h),
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
        ),
      )),
    ],
  );
}

Future<void> selectTime(
    BuildContext context, TextEditingController timeController) async {
  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
    builder: (BuildContext context, Widget? child) {
      return Theme(
        data: ThemeData.light().copyWith(
          primaryColor:
              ColorResources.colorBlue600, // Set your desired primary color
          colorScheme: const ColorScheme.light(
            primary: ColorResources.colorBlue600,
          ), // Adjust your color scheme
          buttonTheme:
              const ButtonThemeData(textTheme: ButtonTextTheme.primary),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    DateTime selectedDateTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      picked.hour,
      picked.minute,
    );

    // timeController.text = DateFormat('hh:mm a').format(selectedDateTime);
  }
}

Widget iconProfileWidget(
    {required String svgIcon,
    double height = 48.0,
    double width = 48.0,
    Color? iconColor,
    Color? bgColor}) {
  return Container(
    height: height.h,
    width: width.h,
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(100.r),
    ),
    child: Center(
      child: SvgPicture.asset(
        svgIcon,
        color: iconColor,
      ),
    ),
  );
}

Widget courseProfileWidget(
    {required String courseName,
    required String batchName,
    required String image,
    required bool isProfile,
    bool showBatchEnd = false,
    String? batchStart,
    String? batchTeacher,
    String? oneOnOneTeacher,
    String? expiryDate,
    String? batchEnd}) {
  return Container(
    // height: 80.h,
    decoration: BoxDecoration(
        color: ColorResources.colorwhite,
        borderRadius: BorderRadius.circular(8)),
    child: Row(
      children: [
        const SizedBox(
          width: 6,
        ),
        Container(
          width: 100.w,
          height: 65.h,
          decoration: BoxDecoration(
              image: DecorationImage(image: CachedNetworkImageProvider(image)),
              borderRadius: BorderRadius.circular(8.r)),
        ),
        const SizedBox(
          width: 6,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  courseName,
                  style: GoogleFonts.plusJakartaSans(
                    color: ColorResources.colorgrey700,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                batchName.isNotEmpty
                    ? Text(
                        '$batchName',
                        style: GoogleFonts.plusJakartaSans(
                          color: ColorResources.colorgrey600,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : const SizedBox(),
                const SizedBox(
                  height: 4,
                ),
                isProfile
                    ? Text(
                        batchStart ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          color: ColorResources.colorgrey600,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : SizedBox(),
                isProfile
                    ? const SizedBox(
                        height: 4,
                      )
                    : SizedBox(),
                isProfile
                    ? showBatchEnd
                        ? Text(
                            batchEnd ?? '',
                            style: GoogleFonts.plusJakartaSans(
                              color: ColorResources.colorgrey600,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : SizedBox()
                    : SizedBox(),
                isProfile
                    ? showBatchEnd
                        ? const SizedBox(
                            height: 4,
                          )
                        : SizedBox()
                    : SizedBox(),
                isProfile
                    ? Text(
                        batchTeacher ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          color: ColorResources.colorgrey600,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : SizedBox(),
                isProfile
                    ? const SizedBox(
                        height: 4,
                      )
                    : SizedBox(),
                isProfile
                    ? Text(
                        oneOnOneTeacher ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          color: ColorResources.colorgrey600,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : SizedBox(),
                isProfile
                    ? const SizedBox(
                        height: 4,
                      )
                    : SizedBox(),
                isProfile
                    ? (expiryDate != null && expiryDate.isNotEmpty)
                        ? Text(
                            expiryDate,
                            style: GoogleFonts.plusJakartaSans(
                              color: ColorResources.colorgrey600,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : SizedBox()
                    : SizedBox(),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
