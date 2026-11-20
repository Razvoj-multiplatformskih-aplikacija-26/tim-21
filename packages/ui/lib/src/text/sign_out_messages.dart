import 'package:blocs/blocs.dart';

import 'failures.dart';

const mobileRoleNotAllowedMessage = 'Aplikacija je za članove biblioteke.';
const backofficeRoleNotAllowedMessage = 'Backoffice je za osoblje biblioteke.';

String? signOutMessage(SignOutReason? reason, {required String roleNotAllowed}) => switch (reason) {
  SignOutReason.expired => sessionExpiredMessage,
  SignOutReason.roleNotAllowed => roleNotAllowed,
  SignOutReason.unreachable => serverUnreachableMessage,
  SignOutReason.loggedOut || null => null,
};
