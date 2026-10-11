import 'package:paypadi/core/utils/enums.dart';
import 'package:paypadi/data/transaction/models/beneficiary_model.dart';
import 'package:paypadi/data/transaction/models/transaction_model.dart';

/// Stand-in rows for skeleton loading while the real lists load.
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
    createdAt: DateTime.now().subtract(Duration(days: index + 2)),
    updatedAt: DateTime.now().subtract(Duration(hours: index * 3)),
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
    createdAt: DateTime.now().subtract(Duration(days: index, hours: index + 1)),
    senderName: index.isEven ? 'PayPadi Wallet' : 'GTBank Card',
    recipientName: index.isEven ? 'Tunde Adebayo' : 'PayPadi Wallet',
    transactionFee: index.isEven ? '15' : '0',
  ),
);
