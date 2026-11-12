# EAX Unified Wrapper 2.1 — expérimental, Windows x86

Cette version intègre **OpenAL Soft 1.25.2 et DSOAL dans la DLL principale**. Le chemin par défaut devient DirectSound → DSOAL → OpenAL Soft → WASAPI. L'ancien moteur DirectSound → XAudio2 1.3 reste disponible par configuration. Il n'y a pas de conversion OpenAL vers XAudio2 : ce sont deux moteurs sélectionnables.

## Architecture conservée

| Fichier | Rôle |
|---|---|
| `dsound.dll` | Moteur unique : DirectSound/DirectSound3D/EAX, DSOAL, OpenAL Soft et ancien XAudio2 ; renommable |
| `eax.dll` | Relais des sept exports Creative historiques, avec leurs ordinaux et conventions d'appel |
| `OpenAL32.dll` | Relais de 331 fonctions AL/ALC/EFX/EAX et extensions vers le moteur principal |
| `audio-wrapper.ini` | Choix du moteur et, éventuellement, du nom du moteur principal |

OpenAL Soft est lié statiquement dans le moteur principal. Aucun `dsoal-aldrv.dll`, second `OpenAL32.dll` moteur, ou runtime GCC séparé n'est nécessaire. Le relais OpenAL32 ne contient pas un deuxième moteur. Les pointeurs d'extensions obtenus par `alGetProcAddress` / `alcGetProcAddress` pointent vers le moteur principal, conservé en mémoire jusqu'à la fin du processus.

## Apports du moteur OpenAL / DSOAL

- Traduction des interfaces DirectSound et DirectSound3D par DSOAL : buffers, streaming, notifications, périphériques, capture et full duplex, selon les fonctions de cette version amont.
- Traduction des propriétés EAX 1, 2, 3 et 4 via IKsPropertySet vers le moteur EAX réel d'OpenAL Soft, avec validation, paramètres différés, occlusion, obstruction, exclusion et niveaux des envois.
- Quatre slots EAX 4, deux slots actifs par source, environnements simultanés et douze effets : réverbération, compresseur AGC, autowah, chorus, distorsion, écho, égaliseur, flanger, frequency shifter, vocal morpher, pitch shifter et ring modulator.
- Spatialisation OpenAL Soft, HRTF pour casque et sorties multicanaux selon configuration et périphérique. Les limites stéréo du moteur XAudio2 historique ne sont plus celles du moteur par défaut.
- Gestion des sources et des contextes par DSOAL / OpenAL Soft. Les capacités matérielles historiques sont émulées sur CPU ; leur budget est déterminé par DSOAL (64 ou 128 selon les ressources obtenues), sans imposer 8/32 voix selon l'ancienne version EAX. Ce n'est pas du traitement matériel Creative.
- API OpenAL native disponible via le relais, avec EFX et les extensions de cette version d'OpenAL Soft. **Un pont EAX 5 partiel utilisant du code d'eaxefx est maintenant ajouté à DirectSound**, avec quatre envois actifs, propriétés de contexte/source/slots et occlusion des slots. Voir `EAX5_PARTIEL.md`. Le numéro historique retourné par eax.dll reste 4.0 ; ce numéro ne constitue pas une annonce de conformité EAX 5 complète.

Du code **eaxefx est désormais compilé et utilisé** : `EaxxEaxCall`, `EaxxFxSlotIndex`, les définitions d'ABI EAX et les exceptions associées assurent le décodage des appels EAX 5 et des slots dans le nouveau pont. Le DSP et la conversion EAX→effets OpenAL Soft restent ceux du moteur intégré, qui a lui-même repris l'émulation d'eaxefx. Il n'y a pas de deuxième moteur EFX indépendant ni d'eaxefx_driver.dll à fournir.

Le support est partiel : **pas de rendu MacroFX, pas de PurePath par haut-parleur, pas d'EAX Voice ni de X-RAM matériel**. Certains paramètres du contexte sont conservés pour la compatibilité sans traitement acoustique associé ; les détails figurent dans `EAX5_PARTIEL.md`. Le moteur historique XAudio2 reste limité à EAX 1–4.

