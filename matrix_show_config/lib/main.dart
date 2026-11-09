import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/amz_light_theme.dart';
import 'core/theme/amz_dark_theme.dart';
import 'core/design_system/spacing.dart';
import 'core/design_system/components/amz_section_card.dart';
import 'core/responsive/breakpoints.dart';
import 'features/playlists/playlist_page.dart';
import 'features/schedule/schedule_page.dart';
import 'services/phone_clock.dart';
import 'services/panel_service.dart';
import 'features/game_settings/game_settings_page.dart';
import 'features/live_ad/live_ad_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ThemeMode initial = ThemeMode.system;

  try {
    final saved = await SharedPreferencesAsync().getString('theme_mode');
    initial = ThemeMode.values
        .where((m) => m.name == saved)
        .firstOrNull ??
        ThemeMode.system;
  } catch (_) {
    // Un problème de stockage ne doit pas bloquer le démarrage.
  }

  runApp(AmzApp(initialTheme: initial));
}

class Texts extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'fr_FR': {
      'dash_kicker': 'VUE D’ENSEMBLE',
      'dash_intro': 'Suivez l’état confirmé de votre panneau et choisissez son mode d’affichage.',
      'dash_game_mode': 'Jeu sélectionné',
      'panel_id_label': 'Identifiant du panneau',
      'panel_id_unknown': 'Non disponible',
      'display_title': 'Mode du panneau',
      'display_game': 'Game',
      'display_advertising': 'Advertising',
      'display_unknown': 'Mode non confirmé',
      'display_current': 'Mode confirmé',
      'display_required': 'Sélectionnez Advertising dans le tableau de bord.',
      'display_change_error':
      'Changement non confirmé : vérifiez la connexion et actualisez le panneau.',
      'display_confirm_title': 'Passer en Advertising ?',
      'display_confirm_body': 'La partie ou le résultat en cours sera annulé.',
      'display_confirm': 'Changer de mode',

      'pub_store_button': 'Sauvegarder pour redémarrage',
      'pub_store_note':
      'Sauvegarde permanente séparée : après redémarrage, le panneau démarre en Game. La publicité sauvegardée démarre lors du passage en Advertising.',
      'pub_store_confirm_title': 'Sauvegarder sur le panneau ?',
      'pub_store_confirm':
      'Ce message et ses réglages remplaceront la précédente sauvegarde. Après redémarrage en Game, ils seront lancés lors du passage en Advertising.',
      'pub_store_success': 'Sauvegarde écrite et relue par le panneau.',
      'pub_store_unavailable':
      'Stockage publicitaire indisponible sur le panneau.',
      'pub_store_uncertain':
      'Sauvegarde non confirmée : le résultat après redémarrage est incertain.',
      'pub_store_firmware':
      'Firmware incompatible : téléversez la version avec sauvegarde.',

      'effects_title': 'Effet publicitaire',
      'effect_0': 'Aucun',
      'effect_1': 'Clignotement',
      'effect_2': 'Couleurs alternées',
      'effects_notice':
      'Clignotement : 1 seconde allumé, 1 seconde éteint. Couleurs alternées : une couleur par seconde, remplace temporairement la couleur choisie.',
      'effects_firmware':
      'Firmware incompatible : téléversez la version avec effets.',

      'product_title': 'Produit et prix',
      'product_explanation':
      'Prépare un texte localement. Envoyez ensuite les réglages au panneau. Aucun taux de change n’est appliqué.',
      'product_name': 'Nom du produit',
      'product_ascii': 'Sans accents ni émojis.',
      'product_currency': 'Devise',
      'product_price': 'Prix',
      'product_eur_hint':
      'Ex. 12,50 : 9 chiffres maximum avant la virgule, 2 après.',
      'product_fcfa_hint':
      'Ex. 2500 : nombre entier, 9 chiffres maximum.',
      'product_invalid_name':
      'Saisissez un nom non vide, sans accents ni émojis.',
      'product_invalid_eur':
      'Prix EUR invalide : utilisez 0 à 2 décimales et 9 chiffres maximum avant la virgule.',
      'product_invalid_fcfa':
      'Prix FCFA invalide : utilisez un entier de 9 chiffres maximum.',
      'product_too_long': 'Le texte complet dépasse 100 caractères.',
      'product_prepare': 'Préparer le message',

