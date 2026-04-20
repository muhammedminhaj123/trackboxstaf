import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/model/section_by_course_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class GridviewCategoryWidget extends StatelessWidget {
  final List<SectionByCourseModel> sectionByCourse;
  final int? selectedIndex;
  final void Function(SectionByCourseModel) onDayTapped;
  final bool isTab;
  final VoidCallback? onRecordingTapped;

  const GridviewCategoryWidget({
    Key? key,
    required this.onDayTapped,
    required this.sectionByCourse,
    this.selectedIndex,
    required this.isTab,
    this.onRecordingTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> sectionIcons = [
      "assets/images/listening.png",
      "assets/images/reading.png",
      // "assets/images/writing.png",
      // "assets/images/speaking.png",
    ];

    if (isTab) {
      sectionIcons.add("assets/images/speaking.png"); // Only add recording icon
    }

    return Obx(() {
      final filteredSections = sectionByCourse
          .where((s) => s.sectionName.trim().isNotEmpty)
          .toList();

      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: filteredSections.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          mainAxisExtent: 85,
        ),
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;

          final iconPath = index < sectionIcons.length
              ? sectionIcons[index]
              : "assets/images/listening.png";

          return GestureDetector(
            onTap: () {
              onDayTapped(filteredSections[index]);
            },
            child: Container(
              decoration: BoxDecoration(
                color: ColorResources.colorwhite,
                borderRadius: BorderRadius.circular(8.0),
                border: isSelected
                    ? Border.all(color: Colors.blue, width: 2)
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(iconPath),
                    Text(
                      filteredSections[index].sectionName,
                      style: GoogleFonts.plusJakartaSans(
                        color: ColorResources.colorgrey700,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

void showCustomBottomSheet(BuildContext context) {
  showModalBottomSheet(
    backgroundColor: Color(0xffF4F7FA),
    context: context,
    builder: (BuildContext context) {
      return Container(
        width: Get.width,
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Image.asset('assets/images/lockblue.png', width: 80, height: 80),
            const SizedBox(height: 20),
            Text(
              "Test Locked",
              style: GoogleFonts.plusJakartaSans(
                color: Color(0xff283B52),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "This test is currently locked for students.\nYou can unlock it to allow access.",
              style: GoogleFonts.plusJakartaSans(
                color: Color(0xff6A7487),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
          ],
        ),
      );
    },
  );
}

void showCustomBottomSheet2(BuildContext context) {
  showModalBottomSheet(
    backgroundColor: Color(0xffF4F7FA),
    context: context,
    builder: (BuildContext context) {
      return Container(
        width: Get.width,
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Image.asset('assets/images/lockblue.png', width: 80, height: 80),
            const SizedBox(height: 20),
            Text(
              "Confirm Unlock Test",
              style: GoogleFonts.plusJakartaSans(
                color: Color(0xff283B52),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Are you sure you want to unlock this test? \nOnce unlocked, students will have access.",
              style: GoogleFonts.plusJakartaSans(
                color: Color(0xff6A7487),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100.w),
                  ),
                  backgroundColor: ColorResources.colorBlue500,

                  // side: const BorderSide(
                  //   color: ColorResources
                  //       .colorBlue600, // Define your border color here
                  //   width: 1, // Define your border width here
                  // ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  showCustomBottomSheet3(context);
                },
                child: Text(
                  'Confirm Unlock',
                  style: GoogleFonts.plusJakartaSans(
                    color: ColorResources.colorwhite,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100.w),
                  ),
                  backgroundColor: ColorResources.colorwhite,
                  side: const BorderSide(
                    color: Color(0xffBAC1CA), // Define your border color here
                    width: 1, // Define your border width here
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(
                    color: ColorResources.colorBlue600,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    },
  );
}

void showCustomBottomSheet3(BuildContext context) {
  showModalBottomSheet(
    backgroundColor: Color(0xffF4F7FA),
    context: context,
    builder: (BuildContext context) {
      return Container(
        width: Get.width,
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/Done.png', width: 150, height: 150),
            Text(
              "Test Unlocked",
              style: GoogleFonts.plusJakartaSans(
                color: Color(0xff283B52),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "The test is now unlocked and \nis accessible to students.",
              style: GoogleFonts.plusJakartaSans(
                color: Color(0xff6A7487),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100.w),
                  ),
                  backgroundColor: ColorResources.colorBlue500,

                  // side: const BorderSide(
                  //   color: ColorResources
                  //       .colorBlue600, // Define your border color here
                  //   width: 1, // Define your border width here
                  // ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Done',
                  style: GoogleFonts.plusJakartaSans(
                    color: ColorResources.colorwhite,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    },
  );
}
