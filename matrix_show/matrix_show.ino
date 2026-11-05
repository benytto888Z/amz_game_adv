#include <Adafruit_GFX.h>
#include <Adafruit_NeoMatrix.h>
#include <Adafruit_NeoPixel.h>
#include <esp_system.h>
#include <Preferences.h>
#include "Config.h"
#include "bluesmiley24.h"

constexpr int PIN_LED=18, PIN_JEU=26, PIN_MODE=27, PIN_SON=13;
constexpr uint8_t LUMINOSITE=20;
uint32_t CIBLE_CS=1000; // 10,00 secondes, en centiemes
uint32_t marge = 0; // 0 = exact, sinon bornes strictes
constexpr uint32_t MAX_MS=5999990UL;
Adafruit_NeoMatrix matrix(32,8,PIN_LED, NEO_MATRIX_TOP+NEO_MATRIX_LEFT+NEO_MATRIX_COLUMNS+NEO_MATRIX_ZIGZAG, NEO_GRB+NEO_KHZ800);
// Chiffres 3 x 7 pour remplir la hauteur et conserver six chiffres.
const uint8_t chiffres[10][7] = {
 {7,5,5,5,5,5,7},{2,6,2,2,2,2,7},{7,1,1,7,4,4,7},{7,1,1,7,1,1,7},{5,5,5,7,1,1,1},
 {7,4,4,7,1,1,7},{7,4,4,7,5,5,7},{7,1,1,1,1,1,1},{7,5,5,7,5,5,7},{7,5,5,7,1,1,7}
};
struct Bouton {
 int pin; bool precedent=HIGH, stable=HIGH; uint32_t change=0;
 bool appui(uint32_t now) {
   bool v=digitalRead(pin);
   if(v!=precedent){precedent=v; change=now;}
   if(v!=stable && uint32_t(now-change)>=30){stable=v; return stable==LOW;}
   return false;
 }
};
Bouton jeu{PIN_JEU}, mode{PIN_MODE};
enum Etat { PRET, EN_COURS, RESULTAT, CAPTURE, VICTOIRE };
constexpr uint32_t DUREE_CAPTURE_MS = 3000;
uint32_t debutCapture = 0;
Etat etat=PRET;
enum ModeJeu { FACILE, DIFFICILE, SMILEY };
ModeJeu modeJeu=FACILE;
bool sonActif=false;
uint32_t TRAVERSEE_MS=1000; // millisecondes pour un cycle complet, entree et sortie comprises
uint32_t couleurFacile=0x00FF00, couleurDifficile=0xFF0000;
int cadreX=16; // choisi aleatoirement a chaque essai : 16 a 25 inclus
constexpr int CADRE_Y=0, SMILEY_Y=CADRE_Y+1; // interieur de 5 x 5
int smileyX=-5;
uint32_t depart=0, resultat=0, dernierAffichage=0, derniereSeconde=0, sonDebut=0, sonDuree=0, dernierScroll=0;
int scrollX=32;
char message[48];
// La phrase musicale se repete pendant 5 secondes, sauf reset anticipe.
const unsigned notesVictoire[] = { 1047, 1319, 1568, 2093 };
const uint32_t dureesVictoire[] = { 120, 120, 120, 300 };
const uint8_t nombreNotes = sizeof(notesVictoire) / sizeof(notesVictoire[0]);
const uint32_t DUREE_MELODIE_MS = 5000;
uint8_t prochaineNote = 0, appuisResetVictoire = 0;
uint32_t debutMelodie = 0;
bool melodieTerminee = false;