      'icons_title': 'Icône avant le texte',
      'icon_0': 'Aucune',
      'icon_1': 'Cœur',
      'icon_2': 'Visage',
      'icon_3': 'Étoile',
      'icons_note': 'Une icône 5 × 5, de la même couleur que le texte.',
      'icons_firmware':
      'Firmware incompatible : téléversez la version avec icônes.',

      'preview_local': 'Aperçu local · 32 × 8',
      'preview_notice':
      'Simulation de votre saisie, indépendante du panneau. La luminosité et la position réelles peuvent différer.',

      'live_title': 'Contrôle publicitaire',
      'live_warning':
      'La publicité affichée est temporaire tant qu’elle n’est pas sauvegardée. Le mode est choisi dans le tableau de bord.',
      'live_unknown':
      'Confirmation perdue : état inconnu. Reconnectez-vous puis relisez le panneau.',
      'live_busy': 'Jeu en cours ou résultat : remettez le jeu à zéro.',
      'live_offline': 'Panneau non connecté.',
      'live_error': 'Erreur de communication ou de validation.',
      'live_loaded': 'Données lues depuis le panneau.',
      'live_saved': 'Configuration confirmée par le panneau.',
      'live_action_ok': 'Commande confirmée par le panneau.',
      'live_color': 'Couleur',
      'live_text': 'Texte',
      'live_required': 'Saisissez un message.',
      'live_ascii': '100 caractères maximum, sans accents ni emoji.',
      'live_speed': 'Intervalle par pixel',
      'live_brightness': 'Luminosité',
      'live_scroll': 'Défilement',
      'live_static_note':
      'Sans défilement, seul le début du texte tient à l’écran.',
      'live_state': 'Dernier état confirmé',
      'live_play': 'Démarrer',
      'live_pause': 'Pause',
      'live_stop': 'Arrêter',
      'live_send': 'Envoyer les réglages',
      'live_reload': 'Relire le panneau (efface les modifications)',
      'live_open': 'Contrôle en direct',
      'playlist_open': 'Playlist',
      'schedule_open': 'Programmation',
      'schedule_active': 'Désactivez la programmation avant le contrôle direct.',

      'studio_kicker': 'CRÉATION · LED STUDIO',
      'studio_intro_ui': 'Créez vos messages, organisez votre playlist et planifiez leur diffusion.',
      'studio_live_detail': 'Préparez un message et visualisez son aperçu local.',
      'studio_playlist_detail': 'Organisez les messages enregistrés sur le panneau.',
      'studio_schedule_detail': 'Définissez les dates et horaires de diffusion.',
      'studio': 'Studio LED',
      'studio_title': 'Studio publicitaire',
      'studio_placeholder':
      'Configurez un message temporaire et pilotez son affichage.',
      'cap_unknown': 'Capacité publicitaire non confirmée',
      'cap_on': 'Publicité disponible',
      'cap_off': 'Publicité non encore disponible sur ce panneau',

      'game_custom_color': 'Couleur personnalisée',
      'game_cancel': 'Annuler',
      'game_choose': 'Choisir',
      'game_selected_color': 'Couleur sélectionnée',
      'color_green': 'Vert',
      'color_red': 'Rouge',
      'color_blue': 'Bleu',
      'color_white': 'Blanc',
      'color_orange': 'Orange',
      'game_settings': 'Réglages du jeu',
      'game_instructions':
      'Valeurs confirmées par le panneau. Les modifications sont possibles uniquement lorsque le jeu est prêt.',
      'game_offline': 'Panneau non connecté.',
      'game_busy': 'Jeu non prêt : remettez-le à zéro.',
      'game_loaded': 'Valeurs lues sur le panneau.',
      'game_saved': 'Réglages appliqués et confirmés par le panneau.',
      'game_target': 'Temps cible',
      'game_time_help': 'Format mm:ss.cc, secondes de 00 à 59',
      'game_margin': 'Marge en centièmes',
      'game_margin_help':
      '0 = exact ; les bornes non nulles sont exclues.',
      'game_easy': 'Couleur facile',
      'game_hard': 'Couleur difficile',
      'game_hex_hint':
      'Six caractères hexadécimaux, par exemple 00FF00.',
      'game_speed': 'Traversée smiley (ms)',
      'game_speed_help': 'De 100 à 60000 ms par cycle',
      'game_apply': 'Appliquer au panneau',
      'game_reload': 'Relire le panneau (efface la saisie)',
      'game_invalid': 'Valeur invalide.',
      'game_error': 'Erreur de communication ou de réponse.',
      'game_storage_error': 'Sauvegarde non confirmée par le panneau.',
      'game_uncertain':
      'Confirmation perdue : résultat inconnu. Reconnectez-vous puis relisez le panneau avant de réessayer.',
      'game_mismatch':
      'La réponse diffère de la demande. Relisez le panneau.',

