#include <Adafruit_GFX.h>
#include <Adafruit_NeoMatrix.h>
#include <Adafruit_NeoPixel.h>
#include <esp_system.h>
#include <Preferences.h>
#include <WiFi.h>
#include <ESPmDNS.h>
#include <WebSocketsServer.h>
#include <ArduinoJson.h>

#include "Config.h"
#include "AdConfig.h"
#include "bluesmiley24.h"

constexpr int PIN_LED = 18;
constexpr int PIN_JEU = 26;
constexpr int PIN_MODE = 27;
constexpr int PIN_SON = 13;

constexpr uint8_t LUMINOSITE = 20;

uint32_t CIBLE_CS = 1000;
uint32_t marge = 0;

constexpr uint32_t MAX_MS = 5999990UL;

constexpr uint8_t MATRIX_MAPPING =
    NEO_MATRIX_TOP +
    NEO_MATRIX_LEFT +
    NEO_MATRIX_COLUMNS +
    NEO_MATRIX_ZIGZAG;

constexpr neoPixelType MATRIX_LED_TYPE =
    NEO_GRB + NEO_KHZ800;

constexpr uint32_t SCROLL_INTERVAL_MS = 70;

Adafruit_NeoMatrix matrix(
    32,
    8,
    PIN_LED,
    MATRIX_MAPPING,
    MATRIX_LED_TYPE
);

// Chiffres 3 × 7.
const uint8_t chiffres[10][7] = {
    {7, 5, 5, 5, 5, 5, 7},
    {2, 6, 2, 2, 2, 2, 7},
    {7, 1, 1, 7, 4, 4, 7},
    {7, 1, 1, 7, 1, 1, 7},
    {5, 5, 5, 7, 1, 1, 1},
    {7, 4, 4, 7, 1, 1, 7},
    {7, 4, 4, 7, 5, 5, 7},
    {7, 1, 1, 1, 1, 1, 1},
    {7, 5, 5, 7, 5, 5, 7},
    {7, 5, 5, 7, 1, 1, 7}
};

struct Bouton {
  int pin;
  bool precedent = HIGH;
  bool stable = HIGH;
  uint32_t change = 0;

  bool appui(uint32_t now) {
    bool v = digitalRead(pin);

    if (v != precedent) {
      precedent = v;
      change = now;
    }

    if (v != stable && uint32_t(now - change) >= 30) {
      stable = v;
      return stable == LOW;
    }

    return false;
  }
};

Bouton jeu{PIN_JEU};
Bouton mode{PIN_MODE};

enum Etat {
  PRET,
  EN_COURS,
  RESULTAT,
  CAPTURE,
  VICTOIRE
};

constexpr uint32_t DUREE_CAPTURE_MS = 3000;
uint32_t debutCapture = 0;
Etat etat = PRET;

// Le mode d'affichage est choisi par l'application.
// Après redémarrage, le panneau démarre en mode Game.
enum ModeAffichage {
  MODE_GAME,
  MODE_ADVERTISING
};

ModeAffichage modeAffichage = MODE_GAME;

enum ModeJeu {
  FACILE,
  DIFFICILE,
  SMILEY
};

ModeJeu modeJeu = FACILE;

bool sonActif = false;

uint32_t TRAVERSEE_MS = 1000;

uint32_t couleurFacile = 0x00FF00;
uint32_t couleurDifficile = 0xFF0000;

int cadreX = 16;

constexpr int CADRE_Y = 0;
constexpr int SMILEY_Y = CADRE_Y + 1;

int smileyX = -5;

uint32_t depart = 0;
uint32_t resultat = 0;
uint32_t dernierAffichage = 0;
uint32_t derniereSeconde = 0;
uint32_t sonDebut = 0;
uint32_t sonDuree = 0;
uint32_t dernierScroll = 0;

int scrollX = 32;
char message[48];

const unsigned notesVictoire[] = {
    1047,
    1319,
    1568,
    2093
};

const uint32_t dureesVictoire[] = {
    120,
    120,
    120,
    300
};

const uint8_t nombreNotes =
    sizeof(notesVictoire) / sizeof(notesVictoire[0]);

const uint32_t DUREE_MELODIE_MS = 5000;

uint8_t prochaineNote = 0;
uint8_t appuisResetVictoire = 0;

uint32_t debutMelodie = 0;
bool melodieTerminee = false;

// ------------------------------------------------------------
// Publicité
// ------------------------------------------------------------

char textePub[101] = "AMZ-IT";

uint32_t couleurPub = 0x00ffff;
uint32_t intervallePub = 70;

// Icônes originales 5 × 5.
// L'identifiant est partagé avec l'application.
// 0 = aucune.
const uint8_t iconesPub[4][5] = {
    {0, 0, 0, 0, 0},
    {10, 31, 31, 14, 4},
    {14, 21, 17, 21, 14},
    {4, 21, 14, 31, 10}
};

uint8_t iconePub = 0;
uint8_t effetPub = 0;
uint8_t phaseEffetPub = 0;

uint32_t dernierEffetPub = 0;

const uint32_t couleursEffetPub[] = {
    0xff0000,
    0xff8000,
    0xffff00,
    0x00ff00,
    0x00ffff,
    0x0000ff,
    0xff00ff
};

// Limite logicielle : 20 / 255.
uint8_t luminositePub = 20;

bool scrollPub = true;
bool pubSale = true;

enum EtatPub {
  PUB_STOP,
  PUB_PLAY,
  PUB_PAUSE
};

EtatPub etatPub = PUB_STOP;

int positionPub = 32;
uint32_t dernierPub = 0;