## Installation

1. Fermer le jeu et sauvegarder ses DLL audio existantes.
2. Copier **les trois DLL de cette version** et `audio-wrapper.ini` à côté de l'exécutable 32 bits du jeu.
3. Activer EAX dans les options du jeu si elles sont proposées.
4. Pour revenir en arrière, retirer les fichiers ajoutés et restaurer les originaux.

Cible : jeux 32 bits sous Windows 10/11. Aucun binaire x64 n'est livré. Ne pas installer ces fichiers dans les dossiers système ni utiliser regsvr32. Les exports d'inscription COM du relais eax sont présents, mais ne modifient pas le système. Une activation COM globale ou une vérification spécifique du pilote Creative peut nécessiter une adaptation du jeu.

Le relais OpenAL utilise toujours OpenAL Soft, même avec `Backend=xaudio2` : cette option sélectionne le moteur DirectSound uniquement. Les deux moteurs ne partagent pas leurs objets audio.

## Renommer la DLL principale

Les relais trouvent le moteur dans leur propre dossier par son export `EAXWrapperGetABI_v1`, sans charger des DLL candidates pour les identifier. La recherche privilégie une configuration explicite, puis un moteur compatible déjà chargé, puis `dsound.dll`, puis un unique autre candidat. Plusieurs candidats dans cette dernière étape provoquent une erreur.

Exemple, après renommage de `dsound.dll` en `game_audio.dll` :

```ini
[Wrapper]
Core=game_audio.dll
Backend=openal
```

Un nom de fichier seul est accepté pour `Core` ; les chemins externes et les relais eux-mêmes sont refusés. Le champ peut rester vide si le moteur est identifiable sans ambiguïté. Conserver les noms `eax.dll` et `OpenAL32.dll` pour les relais : ils ne peuvent pas aussi nommer le moteur dans ce même dossier.

**Une importation Windows explicitement nommée `dsound.dll` exige toujours ce nom.** Le renommage fonctionne pour les relais et les appelants qui chargent le nouveau nom ; il ne réécrit pas automatiquement les imports d'un exécutable. Pour un jeu qui importe directement dsound.dll, conserver ce nom ou adapter son mécanisme de chargement.

## Réglages et craquements

Le nouveau chemin utilise le mixeur et les effets d'OpenAL Soft. Il évite le DSP maison lorsqu'`openal` est sélectionné, mais la disparition du craquement dans votre jeu n'a pas encore été vérifiée à l'écoute.

`alsoft.example.ini` contient des exemples optionnels. Le copier sous `alsoft.ini` à côté de l'exécutable et décommenter les deux réglages casque pour forcer HRTF. Les réglages de tampon permettent d'augmenter la marge en cas d'interruption audio, au prix d'une latence accrue. Sans fichier, les réglages OpenAL Soft par défaut s'appliquent ; une configuration globale existante peut aussi être lue.

Pour comparer avec l'ancien moteur : remplacer `Backend=openal` par `Backend=xaudio2`, puis redémarrer le jeu. Ses limites et corrections antérieures sont décrites dans `README_XAudio2_1.3_HISTORIQUE.md`.

## Diagnostics Windows

```powershell
.\wrapper_probe.exe
.\wrapper_probe.exe --device
.\wrapper_probe.exe --tone
powershell -ExecutionPolicy Bypass -File .\Test-Rename.ps1 -Keep
```

