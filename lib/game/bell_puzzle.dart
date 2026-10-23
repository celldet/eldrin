/// The bell-ringing puzzle in the Hollow Choir.
///
/// The correct order is recorded in the Salt Archive's ledger: Heart, Root,
/// Sky. A wrong note unravels the sequence immediately.
class BellPuzzle {
  const BellPuzzle._();

  static const List<String> order = ['bell_heart', 'bell_root', 'bell_sky'];

  static const Map<String, String> notes = {
    'bell_heart': 'The HEART bell sings a round, warm note that you feel in your chest.',
    'bell_root': 'The ROOT bell answers with a deep note, which you feel in the soles of your feet.',
    'bell_sky': 'The SKY bell rings a high, clean note that seems to climb out of the roof.',
  };

  static const String wrong =
      'The note clashes with the hush. The hall shudders; the three bells shiver and fall quiet, and the song unravels. You will have to begin again.';

  static const String solved =
      'The third note rises and meets the first two, and for a moment the whole hall sings in one voice. The seam of silence in the bronze door unzips, and the door swings wide.';

  /// Whether [sequence] is a (possibly complete) prefix of the correct order.
  static bool isPrefix(List<String> sequence) {
    if (sequence.length > order.length) return false;
    for (var i = 0; i < sequence.length; i++) {
      if (sequence[i] != order[i]) return false;
    }
    return true;
  }

  static bool isComplete(List<String> sequence) =>
      sequence.length == order.length && isPrefix(sequence);
}
