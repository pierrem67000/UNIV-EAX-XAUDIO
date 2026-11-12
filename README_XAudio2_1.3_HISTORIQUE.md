# EAX → XAudio2 — version expérimentale x86 1.3

Wrapper DirectSound / DirectSound3D / EAX 1, 2, 3 et 4, construit à partir des sources fournies. Les jeux appellent les interfaces historiques ; le son est traité par XAudio2 2.8 ou 2.9 et quatre effets XAPO intégrés au wrapper.

**Statut : compilé, tests DSP et propriétés exécutés ; validation réelle dans un jeu Windows restant à faire. Ce n'est pas une reproduction certifiée du DSP Creative.**

## Version 1.3 — presets, réverbération et transitions 3D

- **26 presets EAX 1 distincts**, avec les valeurs de volume/décroissance/amortissement du SDK, plutôt qu'une reconstruction depuis EAX 3. Le volume nul coupe le chemin réverbéré ; la conversion vers le DSP reste une approximation logicielle.
- **Réverbération à trois bandes de décroissance** : boucles stables séparées pour les graves, médiums et aigus, commandées par DecayTime, DecayLFRatio, DecayHFRatio, LFReference et HFReference. Le flag DECAYHFLIMIT borne la décroissance aiguë selon l'absorption de l'air.
- **Diffusion du champ tardif** par quatre étages allpass par canal. EnvironmentDiffusion ne règle plus seulement des taps de réflexions précoces.
- **Panoramiques séparés des réflexions et de la réverbération tardive**, avec projection des vecteurs relatifs à l'auditeur sur deux haut-parleurs. La magnitude règle la focalisation, les transitions des vecteurs sont lissées. Aucun positionnement avant/arrière ou vertical réel n'est revendiqué en stéréo.
- **État DirectSound3D différé distinct de l'état appliqué**, pour les positions, vitesses, cônes, distances et paramètres de l'auditeur. Une mise à jour de volume ou d'EAX ne fait plus fuiter prématurément un déplacement en attente. CommitDeferredSettings applique ensemble les états en attente des buffers et de l'auditeur ; les mises à jour immédiates d'autres champs sont conservées.
- Validation des mises à jour spatiales, notamment NaN, distances non positives et orientations d'auditeur dégénérées, avec conservation de l'état précédent en cas d'erreur.

L'API annoncée reste **EAX 4.0**, avec les chemins EAX 1–3 et le pool de 64 voix émulées de la v1.2. Les limites ne sont pas artificiellement ramenées à 8/32 voix quand une ancienne API est utilisée. L'API EAX 1 n'offre qu'un mix de réverbération par source et un environnement global : cette version n'invente pas de propriété de preset individuel par canal.

**EAX 5 n'est pas ajouté** : pas d'API EAX 5, EAX Voice, PurePath, MacroFX ou quatre envois FlexiFX par source. Le traitement est effectué sur CPU, hébergé dans XAudio2, et non sur un DSP Creative. Les ajouts améliorent le rendu et le comportement sans constituer une certification de conformité Creative.

## Version 1.2 — rapprochement du comportement EAX 4

- Slots 0/1 initialisés en **réverbération / chorus verrouillés**. Les types de ces deux slots historiques ne peuvent plus être remplacés ni déverrouillés ; leurs paramètres, volume et flags restent réglables. Les slots 2/3 sont flexibles.
- Un appel Set immédiat valide applique les réglages différés antérieurs dans les autres objets, sans exiger systématiquement un appel NONE. Un appel invalide laisse l'état courant et la file en attente intacts.
- Les sources commencent avec l'alias PrimaryFXSlotID du SDK EAX 4. Changer le slot primaire redirige les sources EAX 4 utilisant cet alias. Les sources configurées via EAX 1, 2 ou 3 restent dirigées vers la réverbération historique.
- Les Get des envois initialisent eux-mêmes les GUID de sortie, dans l'ordre des quatre slots. Les tableaux de sortie n'ont plus besoin d'être préremplis. Les Set utilisent des GUID concrets de slot, rejettent les doublons et valident toute l'opération avant application.
- Les listes de slots actifs peuvent contenir un ou deux GUID ; une liste courte est complétée par un slot nul. Deux envois au maximum restent actifs par source.
- Le mode de mix EAX 1 est suivi par source : une autre source utilisant EAX 4 ne le désactive plus.
- Un pool suit **64 voix matérielles émulées** : une demande explicite de 65e buffer matériel échoue, les compteurs GetCaps baissent/remontent à l'allocation/libération. Un buffer sans préférence matérielle explicite peut basculer en logiciel quand le pool est plein. Les buffers explicitement logiciels ne consomment pas ce pool.
- Le budget de stockage émulé est de 32 Mio ; les buffers dupliqués partagent le stockage de leurs échantillons et consomment chacun une voix. Il s'agit d'un budget logiciel, pas de RAM de carte Creative.
- Le rechargement complet d'un effet flexible remet ses paramètres par défaut et efface son historique DSP sans allocation dans le callback. Les protections contre les craquements de la v1.1 sont conservées.