// Stockage publicitaire indépendant des réglages Game.
Preferences stockagePub;

bool stockagePubPret = false;
bool pubSauvee = false;

int slotPub = -1;
uint32_t generationPub = 0;

AdConfig dernierePub = {};

void valeursPub(JsonDocument &d) {
  d["texte"] = textePub;
  d["couleur_rgb"] = couleurPub;
  d["intervalle_ms"] = intervallePub;
  d["luminosite"] = luminositePub;
  d["scroll"] = scrollPub;
  d["icone"] = iconePub;
  d["effet"] = effetPub;

  d["lecture"] =
      etatPub == PUB_PLAY
          ? "play"
          : etatPub == PUB_PAUSE
                ? "pause"
                : "stop";

  d["sauvegarde"] = pubSauvee;
  d["stockage_disponible"] = stockagePubPret;
}

// Double emplacement : le dernier emplacement valide reste
// disponible pendant l'écriture du suivant.
const uint32_t SIGNATURE_PUB = 0x414D5A50;
const uint32_t VERSION_PUB = 1;

uint32_t checksumPub(const AdConfig &c) {
  uint32_t h = 2166136261UL;

  const uint32_t nombres[] = {
      c.signature,
      c.version,
      c.generation,
      c.luminosite,
      c.scroll,
      c.icone,
      c.effet,
      c.couleur,
      c.intervalle
  };

  for (uint32_t v : nombres) {
    for (int i = 0; i < 4; i++) {
      h ^= (v >> (8 * i)) & 255;
      h *= 16777619UL;
    }
  }

  for (size_t i = 0; i < sizeof c.texte; i++) {
    h ^= (uint8_t)c.texte[i];
    h *= 16777619UL;
  }

  return h;
}

bool pubValide(const AdConfig &c) {
  if (c.signature != SIGNATURE_PUB ||
      c.version != VERSION_PUB ||
      c.checksum != checksumPub(c) ||
      !memchr(c.texte, '\0', sizeof c.texte) ||
      c.texte[0] == '\0' ||
      c.couleur > 0xffffff ||
      c.intervalle < 20 ||
      c.intervalle > 500 ||
      c.luminosite < 1 ||
      c.luminosite > 20 ||
      c.scroll > 1 ||
      c.icone > 3 ||
      c.effet > 2) {
    return false;
  }

  for (size_t i = 0; c.texte[i]; i++) {
    if ((uint8_t)c.texte[i] < 32 ||
        (uint8_t)c.texte[i] > 126) {
      return false;
    }
  }

  return true;
}

bool lireSlotPub(const char *cle, AdConfig &c) {
  return stockagePub.getBytesLength(cle) == sizeof c &&
         stockagePub.getBytes(cle, &c, sizeof c) == sizeof c &&
         pubValide(c);
}

void chargerPub() {
  if (!stockagePubPret) return;

  AdConfig a = {};
  AdConfig b = {};

  bool va = lireSlotPub("pub0", a);
  bool vb = lireSlotPub("pub1", b);

  if (!va && !vb) {
    Serial.println("Aucune publicite sauvegardee valide.");
    return;
  }

  if (va && (!vb || (int32_t)(a.generation - b.generation) > 0)) {
    dernierePub = a;
    slotPub = 0;
  } else {
    dernierePub = b;
    slotPub = 1;
  }

  generationPub = dernierePub.generation;
  pubSauvee = true;

  strlcpy(
      textePub,
      dernierePub.texte,
      sizeof textePub
  );

  couleurPub = dernierePub.couleur;
  intervallePub = dernierePub.intervalle;
  luminositePub = dernierePub.luminosite;
  scrollPub = dernierePub.scroll != 0;
  iconePub = dernierePub.icone;
  effetPub = dernierePub.effet;

  positionPub = scrollPub ? 32 : 0;
  phaseEffetPub = 0;
  dernierEffetPub = millis();

  etatPub = PUB_PLAY;
  pubSale = true;

  Serial.println(
      "Publicite restauree ; en attente du mode Advertising."
  );
}

bool enregistrerPub() {
  if (!stockagePubPret) return false;

  AdConfig c = {};

  c.signature = SIGNATURE_PUB;
  c.version = VERSION_PUB;
  c.generation = generationPub + 1;

  strlcpy(c.texte, textePub, sizeof c.texte);

  c.couleur = couleurPub;
  c.intervalle = intervallePub;
  c.luminosite = luminositePub;
  c.scroll = scrollPub ? 1 : 0;
  c.icone = iconePub;
  c.effet = effetPub;
  c.checksum = checksumPub(c);

  if (!pubValide(c)) return false;

  // Ne pas réécrire si les données sauvegardées sont identiques
  // et que l'emplacement peut toujours être relu.
  if (pubSauvee &&
      strcmp(c.texte, dernierePub.texte) == 0 &&
      c.couleur == dernierePub.couleur &&
      c.intervalle == dernierePub.intervalle &&
      c.luminosite == dernierePub.luminosite &&
      c.scroll == dernierePub.scroll &&
      c.icone == dernierePub.icone &&
      c.effet == dernierePub.effet) {
    AdConfig verifie = {};

    if (lireSlotPub(slotPub == 0 ? "pub0" : "pub1", verifie) &&
        memcmp(&verifie, &dernierePub, sizeof verifie) == 0) {
      return true;
    }
  }

  int cible = slotPub == 0 ? 1 : 0;
  const char *cle = cible == 0 ? "pub0" : "pub1";

  if (stockagePub.putBytes(cle, &c, sizeof c) != sizeof c) {
    return false;
  }

  AdConfig verifie = {};

  if (!lireSlotPub(cle, verifie) ||
      memcmp(&c, &verifie, sizeof c) != 0) {
    return false;
  }

  dernierePub = verifie;
  slotPub = cible;
  generationPub = verifie.generation;
  pubSauvee = true;

  return true;
}

