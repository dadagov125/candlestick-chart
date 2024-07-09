class XAxisOffsetDetails {
  XAxisOffsetDetails({
    required this.offset,
    required this.maxOffset,
    required this.prevOffset,
  });

  final double offset;
  final double maxOffset;
  final double prevOffset;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XAxisOffsetDetails &&
          runtimeType == other.runtimeType &&
          offset == other.offset &&
          maxOffset == other.maxOffset &&
          prevOffset == other.prevOffset;

  @override
  int get hashCode =>
      offset.hashCode ^ maxOffset.hashCode ^ prevOffset.hashCode;

  @override
  String toString() {
    return 'XAxisOffsetDetails{offset: $offset, maxOffset: $maxOffset, prevOffset: $prevOffset}';
  }
}