      'connect': 'Connexion',
      'dashboard': 'Tableau de bord',
      'settings_kicker': 'CONFIGURATION',
      'settings_intro': 'Personnalisez l’apparence et accédez aux réglages du jeu.',
      'settings': 'Réglages',
      'connection_kicker': 'APPAREIL · CONNEXION LOCALE',
      'connection_intro': 'Reliez votre téléphone au panneau AMZ-IT pour consulter son état et le piloter.',
      'connection_steps': 'Comment se connecter',
      'connect_title': 'Connecter le panneau',
      'instructions':
      '1. Rejoignez le réseau Wi-Fi AMZ-IT-XXXX dans les réglages du téléphone.\n\n'
          '2. Restez connecté même si le réseau est sans Internet. Si nécessaire, désactivez les données mobiles pour le test.\n\n'
          '3. Revenez ici et vérifiez la connexion.',
      'address': 'Nom du panneau',
      'check': 'Vérifier la connexion',
      'checking': 'Connexion…',
      'connected': 'Panneau connecté',
      'disconnected': 'Panneau déconnecté',
      'unconfirmed': 'Aucun état confirmé',
      'state': 'État',
      'mode': 'Mode',
      'refresh': 'Actualiser',
      'lang': 'Langue',
      'theme': 'Apparence',
      'light': 'Clair',
      'dark': 'Sombre',
      'system': 'Système',
      'theme_save_error': 'Impossible de sauvegarder le thème.',
      'invalid_ip': 'Adresse IPv4 invalide.',
      'connection_error':
      'Connexion impossible. Vérifiez le Wi-Fi et l’adresse du panneau.',
      'security':
      'WebSocket non chiffré et sans clé API : réservé aux essais sur réseau de confiance.',
      'next': 'Les réglages du jeu seront ajoutés à l’étape suivante.',
      'last': 'Dernier état confirmé par le panneau.',