void son(uint32_t now, unsigned freq, uint32_t duree) {
 tone(PIN_SON, freq); sonActif=true; sonDebut=now; sonDuree=duree;
}
void arreterSon(){ noTone(PIN_SON); sonActif=false; }
void chiffre(int n,int x,uint16_t c) {
 for(int y=0;y<7;y++) for(int dx=0;dx<3;dx++)
  if(chiffres[n][y] & (1<<(2-dx))) matrix.drawPixel(x+dx,y,c);
}
void afficherTemps(uint32_t ms) {
 if(ms>MAX_MS) ms=MAX_MS;
 uint32_t cs=ms/10; int m=cs/6000,s=(cs/100)%60,c=cs%100;
 uint32_t rgb=(modeJeu==DIFFICILE)?couleurDifficile:couleurFacile;
 uint16_t couleur=matrix.Color((rgb>>16)&255,(rgb>>8)&255,rgb&255);
 matrix.fillScreen(0);
 chiffre(m/10,3,couleur); chiffre(m%10,7,couleur);
 matrix.drawPixel(11,2,couleur); matrix.drawPixel(11,5,couleur);
 chiffre(s/10,13,couleur); chiffre(s%10,17,couleur);
 matrix.drawPixel(21,6,couleur);
 chiffre(c/10,23,couleur); chiffre(c%10,27,couleur);
 matrix.show();
}
void afficherSmiley(int x, bool visible) {
 matrix.fillScreen(0);
 matrix.drawRect(cadreX,CADRE_Y,7,7,matrix.Color(0,0,255));
 if(visible) {
  // Un dessin 5 x 5 ; les bits eteints sont transparents.
  for(int y=0;y<5;y++) for(int dx=0;dx<5;dx++) {
   uint8_t ligne=pgm_read_byte(&smiley5x5[y]);
   if(ligne & (1 << (4-dx))) matrix.drawPixel(x+dx,SMILEY_Y+y,matrix.Color(255,255,0));
  }
 }
 matrix.show();
}
void afficherPret() {
 if(modeJeu==SMILEY) afficherSmiley(-5,false);
 else afficherTemps(0);
}
void demarrerMelodie(uint32_t now) {
 son(now,notesVictoire[0],dureesVictoire[0]);
 prochaineNote=1; appuisResetVictoire=0;
 debutMelodie=now; melodieTerminee=false;
 Serial.println("Victoire : 3 appuis pour reinitialiser.");
}
bool estGagnant(uint32_t ms) {
 uint32_t tempsCS = ms / 10; // comparer les centiemes affiches
 uint32_t ecart = tempsCS >= CIBLE_CS ? tempsCS - CIBLE_CS : CIBLE_CS - tempsCS;
 return marge == 0 ? ecart == 0 : ecart < marge;
}
void victoire(uint32_t ms) {
 uint32_t cs=ms/10;
 snprintf(message,sizeof(message),"BRAVO ! GAGNE : %02lu:%02lu.%02lu ",
   (unsigned long)(cs/6000), (unsigned long)((cs/100)%60), (unsigned long)(cs%100));
 scrollX=32; dernierScroll=millis()-70; etat=VICTOIRE;
}