void afficherPub() {
  matrix.setBrightness(luminositePub);
  matrix.fillScreen(0);

  matrix.setFont();
  matrix.setTextSize(1);
  matrix.setTextWrap(false);

  if (effetPub == 1 && phaseEffetPub % 2 == 1) {
    matrix.show();
    return;
  }

  const uint32_t rgbEffet =
      effetPub == 2
          ? couleursEffetPub[phaseEffetPub % 7]
          : couleurPub;

  const uint16_t couleur = matrix.Color(
      (rgbEffet >> 16) & 255,
      (rgbEffet >> 8) & 255,
      rgbEffet & 255
  );

  matrix.setTextColor(couleur);

  const int x = scrollPub ? positionPub : 0;

  if (iconePub != 0) {
    for (int y = 0; y < 5; y++) {
      for (int dx = 0; dx < 5; dx++) {
        if (iconesPub[iconePub][y] & (1 << (4 - dx))) {
          matrix.drawPixel(x + dx, y + 1, couleur);
        }
      }
    }
  }

  matrix.setCursor(x + (iconePub ? 6 : 0), 0);
  matrix.print(textePub);
  matrix.show();
}

void actualiserPub(uint32_t now) {
  // Aucun rendu publicitaire en mode Game.
  if (modeAffichage != MODE_ADVERTISING ||
      etat != PRET ||
      etatPub == PUB_STOP) {
    dernierEffetPub = now;
    return;
  }

  bool redessiner = pubSale;

  if (etatPub == PUB_PLAY) {
    if (effetPub != 0 &&
        uint32_t(now - dernierEffetPub) >= 1000) {
      phaseEffetPub = (phaseEffetPub + 1) % 7;

      if (effetPub == 1) {
        phaseEffetPub %= 2;
      }

      dernierEffetPub = now;
      redessiner = true;
    }

    if (scrollPub &&
        !pubSale &&
        uint32_t(now - dernierPub) >= intervallePub) {
      --positionPub;

      if (positionPub <=
          -(int)(strlen(textePub) * 6 + (iconePub ? 6 : 0))) {
        positionPub = 32;
      }

      dernierPub = now;
      redessiner = true;
    }
  } else {
    dernierEffetPub = now;
  }

  if (redessiner) {
    afficherPub();
    pubSale = false;
  }
}

// ------------------------------------------------------------
// Jeu
// ------------------------------------------------------------

void son(uint32_t now, unsigned freq, uint32_t duree) {
  tone(PIN_SON, freq);
  sonActif = true;
  sonDebut = now;
  sonDuree = duree;
}

void arreterSon() {
  noTone(PIN_SON);
  sonActif = false;
}

void chiffre(int n, int x, uint16_t c) {
  for (int y = 0; y < 7; y++) {
    for (int dx = 0; dx < 3; dx++) {
      if (chiffres[n][y] & (1 << (2 - dx))) {
        matrix.drawPixel(x + dx, y, c);
      }
    }
  }
}

void afficherTemps(uint32_t ms) {
  if (ms > MAX_MS) ms = MAX_MS;

  uint32_t cs = ms / 10;

  int m = cs / 6000;
  int s = (cs / 100) % 60;
  int c = cs % 100;

  uint32_t rgb =
      modeJeu == DIFFICILE
          ? couleurDifficile
          : couleurFacile;

  uint16_t couleur = matrix.Color(
      (rgb >> 16) & 255,
      (rgb >> 8) & 255,
      rgb & 255
  );

  matrix.fillScreen(0);

  chiffre(m / 10, 3, couleur);
  chiffre(m % 10, 7, couleur);

  matrix.drawPixel(11, 2, couleur);
  matrix.drawPixel(11, 5, couleur);

  chiffre(s / 10, 13, couleur);
  chiffre(s % 10, 17, couleur);

  matrix.drawPixel(21, 6, couleur);

  chiffre(c / 10, 23, couleur);
  chiffre(c % 10, 27, couleur);

  matrix.show();
}

void afficherSmiley(int x, bool visible) {
  matrix.fillScreen(0);
  matrix.drawRect(
      cadreX,
      CADRE_Y,
      7,
      7,
      matrix.Color(0, 0, 255)
  );

  if (visible) {
    for (int y = 0; y < 5; y++) {
      for (int dx = 0; dx < 5; dx++) {
        uint8_t ligne = pgm_read_byte(&smiley5x5[y]);

        if (ligne & (1 << (4 - dx))) {
          matrix.drawPixel(
              x + dx,
              SMILEY_Y + y,
              matrix.Color(255, 255, 0)
          );
        }
      }
    }
  }

  matrix.show();
}

void afficherPret() {
  if (modeJeu == SMILEY) {
    afficherSmiley(-5, false);
  } else {
    afficherTemps(0);
  }
}

void demarrerMelodie(uint32_t now) {
  son(now, notesVictoire[0], dureesVictoire[0]);

  prochaineNote = 1;
  appuisResetVictoire = 0;
  debutMelodie = now;
  melodieTerminee = false;

  Serial.println("Victoire : 3 appuis pour reinitialiser.");
}

bool estGagnant(uint32_t ms) {
  uint32_t tempsCS = ms / 10;

  uint32_t ecart =
      tempsCS >= CIBLE_CS
          ? tempsCS - CIBLE_CS
          : CIBLE_CS - tempsCS;

  return marge == 0 ? ecart == 0 : ecart < marge;
}

