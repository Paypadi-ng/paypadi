import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:paypadi/config/gen/assets.gen.dart';
import 'package:paypadi/config/gen/colors.gen.dart';
import 'package:paypadi/core/models/beneficiary_model/beneficiary_model.dart';
import 'package:paypadi/core/models/transaction_model/transaction_model.dart';
import 'package:paypadi/core/utils/enums.dart';
import 'package:talker_flutter/talker_flutter.dart';

class Values {
  static const double zero = 0.0;
  static const double v1 = 1.0;
  static const double v2 = 2.0;
  static const double v4 = 4.0;
  static const double v6 = 6.0;
  static const double v8 = 8.0;
  static const double v10 = 10.0;
  static const double v12 = 12.0;
  static const double v14 = 14.0;
  static const double v16 = 16.0;
  static const double v18 = 18.0;
  static const double v20 = 20.0;
  static const double v24 = 24.0;
  static const double v28 = 28.0;
  static const double v32 = 32.0;
  static const double v36 = 36.0;
  static const double v48 = 48.0;
  static const double v64 = 64.0;
  static const double v72 = 72.0;
  static const double v84 = 84.0;
  static const double v92 = 92.0;
  static const double v96 = 96.0;
  static const double v108 = 108.0;
  static const double v120 = 120.0;
  static const double v136 = 136.0;
  static const double v150 = 150.0;
}

const int transactionPinLength = 4;

const int passwordPinLength = 6;

const double kZeroLetterSpacing = 0.0;

const double kVeryTightLetterSpacing = -0.43;

const Size appDesignSize = Size(393, 852);

final Size kButtonSize = Size(362.w, 48.h);

const Size kButtonMediumSize = Size(158, 48);

const Size kButtonSmallSize = Size(125, 32);

const Size kAppBarSize = Size(double.infinity, 56);

const Duration animatedFooDuration = Durations.medium4;

const String kDemoProfilePic =
    'https://images.unsplash.com/photo-1590086782957-93c06ef21604?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8d2hpdGUlMjBtYWxlfGVufDB8fDB8fHww';

const String placeholder = 'Placeholder';

const String placeholderShort = 'Placeholder Short';

const String placeholderLong = 'Placeholder Text Long';

const List<Color> availableColors = [
  AppColors.primary,
  AppColors.blueThemeColor,
  AppColors.pinkThemeColor,
  AppColors.orangeThemeColor,
  AppColors.lightGreenThemeColor,
];

final Map<String, String> onboardingStoryAndAsset = {
  'Pay Seamlessly with your wallet—No More Change Wahala!':
      AppAssets.images.storyOne.path,
  'Exact Payments, No More Change Drama!': AppAssets.images.storyTwo.path,
  'Your ‘Last Card’ Just Got Smarter': AppAssets.images.storyThree.path,
};

final List<String> kAppKeyPadKeys = [
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  '.',
  '0',
  'x',
];

final List<BeneficiaryModel> kMockBeneficiaries = List.generate(
  5,
  (index) => BeneficiaryModel(
    id: 'beneficiary_$index',
    type: index.isEven ? 'User' : 'Merchant',
    accountNumber: '01234567${(10 + index).toString()}',
    accountName: [
      'Adaeze Okafor',
      'Tunde Adebayo',
      'Zainab Bello',
      'Chinedu Eze',
      'Temitope Lawal',
    ][index],
    bankName: ['First Bank', 'GT Bank', 'Opay', 'UBA', 'Zenith'][index],
    bankCode: ['058', '044', '033', '011', '232'][index],
    isVerified: index != 3,
    createdAt: DateTime.now()
        .subtract(Duration(days: index + 2))
        .toIso8601String(),
    updatedAt: DateTime.now()
        .subtract(Duration(hours: index * 3))
        .toIso8601String(),
  ),
);

final List<TransactionHistoryModel> kMockTransactionHistory = List.generate(
  10,
  (index) => TransactionHistoryModel(
    id: 'txn_$index',
    amount: (1500 + (index * 750)).toString(),
    status: index.isEven
        ? TransactionStatus.success
        : TransactionStatus.pending,
    reference: 'PAYPADI-REF-${100000 + index}',
    description: index.isEven
        ? 'Wallet transfer to beneficiary'
        : 'Wallet funding from bank card',
    metadata: TransactionHistoryMetadata(
      receipientAccount: '01234567${(index % 10).toString().padLeft(2, '0')}',
      receipientBankCode: '058',
      isPinVerified: index.isEven,
    ),
    type: index.isEven ? TransactionType.transfer : TransactionType.deposit,
    createdAt: DateTime.now()
        .subtract(Duration(days: index, hours: index + 1))
        .toIso8601String(),
    senderName: index.isEven ? 'PayPadi Wallet' : 'GTBank Card',
    recipientName: index.isEven ? 'Tunde Adebayo' : 'PayPadi Wallet',
    transactionFee: index.isEven ? '15' : '0',
  ),
);

final Talker debugLogger = TalkerFlutter.init(
  settings: TalkerSettings(
    colors: {
      TalkerKey.route: AnsiPen()..cyan(),
      TalkerKey.error: AnsiPen()..magenta(),
      TalkerKey.debug: AnsiPen()..white(),
      TalkerKey.info: AnsiPen()..rgb(r: 100 / 255, g: 181 / 255, b: 246 / 255),
      TalkerKey.riverpodAdd: AnsiPen()
        ..rgb(r: 129 / 255, g: 212 / 255, b: 250 / 255),
      TalkerKey.riverpodUpdate: AnsiPen()..rgb(g: 214 / 255, b: 165 / 255),
      TalkerKey.riverpodFail: AnsiPen()
        ..rgb(r: 171 / 255, g: 235 / 255, b: 198 / 255),
      TalkerKey.riverpodDispose: AnsiPen()..rgb(g: 171 / 255, b: 145 / 255),
      TalkerKey.httpRequest: AnsiPen()..rgb(g: 235 / 255, b: 59 / 255),
      TalkerKey.httpResponse: AnsiPen()
        ..rgb(r: 0 / 255, g: 188 / 255, b: 212 / 255),
      TalkerKey.httpError: AnsiPen()
        ..rgb(r: 239 / 255, g: 83 / 255, b: 80 / 255),
    },
  ),
);

class CacheKeys {
  static const String darkMode = 'dark_mode';
  static const String biometrics = 'biometrics';
  static const String inAppColor = 'in_app_color';

  static const String accessToken = 'session_access_token';
  static const String refreshToken = 'session_refresh_token';
  static const String refreshTokenExpiry =
      'session_refresh_token_expiry_duration';
  static const String accessTokenExpiry =
      'session_access_token_expiry_duration';

  static const String firstName = 'user_first_name';
  static const String email = 'user_email';
  static const String password = 'user_password';
  static const String phoneNumber = 'user_phone_number';
  static const String transactionPin = 'user_transaction_pin';
}