      'pret': 'Prêt',
      'en_cours': 'En cours',
      'resultat': 'Résultat',
      'victoire': 'Victoire',
      'capture': 'Capture',
      'facile': 'Facile',
      'difficile': 'Difficile',
      'smiley': 'Smiley',
    },

    'en_US': {
      'dash_kicker': 'OVERVIEW',
      'dash_intro': 'Follow your panel’s confirmed status and select its display mode.',
      'dash_game_mode': 'Selected game',
      'panel_id_label': 'Panel identifier',
      'panel_id_unknown': 'Unavailable',
      'display_title': 'Panel mode',
      'display_game': 'Game',
      'display_advertising': 'Advertising',
      'display_unknown': 'Unconfirmed mode',
      'display_current': 'Confirmed mode',
      'display_required': 'Select Advertising on the dashboard.',
      'display_change_error':
      'Change not confirmed: check the connection and refresh the panel.',
      'display_confirm_title': 'Switch to Advertising?',
      'display_confirm_body':
      'The current game or result will be cancelled.',
      'display_confirm': 'Change mode',

      'pub_store_button': 'Save for restart',
      'pub_store_note':
      'Separate persistent save: the panel restarts in Game. The saved advertisement starts when Advertising is selected.',
      'pub_store_confirm_title': 'Save to panel?',
      'pub_store_confirm':
      'This message and its settings will replace the previous saved version. After restarting in Game, they will start when Advertising is selected.',
      'pub_store_success': 'Save written and read back by the panel.',
      'pub_store_unavailable':
      'Panel advertising storage is unavailable.',
      'pub_store_uncertain':
      'Save not confirmed: the outcome after restart is uncertain.',
      'pub_store_firmware':
      'Incompatible firmware: upload the version with storage.',

      'effects_title': 'Advertising effect',
      'effect_0': 'None',
      'effect_1': 'Blink',
      'effect_2': 'Changing colors',
      'effects_notice':
      'Blink: 1 second on, 1 second off. Changing colors: one color per second, temporarily overrides the selected color.',
      'effects_firmware':
      'Incompatible firmware: upload the effects version.',

      'product_title': 'Product and price',
      'product_explanation':
      'Prepare text locally, then send the settings to the panel. No currency conversion is applied.',
      'product_name': 'Product name',
      'product_ascii': 'No accents or emoji.',
      'product_currency': 'Currency',
      'product_price': 'Price',
      'product_eur_hint':
      'E.g. 12.50: up to 9 digits before and 2 after the decimal.',
      'product_fcfa_hint':
      'E.g. 2500: whole number, up to 9 digits.',
      'product_invalid_name':
      'Enter a non-empty name without accents or emoji.',
      'product_invalid_eur':
      'Invalid EUR price: use up to 9 whole digits and 0 to 2 decimals.',
      'product_invalid_fcfa':
      'Invalid FCFA price: use a whole number of up to 9 digits.',
      'product_too_long': 'The complete message exceeds 100 characters.',
      'product_prepare': 'Prepare message',

      'icons_title': 'Icon before text',
      'icon_0': 'None',
      'icon_1': 'Heart',
      'icon_2': 'Face',
      'icon_3': 'Star',
      'icons_note': 'One 5 × 5 icon, in the same color as the text.',
      'icons_firmware':
      'Incompatible firmware: upload the version with icons.',

      'preview_local': 'Local preview · 32 × 8',
      'preview_notice':
      'Simulation of your draft, independent of the panel. Actual brightness and position may differ.',

      'live_title': 'Advertising control',
      'live_warning':
      'The displayed advertisement is temporary until saved. Select the panel mode on the dashboard.',
      'live_unknown':
      'Confirmation lost: outcome unknown. Reconnect and reload the panel.',
      'live_busy': 'Game active or result displayed: reset the game.',
      'live_offline': 'Panel disconnected.',
      'live_error': 'Communication or validation error.',
      'live_loaded': 'Values read from panel.',
      'live_saved': 'Settings confirmed by the panel.',
      'live_action_ok': 'Command confirmed by the panel.',
      'live_color': 'Color',
      'live_text': 'Text',
      'live_required': 'Enter a message.',
      'live_ascii': 'Maximum 100 characters, no accents or emoji.',
      'live_speed': 'Interval per pixel',
      'live_brightness': 'Brightness',
      'live_scroll': 'Scroll',
      'live_static_note':
      'Without scrolling only the beginning of the text fits on screen.',
      'live_state': 'Last confirmed state',
      'live_play': 'Start',
      'live_pause': 'Pause',
      'live_stop': 'Stop',
      'live_send': 'Send settings',
      'live_reload': 'Reload panel (discard edits)',
      'live_open': 'Live control',
      'playlist_open': 'Playlist',
      'schedule_open': 'Schedule',
      'schedule_active': 'Disable the schedule before using live control.',

      'studio_kicker': 'CREATE · LED STUDIO',
      'studio_intro_ui': 'Create messages, organize your playlist and schedule playback.',
      'studio_live_detail': 'Prepare a message and view its local preview.',
      'studio_playlist_detail': 'Organize messages saved on the panel.',
      'studio_schedule_detail': 'Set dates and times for playback.',
      'studio': 'LED Studio',
      'studio_title': 'Advertising studio',
      'studio_placeholder':
      'Configure a temporary message and control its display.',
      'cap_unknown': 'Advertising capability unconfirmed',
      'cap_on': 'Advertising available',
      'cap_off': 'Advertising not yet available on this panel',

      'game_custom_color': 'Custom color',
      'game_cancel': 'Cancel',
      'game_choose': 'Select',
      'game_selected_color': 'Selected color',
      'color_green': 'Green',
      'color_red': 'Red',
      'color_blue': 'Blue',
      'color_white': 'White',
      'color_orange': 'Orange',
      'game_settings': 'Game settings',
      'game_instructions':
      'Values confirmed by the panel. Changes are accepted only when the game is ready.',
      'game_offline': 'Panel disconnected.',
      'game_busy': 'Game not ready: reset it first.',
      'game_loaded': 'Values read from panel.',
      'game_saved': 'Settings applied and confirmed by the panel.',
      'game_target': 'Target time',
      'game_time_help': 'Format mm:ss.cc, seconds from 00 to 59',
      'game_margin': 'Margin in hundredths',
      'game_margin_help': '0 = exact; nonzero boundaries are excluded.',
      'game_easy': 'Easy mode color',
      'game_hard': 'Hard mode color',
      'game_hex_hint':
      'Six hexadecimal characters, for example 00FF00.',
      'game_speed': 'Smiley traversal (ms)',
      'game_speed_help': 'From 100 to 60000 ms per cycle',
      'game_apply': 'Apply to panel',
      'game_reload': 'Reload panel (discards edits)',
      'game_invalid': 'Invalid value.',
      'game_error': 'Communication or response error.',
      'game_storage_error': 'Panel did not confirm storage.',
      'game_uncertain':
      'Confirmation lost: outcome unknown. Reconnect and reload before retrying.',
      'game_mismatch': 'Response differs from request. Reload the panel.',

      'connect': 'Connection',
      'dashboard': 'Dashboard',
      'settings_kicker': 'CONFIGURATION',
      'settings_intro': 'Personalize the appearance and access game settings.',
      'settings': 'Settings',
      'connection_kicker': 'DEVICE · LOCAL CONNECTION',
      'connection_intro': 'Connect your phone to the AMZ-IT panel to check its status and control it.',
      'connection_steps': 'How to connect',
      'connect_title': 'Connect the panel',
      'instructions':
      '1. Join the AMZ-IT-XXXX Wi-Fi network in your phone settings.\n\n'
          '2. Stay connected even if there is no Internet. If necessary, disable mobile data for testing.\n\n'
          '3. Return here and check the connection.',
      'address': 'Panel name',
      'check': 'Check connection',
      'checking': 'Connecting…',
      'connected': 'Panel connected',
      'disconnected': 'Panel disconnected',
      'unconfirmed': 'No confirmed status',
      'state': 'State',
      'mode': 'Mode',
      'refresh': 'Refresh',
      'lang': 'Language',
      'theme': 'Appearance',
      'light': 'Light',
      'dark': 'Dark',
      'system': 'System',
      'theme_save_error': 'Could not save the theme.',
      'invalid_ip': 'Invalid IPv4 address.',
      'connection_error':
      'Connection failed. Check Wi-Fi and the panel address.',
      'security':
      'Unencrypted WebSocket with no API key: use only for testing on a trusted network.',
      'next': 'Game settings will be added in the next step.',
      'last': 'Last status confirmed by the panel.',

      'pret': 'Ready',
      'en_cours': 'Running',
      'resultat': 'Result',
      'victoire': 'Victory',
      'capture': 'Captured',
      'facile': 'Easy',
      'difficile': 'Hard',
      'smiley': 'Smiley',
    },
  };
}