void victoire(uint32_t ms) {
  uint32_t cs = ms / 10;

  snprintf(
      message,
      sizeof(message),
      "BRAVO ! GAGNE : %02lu:%02lu.%02lu ",
      (unsigned long)(cs / 6000),
      (unsigned long)((cs / 100) % 60),
      (unsigned long)(cs % 100)
  );

  scrollX = 32;
  dernierScroll = millis() - SCROLL_INTERVAL_MS;
  etat = VICTOIRE;
}

// ------------------------------------------------------------
// Configuration Game et Wi-Fi
// ------------------------------------------------------------

Preferences stockage;
Preferences identifiants;

WebSocketsServer serveur(81);

String nomReseau;
bool wifiActif = false;

const uint32_t SIGNATURE = 0x414D5A47;
const uint32_t VERSION_CONFIG = 1;

int emplacement = -1;
uint32_t generation = 0;

char ligneSerie[96];
size_t longueurSerie = 0;
bool ligneTropLongue = false;

uint32_t checksumConfig(const Config &c) {
  const uint32_t mots[] = {
      c.signature,
      c.version,
      c.generation,
      c.cible,
      c.margeCs,
      c.facile,
      c.difficile,
      c.traversee
  };

  uint32_t h = 2166136261UL;

  for (uint32_t mot : mots) {
    for (int i = 0; i < 4; i++) {
      h ^= (mot >> (8 * i)) & 255;
      h *= 16777619UL;
    }
  }

  return h;
}

bool configValide(const Config &c) {
  return c.signature == SIGNATURE &&
         c.version == VERSION_CONFIG &&
         c.cible <= 599999 &&
         c.margeCs <= 599999 &&
         c.facile <= 0xFFFFFF &&
         c.difficile <= 0xFFFFFF &&
         c.traversee >= 100 &&
         c.traversee <= 60000 &&
         c.checksum == checksumConfig(c);
}

void appliquer(const Config &c) {
  CIBLE_CS = c.cible;
  marge = c.margeCs;
  couleurFacile = c.facile;
  couleurDifficile = c.difficile;
  TRAVERSEE_MS = c.traversee;
  generation = c.generation;
}

Config configCourante() {
  Config c = {
      SIGNATURE,
      VERSION_CONFIG,
      generation,
      CIBLE_CS,
      marge,
      couleurFacile,
      couleurDifficile,
      TRAVERSEE_MS,
      0
  };

  c.checksum = checksumConfig(c);
  return c;
}

void chargerConfig() {
  Config a = {};
  Config b = {};

  bool va =
      stockage.getBytesLength("cfg0") == sizeof(Config) &&
      stockage.getBytes("cfg0", &a, sizeof a) == sizeof a &&
      configValide(a);

  bool vb =
      stockage.getBytesLength("cfg1") == sizeof(Config) &&
      stockage.getBytes("cfg1", &b, sizeof b) == sizeof b &&
      configValide(b);

  if (va && (!vb || (int32_t)(a.generation - b.generation) > 0)) {
    appliquer(a);
    emplacement = 0;
  } else if (vb) {
    appliquer(b);
    emplacement = 1;
  } else {
    Serial.println(
        "Aucune configuration valide : valeurs par defaut utilisees."
    );
  }
}

bool enregistrer(Config c) {
  c.signature = SIGNATURE;
  c.version = VERSION_CONFIG;
  c.generation = generation + 1;
  c.checksum = checksumConfig(c);

  if (!configValide(c)) return false;

  int cibleSlot = emplacement == 0 ? 1 : 0;
  const char *cle = cibleSlot == 0 ? "cfg0" : "cfg1";

  if (stockage.putBytes(cle, &c, sizeof c) != sizeof c) {
    return false;
  }

  Config verifie = {};

  if (stockage.getBytes(cle, &verifie, sizeof verifie) != sizeof verifie ||
      !configValide(verifie) ||
      memcmp(&c, &verifie, sizeof c) != 0) {
    return false;
  }

  appliquer(verifie);
  emplacement = cibleSlot;

  return true;
}

void afficherConfig() {
  Serial.printf(
      "cible=%lu centiemes | marge=%lu centiemes | facile=#%06lX | "
      "difficile=#%06lX | traversee=%lu ms\n",
      (unsigned long)CIBLE_CS,
      (unsigned long)marge,
      (unsigned long)couleurFacile,
      (unsigned long)couleurDifficile,
      (unsigned long)TRAVERSEE_MS
  );
}

bool configurerWifi(const char *motDePasse);

