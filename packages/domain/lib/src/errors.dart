// Every rule failure is a subclass here, so a switch without a default branch
// in the apps lists each error that needs a Serbian message.
sealed class DomainError {
  const DomainError();
}
