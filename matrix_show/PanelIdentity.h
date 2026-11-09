#pragma once

#include <Arduino.h>
#include <stdint.h>
#include <stdio.h>

// Identifiant stable dérivé de l'adresse MAC eFuse de l'ESP32.
// Ce code est public : ce n'est ni un mot de passe ni une preuve d'identité.
// Remplacer l'ESP32 change l'identifiant ; un doublon ou une usurpation
// restent possibles. Ne pas l'utiliser pour autoriser des commandes.
inline String identifiantPanneau() {
  const uint64_t mac = ESP.getEfuseMac() & 0x0000FFFFFFFFFFFFULL;
  char texte[17];  // "AMZ-" + 12 caractères hexadécimaux + '\0'.
  snprintf(texte, sizeof texte, "AMZ-%04X%08lX",
           static_cast<unsigned int>((mac >> 32) & 0xFFFFU),
           static_cast<unsigned long>(mac & 0xFFFFFFFFUL));
  return String(texte);
}