// Configuration NVS : deux emplacements, version et somme de controle.
// La configuration n'est changee en RAM qu'apres verification de l'ecriture.
Preferences stockage;
const uint32_t SIGNATURE=0x414D5A47, VERSION_CONFIG=1;
int emplacement=-1; uint32_t generation=0;
char ligneSerie[96]; size_t longueurSerie=0; bool ligneTropLongue=false;
uint32_t checksumConfig(const Config &c) {
 const uint32_t mots[]={c.signature,c.version,c.generation,c.cible,c.margeCs,c.facile,c.difficile,c.traversee};
 uint32_t h=2166136261UL;
 for(uint32_t mot:mots) for(int i=0;i<4;i++){h^=(mot>>(8*i))&255; h*=16777619UL;}
 return h;
}
bool configValide(const Config &c) {
 return c.signature==SIGNATURE && c.version==VERSION_CONFIG &&
 c.cible<=599999 && c.margeCs<=599999 && c.facile<=0xFFFFFF && c.difficile<=0xFFFFFF &&
 c.traversee>=100 && c.traversee<=60000 && c.checksum==checksumConfig(c);
}
void appliquer(const Config &c) {
 CIBLE_CS=c.cible; marge=c.margeCs; couleurFacile=c.facile; couleurDifficile=c.difficile;
 TRAVERSEE_MS=c.traversee; generation=c.generation;
}
Config configCourante() {
 Config c={SIGNATURE,VERSION_CONFIG,generation,CIBLE_CS,marge,couleurFacile,couleurDifficile,TRAVERSEE_MS,0};
 c.checksum=checksumConfig(c); return c;
}
void chargerConfig() {
 Config a={},b={};
 bool va=stockage.getBytesLength("cfg0")==sizeof(Config) && stockage.getBytes("cfg0",&a,sizeof a)==sizeof a && configValide(a);
 bool vb=stockage.getBytesLength("cfg1")==sizeof(Config) && stockage.getBytes("cfg1",&b,sizeof b)==sizeof b && configValide(b);
 if(va && (!vb || (int32_t)(a.generation-b.generation)>0)){appliquer(a);emplacement=0;}
 else if(vb){appliquer(b);emplacement=1;}
 else Serial.println("Aucune configuration valide : valeurs par defaut utilisees.");
}
bool enregistrer(Config c) {
 c.signature=SIGNATURE; c.version=VERSION_CONFIG; c.generation=generation+1; c.checksum=checksumConfig(c);
 if(!configValide(c)) return false;
 int cibleSlot=emplacement==0?1:0; const char *cle=cibleSlot==0?"cfg0":"cfg1";
 if(stockage.putBytes(cle,&c,sizeof c)!=sizeof c) return false;
 Config verifie={};
 if(stockage.getBytes(cle,&verifie,sizeof verifie)!=sizeof verifie || !configValide(verifie) || memcmp(&c,&verifie,sizeof c)!=0) return false;
 appliquer(verifie); emplacement=cibleSlot; return true;
}
void afficherConfig() {
 Serial.printf("cible=%lu centiemes | marge=%lu centiemes | facile=#%06lX | difficile=#%06lX | traversee=%lu ms\n",
 (unsigned long)CIBLE_CS,(unsigned long)marge,(unsigned long)couleurFacile,(unsigned long)couleurDifficile,(unsigned long)TRAVERSEE_MS);
}
void commande(const char *s) {
 if(strcmp(s,"etat")==0){afficherConfig();return;}
 if(strcmp(s,"aide")==0){
  Serial.println("etat | cible N | marge N | facile R G B | difficile R G B | vitesse N");
  Serial.println("cible/marge en centiemes ; vitesse en ms (100..60000). Reglage seulement si PRET.");return;
 }
 if(etat!=PRET){Serial.println("ERREUR : jeu non pret, remettre a zero.");return;}
 Config c=configCourante(); unsigned long n=0,r=0,g=0,b=0; char fin;
 if(sscanf(s,"cible %lu %c",&n,&fin)==1 && n<=599999) c.cible=n;
 else if(sscanf(s,"marge %lu %c",&n,&fin)==1 && n<=599999) c.margeCs=n;
 else if(sscanf(s,"vitesse %lu %c",&n,&fin)==1 && n>=100 && n<=60000) c.traversee=n;
 else if(sscanf(s,"facile %lu %lu %lu %c",&r,&g,&b,&fin)==3 && r<=255 && g<=255 && b<=255) c.facile=(r<<16)|(g<<8)|b;
 else if(sscanf(s,"difficile %lu %lu %lu %c",&r,&g,&b,&fin)==3 && r<=255 && g<=255 && b<=255) c.difficile=(r<<16)|(g<<8)|b;
 else {Serial.println("ERREUR : commande ou valeurs invalides. Tapez aide.");return;}
 Config avant=configCourante();
 if(c.cible==avant.cible && c.margeCs==avant.margeCs && c.facile==avant.facile && c.difficile==avant.difficile && c.traversee==avant.traversee) {
  Serial.println("Inchange : aucune ecriture flash."); return;
 }
 if(enregistrer(c)){Serial.println("OK : enregistre et verifie.");afficherConfig();afficherPret();}
 else Serial.println("ERREUR : sauvegarde non confirmee ; reglages en RAM inchanges.");
}
void lireSerie() {
 while(Serial.available()) {
  char c=Serial.read();
  if(c=='\n'||c=='\r') {
   if(ligneTropLongue) Serial.println("ERREUR : ligne trop longue.");
   else if(longueurSerie){ligneSerie[longueurSerie]='\0';commande(ligneSerie);}
   longueurSerie=0;ligneTropLongue=false;
  } else if(!ligneTropLongue) {
   if(longueurSerie<sizeof(ligneSerie)-1) ligneSerie[longueurSerie++]=c;
   else ligneTropLongue=true;
  }
 }
}