`wrapper_probe.exe` contrôle le relais eax, la convention cdecl de GetCurrentVersion, la fabrique COM EAX, le relais OpenAL, le HRTF, EAX 1–4, les douze effets, puis EAX 5 partiel (quatre envois, quatre sorties d'effets isolées, occlusion des slots, tailles Get et commit différé), et l'identité du moteur partagé. Par défaut, son rendu se fait hors ligne. `--device` ajoute la création réelle du périphérique et du buffer DirectSound avec contrôle IKsPropertySet EAX 1–4 et du pont EAX 5 lorsque le moteur OpenAL est sélectionné ; `--tone` ajoute une courte lecture à 440 Hz. Ces options doivent être exécutées sur la machine Windows pour contrôler la sortie physique. `Test-Rename.ps1` teste des processus isolés avec le nom standard, un nom découvert automatiquement, un nom configuré, et trois erreurs de sélection attendues. Le script ne modifie pas le dossier du jeu.

Pour un diagnostic dans le jeu, définir avant lancement `DSOAL_LOGLEVEL=3`, `DSOAL_LOGFILE` avec un chemin de journal, `ALSOFT_LOGLEVEL=3` et `ALSOFT_LOGFILE` avec un second chemin. Le moteur XAudio2 conserve son journal `dsound-xaudio2.log`.

## Validation effectuée

- Compilation croisée des trois DLL et du diagnostic PE32/i386, avec ASLR/DEP, runtime GCC statique et contrôle des exports/imports.
- Exécution native Linux du moteur OpenAL Soft issu des mêmes sources : rendu stéréo 48 kHz avec HRTF, Get/Set EAX 1–4, deux envois, traîne de réverbération, chargement/rendu des douze effets, occlusion et rejet d'une valeur invalide. Sorties finies vérifiées.
- Test du nouveau pont EAX 5 avec le véritable code eaxefx et le moteur OpenAL Soft : quatre sorties d’effets isolées avec le son direct coupé, quatre envois simultanés, atténuation acoustique par occlusion des slots, erreurs et états différés. Allocation de 128 sources vérifiée, sans prétendre mesurer 128 sons simultanés.
- Inspection du moteur et des relais par le parseur de sélection PE ; entrées tronquées et 5000 en-têtes corrompus sous AddressSanitizer / UndefinedBehaviorSanitizer.
- Tests natifs du dispatch du moteur XAudio2 historique : 800 assertions réussies.
- **Aucune exécution des DLL Windows ni écoute dans un jeu dans cet environnement.** Les tests natifs ne valident pas le chaînage réel des trois DLL, les interfaces COM sous Windows ou le périphérique WASAPI. Les diagnostics fournis servent à cette étape. La compilation seule ne prouve pas une compatibilité universelle ni une reproduction exacte des cartes Creative.

Les journaux et empreintes des binaires sont dans `validation/`. Les anciens tests `eax_probe` / `property_tests` restent dans les sources pour le moteur historique ; le nouveau diagnostic livré est `wrapper_probe.exe`.

## Sources et compilation

Les sources complètes nécessaires, dont les arbres OpenAL Soft, DSOAL et eaxefx modifiés, sont dans `sources/` dans l'archive. Les références amont et adaptations locales sont consignées dans `THIRD_PARTY.md` et `patches/`. Aucun SDK Creative propriétaire n'est requis.

Prérequis : CMake 3.24+, Ninja, Python 3 et MinGW-w64 i686 avec GCC 13+ et C++20. Exécuter depuis les sources :

```sh
bash build/build.sh
```

Sous Windows, avec les outils i686 dans PATH : `build-mingw.cmd`. Les DLL recompilées vont dans `dist/`. Le fichier toolchain permet aussi de définir `MINGW_ROOT` pour une installation croisée Linux contenant `usr/bin/i686-w64-mingw32-*-posix`.

Test natif du moteur OpenAL sous Linux :

```sh
cmake -S . -B build/native -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build/native --parallel 2
./build/native/openal_integration_tests
./build/native/eax5_integration_tests
./build/native/eax5_validation_tests
python3 tests/run_native.py
```

Les textes de licence accompagnent les sources : OpenAL Soft et DSOAL sont sous LGPL ; le code eaxefx réutilisé reste sous MIT avec ses attributions. Les licences des composants tiers sont conservées. Ne pas distribuer la DLL combinée sous la seule licence MIT des ajouts historiques. Les sources fournies permettent de modifier et reconstruire l'ensemble du wrapper.
