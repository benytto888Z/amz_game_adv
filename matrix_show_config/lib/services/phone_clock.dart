/// Construit une synchronisation bornée à partir du fuseau actuel
/// du téléphone.
///
/// Un changement de fuseau sur le téléphone exige une nouvelle
/// synchronisation.
class PhoneClock {
  static Map<String, int> snapshot() {
    final utc =
        DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

    int offsetAt(int seconds) =>
        DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000,
          isUtc: true,
        ).toLocal().timeZoneOffset.inSeconds;

    final offset = offsetAt(utc);

    // Sept jours maximum ; le téléphone doit resynchroniser
    // avant expiration.
    var deadline = utc + 7 * 86400;

    // L'heure fournie par la plateforme est sondée toutes les minutes.
    // Si une transition est détectée, la validité s'arrête à cette
    // transition.
    var previous = utc;

    for (var probe = utc + 60; probe <= deadline; probe += 60) {
      if (offsetAt(probe) != offset) {
        var lo = previous;
        var hi = probe;

        while (hi - lo > 1) {
          final mid = lo + (hi - lo) ~/ 2;

          if (offsetAt(mid) == offset) {
            lo = mid;
          } else {
            hi = mid;
          }
        }

        deadline = hi;
        break;
      }

      previous = probe;
    }

    return <String, int>{
      'utc_s': utc,
      'offset_s': offset,
      'transition_s': 0,
      'next_offset_s': offset,
      'valid_until_s': deadline,
    };
  }
}

// Fonction de premier niveau pour compute().
Map<String, int> phoneClockSnapshot(int _) => PhoneClock.snapshot();