#pragma once

#include <stdint.h>
#include "CalendrierCampagne.h"

struct AgendaConfig {
  uint32_t signature;
  uint32_t version;
  uint32_t generation;

  RegleCampagne regle;

  uint8_t actif;
  uint32_t checksum;
};