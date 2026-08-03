class Constant {
  // static String baseUrl = 'http://114.143.140.28:8020/';
  //this is public ip hosted on 25 serve r
  static String baseUrl = 'http://114.143.140.28:8020/';

  static String loginUrl = baseUrl + 'Users/GetLoginData?';
  static String staffDetailsUrl = baseUrl + 'api/GatePass/GetStaffDetails/';
  static String getPendinggatePassUrl =
      baseUrl + 'api/GatePass/GetPendingGatePass?StaffCode=';

  static String addGatepass = baseUrl + 'api/GatePass/SubmitGatePass';

  static String cancelGatepass = baseUrl + 'api/GatePass/CancelGatePass';

  static String getAllVisitData = baseUrl + 'api/Visit/GetAllVisit/';

  static String getVisitLatLongList =
      baseUrl + 'api/Visit/GetLatitudeLongitude/';

  static String getAllUsers = baseUrl + 'Users/GetAllUsers';

  static String requestDataDeletion = baseUrl + 'Users/UpdateIsDeletedFlag?';

  static String getVisitByFromDateToDate =
      baseUrl + 'api/Visit/GetVisitByFromDateToDate/';

  static String getVisitRecords = baseUrl + 'api/Visit/GetVisitRecords?';
  static String getleavestaffdetailsUrl =
      baseUrl + 'api/Leave/GetStaffDataForLeave/';
  static String getpendingleaveUrl = baseUrl + 'api/Leave/GetLeavePendingData?';
  static String getleavetypelistUrl = baseUrl + 'api/Leave/GetLeaveDetails?';
  static String submitleaveUrl = baseUrl + 'api/Leave/LeaveApplicationForm';
  static String cancelleaveUrl = baseUrl + 'api/Leave/CancelLeave';

  static String userinfo = baseUrl + 'Users/GetUserInfoByStaffCode?';
  static String updateuserinfo = baseUrl + 'api/Profile/UpdateProfile';

  static String approvesanction =
      baseUrl + 'api/SanctionAll/SanctionAllScreen/';

  static String submitapprovesanction =
      baseUrl + 'api/SanctionAll/SubmitSanctionOrRejectData';

  static String addStaffEntry = baseUrl + 'api/Track/AddNewTrackingStaff';

  static String deleteStaffEntry = baseUrl + 'Users/DeleteUserByStaffCode';

  static String GetStaffDetailsForCoff =
      baseUrl + 'api/Coff/GetStaffDetailsForCoff';

  static String SubmitCoff = baseUrl + 'api/Coff/SubmitCoff';
  static String FetchCoffTransactions =
      baseUrl + 'api/Coff/FetchCoffTransactions';
  static String CancelCoffOTHWOFF = baseUrl + 'api/Coff/CancelCoffOTHWOFF';

  static String GetCoffsTransactions =
      baseUrl + 'api/CoffDebit/GetCoffsTransactions';

  static String CancelCoff = baseUrl + 'api/CoffDebit/CancelCoff';
  static String SubmitCoffDebit = baseUrl + 'api/CoffDebit/SubmitCoffDebit';
  static String InsertMMData = baseUrl + 'api/MinutesOfMeeting/InsertMMData';
  static String InsertMMALLData =
      baseUrl + 'api/MinutesOfMeeting/InsertMMAllData';
  static String UpdateMeetingFormNo =
      baseUrl + 'api/MinutesOfMeeting/UpdateMeetingFormNo/';
  static String GetMinutesOfMeetingFormNo =
      baseUrl + 'api/MinutesOfMeeting/GetMinutesOfMeetingFormNo/';
  static String GetMinutesOfTheMeetingAllDataByVisitSrNo =
      baseUrl + 'api/MinutesOfMeeting/MinutesOfTheMeetingAllDataByVisitSrNo/';

  static String UpdateMMAllData =
      baseUrl + 'api/MinutesOfMeeting/UpdateMMAllData';
  static String UpdateMMData = baseUrl + 'api/MinutesOfMeeting/UpdateMMData';

  static String GetMinutesOfTheMeetingDataByVisitSrNo =
      baseUrl + 'api/MinutesOfMeeting/MinutesOfTheMeetingDataByVisitSrNo/';

  static String fetchcancellationURl =
      baseUrl + 'api/CancellationRequest/FetchRecords';
  static String submitOTcancellation =
      baseUrl + 'api/CancellationRequest/SaveDataOT';
  static String submitleavecancellationUrl =
      baseUrl + 'api/CancellationRequest/SaveDataLeave';
  static String submitgatepasscancellationUrl =
      baseUrl + 'api/CancellationRequest/SaveDataGatePass';
  static String submitcoffcancellationUrl =
      baseUrl + 'api/CancellationRequest/SaveDataCOffCredit';
  static String submitcdebitcancellationUrl =
      baseUrl + 'api/CancellationRequest/SaveDataCOffDebit';
  static String submittourcancellationUrl =
      baseUrl + 'api/CancellationRequest/SaveDataTour';
  static String expensesubmit = baseUrl + 'api/Expense/InsertExpense';

  static String getstafftourdetails =
      baseUrl + 'api/Tour/GetStaffDetailsForTour?StaffCode=';
  static String submittourdetails = baseUrl + 'api/Tour/SubmitTour';
  static String getAppliedTour =
      baseUrl + 'api/Tour/TourTransactions?staffcode=';
  static String canceltour = baseUrl + 'api/Tour/CancelTour?';
  static String viewexpensedetails =
      baseUrl + 'api/Expense/GetExpenseData?staffcode=';
  static String remotelocationrequest =
      baseUrl + 'Users/UpdateRemoteLocationValues';
  static String acceptremotelocation = baseUrl + 'Users/ChangeAddress';
  static String showremotelocation = baseUrl + 'Users/ShowRemoteLocation';
  static String nondistancecheckrequest = baseUrl + 'Users/DistanceCheck';
  static String updateuuid = baseUrl + 'Users/UpdateUUID/';
  static String updateatsflag = baseUrl + 'Users/UpdateATSCheckFlag/';

  static String searchbystaffcode = baseUrl + 'Users/GetUserDataByDetails/';
  static String pageinitiationalluserlist =
      baseUrl + 'Users/GetAllUsersByPagination/';

  static String addMultiRemoteLocation =
      baseUrl + 'Users/PostMultiRemoteLocation';
  static String getMultiRemoteLocation =
      baseUrl + 'Users/GetMultiRemoteLocationByStaffCode';
  static String deleteMultiRemoteLocation =
      baseUrl + 'Users/DeleteMultiRemoteLocation';
  static String updateMultiRemoteLocation =
      baseUrl + 'Users/PutMultiRemoteLocation';
}
