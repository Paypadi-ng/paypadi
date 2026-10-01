import 'package:flutter_test/flutter_test.dart';
import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/models/account_payout_model/account_payout_model.dart';
import 'package:paypadi/core/models/transaction_model/transaction_model.dart';
import 'package:paypadi/core/models/user_profile_model/user_profile_model.dart';
import 'package:paypadi/core/utils/enums.dart';
import 'package:paypadi/core/utils/helpers.dart';

// Sample bodies follow the Swagger schemas at /api/v1/swagger, including the
// fields they mark as nullable or optional.

Map<String, dynamic> _transaction({
  String type = 'transfer',
  Object? description = 'Lunch',
  bool includeMetadata = true,
}) => {
  'id': '7c9e6679-7425-40de-944b-e07fc1f90ae7',
  'amount': '1500.00',
  'transaction_type': type,
  'status': 'success',
  'reference': 'PPD-123',
  'description': description,
  if (includeMetadata) 'metadata': {'pin_verified': true},
  'created_at': '2026-10-01T09:00:00Z',
  'recipient_phone': '+2348031234567',
  'recipient_account_number': '0123456789',
  'recipient_bank_code': '058',
  'sender_name': 'Ada Obi',
  'recipient_name': 'Tunde Bello',
  'fee_amount': '10.00',
};

Map<String, dynamic> _userDetail({
  Object? referralCode = 'ADA123',
  Object? totalReferrals = 3,
  Object? isDriver = false,
}) => {
  'id': 'b7d1c2e4-0000-4000-8000-000000000000',
  'phone_number': '+2348031234567',
  'first_name': 'Ada',
  'last_name': 'Obi',
  'email': null,
  'role': 'rider',
  'is_active': true,
  'verified_phone': true,
  'is_driver': isDriver,
  'date_joined': '2026-10-01T09:00:00Z',
  'last_login': null,
  'kyc_status': 'none',
  'referral_code': referralCode,
  'total_referrals': totalReferrals,
};

void main() {
  group('TransactionHistoryModel', () {
    test('parses a transaction with no description or metadata', () {
      final transaction = TransactionHistoryModel.fromJson(
        _transaction(description: null, includeMetadata: false),
      );

      expect(transaction.description, isNull);
      expect(transaction.metadata, isNull);
      expect(transaction.amount, '1500.00');
    });

    test('recognises every transaction type the API sends', () {
      const apiTypes = {
        'deposit': TransactionType.deposit,
        'withdrawal': TransactionType.withdrawal,
        'transfer': TransactionType.transfer,
        'refund': TransactionType.refund,
        'reversal': TransactionType.reversal,
        'fee': TransactionType.fee,
        'reservation': TransactionType.reservation,
        'adjustment': TransactionType.adjustment,
      };

      for (final MapEntry(key: apiType, value: expected) in apiTypes.entries) {
        expect(
          TransactionHistoryModel.fromJson(_transaction(type: apiType)).type,
          expected,
          reason: apiType,
        );
      }
    });

    test('maps a type it does not know to unknown', () {
      expect(
        TransactionHistoryModel.fromJson(_transaction(type: 'cashback')).type,
        TransactionType.unknown,
      );
    });
  });

  group('TransactionType direction', () {
    test('credits, debits and holds', () {
      expect(
        [for (final type in TransactionType.values) (type, type.isCredit)],
        [
          (TransactionType.transfer, false),
          (TransactionType.deposit, true),
          (TransactionType.withdrawal, false),
          (TransactionType.refund, true),
          (TransactionType.reversal, true),
          (TransactionType.fee, false),
          (TransactionType.reservation, null),
          (TransactionType.adjustment, null),
          (TransactionType.unknown, null),
        ],
      );
    });

    test('labels the counterparty by direction', () {
      expect(getTransactionDirectionLabel(TransactionType.refund), 'From');
      expect(getTransactionDirectionLabel(TransactionType.fee), 'To');
      expect(getTransactionDirectionLabel(TransactionType.adjustment), '?');
    });
  });

  group('DriverProfileModel', () {
    test('parses a new driver who has not added a vehicle yet', () {
      final profile = DriverProfileModel.fromJson({
        'id': 12,
        'vehicle_make': null,
        'vehicle_model': null,
        'vehicle_year': null,
        'driver_license_number': null,
        'driver_license_expiry': null,
        'license_plate': null,
        'license_front': null,
        'license_back': null,
        'vehicle_registration': null,
        'submitted_for_approval': false,
        'is_approved': false,
        'approved_at': null,
        'rejection_reason': null,
        'is_available': false,
        'rating': '0.00',
        'total_rides': 0,
        'created_at': '2026-10-01T09:00:00Z',
        'updated_at': '2026-10-01T09:00:00Z',
      });

      expect(profile.vehicleMake, isNull);
      expect(profile.vehicleYear, isNull);
      expect(profile.licensePlate, isNull);
      expect(profile.submittedForApproval, isFalse);
    });
  });

  group('AccountPayoutModel', () {
    test('parses a mobile-money account with no bank', () {
      final account = AccountPayoutModel.fromJson({
        'id': 4,
        'account_type': 'mobile_money',
        'account_name': 'Ada Obi',
        'account_number': '08031234567',
        'bank_name': null,
        'bank_code': null,
        'is_primary': true,
        'is_verified': false,
        'created_at': '2026-10-01T09:00:00Z',
        'updated_at': '2026-10-01T09:00:00Z',
      });

      expect(account.bankName, isNull);
      expect(account.bankCode, isNull);
    });
  });

  group('UserProfileModel', () {
    test('parses a user without a referral code', () {
      final user = UserProfileModel.fromJson(_userDetail(referralCode: null));

      expect(user.referralCode, isNull);
    });

    test('reads total_referrals as a number or a numeric string', () {
      expect(UserProfileModel.fromJson(_userDetail()).totalReferrals, 3);
      expect(
        UserProfileModel.fromJson(
          _userDetail(totalReferrals: '7'),
        ).totalReferrals,
        7,
      );
    });

    test('reads is_driver as a bool or a "true"/"false" string', () {
      expect(UserProfileModel.fromJson(_userDetail()).isDriver, isFalse);
      expect(
        UserProfileModel.fromJson(_userDetail(isDriver: 'true')).isDriver,
        isTrue,
      );
    });
  });

  group('RequestOtpResponse', () {
    test('parses the documented body, which has no otp', () {
      final response = RequestOtpResponse.fromJson({
        'detail': 'OTP sent',
        'expires_in': 300,
      });

      expect(response.expiresIn, 300);
      expect(response.otp, isNull);
    });
  });
}
