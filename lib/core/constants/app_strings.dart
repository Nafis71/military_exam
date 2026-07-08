abstract final class AppStrings {
  // App
  static const appName = 'সামরিক পরীক্ষা';
  static const appNameDev = 'সামরিক পরীক্ষা (ডেভ)';
  static const appNameStaging = 'সামরিক পরীক্ষা (স্টেজিং)';
  static const appNameDemo = 'সামরিক পরীক্ষা (ডেমো)';

  // Splash & login
  static const signInSubtitle = 'পরীক্ষার্থীর তথ্য দিয়ে সাইন ইন করুন';
  static const examineeId = 'পরীক্ষার্থী আইডি';
  static const password = 'পাসওয়ার্ড';
  static const signIn = 'সাইন ইন';
  static const notEligible =
      'আপনি এই পরীক্ষার জন্য যোগ্য নন।';

  // Validation
  static const fieldRequired = 'এই ঘরটি আবশ্যক';
  static const examineeIdMinLength =
      'পরীক্ষার্থী আইডি কমপক্ষে ৩ অক্ষরের হতে হবে';
  static const passwordMinLength =
      'পাসওয়ার্ড কমপক্ষে ৪ অক্ষরের হতে হবে';

  // Instructions
  static const rule1Title = 'নিয়ম ১: এয়ারপ্লেন মোড';
  static const rule1Description =
      'পরীক্ষার সময় ফোন কল ও নেটওয়ার্ক বাধা এড়াতে এয়ারপ্লেন মোড অবশ্যই চালু থাকতে হবে। পরীক্ষা চলাকালীন এয়ারপ্লেন মোড বন্ধ করলে তাৎক্ষণিক শাস্তি, স্বয়ংক্রিয় জমা ও পরীক্ষা লক হয়ে যাবে।';
  static const rule2Title = 'নিয়ম ২: স্ক্রিনশট নিষিদ্ধ';
  static const rule2Description =
      'পরীক্ষার সময় স্ক্রিনশট ও স্ক্রিন রেকর্ডিং কঠোরভাবে নিষিদ্ধ। লঙ্ঘন শনাক্ত হলে তাৎক্ষণিক শাস্তি, স্বয়ংক্রিয় জমা ও পরীক্ষা লক হয়ে যাবে।';
  static const rule3Title = 'নিয়ম ৩: অ্যাপে থাকুন';
  static const rule3Description =
      'পরীক্ষা চলাকালীন আপনি অ্যাপ ছোট করা, হোম বাটন, সাম্প্রতিক অ্যাপ বা অন্য অ্যাপে যেতে পারবেন না। লঙ্ঘন হলে তাৎক্ষণিক শাস্তি, স্বয়ংক্রিয় জমা ও পরীক্ষা লক হয়ে যাবে।';
  static const next = 'পরবর্তী';
  static const continueToSecurityCheck = 'নিরাপত্তা পরীক্ষায় যান';

  // Camera permission gate
  static const enableCameraPermission = 'ক্যামেরার অনুমতি প্রয়োজন';
  static const checkingCameraPermissionStatus =
      'ক্যামেরার অনুমতির অবস্থা যাচাই হচ্ছে...';
  static const cameraPermissionGrantedContinue =
      'ক্যামেরার অনুমতি দেওয়া হয়েছে। আপনি পরীক্ষায় যেতে পারেন।';
  static const cameraPermissionMustBeGranted =
      'লিখিত পরীক্ষায় উত্তরের পৃষ্ঠা তুলতে ক্যামেরার অনুমতি প্রয়োজন।';
  static const cameraPermissionPermanentlyDenied =
      'ক্যামেরার অনুমতি বন্ধ আছে। সেটিংস থেকে অনুমতি চালু করুন।';
  static const grantCameraPermission = 'অনুমতি দিন';

  // Security gate
  static const verifyingDeviceSecurity = 'ডিভাইসের নিরাপত্তা যাচাই হচ্ছে';
  static const securityChecksPassed = 'নিরাপত্তা পরীক্ষা সফল';
  static const deviceNotPermitted = 'ডিভাইস অনুমোদিত নয়';
  static const airplaneModeRequired = 'এয়ারপ্লেন মোড প্রয়োজন';
  static const securityCheckFailed = 'নিরাপত্তা পরীক্ষা ব্যর্থ';
  static const checkingDeviceIntegrity =
      'ডিভাইসের অখণ্ডতা ও নেটওয়ার্ক বিচ্ছিন্নতা যাচাই হচ্ছে...';
  static const deviceMeetsRequirements =
      'আপনার ডিভাইস নিরাপত্তার শর্ত পূরণ করেছে।';
  static const enableAirplaneModeBeforeContinuing =
      'চালিয়ে যেতে এয়ারপ্লেন মোড চালু করুন।';
  static const retry = 'আবার চেষ্টা করুন';
  static const integrityCheckFailed = 'অখণ্ডতা পরীক্ষা ব্যর্থ';
  static const airplaneModeCheckFailed = 'এয়ারপ্লেন মোড পরীক্ষা ব্যর্থ';

  // Airplane mode
  static const enableAirplaneMode = 'এয়ারপ্লেন মোড চালু করুন';
  static const checkingAirplaneModeStatus =
      'এয়ারপ্লেন মোডের অবস্থা যাচাই হচ্ছে...';
  static const airplaneModeEnabled = 'এয়ারপ্লেন মোড চালু আছে';
  static const airplaneModeEnabledContinue =
      'এয়ারপ্লেন মোড চালু আছে। কল গ্রহণ বন্ধ আছে। আপনি পরীক্ষায় যেতে পারেন।';
  static const airplaneModeMustBeEnabled =
      'পরীক্ষার সময় কল গ্রহণ রোধ করতে এয়ারপ্লেন মোড চালু করুন।';
  static const unableToVerifyAirplaneMode =
      'এয়ারপ্লেন মোড যাচাই করা যায়নি। আবার চেষ্টা করুন।';
  static const continueAction = 'চালিয়ে যান';
  static const openSettings = 'সেটিংস খুলুন';
  static const refresh = 'রিফ্রেশ';
  static const unableToOpenSettings = 'সেটিংস খোলা যায়নি';
  static const airplaneModeMonitoringFailed =
      'এয়ারপ্লেন মোড পর্যবেক্ষণ ব্যর্থ';
  static const checkingWifiStatus = 'ওয়াইফাই/ইন্টারনেট অবস্থা যাচাই হচ্ছে...';
  static const wifiMustBeEnabled =
      'এয়ারপ্লেন মোড চালু আছে। পরীক্ষা চালিয়ে যেতে ওয়াইফাই চালু করুন।';
  static const enableWifi = 'ওয়াইফাই চালু করুন';
  static const wifiEnabled = 'ওয়াইফাই চালু আছে';
  static const networkConnectedContinue =
      'ওয়াইফাই চালু আছে। আপনি পরীক্ষায় যেতে পারেন।';
  static const unableToVerifyConnectivity =
      'নেটওয়ার্ক সংযোগ যাচাই করা যায়নি। আবার চেষ্টা করুন।';
  static const connectivityCheckFailedWithError =
      'নেটওয়ার্ক সংযোগ পরীক্ষা ব্যর্থ';
  static const connectivityMonitoringFailed =
      'নেটওয়ার্ক সংযোগ পর্যবেক্ষণ ব্যর্থ';

  // Security errors
  static const examinationLocked = 'পরীক্ষা লক করা হয়েছে';
  static const securityViolationDuringExam =
      'পরীক্ষার সময় একটি নিরাপত্তা লঙ্ঘন ঘটেছে।';
  static const sessionUnknown = 'অজানা';

  // Violations
  static const examPenalized = 'আপনাকে শাস্তি দেওয়া হয়েছে';
  static const examAnswersPublished =
      'আপনার উত্তরসমূহ প্রকাশিত হয়েছে এবং পরীক্ষা স্বয়ংক্রিয়ভাবে জমা দেওয়া হয়েছে।';
  static const securityViolation = 'নিরাপত্তা লঙ্ঘন';
  static const examAutoSubmittedLocked =
      'আপনার পরীক্ষা স্বয়ংক্রিয়ভাবে জমা দেওয়া হয়েছে এবং লক করা হয়েছে।';
  static const securityViolationLocked =
      'নিরাপত্তা লঙ্ঘন ঘটেছে। আপনার পরীক্ষা লক করা হয়েছে।';
  static const airplaneModeDisabledDuringExam =
      'পরীক্ষার সময় এয়ারপ্লেন মোড বন্ধ করা হয়েছিল।';
  static const wifiDisabledDuringExam =
      'পরীক্ষার সময় ওয়াইফাই বা ইন্টারনেট সংযোগ বন্ধ করা হয়েছিল।';
  static const appBackgrounded = 'অ্যাপটি ব্যাকগ্রাউন্ডে পাঠানো হয়েছিল।';
  static const appMinimized =
      'অ্যাপটি ছোট করা হয়েছিল বা পরীক্ষার স্ক্রিন থেকে বের হয়ে গেছে।';
  static const screenshotAttemptDetected = 'স্ক্রিনশটের চেষ্টা শনাক্ত হয়েছে।';
  static const screenRecordingDetected = 'স্ক্রিন রেকর্ডিং শনাক্ত হয়েছে।';
  static const rootedDeviceDetected = 'রুট করা ডিভাইস শনাক্ত হয়েছে।';
  static const jailbrokenDeviceDetected = 'জেলব্রোক করা ডিভাইস শনাক্ত হয়েছে।';
  static const developerModeEnabled =
      'এই ডিভাইসে ডেভেলপার মোড চালু আছে।';

  // MCQ exam
  static const multipleChoice = 'বহুনির্বাচনী';
  static const noInternetDuringExam =
      'No internet connection is detected, Please turn on wifi,';
  static const unstableInternetDuringExam =
      'ইন্টারনেট সংযোগ অস্থির। উত্তর স্থানীয়ভাবে সংরক্ষিত থাকবে।';
  static const noQuestionsAvailable = 'কোনো প্রশ্ন পাওয়া যায়নি।';
  static const finishMcq = 'বহুনির্বাচনী শেষ করুন';
  static const questionOf = 'প্রশ্ন'; // used as: প্রশ্ন ১ / ৫
  static const of = '/';

  // Written exam
  static const writtenAnswers = 'লিখিত উত্তর';
  static const captureAnswerPageTooltip = 'উত্তরের পৃষ্ঠা তুলুন';
  static const captureWrittenAnswersHint =
      'হাতে লেখা উত্তরের পৃষ্ঠা তুলতে ক্যামেরা আইকনে ট্যাপ করুন। গ্যালারি অ্যাক্সেস নিষ্ক্রিয়।';
  static const answerPage = 'উত্তরের পৃষ্ঠা';
  static const replace = 'প্রতিস্থাপন';
  static const delete = 'মুছুন';
  static const submitWrittenExam = 'লিখিত পরীক্ষা জমা দিন';
  static const cameraPermissionRequired = 'ক্যামেরার অনুমতি প্রয়োজন।';
  static const cameraPermissionRequiredBeforeExam =
      'পরীক্ষা শুরু করতে ক্যামেরার অনুমতি প্রয়োজন।';
  static const noCameraAvailable = 'এই ডিভাইসে কোনো ক্যামেরা নেই।';

  // Image upload status
  static const uploadStatusLocalOnly = 'শুধু ডিভাইসে';
  static const uploadStatusUploading = 'আপলোড হচ্ছে';
  static const uploadStatusUploaded = 'আপলোড সম্পন্ন';
  static const uploadStatusFailed = 'আপলোড ব্যর্থ';

  // Finish exam
  static const submissionSuccessful = 'জমা সফল';
  static const thankYouCloseApp =
      'পরীক্ষা সম্পন্ন করার জন্য ধন্যবাদ। এখন অ্যাপ বন্ধ করতে পারেন।';

  // Network & errors
  static const networkRequestFailed = 'নেটওয়ার্ক অনুরোধ ব্যর্থ';
  static const requestTimedOut = 'অনুরোধের সময় শেষ';
  static const noInternetConnection = 'ইন্টারনেট সংযোগ নেই';
  static const imageNotFound = 'ছবি পাওয়া যায়নি';
  static const imageFileNotFound = 'ছবির ফাইল পাওয়া যায়নি';
  static const failedToLoadWrittenImages =
      'লিখিত ছবি লোড করা যায়নি';
  static const deviceIntegrityCheckFailed = 'ডিভাইস অখণ্ডতা পরীক্ষা ব্যর্থ';
  static const airplaneModeCheckFailedWithError =
      'এয়ারপ্লেন মোড পরীক্ষা ব্যর্থ';
  static const unableToOpenAirplaneModeSettings =
      'এয়ারপ্লেন মোড সেটিংস খোলা যায়নি';
  static const unableToOpenWifiSettings = 'ওয়াইফাই সেটিংস খোলা যায়নি';

  // Developer mode
  static const disableDeveloperMode = 'ডেভেলপার মোড বন্ধ করুন';
  static const checkingDeveloperModeStatus =
      'ডিভাইসের অখণ্ডতা ও ডেভেলপার মোড যাচাই হচ্ছে...';
  static const developerModeDisabledContinue =
      'ডেভেলপার মোড বন্ধ আছে। আপনি চালিয়ে যেতে পারেন।';
  static const developerModeMustBeDisabled =
      'পরীক্ষার জন্য ডেভেলপার মোড বন্ধ করতে হবে। সেটিংস খুলে বন্ধ করুন, তারপর অ্যাপে ফিরে আসুন।';
  static const unableToVerifyDeveloperMode =
      'ডেভেলপার মোড যাচাই করা যায়নি। আবার চেষ্টা করুন।';
  static const unableToOpenDeveloperModeSettings =
      'ডেভেলপার মোড সেটিংস খোলা যায়নি';

  // Demo / API messages
  static const demoEligibleForExam =
      'ডেমো মোড: পরীক্ষার জন্য যোগ্য।';
  static const demoExamineeNamePrefix = 'ক্যাডেট';
  static const submitted = 'জমা দেওয়া হয়েছে।';
  static const autoSubmittedDemo = 'স্বয়ংক্রিয় জমা (ডেমো মোড)।';
  static const autoSubmittedTimeExpiry =
      'সময় শেষ হওয়ায় স্বয়ংক্রিয় জমা।';
  static const examSubmittedDemo =
      'পরীক্ষা সফলভাবে জমা (ডেমো মোড)।';
  static const examSubmittedSuccessfully =
      'পরীক্ষা সফলভাবে জমা দেওয়া হয়েছে।';
  static const writtenExamSubmittedDemo =
      'লিখিত পরীক্ষা সফলভাবে জমা (ডেমো মোড)।';
  static const writtenExamSubmitted = 'লিখিত পরীক্ষা জমা দেওয়া হয়েছে।';
  static const writtenExamSubmittedSuccessfullyDemo =
      'লিখিত পরীক্ষা সফলভাবে জমা (ডেমো)।';

  // Penalty & storage errors
  static const violationRecorded = 'লঙ্ঘন রেকর্ড করা হয়েছে';
  static const failedToSaveExamSession =
      'পরীক্ষার সেশন সংরক্ষণ করা যায়নি';
  static const failedToReadExamSession =
      'পরীক্ষার সেশন পড়া যায়নি';
  static const failedToSaveMcqAnswer =
      'বহুনির্বাচনী উত্তর সংরক্ষণ করা যায়নি';
  static const failedToReadMcqAnswers =
      'বহুনির্বাচনী উত্তর পড়া যায়নি';
  static const failedToSetLockState = 'লক অবস্থা সেট করা যায়নি';
  static const failedToReadLockState = 'লক অবস্থা পড়া যায়নি';

  // Demo MCQ questions
  static const mcq1Question =
      'সামরিক সালামের প্রধান উদ্দেশ্য কী?';
  static const mcq1OptionA = 'সম্মানের সাথে সহসৈনিকদের অভিবাদন';
  static const mcq1OptionB = 'যুদ্ধে পিছু হটের সংকেত';
  static const mcq1OptionC = 'চিকিৎসা সহায়তা চাওয়া';
  static const mcq1OptionD = 'টহল শেষ চিহ্নিত করা';

  static const mcq2Question =
      'কোন বাহিনী প্রধানত নৌযান পরিচালনা করে?';
  static const mcq2OptionA = 'সেনাবাহিনী';
  static const mcq2OptionB = 'নৌবাহিনী';
  static const mcq2OptionC = 'বায়ুবাহিনী';
  static const mcq2OptionD = 'শুধু কোস্ট গার্ড';

  static const mcq3Question =
      'সামরিক অভিযানে "ROE" সংক্ষিপ্ত রূপের অর্থ কী?';
  static const mcq3OptionA = 'সংলগ্নতার নিয়ম (Rules of Engagement)';
  static const mcq3OptionB = 'সরঞ্জাম প্রতিবেদন';
  static const mcq3OptionC = 'নিয়োগের পদমর্যাদা';
  static const mcq3OptionD = 'উচ্ছেদের পথ';

  static const mcq4Question =
      'কোন নথিতে সেবার সদস্যদের মূল মূল্যবোধ ও নীতি বর্ণিত?';
  static const mcq4OptionA = 'শুধু ফিল্ড ম্যানুয়াল';
  static const mcq4OptionB = 'আচরণ বিধি';
  static const mcq4OptionC = 'সরবরাহ চাহিদাপত্র';
  static const mcq4OptionD = 'ছুটির আবেদন';

  static const mcq5Question =
      'সারিবদ্ধভাবে দাঁড়ানোর সময় সাধারণত "Fall In" কমান কে দেন?';
  static const mcq5OptionA = 'জ্যেষ্ঠ সেনা কর্মকর্তা বা NCO';
  static const mcq5OptionB = 'দায়িত্বরত চিকিৎসক';
  static const mcq5OptionC = 'নতুন নিয়োগপ্রাপ্ত';
  static const mcq5OptionD = 'সরবরাহ কর্মকর্তা';
}