Les détails du SDK ont été confrontés au header EAX4 fourni avec Doom 3 ; certains comportements d'appels et de tableaux ont également été confrontés à l'implémentation EAX d'OpenAL Soft. Aucun code DSP OpenAL Soft n'a été intégré.

**Cette version se rapproche de l'API EAX 4, sans revendiquer une conformité complète ou un rendu acoustique identique à Audigy.** Elle conserve le mixage final stéréo, le DSP approximatif, le listener partagé et les limites DirectSound décrites ci-dessous. EAX 5 n'est pas implémenté.

## Version 1.1 — correction des craquements

Un test a reproduit une instabilité de la version 1.0 avec une décroissance longue et un ratio LF supérieur à 1, pourtant valides en EAX : l'énergie de la boucle augmentait jusqu'à la saturation. Le gain de feedback est maintenant normalisé pour éviter cette divergence.

Autres changements : calcul des coefficients de réverbération déplacé hors de la boucle par échantillon, lecture interpolée des lignes à retard, lissage de 20 ms des temps/niveaux/panoramiques de réverbération, absence d'attente bloquante sur le verrou de paramètres dans le callback XAPO et slots vides rendus silencieux sans boucle DSP inutile.

Un limiteur stéréo à anticipation de 64 échantillons (environ 1,33 ms à 48 kHz) protège le mixage final. Il laisse les signaux modérés inchangés à ce délai près, réduit les pointes dépassant 0,95 et peut modifier la dynamique d'un mixage très fort. Le journal indique maintenant les interruptions audio comptabilisées par XAudio2. Le numéro d'API EAX annoncé reste 4.0.

Ces corrections résolvent les défauts reproduits par les tests, mais leur effet sur le craquement entendu dans le jeu doit être vérifié sous Windows.

## Installation

1. Fermer le jeu et sauvegarder ses DLL existantes.
2. Placer **dsound.dll** et **eax.dll** à côté de l'exécutable du jeu.
3. Activer l'accélération audio / EAX dans les options du jeu, si proposées.
4. Pour revenir à l'état précédent, retirer ces deux fichiers et restaurer les originaux.

Ne pas copier ces fichiers dans System32 ou SysWOW64. Ne pas lancer regsvr32. Ne pas superposer une seconde dsound.dll (DSOAL, ALchemy, autre wrapper) dans le même dossier.

L'archive contient les deux DLL prêtes à essayer, les sources complètes de cette version et deux programmes de diagnostic. Le fichier Creative original fourni n'est pas redistribué dans ce pack.

**Pourquoi deux DLL ?** `dsound.dll` contient tout le moteur. Un jeu qui importe explicitement `eax.dll` a aussi besoin du petit relais portant ce nom. Renommer seulement dsound.dll ne satisfait pas simultanément les deux noms d'import.

## Détection d'EAX

- `eax.dll` conserve les 7 noms d'export et les ordinaux 1 à 7 de la DLL Creative fournie.
- `GetCurrentVersion` retourne HRESULT S_OK et écrit 4 et 0. Sa convention **cdecl** a été vérifiée dans le binaire Creative original ; les fonctions EAXDirectSoundCreate/Create8 restent stdcall.
- `EAXDirectSoundCreate` et `EAXDirectSoundCreate8` créent les objets du wrapper.
- Les buffers exposent `IKsPropertySet`. `QuerySupport` annonce GET/SET pour les propriétés prises en charge, et les capacités DirectSound annoncent 64 voix 3D matérielles émulées en logiciel.
- Les GUID EAX 1, 2, 3 et 4 sont reconnus. Les propriétés inconnues renvoient une erreur au lieu d'un faux succès.

Cela couvre la détection par chargement de DLL, exports, capacités DirectSound et IKsPropertySet. Les jeux qui exigent une clé de registre Creative, un pilote Creative précis ou une activation COM globale peuvent demander une adaptation supplémentaire. Les exports DllRegisterServer/UnregisterServer sont présents pour la compatibilité de chargement mais renvoient SELFREG_E_CLASS, sans modifier le système.

## Fonctions de cette version

