#pragma once
#include <stdint.h>
#include "AdConfig.h"

// Format persisté versionné, distinct de la publicité individuelle.
constexpr uint8_t PLAYLIST_MAX = 5;

struct PlaylistConfig {
  uint32_t signature;
  uint32_t version;
  uint32_t generation;
  uint32_t dureeSecondes;
  uint32_t nombre;

  AdConfig messages[PLAYLIST_MAX];

  uint32_t checksum;
};