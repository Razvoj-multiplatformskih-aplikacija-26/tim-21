String formatDate(DateTime instant) {
  final local = instant.toLocal();
  return '${local.day}. ${local.month}. ${local.year}.';
}