void commande(const char *s) {
  if (strcmp(s, "etat") == 0) {
    afficherConfig();
    return;
  }

  if (strcmp(s, "aide") == 0) {
    Serial.println(
        "etat | cible N | marge N | facile R G B | "
        "difficile R G B | vitesse N"
    );
    Serial.println(
        "wifi MOT_DE_PASSE (sans espaces, 8..63 caracteres)"
    );
    Serial.println(
        "cible/marge en centiemes ; vitesse en ms "
        "(100..60000). Reglage seulement si PRET."
    );
    return;
  }

  if (etat != PRET) {
    Serial.println("ERREUR : jeu non pret, remettre a zero.");
    return;
  }

  char wifiPass[64] = {};
  char surplus;

  if (strncmp(s, "wifi ", 5) == 0) {
    if (sscanf(s, "wifi %63s %c", wifiPass, &surplus) != 1 ||
        !configurerWifi(wifiPass)) {
      Serial.println(
          "ERREUR : configuration Wi-Fi impossible ou codes invalides."
      );
    }

    return;
  }

  Config c = configCourante();

  unsigned long n = 0;
  unsigned long r = 0;
  unsigned long g = 0;
  unsigned long b = 0;

  char fin;

  if (sscanf(s, "cible %lu %c", &n, &fin) == 1 &&
      n <= 599999) {
    c.cible = n;
  } else if (
      sscanf(s, "marge %lu %c", &n, &fin) == 1 &&
      n <= 599999) {
    c.margeCs = n;
  } else if (
      sscanf(s, "vitesse %lu %c", &n, &fin) == 1 &&
      n >= 100 &&
      n <= 60000) {
    c.traversee = n;
  } else if (
      sscanf(s, "facile %lu %lu %lu %c", &r, &g, &b, &fin) == 3 &&
      r <= 255 &&
      g <= 255 &&
      b <= 255) {
    c.facile = (r << 16) | (g << 8) | b;
  } else if (
      sscanf(s, "difficile %lu %lu %lu %c", &r, &g, &b, &fin) == 3 &&
      r <= 255 &&
      g <= 255 &&
      b <= 255) {
    c.difficile = (r << 16) | (g << 8) | b;
  } else {
    Serial.println(
        "ERREUR : commande ou valeurs invalides. Tapez aide."
    );
    return;
  }

  Config avant = configCourante();

  if (c.cible == avant.cible &&
      c.margeCs == avant.margeCs &&
      c.facile == avant.facile &&
      c.difficile == avant.difficile &&
      c.traversee == avant.traversee) {
    Serial.println("Inchange : aucune ecriture flash.");
    return;
  }

  if (enregistrer(c)) {
    Serial.println("OK : enregistre et verifie.");
    afficherConfig();

    if (modeAffichage == MODE_GAME) {
      afficherPret();
    } else {
      pubSale = true;
    }
  } else {
    Serial.println(
        "ERREUR : sauvegarde non confirmee ; "
        "reglages en RAM inchanges."
    );
  }
}

void lireSerie() {
  while (Serial.available()) {
    char c = Serial.read();

    if (c == '\n' || c == '\r') {
      if (ligneTropLongue) {
        Serial.println("ERREUR : ligne trop longue.");
      } else if (longueurSerie) {
        ligneSerie[longueurSerie] = '\0';
        commande(ligneSerie);
      }

      longueurSerie = 0;
      ligneTropLongue = false;
    } else if (!ligneTropLongue) {
      if (longueurSerie < sizeof(ligneSerie) - 1) {
        ligneSerie[longueurSerie++] = c;
      } else {
        ligneTropLongue = true;
      }
    }
  }
}

// ------------------------------------------------------------
// WebSocket
// Attention : non authentifié et non chiffré.
// Réservé aux essais sur réseau de confiance.
// ------------------------------------------------------------

void remplirConfig(JsonDocument &d) {
  d["cible_cs"] = CIBLE_CS;
  d["marge_cs"] = marge;
  d["facile_rgb"] = couleurFacile;
  d["difficile_rgb"] = couleurDifficile;
  d["traversee_ms"] = TRAVERSEE_MS;
}

bool champEntier(
    JsonObjectConst d,
    const char *cle,
    uint32_t min,
    uint32_t max,
    uint32_t &out
) {
  if (!d[cle].is<uint32_t>()) return false;

  uint32_t v = d[cle].as<uint32_t>();

  if (v < min || v > max) return false;

  out = v;
  return true;
}

