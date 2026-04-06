import 'package:breffini_staff/core/theme/color_resources.dart';
import 'package:breffini_staff/view/widgets/common_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

Widget chatHistoryWidget(
    {required String name,
    required String content,
    required String count,
    required String time,
    required String image,
    void Function()? onTap,
    required String date}) {
  return Column(
    children: [
      ListTile(
        // tileColor: ColorResources.colorBlack,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: CircleAvatar(
            radius: 23.r,
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
        ),
        title: Text(
          name,
          style: GoogleFonts.plusJakartaSans(
            color: ColorResources.colorBlack,
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            content,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: ColorResources.colorgrey600,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              date == 'Today' ? time : date,
              style: GoogleFonts.plusJakartaSans(
                color: ColorResources.colorgrey700,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(
              height: 8.h,
            ),
            count != '0'
                ? Container(
                    height: 20.h,
                    width: 20.h,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorResources.colorBlue500,
                    ),
                    child: Center(
                      child: Text(
                        count,
                        style: GoogleFonts.plusJakartaSans(
                          color: ColorResources.colorwhite,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(),
            // Text(
            //   count,
            //   style: GoogleFonts.plusJakartaSans(
            //     color: ColorResources.colorgrey600,
            //     fontSize: 9.sp,
            //     fontWeight: FontWeight.w700,
            //   ),
            // ),
          ],
        ),
      ),
    ],
  );
}

Widget courseWidget({
  required String name,
  required String content,
  required String image,
}) {
  return Container(
    decoration: BoxDecoration(
        border: Border.all(color: ColorResources.colorgrey300),
        borderRadius: BorderRadius.circular(10.r)),
    height: 85.h,
    child: ListTile(
      tileColor: ColorResources.colorwhite,
      leading: Container(
        width: 75.w,
        height: 60.h,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            color: ColorResources.colorBlack,
            image: DecorationImage(
                image: CachedNetworkImageProvider(image), fit: BoxFit.cover)),
      ),
      title: Text(
        name,
        style: GoogleFonts.plusJakartaSans(
          color: ColorResources.colorBlack,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          content,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            color: ColorResources.colorgrey600,
            fontSize: 10.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      trailing: SizedBox(
        width: 45.w,
        height: 45.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: 0.35,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  ColorResources.colorBlue500),
            ),
            Text(
              '35%',
              style: GoogleFonts.plusJakartaSans(
                color: ColorResources.colorBlack,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget profileTileWidget(
    {required String name,
    required String svgIcon,
    required void Function()? onPressed}) {
  return SizedBox(
      height: 65.h,
      child: Row(
        children: [
          SvgPicture.asset(
            svgIcon,
            height: 25.h,
            width: 25.w,
          ),
          SizedBox(
            width: 16.w,
          ),
          Text(
            name,
            style: GoogleFonts.plusJakartaSans(
              color: ColorResources.colorgrey700,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Expanded(child: SizedBox()),
          IconButton(
              onPressed: onPressed,
              icon: const Icon(
                CupertinoIcons.forward,
                color: ColorResources.colorgrey400,
              ))
        ],
      ));
}

Widget callStudentWidget(
    {required String name,
    required String content,
    required String image,
    required String startTime,
    required String endTime,
    IconData? chatIcon,
    void Function()? avatarTap,
    void Function()? onChatTap}) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 16.w),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        color: ColorResources.colorwhite,
      ),
      child: ListTile(
        // tileColor: ColorResources.colorBlack,
        leading: InkWell(
          onTap: avatarTap,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: CircleAvatar(
              radius: 23.r,
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
          ),
        ),
        title: Text(
          name,
          style: GoogleFonts.plusJakartaSans(
            color: ColorResources.colorBlack,
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),

        subtitle:
            content.isNotEmpty || (startTime.isNotEmpty && endTime.isNotEmpty)
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (content.isNotEmpty)
                          Text(
                            content,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: ColorResources.colorgrey600,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        if (startTime.isNotEmpty && endTime.isNotEmpty)
                          Text(
                            '$startTime - $endTime',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: ColorResources.colorgrey600,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  )
                : Container(),

        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 6.h,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: onChatTap,
                  child: iconProfileWidget(
                      height: 35,
                      width: 35,
                      bgColor: ColorResources.colorBlue400,
                      iconColor: ColorResources.colorwhite,
                      svgIcon: 'assets/images/ic_icon_profile_chat.svg'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
