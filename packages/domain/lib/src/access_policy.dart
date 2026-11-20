import 'loan/loan.dart';
import 'user.dart';

abstract final class AccessPolicy {
  static bool canView(User user, Loan loan) => user.role == Role.librarian || _isOwn(user, loan);

  static bool canRequest(User user) => user.role == Role.member;

  static bool canCancel(User user, Loan loan) => user.role == Role.member && _isOwn(user, loan);

  static bool canDecide(User user) => user.role == Role.librarian;

  static bool canUseMobile(User user) => user.role == Role.member;

  static bool canUseBackoffice(User user) => user.role == Role.librarian;

  static bool _isOwn(User user, Loan loan) => loan.memberId.value == user.id.value;
}
