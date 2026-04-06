class TeacherProfileModel {
  int userId;
  String firstName;
  String lastName;
  String email;
  String phoneNumber;
  int deleteStatus;
  int userTypeId;
  int userActiveStatus;

  dynamic userRoleId;
  dynamic userStatus;
  dynamic otp;
  String password;
  String profilePhotoPath;
  String profilePhotoName;
  String? gMeetLink;
  String? registeredDate;

  TeacherProfileModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.deleteStatus,
    required this.userTypeId,
    required this.userRoleId,
    required this.userStatus,
    required this.otp,
    required this.password,
    required this.profilePhotoPath,
    required this.profilePhotoName,
    required this.userActiveStatus,
    this.gMeetLink,
    this.registeredDate,
  });

  factory TeacherProfileModel.fromJson(Map<String, dynamic> json) =>
      TeacherProfileModel(
          userActiveStatus: json["User_Active_Status"] ?? 0,
          userId: json["User_ID"],
          firstName: json["First_Name"],
          lastName: json["Last_Name"],
          email: json["Email"],
          phoneNumber: json["PhoneNumber"],
          deleteStatus: json["Delete_Status"],
          userTypeId: json["User_Type_Id"],
          userRoleId: json["User_Role_Id"],
          userStatus: json["User_Status"],
          otp: json["OTP"],
          password: json["password"],
          profilePhotoPath: json["Profile_Photo_Path"] ?? '',
          profilePhotoName: json["Profile_Photo_Name"] ?? '',
          gMeetLink: json["Live_Link"] ?? '',
          registeredDate: json["Registered_Date"] ?? '');

  Map<String, dynamic> toJson() => {
        "User_ID": userId,
        "User_Active_Status": userActiveStatus,
        "First_Name": firstName,
        "Last_Name": lastName,
        "Email": email,
        "PhoneNumber": phoneNumber,
        "Delete_Status": deleteStatus,
        "User_Type_Id": userTypeId,
        "User_Role_Id": userRoleId,
        "User_Status": userStatus,
        "OTP": otp,
        "password": password,
        "Profile_Photo_Path": profilePhotoPath,
        "Profile_Photo_Name": profilePhotoName,
        "Live_Link": gMeetLink,
        "Registered_Date": registeredDate,
      };
}