class AppController extends GetxController {
  AppController(ThemeMode initialTheme)
      : selectedTheme = initialTheme.obs;

  final Rx<ThemeMode> selectedTheme;
  final prefs = SharedPreferencesAsync();
  Future<void> pendingThemeSave = Future.value();

  final service = PanelService();

  static const String panneauIp = '192.168.4.88';
  static const String panneauNom = 'amz-adv.local';

  final selected = 0.obs;
  final busy = false.obs;
  final connected = false.obs;
  final mode = ''.obs;
  final state = ''.obs;
  final displayMode = 'unknown'.obs;
  final panelId = ''.obs;
  final modeBusy = false.obs;
  final modeError = ''.obs;
  final error = ''.obs;
  final RxnBool advertising = RxnBool();
  Timer? _clockTimer; bool _clockBusy = false;

  Future<void> connect() async {
    if (busy.value) return;

    busy.value = true;
    connected.value = false;
    error.value = '';
    advertising.value = null;
    displayMode.value = 'unknown';
    panelId.value = '';

    try {
      await service.connect(
        panneauIp,
        onStatus: (s) {
          mode.value = s.mode;
          state.value = s.state;
          displayMode.value = s.displayMode;
          panelId.value = s.panelId ?? '';
          connected.value = true;
        },
        onDisconnected: () {
          connected.value = false;
          advertising.value = null;
          displayMode.value = 'unknown';
          panelId.value = '';
          error.value = 'connection_error';
        },
      );

      selected.value = 1;
      unawaited(syncClock());
      _clockTimer?.cancel();
      _clockTimer=Timer.periodic(const Duration(minutes:30), (_) => unawaited(syncClock()));

      try {
        final available = await service.advertisingAvailable();

        if (connected.value) {
          advertising.value = available;
        }
      } catch (_) {
        advertising.value = null;
      }
    } catch (e) {
      connected.value = false;
      error.value = e is FormatException && e.message == 'invalid_ip'
          ? 'invalid_ip'
          : 'connection_error';
    } finally {
      busy.value = false;
    }
  }

