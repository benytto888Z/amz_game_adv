import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/amz_light_theme.dart';
import 'core/theme/amz_dark_theme.dart';
import 'core/design_system/spacing.dart';
import 'core/design_system/components/amz_section_card.dart';
import 'core/responsive/breakpoints.dart';
import 'services/panel_service.dart';
import 'features/game_settings/game_settings_page.dart';
import 'features/live_ad/live_ad_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ThemeMode initial=ThemeMode.system;
  try {
    final saved=await SharedPreferencesAsync().getString('theme_mode');
    initial=ThemeMode.values.where((m)=>m.name==saved).firstOrNull ?? ThemeMode.system;
  } catch (_) { /* A storage failure must not block startup. */ }
  runApp(AmzApp(initialTheme:initial));
}

class Texts extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'fr_FR': {'icons_title':'Icône avant le texte','icon_0':'Aucune','icon_1':'Cœur','icon_2':'Visage','icon_3':'Étoile','icons_note':'Une icône 5 × 5, de la même couleur que le texte.','icons_firmware':'Firmware incompatible : téléversez la version avec icônes.','preview_local':'Aperçu local · 32 × 8','preview_notice':'Simulation de votre saisie, indépendante du panneau. La luminosité et la position réelles peuvent différer.','live_title':'Contrôle publicitaire','live_warning':'Contrôle temporaire : le texte est perdu au redémarrage. La lecture reprend après le jeu.','live_unknown':'Confirmation perdue : état inconnu. Reconnectez-vous puis relisez le panneau.','live_busy':'Jeu en cours ou résultat : remettez le jeu à zéro.','live_offline':'Panneau non connecté.','live_error':'Erreur de communication ou de validation.','live_loaded':'Données lues depuis le panneau.','live_saved':'Configuration confirmée par le panneau.','live_action_ok':'Commande confirmée par le panneau.','live_color':'Couleur','live_text':'Texte','live_required':'Saisissez un message.','live_ascii':'100 caractères maximum, sans accents ni emoji.','live_speed':'Intervalle par pixel','live_brightness':'Luminosité','live_scroll':'Défilement','live_static_note':'Sans défilement, seul le début du texte tient à l’écran.','live_state':'Dernier état confirmé','live_play':'Démarrer','live_pause':'Pause','live_stop':'Arrêter','live_send':'Envoyer les réglages','live_reload':'Relire le panneau (efface les modifications)','live_open':'Contrôle en direct','studio':'Studio LED','studio_title':'Studio publicitaire','studio_placeholder':'Configurez un message temporaire et pilotez son affichage.','cap_unknown':'Capacité publicitaire non confirmée','cap_on':'Publicité disponible','cap_off':'Publicité non encore disponible sur ce panneau','game_custom_color':'Couleur personnalisée','game_cancel':'Annuler','game_choose':'Choisir','game_selected_color':'Couleur sélectionnée','color_green':'Vert','color_red':'Rouge','color_blue':'Bleu','color_white':'Blanc','color_orange':'Orange','game_settings':'Réglages du jeu','game_instructions':'Valeurs confirmées par le panneau. Les modifications sont possibles uniquement lorsque le jeu est prêt.','game_offline':'Panneau non connecté.','game_busy':'Jeu non prêt : remettez-le à zéro.','game_loaded':'Valeurs lues sur le panneau.','game_saved':'Réglages appliqués et confirmés par le panneau.','game_target':'Temps cible','game_time_help':'Format mm:ss.cc, secondes de 00 à 59','game_margin':'Marge en centièmes','game_margin_help':'0 = exact ; les bornes non nulles sont exclues.','game_easy':'Couleur facile','game_hard':'Couleur difficile','game_hex_hint':'Six caractères hexadécimaux, par exemple 00FF00.','game_speed':'Traversée smiley (ms)','game_speed_help':'De 100 à 60000 ms par cycle','game_apply':'Appliquer au panneau','game_reload':'Relire le panneau (efface la saisie)','game_invalid':'Valeur invalide.','game_error':'Erreur de communication ou de réponse.','game_storage_error':'Sauvegarde non confirmée par le panneau.','game_uncertain':'Confirmation perdue : résultat inconnu. Reconnectez-vous puis relisez le panneau avant de réessayer.','game_mismatch':'La réponse diffère de la demande. Relisez le panneau.','connect':'Connexion','dashboard':'Tableau de bord','settings':'Réglages',
      'connect_title':'Connecter le panneau','instructions':'1. Rejoignez le réseau Wi-Fi AMZ-IT-XXXX dans les réglages du téléphone.\n\n2. Restez connecté même si le réseau est sans Internet. Si nécessaire, désactivez les données mobiles pour le test.\n\n3. Revenez ici et vérifiez la connexion.',
      'address':'Nom du panneau','check':'Vérifier la connexion','checking':'Connexion…','connected':'Panneau connecté','disconnected':'Panneau déconnecté',
      'unconfirmed':'Aucun état confirmé','state':'État','mode':'Mode','refresh':'Actualiser','lang':'Langue','theme':'Apparence','light':'Clair','dark':'Sombre','system':'Système','theme_save_error':'Impossible de sauvegarder le thème.',
      'invalid_ip':'Adresse IPv4 invalide.','connection_error':'Connexion impossible. Vérifiez le Wi-Fi et l’adresse du panneau.',
      'security':'WebSocket non chiffré et sans clé API : réservé aux essais sur réseau de confiance.',
      'next':'Les réglages du jeu seront ajoutés à l’étape suivante.', 'last':'Dernier état confirmé par le panneau.',
      'pret':'Prêt','en_cours':'En cours','resultat':'Résultat','victoire':'Victoire','capture':'Capture','facile':'Facile','difficile':'Difficile','smiley':'Smiley'},
    'en_US': {'icons_title':'Icon before text','icon_0':'None','icon_1':'Heart','icon_2':'Face','icon_3':'Star','icons_note':'One 5 × 5 icon, in the same color as the text.','icons_firmware':'Incompatible firmware: upload the version with icons.','preview_local':'Local preview · 32 × 8','preview_notice':'Simulation of your draft, independent of the panel. Actual brightness and position may differ.','live_title':'Advertising control','live_warning':'Temporary control: text is lost on restart. Playback resumes after a game.','live_unknown':'Confirmation lost: outcome unknown. Reconnect and reload the panel.','live_busy':'Game active or result displayed: reset the game.','live_offline':'Panel disconnected.','live_error':'Communication or validation error.','live_loaded':'Values read from panel.','live_saved':'Settings confirmed by the panel.','live_action_ok':'Command confirmed by the panel.','live_color':'Color','live_text':'Text','live_required':'Enter a message.','live_ascii':'Maximum 100 characters, no accents or emoji.','live_speed':'Interval per pixel','live_brightness':'Brightness','live_scroll':'Scroll','live_static_note':'Without scrolling only the beginning of the text fits on screen.','live_state':'Last confirmed state','live_play':'Start','live_pause':'Pause','live_stop':'Stop','live_send':'Send settings','live_reload':'Reload panel (discard edits)','live_open':'Live control','studio':'LED Studio','studio_title':'Advertising studio','studio_placeholder':'Configure a temporary message and control its display.','cap_unknown':'Advertising capability unconfirmed','cap_on':'Advertising available','cap_off':'Advertising not yet available on this panel','game_custom_color':'Custom color','game_cancel':'Cancel','game_choose':'Select','game_selected_color':'Selected color','color_green':'Green','color_red':'Red','color_blue':'Blue','color_white':'White','color_orange':'Orange','game_settings':'Game settings','game_instructions':'Values confirmed by the panel. Changes are accepted only when the game is ready.','game_offline':'Panel disconnected.','game_busy':'Game not ready: reset it first.','game_loaded':'Values read from panel.','game_saved':'Settings applied and confirmed by the panel.','game_target':'Target time','game_time_help':'Format mm:ss.cc, seconds from 00 to 59','game_margin':'Margin in hundredths','game_margin_help':'0 = exact; nonzero boundaries are excluded.','game_easy':'Easy mode color','game_hard':'Hard mode color','game_hex_hint':'Six hexadecimal characters, for example 00FF00.','game_speed':'Smiley traversal (ms)','game_speed_help':'From 100 to 60000 ms per cycle','game_apply':'Apply to panel','game_reload':'Reload panel (discards edits)','game_invalid':'Invalid value.','game_error':'Communication or response error.','game_storage_error':'Panel did not confirm storage.','game_uncertain':'Confirmation lost: outcome unknown. Reconnect and reload before retrying.','game_mismatch':'Response differs from request. Reload the panel.','connect':'Connection','dashboard':'Dashboard','settings':'Settings',
      'connect_title':'Connect the panel','instructions':'1. Join the AMZ-IT-XXXX Wi-Fi network in your phone settings.\n\n2. Stay connected even if there is no Internet. If necessary, disable mobile data for testing.\n\n3. Return here and check the connection.',
      'address':'Panel name','check':'Check connection','checking':'Connecting…','connected':'Panel connected','disconnected':'Panel disconnected',
      'unconfirmed':'No confirmed status','state':'State','mode':'Mode','refresh':'Refresh','lang':'Language','theme':'Appearance','light':'Light','dark':'Dark','system':'System','theme_save_error':'Could not save the theme.',
      'invalid_ip':'Invalid IPv4 address.','connection_error':'Connection failed. Check Wi-Fi and the panel address.',
      'security':'Unencrypted WebSocket with no API key: use only for testing on a trusted network.',
      'next':'Game settings will be added in the next step.', 'last':'Last status confirmed by the panel.',
      'pret':'Ready','en_cours':'Running','resultat':'Result','victoire':'Victory','capture':'Captured','facile':'Easy','difficile':'Hard','smiley':'Smiley'},
  };
}