void traiterSocket(
    uint8_t client,
    WStype_t type,
    uint8_t *payload,
    size_t length
) {
  if (type != WStype_TEXT) return;

  JsonDocument reponse;
  reponse["version"] = 1;

  JsonDocument entree;

  if (length > 512 ||
      deserializeJson(entree, payload, length) ||
      !entree.is<JsonObject>()) {
    reponse["type"] = "error";
    reponse["code"] = "invalid_json";
  } else {
    const char *id = entree["id"] | "";

    if (strlen(id) > 40) {
      reponse["type"] = "error";
      reponse["code"] = "invalid_id";
    } else {
      reponse["id"] = id;

      const char *action = entree["type"] | "";

      if (strcmp(action, "get_capabilities") == 0) {
        reponse["type"] = "capabilities";

        reponse["matrix"]["width"] = 32;
        reponse["matrix"]["height"] = 8;

        reponse["features"]["game"] = true;
        reponse["features"]["advertising"] = true;
        reponse["features"]["playlist"] = false;
        reponse["features"]["scheduler"] = false;

        reponse["security"]["authentication"] = false;
        reponse["security"]["transport_encrypted"] = false;

      } else if (strcmp(action, "get_status") == 0) {
        reponse["type"] = "status";

        reponse["etat"] =
            etat == PRET
                ? "pret"
                : etat == EN_COURS
                      ? "en_cours"
                      : etat == CAPTURE
                            ? "capture"
                            : etat == VICTOIRE
                                  ? "victoire"
                                  : "resultat";

        reponse["mode"] =
            modeJeu == FACILE
                ? "facile"
                : modeJeu == DIFFICILE
                      ? "difficile"
                      : "smiley";

        reponse["dernier_temps_ms"] = resultat;

        reponse["display_mode"] =
            modeAffichage == MODE_GAME
                ? "game"
                : "advertising";

      } else if (strcmp(action, "set_display_mode") == 0) {
        const char *val = entree["action"] | "";

        if (strcmp(val, "game") != 0 &&
            strcmp(val, "advertising") != 0) {
          reponse["type"] = "error";
          reponse["code"] = "invalid_mode";
        } else {
          ModeAffichage demande =
              strcmp(val, "game") == 0
                  ? MODE_GAME
                  : MODE_ADVERTISING;

          if (demande != modeAffichage) {
            // Le changement annule la partie et la mélodie.
            // Les réglages restent conservés.
            arreterSon();
            melodieTerminee = true;
            appuisResetVictoire = 0;
            etat = PRET;

            modeAffichage = demande;
            matrix.setBrightness(LUMINOSITE);

            if (modeAffichage == MODE_GAME) {
              afficherPret();
            } else {
              matrix.fillScreen(0);
              matrix.show();
              pubSale = true;
            }
          }

          reponse["type"] = "display_mode_changed";

          reponse["display_mode"] =
              modeAffichage == MODE_GAME
                  ? "game"
                  : "advertising";

          reponse["etat"] =
              etat == PRET
                  ? "pret"
                  : etat == EN_COURS
                        ? "en_cours"
                        : etat == CAPTURE
                              ? "capture"
                              : etat == VICTOIRE
                                    ? "victoire"
                                    : "resultat";
        }

      } else if (strcmp(action, "get_live_ad") == 0) {
        reponse["type"] = "live_ad";
        valeursPub(reponse);

      } else if (strcmp(action, "set_live_ad") == 0) {
        JsonObjectConst p =
            entree["config"].as<JsonObjectConst>();

        uint32_t rgb = 0;
        uint32_t vitesse = 0;
        uint32_t lum = 0;
        uint32_t icone = 0;
        uint32_t effet = 0;

        const char *text = p["texte"] | "";

        size_t n = strlen(text);
        bool ascii = n > 0 && n <= 100;

        for (size_t i = 0; i < n && ascii; i++) {
          if ((unsigned char)text[i] < 32 ||
              (unsigned char)text[i] > 126) {
            ascii = false;
          }
        }

        if (modeAffichage != MODE_ADVERTISING) {
          reponse["type"] = "error";
          reponse["code"] = "not_advertising";
        } else if (etat != PRET) {
          reponse["type"] = "error";
          reponse["code"] = "game_busy";
        } else if (
            p.isNull() ||
            (p.size() != 5 && p.size() != 6 && p.size() != 7) ||
            !p["scroll"].is<bool>() ||
            !ascii ||
            (p.size() >= 6 &&
             !champEntier(p, "icone", 0, 3, icone)) ||
            (p.size() == 7 &&
             !champEntier(p, "effet", 0, 2, effet)) ||
            !champEntier(p, "couleur_rgb", 0, 0xffffff, rgb) ||
            !champEntier(p, "intervalle_ms", 20, 500, vitesse) ||
            !champEntier(p, "luminosite", 1, 20, lum)) {
          reponse["type"] = "error";
          reponse["code"] = "invalid_config";
        } else {
          strlcpy(textePub, text, sizeof textePub);

          couleurPub = rgb;
          intervallePub = vitesse;
          luminositePub = lum;
          iconePub = icone;
          effetPub = effet;
          phaseEffetPub = 0;
          dernierEffetPub = millis();
          scrollPub = p["scroll"].as<bool>();
          positionPub = scrollPub ? 32 : 0;
          pubSale = true;

          reponse["type"] = "live_ad_configured";
          valeursPub(reponse);
        }

      } else if (strcmp(action, "save_live_ad") == 0) {
        if (modeAffichage != MODE_ADVERTISING) {
          reponse["type"] = "error";
          reponse["code"] = "not_advertising";
        } else if (etat != PRET) {
          reponse["type"] = "error";
          reponse["code"] = "game_busy";
        } else if (!stockagePubPret) {
          reponse["type"] = "error";
          reponse["code"] = "ad_storage_unavailable";
        } else if (!enregistrerPub()) {
          reponse["type"] = "error";
          reponse["code"] = "ad_storage_uncertain";
        } else {
          reponse["type"] = "live_ad_saved";
          valeursPub(reponse);
        }

      } else if (strcmp(action, "live_ad_action") == 0) {
        const char *cmd = entree["action"] | "";

        if (modeAffichage != MODE_ADVERTISING) {
          reponse["type"] = "error";
          reponse["code"] = "not_advertising";
        } else if (etat != PRET) {
          reponse["type"] = "error";
          reponse["code"] = "game_busy";
        } else if (strcmp(cmd, "play") == 0) {
          etatPub = PUB_PLAY;
          pubSale = true;
          reponse["type"] = "live_ad_state";
          valeursPub(reponse);
        } else if (strcmp(cmd, "pause") == 0 &&
                   etatPub != PUB_STOP) {
          etatPub = PUB_PAUSE;
          pubSale = true;
          reponse["type"] = "live_ad_state";
          valeursPub(reponse);
        } else if (strcmp(cmd, "stop") == 0) {
          etatPub = PUB_STOP;
          matrix.fillScreen(0);
          matrix.show();
          reponse["type"] = "live_ad_state";
          valeursPub(reponse);
        } else {
          reponse["type"] = "error";
          reponse["code"] = "invalid_action";
        }

      } else if (strcmp(action, "get_config") == 0) {
        reponse["type"] = "config";
        remplirConfig(reponse);

      } else if (strcmp(action, "set_config") == 0) {
        Config c = configCourante();

        JsonObjectConst params =
            entree["config"].as<JsonObjectConst>();

        if (etat != PRET) {
          reponse["type"] = "error";
          reponse["code"] = "game_busy";
        } else if (
            params.isNull() ||
            params.size() != 5 ||
            !champEntier(params, "cible_cs", 0, 599999, c.cible) ||
            !champEntier(params, "marge_cs", 0, 599999, c.margeCs) ||
            !champEntier(params, "facile_rgb", 0, 0xFFFFFF, c.facile) ||
            !champEntier(
                params,
                "difficile_rgb",
                0,
                0xFFFFFF,
                c.difficile
            ) ||
            !champEntier(
                params,
                "traversee_ms",
                100,
                60000,
                c.traversee
            )) {
          reponse["type"] = "error";
          reponse["code"] = "invalid_config";
        } else {
          Config old = configCourante();

          bool identique =
              c.cible == old.cible &&
              c.margeCs == old.margeCs &&
              c.facile == old.facile &&
              c.difficile == old.difficile &&
              c.traversee == old.traversee;

          if (!identique && !enregistrer(c)) {
            reponse["type"] = "error";
            reponse["code"] = "storage_error";
          } else {
            if (modeAffichage == MODE_GAME) {
              afficherPret();
            } else {
              pubSale = true;
            }

            reponse["type"] = "config_applied";
            remplirConfig(reponse);
          }
        }

      } else {
        reponse["type"] = "error";
        reponse["code"] = "unknown_action";
      }
    }
  }

  String texte;
  serializeJson(reponse, texte);
  serveur.sendTXT(client, texte);
}