void setup() {
 Serial.begin(115200);
 pinMode(PIN_JEU,INPUT_PULLUP); pinMode(PIN_MODE,INPUT_PULLUP); pinMode(PIN_SON,OUTPUT);
 matrix.begin(); matrix.setBrightness(LUMINOSITE); matrix.setTextWrap(false);
 matrix.setFont(); matrix.setTextSize(1); // police GFX classique 5 x 7
 if(stockage.begin("amz-game",false)) chargerConfig();
 else Serial.println("ERREUR : stockage NVS indisponible.");
 afficherConfig(); afficherPret();
 Serial.println("Pret : facile, difficile, puis smiley. Gros bouton : depart / arret / reset.");
}
void loop() {
 uint32_t now=millis();
 lireSerie();
 if(sonActif && uint32_t(now-sonDebut)>=sonDuree) arreterSon();
 bool go=jeu.appui(now), choix=mode.appui(now);
 if(choix && etat==PRET){modeJeu=(ModeJeu)((modeJeu+1)%3); afficherPret(); Serial.println(modeJeu==FACILE?"Mode facile":modeJeu==DIFFICILE?"Mode difficile":"Mode smiley");}
 if(go){
  if(etat==PRET){
   depart=now; dernierAffichage=now; derniereSeconde=0; etat=EN_COURS;
   if(modeJeu==DIFFICILE){matrix.fillScreen(0);matrix.show();}
   else if(modeJeu==SMILEY){
    // Tirer une autre position parmi les 10 possibles dans la moitie droite.
    int ancien = cadreX;
    int tirage = (int)(esp_random() % 9); // 0..8 : on saute l'ancienne position
    if (tirage >= ancien - 16) ++tirage;
    cadreX = 16 + tirage;
    smileyX=-5; afficherSmiley(smileyX,true);
    Serial.print("Cadre, colonne gauche : "); Serial.println(cadreX);
   }
   else afficherTemps(0);
   son(now,2000,40); Serial.println("Depart");
  } else if(etat==EN_COURS){
   if(modeJeu==SMILEY) {
    // On juge la derniere image visible, pas une position future non affichee.
    Serial.print("Smiley, position arretee : "); Serial.println(smileyX);
    if(smileyX==cadreX+1) {
     snprintf(message,sizeof(message),"BRAVO ! SMILEY ATTRAPE ! ");
     // Conserver l'image du smiley dans le cadre pendant 3 secondes.
     debutCapture=now; etat=CAPTURE;
     demarrerMelodie(now); // la musique commence des la capture
     Serial.println("Smiley attrape : affichage pendant 3 secondes.");
    } else {etat=RESULTAT; son(now,1200,100); Serial.println("Manque");}
   } else {
    resultat=now-depart; if(resultat>MAX_MS) resultat=MAX_MS;
    afficherTemps(resultat);
    Serial.print("Temps mesure en ms : ");Serial.println(resultat);
    if(estGagnant(resultat)){victoire(resultat);demarrerMelodie(now);}
    else {etat=RESULTAT;son(now,1200,100);Serial.println("Resultat");}
   }
  } else if(etat==CAPTURE) {
   // Ignorer les appuis durant les 3 secondes pour conserver l'image.
  } else if(etat==VICTOIRE) {
   ++appuisResetVictoire;
   Serial.print("Appuis pour reset : "); Serial.print(appuisResetVictoire); Serial.println("/3");
   if(appuisResetVictoire>=3) {
    arreterSon(); etat=PRET; afficherPret(); Serial.println("Remise a zero");
   }
  } else {
   arreterSon(); etat=PRET; afficherPret(); Serial.println("Remise a zero");
  }
 }
 if(etat==EN_COURS){
  uint32_t ecoule=now-depart;
  if(modeJeu==SMILEY) {
   uint32_t duree = TRAVERSEE_MS == 0 ? 1000 : TRAVERSEE_MS;
   int nouvelleX=-5+(int)((uint64_t(ecoule % duree)*37ULL)/duree);
   if(nouvelleX!=smileyX){smileyX=nouvelleX; afficherSmiley(smileyX,true);}
  } else if(ecoule>=MAX_MS){resultat=MAX_MS;etat=RESULTAT;arreterSon();afficherTemps(resultat);}
  else {
   uint32_t seconde=ecoule/1000;
   if(seconde>derniereSeconde){derniereSeconde=seconde;son(now,2000,40);}
   if(modeJeu==FACILE && uint32_t(now-dernierAffichage)>=20){dernierAffichage=now;afficherTemps(ecoule);}
  }
 }
 if(etat==CAPTURE && uint32_t(now-debutCapture)>=DUREE_CAPTURE_MS) {
  scrollX=32; dernierScroll=now-70; etat=VICTOIRE;
 }
 if((etat==CAPTURE || etat==VICTOIRE) && !melodieTerminee) {
  if(uint32_t(now-debutMelodie) >= DUREE_MELODIE_MS) {
   arreterSon();
   melodieTerminee=true;
  } else if(!sonActif && uint32_t(now-sonDebut) >= sonDuree + 40) {
   if(prochaineNote >= nombreNotes) prochaineNote=0;
   son(now, notesVictoire[prochaineNote], dureesVictoire[prochaineNote]);
   ++prochaineNote;
  }
 }
 if(etat==VICTOIRE && uint32_t(now-dernierScroll)>=70){
  dernierScroll=now; matrix.fillScreen(0); matrix.setTextColor(matrix.Color(255,180,0));
  matrix.setCursor(scrollX,0); matrix.print(message); matrix.show();
  --scrollX;
  int16_t x1, y1; uint16_t largeur, hauteur;
  matrix.getTextBounds(message,0,0,&x1,&y1,&largeur,&hauteur);
  if(scrollX + x1 + (int)largeur <= 0) scrollX=32; // boucle jusqu'au reset
 }
}
