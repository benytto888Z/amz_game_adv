#pragma once
#include <stdint.h>

// Stockage prive de l'ESP32, versionne ; les autres configurations NVS ne changent pas.
struct AdConfig {
  uint32_t signature, version, generation;
  char texte[101];
  uint8_t luminosite, scroll, icone, effet;
  uint32_t couleur, intervalle, checksum;
};