  Future<void> syncClock() async {
    if(!connected.value || _clockBusy)return;
    _clockBusy=true;
    try {
      final clock=await compute(phoneClockSnapshot,0);
      if(connected.value) await service.synchronizeClock(clock);
    } catch (_) { /* L'écran de programmation permet de vérifier et réessayer. */ }
    finally {_clockBusy=false;}
  }

  Future<void> switchDisplay(String target) async {
    if (!connected.value || modeBusy.value) return;

    modeBusy.value = true;
    modeError.value = '';

    try {
      final result = await service.setDisplayMode(target);
      displayMode.value = result.displayMode;
      state.value = result.state;
    } catch (_) {
      displayMode.value = 'unknown';
      modeError.value = 'display_change_error';
    } finally {
      modeBusy.value = false;
    }
  }

  void selectLanguage(String language) {
    Get.updateLocale(
      Locale(language, language == 'fr' ? 'FR' : 'US'),
    );
  }

  void selectTheme(ThemeMode value) {
    selectedTheme.value = value;
    Get.changeThemeMode(value);

    pendingThemeSave = pendingThemeSave.then((_) async {
      try {
        await prefs.setString('theme_mode', value.name);
      } catch (_) {
        Get.snackbar('theme'.tr, 'theme_save_error'.tr);
      }
    });
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    unawaited(service.close());
    super.onClose();
  }
}

class AmzApp extends StatelessWidget {
  const AmzApp({
    super.key,
    this.initialTheme = ThemeMode.system,
  });

  final ThemeMode initialTheme;

  @override
  Widget build(BuildContext context) => GetMaterialApp(
    title: 'AMZ-IT',
    debugShowCheckedModeBanner: false,
    translations: Texts(),
    locale: const Locale('fr', 'FR'),
    fallbackLocale: const Locale('en', 'US'),
    theme: amzLightTheme,
    darkTheme: amzDarkTheme,
    themeMode: initialTheme,
    home: Home(initialTheme: initialTheme),
  );
}

class Home extends StatefulWidget {
  const Home({
    super.key,
    required this.initialTheme,
  });

  final ThemeMode initialTheme;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final AppController c;

  @override
  void initState() {
    super.initState();
    c = Get.put(AppController(widget.initialTheme));
  }

