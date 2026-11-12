# EAX 5 partiel — version 3.0 expérimentale x86

Cette version ajoute un pont EAX 5 aux propriétés DirectSound IKsPropertySet
avec la sortie finale XAudio2 obligatoire. Les chemins EAX 1–4 restent présents.
Le relais OpenAL32 continue d'exposer l'API EAX du moteur OpenAL Soft intégré.
L'architecture reste : moteur principal xaudiouniv.dll renommable et sept relais. Aucun moteur de pilote supplémentaire n'est nécessaire.

## Code eaxefx effectivement utilisé

Quatre fichiers amont sont compilés et liés dans la DLL principale :

- `eaxefx_eax_api.cpp` : définitions de GUID, structures et paramètres ;
- `eaxefx_eaxx_eax_call.cpp` : décodage des appels, version, type de propriété,
  indicateur différé, source et validation de base ;
- `eaxefx_eaxx_fx_slot_index.cpp` : identification des quatre slots EAX 4/5 ;
- `eaxefx_exception.cpp` : erreurs du décodeur, contenues à la frontière du pont.

`src/eax5_bridge.cpp` utilise ce décodeur pour les nouvelles requêtes EAX 5
DirectSound, vérifie les tailles, distingue les propriétés Get/Set et appelle
le moteur EAX intégré d'OpenAL Soft. Le traitement EAX→effets et le DSP sont
ceux d'OpenAL Soft, qui a repris l'émulation d'eaxefx. L'ancien moteur EFX
indépendant d'eaxefx n'est pas exécuté une seconde fois sur les mêmes sources.
Ses chargeurs de pilote et ses patchs d'exécutables de jeux ne sont pas activés.

## Portée de l'émulation

| Fonction | Comportement de cette version |
|---|---|
| Quatre slots EAX 5 / FlexiFX | Quatre destinations actives par source ; un effet par slot, donc routage parallèle, pas quatre effets en série |
| Effets | Douze effets du moteur OpenAL Soft ; les quatre slots EAX 5 sont chargeables, sans imposer les verrouillages historiques EAX 4 |
| Envois par source | Niveaux et filtrage, occlusion et exclusion par envoi ; tableaux jusqu'à quatre entrées |
| Occlusion des environnements | Occlusion et ratio LF des slots transmis au filtrage du moteur ; atténuation acoustique vérifiée hors ligne |
| Paramètres de source | Direct/room, obstruction, occlusion, exclusion, cônes, facteurs et paramètres 2D selon l'API sous-jacente |
| Paramètres de contexte | Slot primaire, distance, absorption de l'air, état de session EAX 5 et quatre envois |
| Paramètres différés | Set différé et commit immédiat/NONE ; les Get du nouveau pont lisent l'état courant, sans bit DEFERRED |
| Capacités | Allocation de 128 sources vérifiée hors ligne ; pas de mesure de 128 voix jouées simultanément. Le pool de voix DirectSound reste géré par DSOAL |
| HFReference du contexte | Valeur conservée/restituée ; traitement acoustique spécifique absent dans le moteur utilisé |
| MacroFX | Facteurs conservés/restitués, y compris dans les structures complètes ; **pas d'effet acoustique MacroFX** |
| Configuration des enceintes EAX | Information lue depuis le moteur ; pas de changement de topologie par ce pont |
| PurePath / niveaux par haut-parleur | **Pas d'émulation dédiée**. Le nouveau pont DirectSound refuse la propriété SPEAKERLEVELS |
| EAX Voice | **Absent** ; la capture DirectSound n'est pas une émulation d'EAX Voice |
| X-RAM | Pas de mémoire matérielle Creative émulée ni de capacité X-RAM nouvelle annoncée |

L'API OpenAL native garde le comportement de la version amont intégrée,
y compris ses paramètres éventuellement conservés sans DSP associé. Une
extension `EAX5.0` présente ne signifie donc pas une reproduction complète
ou certifiée des cartes X-Fi. `eax.dll.GetCurrentVersion` reste 4.0, comme
la convention historique conservée jusque-là ; aucun faux numéro de
compatibilité EAX 5 complète n'est ajouté.

Le LASTERROR du contexte reflète les erreurs du moteur sous-jacent ; les rejets de taille ou de propriété effectués avant son appel sont signalés directement par le retour de l’API/pont.

Le mixage et les effets OpenAL Soft sont remis au backend XAudio2. Les anciens choix Backend=openal/xaudio2 ne sont plus utilisés. Le moteur XAudio2 1.x historique n’est plus lié dans la DLL principale.

## Validation et diagnostic

Exécuté sous Linux sur les mêmes sources du pont et du moteur :

- quatre envois actifs simultanément ;
- quatre rendus d'effets isolés avec le son direct coupé, chacun non nul ;
- baisse d'énergie avec occlusion d'un slot ;
- état de session, tableaux d'envois, tailles réelles retournées par Get ;
- paramètres différés, rejet d'une valeur invalide sans commit prématuré ;
- tailles trop courtes, pointeurs nuls, propriétés inconnues et exceptions ;
- tests de frontière avec le décodeur eaxefx instrumenté ASan/UBSan ;
- régression EAX 1–4 / douze effets et tests historiques du moteur XAudio2.

Les journaux se trouvent dans `validation/eax5-*.txt`.
Les boucles de balayage d'identifiants comptent comme scénarios de validation,
pas comme des dizaines de milliers de fonctions EAX distinctes testées.

Les DLL Windows sont compilées mais **pas exécutées ici**. Sous Windows :

```powershell
.\universal_probe.exe
.\universal_probe.exe --device
.\universal_probe.exe --tone
powershell -ExecutionPolicy Bypass -File .\Test-Architecture.ps1 -Keep
```

Le diagnostic par défaut teste le rendu OpenAL hors ligne. `--device` ajoute
le vrai pont DirectSound/IKsPropertySet, notamment EAX 5 session/quatre slots
avec la sortie XAudio2. `--tone` ajoute une écoute. Les tests de renommage
restent à exécuter sous Windows. Le fonctionnement dans chaque jeu et la
correction du craquement entendu ne sont pas garantis par les tests hors ligne.
