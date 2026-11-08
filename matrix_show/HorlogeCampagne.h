#pragma once

#include <stdint.h>
#include <time.h>

// Horloge volatile : update() doit être appelée régulièrement
// par loop().
//
// Le téléphone fournit explicitement la borne de validité et
// au plus une transition de fuseau. Au-delà, une nouvelle
// synchronisation est requise.
class HorlogeCampagne {
 public:
  bool synchroniser(
      int64_t utc,
      int32_t offsetActuel,
      int64_t transitionUtc,
      int32_t offsetSuivant,
      int64_t valideJusquaUtc,
      uint32_t maintenantMs
  ) {
    const int64_t minUtc = 946684800LL;   // 2000-01-01 UTC
    const int64_t maxUtc = 4102444800LL;  // 2100-01-01 UTC exclu

    if (utc < minUtc ||
        utc >= maxUtc ||
        valideJusquaUtc <= utc ||
        valideJusquaUtc > maxUtc ||
        valideJusquaUtc - utc > 400LL * 86400 ||
        offsetActuel < -64800 ||
        offsetActuel > 64800 ||
        offsetSuivant < -64800 ||
        offsetSuivant > 64800 ||
        (transitionUtc != 0 &&
         (transitionUtc <= utc ||
          transitionUtc >= valideJusquaUtc))) {
      return false;
    }

    utcMs_ = utc * 1000;
    dernierMs_ = maintenantMs;
    borneUtc_ = valideJusquaUtc;
    transitionUtc_ = transitionUtc;
    offsetActuel_ = offsetActuel;
    offsetSuivant_ = offsetSuivant;
    synchronisee_ = true;

    return true;
  }

  void update(uint32_t maintenantMs) {
    if (!synchronisee_) return;

    // La soustraction non signée gère le débordement de millis(),
    // à condition que update() soit appelée régulièrement.
    utcMs_ += uint32_t(maintenantMs - dernierMs_);
    dernierMs_ = maintenantMs;

    if (utcMs_ / 1000 >= borneUtc_) {
      synchronisee_ = false;
    }
  }

  bool heureLocale(struct tm &resultat) const {
    if (!synchronisee_) return false;

    const int64_t utc = utcMs_ / 1000;

    const int32_t offset =
        transitionUtc_ != 0 && utc >= transitionUtc_
            ? offsetSuivant_
            : offsetActuel_;

    const int64_t local = utc + offset;
    time_t valeur = static_cast<time_t>(local);

    if (static_cast<int64_t>(valeur) != local) {
      return false;
    }

    return gmtime_r(&valeur, &resultat) != nullptr;
  }

  bool fiable() const {
    return synchronisee_;
  }

 private:
  bool synchronisee_ = false;

  int64_t utcMs_ = 0;
  int64_t borneUtc_ = 0;
  int64_t transitionUtc_ = 0;

  uint32_t dernierMs_ = 0;

  int32_t offsetActuel_ = 0;
  int32_t offsetSuivant_ = 0;
};