  @override
  void dispose() {
    Get.delete<AppController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final wide =
        MediaQuery.sizeOf(context).width >= AmzBreakpoints.tablet;

    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.wifi),
        label: 'connect'.tr,
      ),
      NavigationDestination(
        icon: const Icon(Icons.dashboard_outlined),
        label: 'dashboard'.tr,
      ),
      NavigationDestination(
        icon: const Icon(Icons.auto_awesome_outlined),
        label: 'studio'.tr,
      ),
      NavigationDestination(
        icon: const Icon(Icons.tune),
        label: 'settings'.tr,
      ),
    ];

    final content = SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AmzBreakpoints.contentMax,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AmzSpacing.lg),
            child: pages()[c.selected.value],
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('AMZ', style: Theme.of(context).textTheme.titleLarge),
            Text('-IT', style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            )),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'ADVERTISING MATRIX',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
      body: wide
          ? Row(
        children: [
          NavigationRail(
            selectedIndex: c.selected.value,
            onDestinationSelected: (v) => c.selected.value = v,
            labelType: NavigationRailLabelType.all,
            useIndicator: true,
            destinations: destinations
                .map(
                  (d) => NavigationRailDestination(
                icon: d.icon,
                label: Text(d.label),
              ),
            )
                .toList(),
          ),
          Expanded(child: content),
        ],
      )
          : content,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
        selectedIndex: c.selected.value,
        onDestinationSelected: (v) => c.selected.value = v,
        destinations: destinations,
      ),
    );
  });

  List<Widget> pages() => [
    connection(),
    dashboard(),
    studio(),
    settings(),
  ];

  Widget connection() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final online = c.connected.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('connection_kicker'.tr, style: theme.textTheme.labelSmall?.copyWith(
          color: colors.primary, letterSpacing: 1.4,
        )),
        const SizedBox(height: 8),
        Text('connect_title'.tr, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('connection_intro'.tr, style: theme.textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        )),
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Icon(Icons.wifi_tethering, color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Text('connection_steps'.tr,
                      style: theme.textTheme.titleLarge)),
                ]),
                const SizedBox(height: 16),
                Text('instructions'.tr, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 20),
                TextFormField(
                  initialValue: AppController.panneauNom,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'address'.tr,
                    prefixIcon: const Icon(Icons.dns_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: c.busy.value ? null : c.connect,
                  icon: const Icon(Icons.link),
                  label: Text((c.busy.value ? 'checking' : 'check').tr),
                ),
                if (c.error.value.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(c.error.value.tr, style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.error,
                  )),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(online ? Icons.check_circle_outline : Icons.link_off,
                      color: online ? colors.primary : colors.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(child: Text((online ? 'connected' : 'disconnected').tr,
                      style: theme.textTheme.titleMedium)),
                ]),
                const SizedBox(height: 8),
                Text((online ? 'last' : 'unconfirmed').tr,
                    style: theme.textTheme.bodySmall),
                if (online) ...[
                  const SizedBox(height: 12),
                  Text('panel_id_label'.tr, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 4),
                  SelectableText(c.panelId.value.isEmpty
                      ? 'panel_id_unknown'.tr : c.panelId.value,
                      style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('security'.tr, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Future<void> selectDisplayMode(String target) async {
    if (target == 'advertising' &&
        c.displayMode.value != 'advertising') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('display_confirm_title'.tr),
          content: Text('display_confirm_body'.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('game_cancel'.tr),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('display_confirm'.tr),
            ),
          ],
        ),
      );

      if (!mounted || confirmed != true) return;
    }

    await c.switchDisplay(target);
  }

  Widget dashboard() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final online = c.connected.value;
    final confirmedMode = online && c.displayMode.value != 'unknown'
        ? 'display_${c.displayMode.value}'.tr
        : 'display_unknown'.tr;

    Widget infoCard({required IconData icon, required String label,
      required String value, String? detail}) => Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.primary, size: 22),
            const SizedBox(height: 14),
            Text(label, style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
            )),
            const SizedBox(height: 6),
            Text(value, style: theme.textTheme.titleLarge),
            if (detail != null) ...[
              const SizedBox(height: 4),
              Text(detail, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('dash_kicker'.tr, style: theme.textTheme.labelSmall?.copyWith(
          color: colors.primary, letterSpacing: 1.4,
        )),
        const SizedBox(height: 8),
        Text('dashboard'.tr, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('dash_intro'.tr, style: theme.textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        )),
        const SizedBox(height: 24),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 680 ? 3 :
          constraints.maxWidth >= 420 ? 2 : 1;
          final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(width: width, child: infoCard(
              icon: online ? Icons.wifi : Icons.wifi_off,
              label: 'state'.tr,
              value: (online ? 'connected' : 'disconnected').tr,
              detail: (online ? 'last' : 'unconfirmed').tr,
            )),
            SizedBox(width: width, child: infoCard(
              icon: Icons.memory_outlined,
              label: 'panel_id_label'.tr,
              value: online && c.panelId.value.isNotEmpty
                  ? c.panelId.value : 'panel_id_unknown'.tr,
            )),
            SizedBox(width: width, child: infoCard(
              icon: Icons.layers_outlined,
              label: 'display_current'.tr,
              value: confirmedMode,
            )),
          ]);
        }),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('display_title'.tr, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('${'display_current'.tr} : $confirmedMode',
                    style: theme.textTheme.bodyMedium),
                if (online) ...[
                  const SizedBox(height: 8),
                  Text('${'dash_game_mode'.tr} : ${c.mode.value.tr} · '
                      '${'state'.tr} : ${c.state.value.tr}',
                      style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  OutlinedButton.icon(
                    onPressed: online && !c.modeBusy.value
                        ? () => selectDisplayMode('game') : null,
                    icon: const Icon(Icons.sports_esports_outlined),
                    label: Text('display_game'.tr),
                  ),
                  OutlinedButton.icon(
                    onPressed: online && !c.modeBusy.value
                        ? () => selectDisplayMode('advertising') : null,
                    icon: const Icon(Icons.campaign_outlined),
                    label: Text('display_advertising'.tr),
                  ),
                ]),
                if (c.modeError.value.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(c.modeError.value.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(color: colors.error)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: c.busy.value ? null : c.connect,
            icon: const Icon(Icons.refresh),
            label: Text('refresh'.tr),
          ),
        ),
      ],
    );
  }

  Widget studio() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final available = c.connected.value && c.advertising.value == true;
    final capability = !c.connected.value || c.advertising.value == null
        ? 'cap_unknown'
        : c.advertising.value! ? 'cap_on' : 'cap_off';

    Widget featureCard({
      required IconData icon,
      required String title,
      required String description,
      required VoidCallback open,
    }) => Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.primary, size: 26),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(description, style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            )),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: available ? open : null,
              icon: const Icon(Icons.arrow_forward),
              label: Text(title),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('studio_kicker'.tr, style: theme.textTheme.labelSmall?.copyWith(
          color: colors.primary, letterSpacing: 1.4,
        )),
        const SizedBox(height: 8),
        Text('studio_title'.tr, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('studio_intro_ui'.tr, style: theme.textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        )),
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Icon(available ? Icons.check_circle_outline : Icons.info_outline,
                  color: available ? colors.primary : colors.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(child: Text(capability.tr, style: theme.textTheme.bodyMedium)),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 680 ? 3 :
          constraints.maxWidth >= 420 ? 2 : 1;
          final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(width: width, child: featureCard(
              icon: Icons.edit_note,
              title: 'live_open'.tr,
              description: 'studio_live_detail'.tr,
              open: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => LiveAdPage(
                  service: c.service,
                  connected: c.connected,
                  gameState: c.state,
                  displayMode: c.displayMode,
                ),
              )),
            )),
            SizedBox(width: width, child: featureCard(
              icon: Icons.view_list_outlined,
              title: 'playlist_open'.tr,
              description: 'studio_playlist_detail'.tr,
              open: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PlaylistPage(
                  service: c.service,
                  connected: c.connected,
                  displayMode: c.displayMode,
                ),
              )),
            )),
            SizedBox(width: width, child: featureCard(
              icon: Icons.calendar_month_outlined,
              title: 'schedule_open'.tr,
              description: 'studio_schedule_detail'.tr,
              open: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SchedulePage(service: c.service, connected: c.connected),
              )),
            )),
          ]);
        }),
      ],
    );
  }

  Widget settings() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('settings_kicker'.tr, style: theme.textTheme.labelSmall?.copyWith(
          color: colors.primary, letterSpacing: 1.4,
        )),
        const SizedBox(height: 8),
        Text('settings'.tr, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('settings_intro'.tr, style: theme.textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        )),
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Icon(Icons.palette_outlined, color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Text('theme'.tr, style: theme.textTheme.titleLarge)),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<ThemeMode>(
                  initialValue: c.selectedTheme.value,
                  decoration: InputDecoration(labelText: 'theme'.tr),
                  onChanged: (v) {
                    if (v != null) c.selectTheme(v);
                  },
                  items: [
                    DropdownMenuItem(value: ThemeMode.system, child: Text('system'.tr)),
                    DropdownMenuItem(value: ThemeMode.light, child: Text('light'.tr)),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text('dark'.tr)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Icon(Icons.language, color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Text('lang'.tr, style: theme.textTheme.titleLarge)),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: Get.locale?.languageCode ?? 'fr',
                  decoration: InputDecoration(labelText: 'lang'.tr),
                  onChanged: (v) {
                    if (v != null) c.selectLanguage(v);
                  },
                  items: const [
                    DropdownMenuItem(value: 'fr', child: Text('Français')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Icon(Icons.sports_esports_outlined, color: colors.primary),
            title: Text('game_settings'.tr, style: theme.textTheme.titleMedium),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GameSettingsPage(
                  service: c.service,
                  connected: c.connected,
                  gameState: c.state,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