| Partie | Traitement |
|---|---|
| EAX 1 | Environnement, volume de réverbération, décroissance, amortissement et mix par buffer |
| EAX 2 | Propriétés listener/buffer, occlusion, obstruction, niveaux et filtrage direct/réverbéré |
| EAX 3 | Propriétés étendues de réverbération et source, panoramiques, écho et modulation |
| EAX 4 | Contexte, quatre FX slots distincts, deux slots actifs par source, envois par slot et leurs paramètres d'occlusion/exclusion |
| EAX différé | Validation transactionnelle, bit DEFERRED, lecture de l'état différé et application au commit NONE |
| Effets EAX 4 | Reverb, AGC compressor, autowah, chorus, distortion, echo, equalizer, flanger, frequency shifter, vocal morpher, pitch shifter et ring modulator |
| DirectSound | Buffers, duplication, volume, balance, fréquence, positions et notifications de lecture |
| DirectSound3D | Position, orientation, cônes, distance et Doppler ; restitution stéréo |
| Formats | PCM mono/stéréo, flottant IEEE et Microsoft ADPCM, selon acceptation par XAudio2 |

Le DSP des effets est implémenté dans `src/fx_dsp.h` et hébergé dans XAudio2 via `src/fx_xapo.h`. Il ne dépend pas de la recherche dynamique du symbole inline XAudio2CreateReverb. Les structures/propriétés EAX restent à la frontière du wrapper ; elles sont converties en paramètres du DSP logiciel.

## Corrections par rapport au code fourni

- Convention cdecl de GetCurrentVersion corrigée, avec code de retour HRESULT.
- État des slots actifs stocké par buffer, au lieu d'une variable statique partagée.
- Quatre bus d'effets XAudio2 indépendants ; les slots 1 à 3 ne sont plus seulement des états sans sortie dédiée.
- Envois et occlusion/exclusion conservés par source et par slot, avec prise en charge des tableaux d'envois.
- Chargement et paramètres des onze effets additionnels EAX 4, en plus de la réverbération.
- Paramètres différés, commits, validation des tailles/plages, rejet des NaN et restauration après erreur.
- Verrouillage des slots et code LASTERROR EAX 4, remis à zéro après lecture.
- Mix EAX 1 conservé, notamment la valeur spéciale -1.
- Correction du dépassement de la petite structure de format avec les formats étendus ; stockage dédié du format complet.
- Durée de vie du moteur indépendante de l'objet DirectSound créateur ; les buffers gardent leur voix.
- Correction de GetCaps : ne remet plus à zéro une longueur arbitraire fournie par l'appelant.
- Relais eax.dll chargé depuis le dossier local en Unicode, sans repli silencieux sur un dsound système.
- Chargement de XAudio2 système par chemin de recherche restreint ; redist facultatif chargé depuis le dossier du wrapper.

## Limites à connaître

- **Les effets sont des approximations logicielles.** Réverbération, filtrage, panoramiques, phonèmes et pitch shift ne sont pas acoustiquement identiques aux cartes Live!/Audigy. La table de formants du vocal morpher est une approximation, avec 30 valeurs de phonème adressables.
- Le mixage final est **stéréo**, même si le jeu demande une configuration d'enceintes différente. Il n'y a pas de HRTF, de vrai 5.1/7.1 ou de DSP Creative matériel.
- La compatibilité universelle n'est pas démontrée. Le streaming DirectSound repose sur le tampon partagé fourni à XAudio2 ; les moteurs qui réécrivent une zone déjà en cours de lecture demandent un test particulier.
- Les effets DirectSound8 via SetFX/GetObjectInPath sont distincts d'EAX et ne sont pas implémentés. AcquireResources ne réalise pas de réservation matérielle.
- Capture et full duplex exportés passent par le DirectSound système et ne bénéficient pas des effets EAX du wrapper. Les appels COM système ne sont pas interceptés globalement.
- Un seul moteur et un seul listener sont partagés dans le processus. Le GUID de périphérique de lecture n'est pas utilisé pour sélectionner une autre sortie ; la sortie Windows par défaut est utilisée.
- Le moteur et le module dsound sont conservés jusqu'à la fin du processus pour éviter un déchargement pendant un callback audio. Un redémarrage du jeu est requis après un changement de périphérique problématique.
- Si XAudio2 ou la sortie audio ne s'initialise pas, la création échoue ; le wrapper ne remplace pas silencieusement le moteur par un DirectSound sans EAX.
- Cible conseillée : **jeux 32 bits sous Windows 10/11**. Le moteur sait rechercher XAudio2 2.8 (Windows 8+) ; cette combinaison n'a pas été exécutée ici. Aucun support Windows XP ni binaire x64 n'est fourni.