class AppController extends GetxController {
  AppController(ThemeMode initialTheme) : selectedTheme=initialTheme.obs;
  final Rx<ThemeMode> selectedTheme;
  final prefs=SharedPreferencesAsync();
  Future<void> pendingThemeSave=Future.value();
  final service=PanelService();
  static const String panneauIp='192.168.4.88';
  static const String panneauNom='amz-adv.local';
  final selected=0.obs;
  final busy=false.obs;
  final connected=false.obs;
  final mode=''.obs;
  final state=''.obs;
  final error=''.obs;
  final RxnBool advertising=RxnBool();
  Future<void> connect() async {
    if(busy.value)return;
    busy.value=true; connected.value=false; error.value=''; advertising.value=null;
    try {
      await service.connect(panneauIp, onStatus:(s){mode.value=s.mode;state.value=s.state;connected.value=true;},
          onDisconnected:(){connected.value=false;advertising.value=null;error.value='connection_error';});
      selected.value=1;
      try {
        final available=await service.advertisingAvailable();
        if(connected.value) advertising.value=available;
      } catch (_) { advertising.value=null; }
    } catch(e) {connected.value=false;error.value=e is FormatException && e.message=='invalid_ip'?'invalid_ip':'connection_error';}
    finally {busy.value=false;}
  }
  void selectLanguage(String language) { Get.updateLocale(Locale(language,language=='fr'?'FR':'US')); }
  void selectTheme(ThemeMode value) {
    selectedTheme.value=value;
    Get.changeThemeMode(value);
    pendingThemeSave=pendingThemeSave.then((_) async {
      try { await prefs.setString('theme_mode',value.name); }
      catch (_) { Get.snackbar('theme'.tr,'theme_save_error'.tr); }
    });
  }
  @override void onClose(){unawaited(service.close());super.onClose();}
}

