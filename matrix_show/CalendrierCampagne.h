#pragma once
#include <stdint.h>
#include <time.h>

// Une période calendaire et un créneau commun aux jours cochés.
// Jours : bit 0 = lundi, ..., bit 6 = dimanche.
// Heure de fin exclusive ; un créneau ne traverse pas minuit.
struct RegleCampagne {
  uint32_t debutDate;   // AAAAMMJJ, inclus
  uint32_t finDate;     // AAAAMMJJ, inclus
  uint16_t debutMinute; // 0..1439
  uint16_t finMinute;   // 1..1440, exclue
  uint8_t jours;        // masque lundi..dimanche
};

inline bool dateCampagneValide(uint32_t date) {
  const unsigned annee = date / 10000;
  const unsigned mois = (date / 100) % 100;
  const unsigned jour = date % 100;

  if (annee < 2000 || annee > 2099 ||
      mois < 1 || mois > 12 || jour < 1) {
    return false;
  }

  const uint8_t longueurs[] = {
    31, 28, 31, 30, 31, 30,
    31, 31, 30, 31, 30, 31
  };

  unsigned maximum = longueurs[mois - 1];

  if (mois == 2 &&
      annee % 4 == 0 &&
      (annee % 100 != 0 || annee % 400 == 0)) {
    maximum++;
  }

  return jour <= maximum;
}

inline bool regleCampagneValide(const RegleCampagne &r) {
  return dateCampagneValide(r.debutDate) &&
         dateCampagneValide(r.finDate) &&
         r.debutDate <= r.finDate &&
         r.debutMinute < 1440 &&
         r.finMinute <= 1440 &&
         r.debutMinute < r.finMinute &&
         r.jours > 0 &&
         (r.jours & 0x80) == 0;
}

inline bool campagneDansPlage(
    const RegleCampagne &r,
    const struct tm &local
) {
  if (!regleCampagneValide(r) ||
      local.tm_wday < 0 ||
      local.tm_wday > 6 ||
      local.tm_hour < 0 ||
      local.tm_hour > 23 ||
      local.tm_min < 0 ||
      local.tm_min > 59) {
    return false;
  }

  const uint32_t date =
      (uint32_t)(local.tm_year + 1900) * 10000UL +
      (uint32_t)(local.tm_mon + 1) * 100UL +
      (uint32_t)local.tm_mday;

  if (!dateCampagneValide(date) ||
      date < r.debutDate ||
      date > r.finDate) {
    return false;
  }

  const unsigned jourLundi = (local.tm_wday + 6) % 7;

  if ((r.jours & (1u << jourLundi)) == 0) {
    return false;
  }

  const unsigned minute = local.tm_hour * 60 + local.tm_min;

  return minute >= r.debutMinute &&
         minute < r.finMinute;
}