## Diagnostic sous Windows

Dans une invite de commandes ouverte dans le dossier extrait :

```cmd
eax_probe.exe
eax_probe.exe --tone
eax_probe.exe --voices
property_tests.exe
```

`eax_probe.exe` charge explicitement les DLL adjacentes, vérifie la version, crée un buffer, contrôle la détection EAX 1 à 4, teste le commit différé et le relais eax.dll. `--voices` tente la réservation de toutes les voix matérielles émulées restantes, vérifie le refus du dépassement et la restitution des compteurs après libération. Ce test ne joue pas 64 sons simultanés. `--tone` ajoute une courte sinusoïde à 440 Hz avec une queue de réverbération. Le programme écrit son résultat dans la console.

`dsound-xaudio2.log`, si le dossier est accessible en écriture, indique l'initialisation du moteur. En cas de problème, conserver ce fichier et la sortie d'eax_probe.exe, et préciser le jeu et son exécutable exact.

## Validation effectuée ici

- Compilation PE32/i386 des deux DLL et des diagnostics avec GCC MinGW-w64 13.2.
- Vérification des noms/ordinaux exportés, de la convention cdecl de GetCurrentVersion par désassemblage et des dépendances : DLL système Windows, sans libstdc++/libgcc/libwinpthread à distribuer.
- **800 assertions réussies** sur le code de dispatch des propriétés de production, extrait pour une exécution native avec frontière audio/COM simulée. Cela comprend les presets, les propriétés individuelles, les tableaux d'envois, les états par source, les effets et les erreurs.
- DSP de réverbération et des onze autres effets exécuté sur signal déterministe et queue silencieuse ; contrôle de sorties finies et de feedback borné. Exécution avec AddressSanitizer et UndefinedBehaviorSanitizer, sans détection de fuites (non disponible dans l'environnement).
- **Pas de test d'exécution du PE sous Windows ni d'écoute dans un jeu.** Wine ne peut pas démarrer dans cet environnement, car la création de son socket IPC est interdite. Les diagnostics Windows sont fournis pour cette étape.

Les tests de qualité DSP vérifient aussi la focalisation gauche/droite, la diffusion du champ tardif, les variations indépendantes de décroissance grave/aiguë et le lissage des panoramiques. Les états spatiaux différés sont testés avec accumulation, fusion avec les changements immédiats et rejet atomique des valeurs invalides. Les journaux de tests exécutés se trouvent dans `validation/`. Les assertions natives ne valident pas le chargement réel des XAPO par le moteur audio Windows.

## Compiler

Sous Linux avec le compilateur croisé i686-w64-mingw32-g++ dans PATH :

```sh
bash build/build.sh
```

Sous Windows avec MinGW-w64 **i686** dans PATH :

```cmd
build-mingw.cmd
```

Les nouveaux binaires sont écrits dans `dist`. Un compilateur x64 ne convient pas aux jeux x86. Aucun SDK Creative propriétaire à installer n'est nécessaire.

Tests portables sous Linux :

```sh
mkdir -p build
python3 tests/run_native.py
g++ -std=c++17 -O1 -fsanitize=address,undefined tests/dsp_tests.cpp -o build/dsp_tests
ASAN_OPTIONS=detect_leaks=0 build/dsp_tests
g++ -std=c++17 -O1 tests/spatial_tests.cpp -o build/spatial_tests
build/spatial_tests
g++ -std=c++17 -O1 tests/reverb_quality_tests.cpp -o build/reverb_quality_tests
build/reverb_quality_tests
```

## Références techniques

Les valeurs d'ABI EAX ont été confrontées au SDK EAX 4 publié avec le code de Doom 3 et à OpenAL Soft ; les exports et la convention d'appel ont été confrontés à la DLL Creative fournie.

- SDK EAX 4 : https://github.com/id-Software/DOOM-3/blob/master/neo/openal/include/eax4.h
- Définitions EAX OpenAL Soft : https://github.com/kcat/openal-soft/blob/master/al/eax/api.h
- Microsoft XAPO : https://learn.microsoft.com/en-us/windows/win32/xaudio2/xapo-overview
- Microsoft XAudio2 : https://learn.microsoft.com/en-us/windows/win32/xaudio2/xaudio2-introduction

Référence complémentaire pour les données EAX 1 : https://github.com/kcat/openal-soft/blob/master/al/eax/presets.hpp (valeurs numériques SDK). Référence pour les mises à jour différées DirectSound3D : https://learn.microsoft.com/en-us/previous-versions/windows/desktop/ee418006(v=vs.85).