class AmzApp extends StatelessWidget {
  const AmzApp({super.key, this.initialTheme=ThemeMode.system});
  final ThemeMode initialTheme;
  @override Widget build(BuildContext context) => GetMaterialApp(
      title:'AMZ-IT', debugShowCheckedModeBanner:false, translations:Texts(),
      locale:const Locale('fr','FR'), fallbackLocale:const Locale('en','US'),
      theme:amzLightTheme, darkTheme:amzDarkTheme,
      themeMode:initialTheme, home:Home(initialTheme:initialTheme));
}
class Home extends StatefulWidget {
  const Home({super.key, required this.initialTheme});
  final ThemeMode initialTheme;
  @override State<Home> createState()=>_HomeState();
}
class _HomeState extends State<Home> {
  late final AppController c;
  @override void initState(){super.initState();c=Get.put(AppController(widget.initialTheme));}
  @override void dispose(){Get.delete<AppController>();super.dispose();}
  @override Widget build(BuildContext context) => Obx(() {
    final wide=MediaQuery.sizeOf(context).width>=AmzBreakpoints.tablet;
    final destinations=[
      NavigationDestination(icon:const Icon(Icons.wifi),label:'connect'.tr),
      NavigationDestination(icon:const Icon(Icons.dashboard_outlined),label:'dashboard'.tr),
      NavigationDestination(icon:const Icon(Icons.auto_awesome_outlined),label:'studio'.tr),
      NavigationDestination(icon:const Icon(Icons.tune),label:'settings'.tr),
    ];
    final content=SafeArea(child:Center(child:ConstrainedBox(
        constraints:const BoxConstraints(maxWidth:AmzBreakpoints.contentMax),
        child:SingleChildScrollView(padding:const EdgeInsets.all(AmzSpacing.lg),child:pages()[c.selected.value]))));
    return Scaffold(
      appBar:AppBar(title:const Text('AMZ-IT • GAME')),
      body:wide ? Row(children:[NavigationRail(selectedIndex:c.selected.value,
          onDestinationSelected:(v)=>c.selected.value=v, labelType:NavigationRailLabelType.all,
          destinations:destinations.map((d)=>NavigationRailDestination(icon:d.icon,label:Text(d.label))).toList()),
        Expanded(child:content)]) : content,
      bottomNavigationBar:wide?null:NavigationBar(selectedIndex:c.selected.value,
          onDestinationSelected:(v)=>c.selected.value=v,destinations:destinations),
    );
  });
  List<Widget> pages()=>[connection(),dashboard(),studio(),settings()];
  Widget connection()=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Text('connect_title'.tr,style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:12),
    AmzSectionCard(child:Text('instructions'.tr)),const SizedBox(height:16),
    TextFormField(initialValue:AppController.panneauNom,enabled:false,
        decoration:InputDecoration(labelText:'address'.tr,border:const OutlineInputBorder())),const SizedBox(height:12),
    Text('security'.tr),const SizedBox(height:16),
    FilledButton.icon(onPressed:c.busy.value?null:c.connect,icon:const Icon(Icons.link),label:Text((c.busy.value?'checking':'check').tr)),
    if(c.error.value.isNotEmpty) Padding(padding:const EdgeInsets.only(top:12),child:Text(c.error.value.tr,style:TextStyle(color:Theme.of(context).colorScheme.error))),
  ]);
  Widget dashboard()=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Text('dashboard'.tr,style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:16),
    Card(child:Column(children:[ListTile(leading:Icon(c.connected.value?Icons.check_circle_outline:Icons.link_off),
        title:Text((c.connected.value?'connected':'disconnected').tr),subtitle:Text((c.connected.value?'last':'unconfirmed').tr)),
      if(c.connected.value) ...[ListTile(title:Text('mode'.tr),trailing:Text(c.mode.value.tr)),ListTile(title:Text('state'.tr),trailing:Text(c.state.value.tr))]])),
    const SizedBox(height:12),OutlinedButton(onPressed:c.busy.value?null:c.connect,child:Text('refresh'.tr)),
  ]);
  Widget studio()=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Text('studio_title'.tr,style:Theme.of(context).textTheme.headlineSmall),
    const SizedBox(height:16),
    AmzSectionCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('studio_placeholder'.tr),const SizedBox(height:12),
      Text((!c.connected.value || c.advertising.value==null ? 'cap_unknown' : c.advertising.value! ? 'cap_on' : 'cap_off').tr),
      const SizedBox(height:12),
      FilledButton(onPressed:c.connected.value && c.advertising.value==true ? () => Navigator.of(context).push(MaterialPageRoute(builder:(_)=>LiveAdPage(service:c.service,connected:c.connected,gameState:c.state))) : null,child:Text('live_open'.tr)),
    ])),
  ]);
  Widget settings()=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Text('settings'.tr,style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:12),
    Card(child:Column(children:[ListTile(title:Text('lang'.tr),trailing:DropdownButton<String>(value:Get.locale?.languageCode??'fr',
        onChanged:(v){if(v!=null)c.selectLanguage(v);},items:const [DropdownMenuItem(value:'fr',child:Text('Français')),DropdownMenuItem(value:'en',child:Text('English'))])),
      ListTile(title:Text('theme'.tr), trailing:DropdownButton<ThemeMode>(value:c.selectedTheme.value, onChanged:(v){if(v!=null)c.selectTheme(v);}, items: [DropdownMenuItem(value:ThemeMode.system,child:Text('system'.tr)),DropdownMenuItem(value:ThemeMode.light,child:Text('light'.tr)),DropdownMenuItem(value:ThemeMode.dark,child:Text('dark'.tr))]))])),
    const SizedBox(height:12), Card(child:ListTile(leading:const Icon(Icons.sports_esports_outlined),title:Text('game_settings'.tr), trailing:const Icon(Icons.chevron_right), onTap:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>GameSettingsPage(service:c.service,connected:c.connected,gameState:c.state))))),
  ]);
}