void activerServeur() {
  serveur.begin();
  serveur.onEvent(traiterSocket);
}

bool demarrerWifi(const String &pass) {
  if (wifiActif) {
    serveur.close();
    MDNS.end();
    WiFi.softAPdisconnect(true);
    wifiActif = false;
  }

  uint64_t id = ESP.getEfuseMac();

  char suffixe[5];
  snprintf(suffixe, sizeof suffixe, "%04X", (unsigned)(id & 0xFFFF));

  nomReseau = String("AMZ-IT-") + suffixe;

  WiFi.mode(WIFI_AP);

  const IPAddress ip(192, 168, 4, 88);
  const IPAddress masque(255, 255, 255, 0);

  if (!WiFi.softAPConfig(ip, ip, masque)) {
    Serial.println("ERREUR : configuration IP SoftAP.");
    return false;
  }

  if (!WiFi.softAP(nomReseau.c_str(), pass.c_str())) {
    Serial.println("ERREUR : demarrage SoftAP.");
    return false;
  }

  if (MDNS.begin("amz-adv")) {
    MDNS.addService("ws", "tcp", 81);
    Serial.println("Nom mDNS : amz-adv.local");
  } else {
    Serial.println(
        "AVERTISSEMENT : mDNS indisponible ; "
        "l'adresse IP reste utilisable."
    );
  }

  activerServeur();
  wifiActif = true;

  Serial.print("Reseau : ");
  Serial.println(nomReseau);

  Serial.print("Adresse : ");
  Serial.println(WiFi.softAPIP());

  return true;
}

bool configurerWifi(const char *motDePasse) {
  size_t np = strlen(motDePasse);

  if (np < 8 || np > 63) return false;

  struct Identifiants {
    char pass[64];
    char cle[64];
  } data = {};

  strlcpy(data.pass, motDePasse, sizeof data.pass);

  if (identifiants.putBytes("acces", &data, sizeof data) != sizeof data) {
    return false;
  }

  Identifiants v = {};

  if (identifiants.getBytes("acces", &v, sizeof v) != sizeof v ||
      memcmp(&data, &v, sizeof v) != 0) {
    return false;
  }

  if (!demarrerWifi(String(motDePasse))) return false;

  Serial.println(
      "OK : identifiants enregistres. "
      "Reconnecter le telephone au reseau affiche."
  );

  return true;
}

void chargerWifi() {
  struct Identifiants {
    char pass[64];
    char cle[64];
  } data = {};

  if (identifiants.getBytesLength("acces") != sizeof data ||
      identifiants.getBytes("acces", &data, sizeof data) != sizeof data ||
      memchr(data.pass, '\0', sizeof data.pass) == nullptr ||
      strlen(data.pass) < 8) {
    Serial.println(
        "Wi-Fi non configure. Taper aide pour la configuration serie."
    );
    return;
  }

  demarrerWifi(String(data.pass));
}

// ------------------------------------------------------------
// Démarrage et boucle principale
// ------------------------------------------------------------

void setup() {
  Serial.begin(115200);

  pinMode(PIN_JEU, INPUT_PULLUP);
  pinMode(PIN_MODE, INPUT_PULLUP);
  pinMode(PIN_SON, OUTPUT);

  matrix.begin();
  matrix.setBrightness(LUMINOSITE);
  matrix.setTextWrap(false);
  matrix.setFont();
  matrix.setTextSize(1);

  if (stockage.begin("amz-game", false)) {
    chargerConfig();
  } else {
    Serial.println("ERREUR : stockage NVS indisponible.");
  }

  afficherConfig();
  afficherPret();

  stockagePubPret = stockagePub.begin("amz-pub", false);

  if (stockagePubPret) {
    chargerPub();
  } else {
    Serial.println("ERREUR : stockage publicitaire indisponible.");
  }

  if (identifiants.begin("amz-acces", false)) {
    chargerWifi();
  } else {
    Serial.println("ERREUR : stockage identifiants indisponible.");
  }

  Serial.println(
      "Pret : facile, difficile, puis smiley. "
      "Gros bouton : depart / arret / reset."
  );
}

