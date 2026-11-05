#pragma once
#include <stdint.h>

// Definition dans un en-tete pour etre visible avant les prototypes generes
// automatiquement par l'IDE Arduino pour le fichier .ino.
struct Config {
  uint32_t signature, version, generation, cible, margeCs;
  uint32_t facile, difficile, traversee, checksum;
};