void loop() {
  lireSerie();

  if (wifiActif) {
    serveur.loop();
  }

  uint32_t now = millis();

  if (sonActif && uint32_t(now - sonDebut) >= sonDuree) {
    arreterSon();
  }

  // Les entrées sont toujours lues pour conserver l'anti-rebond,
  // mais leurs événements sont ignorés en mode Advertising.
  bool go = jeu.appui(now);
  bool choix = mode.appui(now);

  if (modeAffichage != MODE_GAME) {
    go = false;
    choix = false;
  }

  if (choix && etat == PRET) {
    pubSale = true;
    modeJeu = (ModeJeu)((modeJeu + 1) % 3);

    afficherPret();

    Serial.println(
        modeJeu == FACILE
            ? "Mode facile"
            : modeJeu == DIFFICILE
                  ? "Mode difficile"
                  : "Mode smiley"
    );
  }

  if (go) {
    if (etat == PRET) {
      depart = now;
      dernierAffichage = now;
      derniereSeconde = 0;
      etat = EN_COURS;

      matrix.setBrightness(LUMINOSITE);

      if (modeJeu == DIFFICILE) {
        matrix.fillScreen(0);
        matrix.show();
      } else if (modeJeu == SMILEY) {
        // Tirer une autre position parmi les dix possibles.
        int ancien = cadreX;
        int tirage = (int)(esp_random() % 9);

        if (tirage >= ancien - 16) {
          ++tirage;
        }

        cadreX = 16 + tirage;
        smileyX = -5;

        afficherSmiley(smileyX, true);

        Serial.print("Cadre, colonne gauche : ");
        Serial.println(cadreX);
      } else {
        afficherTemps(0);
      }

      son(now, 2000, 40);
      Serial.println("Depart");

    } else if (etat == EN_COURS) {
      if (modeJeu == SMILEY) {
        Serial.print("Smiley, position arretee : ");
        Serial.println(smileyX);

        if (smileyX == cadreX + 1) {
          snprintf(
              message,
              sizeof(message),
              "BRAVO ! SMILEY ATTRAPE ! "
          );

          debutCapture = now;
          etat = CAPTURE;

          demarrerMelodie(now);

          Serial.println(
              "Smiley attrape : affichage pendant 3 secondes."
          );
        } else {
          etat = RESULTAT;
          son(now, 1200, 100);
          Serial.println("Manque");
        }
      } else {
        resultat = now - depart;

        if (resultat > MAX_MS) {
          resultat = MAX_MS;
        }

        afficherTemps(resultat);

        Serial.print("Temps mesure en ms : ");
        Serial.println(resultat);

        if (estGagnant(resultat)) {
          victoire(resultat);
          demarrerMelodie(now);
        } else {
          etat = RESULTAT;
          son(now, 1200, 100);
          Serial.println("Resultat");
        }
      }

    } else if (etat == CAPTURE) {
      // Ignorer les appuis durant les trois secondes de capture.

    } else if (etat == VICTOIRE) {
      ++appuisResetVictoire;

      Serial.print("Appuis pour reset : ");
      Serial.print(appuisResetVictoire);
      Serial.println("/3");

      if (appuisResetVictoire >= 3) {
        arreterSon();
        etat = PRET;
        matrix.setBrightness(LUMINOSITE);
        afficherPret();
        pubSale = true;

        Serial.println("Remise a zero");
      }
    } else {
      arreterSon();
      etat = PRET;
      matrix.setBrightness(LUMINOSITE);
      afficherPret();
      pubSale = true;

      Serial.println("Remise a zero");
    }
  }

  if (etat == EN_COURS) {
    uint32_t ecoule = now - depart;

    if (modeJeu == SMILEY) {
      uint32_t duree = TRAVERSEE_MS == 0 ? 1000 : TRAVERSEE_MS;

      int nouvelleX =
          -5 + (int)((uint64_t(ecoule % duree) * 37ULL) / duree);

      if (nouvelleX != smileyX) {
        smileyX = nouvelleX;
        afficherSmiley(smileyX, true);
      }
    } else if (ecoule >= MAX_MS) {
      resultat = MAX_MS;
      etat = RESULTAT;

      arreterSon();
      afficherTemps(resultat);
    } else {
      uint32_t seconde = ecoule / 1000;

      if (seconde > derniereSeconde) {
        derniereSeconde = seconde;
        son(now, 2000, 40);
      }

      if (modeJeu == FACILE &&
          uint32_t(now - dernierAffichage) >= 20) {
        dernierAffichage = now;
        afficherTemps(ecoule);
      }
    }
  }

  if (etat == CAPTURE &&
      uint32_t(now - debutCapture) >= DUREE_CAPTURE_MS) {
    scrollX = 32;
    dernierScroll = now - SCROLL_INTERVAL_MS;
    etat = VICTOIRE;
  }

  if ((etat == CAPTURE || etat == VICTOIRE) &&
      !melodieTerminee) {
    if (uint32_t(now - debutMelodie) >= DUREE_MELODIE_MS) {
      arreterSon();
      melodieTerminee = true;
    } else if (!sonActif &&
               uint32_t(now - sonDebut) >= sonDuree + 40) {
      if (prochaineNote >= nombreNotes) {
        prochaineNote = 0;
      }

      son(
          now,
          notesVictoire[prochaineNote],
          dureesVictoire[prochaineNote]
      );

      ++prochaineNote;
    }
  }

  actualiserPub(now);

  if (etat == VICTOIRE &&
      uint32_t(now - dernierScroll) >= SCROLL_INTERVAL_MS) {
    dernierScroll = now;

    matrix.fillScreen(0);
    matrix.setTextColor(matrix.Color(255, 180, 0));
    matrix.setCursor(scrollX, 0);
    matrix.print(message);
    matrix.show();

    --scrollX;

    int16_t x1, y1;
    uint16_t largeur, hauteur;

    matrix.getTextBounds(
        message,
        0,
        0,
        &x1,
        &y1,
        &largeur,
        &hauteur
    );

    if (scrollX + x1 + (int)largeur <= 0) {
      scrollX = 32;
    }
  }
}