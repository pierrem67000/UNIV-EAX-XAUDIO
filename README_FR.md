# XAudio Universal 3.0.1 — expérimental, Windows x86

**Les sorties prises en charge aboutissent à XAudio2 2.9 ou 2.8. La DLL principale est xaudiouniv.dll.** Le choix entre une sortie OpenAL/WASAPI et une sortie XAudio2 des versions précédentes est supprimé.

Chemin DirectSound / OpenAL : API historique → DSOAL si nécessaire → mixage, spatialisation et effets logiciels OpenAL Soft → tampons PCM possédés par le wrapper → voix source XAudio2 → voix mastering XAudio2. OpenAL Soft reste la couche de compatibilité/DSP ; sa sortie matérielle WASAPI n'est pas utilisée. Les autres backends physiques ne sont pas enregistrés dans cette version Windows. `ALSOFT_DRIVERS` et le réglage `drivers` ne peuvent pas changer cette sortie. Les fonctions OpenAL de loopback restent des rendus hors ligne en mémoire.

## Architecture

| Fichier | Rôle |
|---|---|
| `xaudiouniv.dll` | Moteur principal, compatibilité, DSP et sortie obligatoire XAudio2 |
| `dsound.dll` | Relais DirectSound / DirectSound8 / DirectSound3D et propriétés EAX |
| `eax.dll` | Relais des sept exports historiques de l'eax.dll Creative |
| `OpenAL32.dll` | Relais AL, ALC, EFX, EAX et extensions compilées |
| `wrap_oal.dll`, `ct_oal.dll`, `soft_oal.dll` | Trois alias du relais OpenAL, utilisant le même moteur |
| `winmm.dll` | waveOut / PlaySound vers XAudio2, helpers non audio vers WinMM système |
| `xaudiouniv.ini` | Fonctions et réglages de sortie |
| Un INI par relais | WrapperMode et surcharge de RealDllPath |

Aucun dsoal-aldrv.dll ou eaxefx_driver.dll supplémentaire n'est nécessaire. Les DLL XAudio2 Windows sont chargées par chemin système absolu. Les relais oal ne sont pas des DLL Creative propriétaires.

## Installation

Fermer le jeu, sauvegarder ses DLL audio, puis placer le moteur, les relais nécessaires et les INI à côté de l'exécutable **32 bits**. Pour le diagnostic complet fourni, conserver tous les fichiers ensemble. Pour un jeu, les relais inutilisés peuvent être omis.

Installer les fichiers v3 ensemble : l'ancien dsound.dll v2 était le moteur ; il est maintenant un relais. Les anciens relais ne sont pas interchangeables. L'ancien fichier audio-wrapper.ini et les réglages Backend=openal/xaudio2 sont ignorés. Le module reste chargé jusqu'à la fin du processus ; redémarrer le jeu après modification des INI.

Cible : jeux x86 sous Windows 10/11. Aucun binaire x64, support XP ou installation système n'est fourni. Ne pas copier ces fichiers dans System32/SysWOW64 ni utiliser regsvr32. L'inscription COM globale n'est pas modifiée.

## Choix des fonctions

```ini
[Wrapper]
RealDllPath=xaudiouniv.dll

[Features]
DirectSound=1
DirectSound8=1
DirectSound3D=1
OpenAL=1
OpenALEFX=1
EAX=1
EAX1=1
EAX2=1
EAX3=1
EAX4=1
EAX5=1
WaveOut=1
PlaySound=1

[XAudio2]
SampleRate=48000
Channels=2
PeriodFrames=512
QueueBuffers=4
```

`0` désactive, `1` active. Une API désactivée devient indisponible ; aucune autre sortie audio n'est ouverte en remplacement. `EAX=0` désactive les cinq versions. DirectSound8 dépend de DirectSound. Désactiver l'API OpenAL native ne coupe pas la couche interne nécessaire à DirectSound. Désactiver l'API EFX native ne coupe pas le DSP interne d'EAX. PlaySound et waveOut sont indépendants.

Le numéro historique eax.dll.GetCurrentVersion reste 4.0 ; les propriétés/extensions servent à détecter les capacités EAX. Les versions désactivées sont masquées par les relais OpenAL et refusées par le pont DirectSound.

SampleRate : 16 000 à 192 000 Hz. Channels : 1, 2, 4, 6 ou 8 ; les valeurs non prises en charge reviennent à 2. Les GUID de périphérique DirectSound sont traduits en identifiants d'endpoint pour XAudio2. OpenAL énumère une sortie virtuelle XAudio Universal par défaut.

PeriodFrames : 128–4096. QueueBuffers : 2–8. Ces deux réglages concernent le pont de mixage OpenAL/DirectSound vers XAudio2 ; l'application waveOut gère sa propre file de tampons. Des valeurs plus grandes peuvent aider en cas d'interruption, avec davantage de latence. Cela ne garantit pas la disparition des craquements dans un jeu.

## RealDllPath et WrapperMode

Chaque relais lit l'INI portant son propre nom. Pour un relais DirectSound renommé my_sound.dll, créer my_sound.ini :

```ini
[Wrapper]
WrapperMode=dsound
RealDllPath=xaudiouniv.dll
```

WrapperMode vide est déduit du nom du relais. Modes : dsound, eax, winmm, openal et les alias openal32/wrap_oal/ct_oal/soft_oal. Une surcharge indique la famille du relais renommé ; elle ne transforme pas ses exports en ceux d'une autre famille. Les ordinaux historiques DirectSound et EAX sont conservés dans leurs relais respectifs.

RealDllPath vide dans un INI de relais hérite du réglage de xaudiouniv.ini. Il accepte un chemin relatif au relais, absolu, ou des variables d'environnement. Pour renommer le moteur en audio_engine.dll, utiliser RealDllPath=audio_engine.dll. Le nom du fichier de configuration global reste xaudiouniv.ini, à côté du moteur.

**Différence avec DxWrapper : la cible audio doit être un moteur XAudio Universal compatible, et non la DLL audio système.** Le marqueur d'ABI est vérifié avant chargement. Une DLL tierce arbitraire, le relais lui-même ou un ancien moteur incompatible sont refusés, sans repli. Une chaîne opaque vers un autre wrapper ne permettrait pas de garantir XAudio2 en sortie.

Une importation d'exécutable nommée dsound.dll exige toujours ce nom pour le relais, sauf adaptation du chargement du jeu.

## Portée et limites

- **EAX 1–4** : propriétés historiques via DSOAL/OpenAL Soft, douze effets logiciels, occlusion/obstruction/exclusion et paramètres différés.
- **EAX 5 partiel** : quatre envois, quatre slots, contexte/sources et occlusion des slots, avec le décodeur eaxefx réutilisé. Pas de MacroFX acoustique, PurePath par haut-parleur ou EAX Voice. Certains paramètres sont mémorisés sans DSP associé. Voir EAX5_PARTIEL.md.
- DirectSound8 ne signifie pas que tous les effets SetFX/GetObjectInPath sont implémentés. Les chemins d'effets prévus sont EAX et OpenAL EFX.
- **waveOut** : PCM 8/16/24/32 bits et flottant 32 bits, mono/stéréo ; tampons, notifications, pause/reprise/reset, position, volume et vitesse. Boucles sur un seul WAVEHDR contenant BEGINLOOP et ENDLOOP : jusqu'à 255 lectures ou boucle infinie. Les boucles multi-headers et le pitch indépendant du tempo sont refusés.
- **PlaySound / sndPlaySound** : WAV PCM/flottant depuis fichier, mémoire ou ressource WAVE ; lecture synchrone/asynchrone, arrêt et boucle. Pas d'alias de sons système, ADPCM, décodeur MP3 ou autre format compressé ajouté.
- **MIDI, MCI/CD audio, mixeur matériel et waveIn** : non convertis ; pas de délégation à une sortie système. Ces chemins renvoient une absence de périphérique ou une erreur. Timers, joysticks, mmio et helpers compatibles peuvent utiliser le WinMM système, chargé par chemin absolu.
- Aucun backend de capture OpenAL/DirectSound n'est ajouté : XAudio2 est une API de sortie.
- Pas de certification Creative, de compatibilité universelle ou de garantie pour les exports privés/imports WinMM par ordinaux. Les alias oal exposent l'API commune, pas toutes les fonctions privées des anciens pilotes.

## Diagnostics Windows

```powershell
.\universal_probe.exe
.\universal_probe.exe --device
.\universal_probe.exe --tone
powershell -ExecutionPolicy Bypass -File .\Test-Architecture.ps1 -Keep
```

Par défaut : sept relais, moteur commun, timers WinMM, rendu EAX 5 hors ligne. --device ouvre réellement les chemins OpenAL, DirectSound8/3D et waveOut avec un signal silencieux ; --tone ajoute des tons courts. Le diagnostic contrôle des compteurs de création d'engines XAudio2 et de soumission/consommation des tampons, afin de vérifier une utilisation réelle du moteur final. Le script utilise des processus isolés pour les renommages, options désactivées et erreurs attendues.

Les variables de journalisation OpenAL Soft et DSOAL restent disponibles : ALSOFT_LOGLEVEL, ALSOFT_LOGFILE, DSOAL_LOGLEVEL et DSOAL_LOGFILE. Elles ne changent pas le backend final.

## Validation effectuée ici

- Compilation croisée des huit DLL PE32/i386 et diagnostics ; contrôle des exports, ordinaux DirectSound/EAX, dépendances et protections ASLR/DEP.
- Code de production du backend XAudio2 exécuté avec API Windows/XAudio2 injectée : topologies, répétitions start/stop, conservation des tampons jusqu'au callback, sorties finies/bornées, échecs d'initialisation et de soumission ; ASan/UBSan. Ce test ne valide pas l'ABI ni le pilote Windows réel.
- Tests natifs du DSP : EAX 1–4/douze effets/HRTF, EAX 5 partiel/quatre effets isolés/occlusion réelle. Décodeur eaxefx testé sous ASan/UBSan.
- Parseur WAV de PlaySound testé sur PCM valide, troncatures et entrées corrompues sous ASan/UBSan. Inspection bornée des DLL par le parseur PE.
- **Aucune exécution Windows, sortie physique, écoute en jeu ni exécution PowerShell ici.** WinMM et le chaînage réel des relais restent à valider avec les diagnostics. Les anciens journaux XAudio2 1.x sont historiques.

## Reconstruction et licences

Sources complètes et adaptations dans sources/. Outils : CMake 3.24+, Ninja, Python 3, MinGW-w64 i686/GCC 13+ avec C++20. Exécuter bash build/build.sh sous Linux ou build-mingw.cmd sous Windows. Les relais WinMM générés sont fournis ; leur régénération facultative utilise les headers MinGW indiqués par MINGW_INCLUDE.

OpenAL Soft et DSOAL sont sous LGPL ; eaxefx est sous MIT, attributions conservées. La DLL combinée est livrée avec ses sources et instructions de reconstruction. Aucun moteur Creative propriétaire ni runtime Microsoft n'est redistribué.

## Correctif 3.0.1 : EAX désactivé et lecture DirectSound

La version 3.0 bloquait le relais eax.dll lorsque toutes les versions EAX
étaient désactivées. Des jeux utilisant EAXDirectSoundCreate/Create8 ou la
fabrique COM Creative pouvaient ainsi perdre la création audio elle-même.
Le correctif sépare ces fonctions de création des propriétés d'effets EAX.
EAX=0, ou EAX1 à EAX5 tous à zéro, laisse les objets DirectSound disponibles
lorsque DirectSound=1. DirectSound3D reste indépendant d'EAX et de l'API
OpenAL/EFX native. Les propriétés EAX désactivées restent indisponibles.

Test de lecture 3D sans EAX sous Windows (avec EAX=0 dans l'INI) :

```powershell
.\universal_probe.exe --expect-eax-off --tone
```

Sans --tone/--device, ce mode vérifie seulement la fabrique COM du relais EAX.
Avec --tone/--device, il vérifie la création via EAXDirectSoundCreate8, un
buffer 3D matériel émulé, les capacités DirectSound, l'interface 3D et le rejet
des propriétés EAX désactivées, puis joue un ton bref. Ces vérifications
Windows ne sont pas exécutées dans l'environnement de développement.
Le script Test-Architecture.ps1 ajoute trois combinaisons EAX désactivé.

Le texte DirectSound (SW) / DirectSound3D est choisi par chaque jeu. Ce
correctif maintient les capacités 3D ; il ne modifie pas les menus de Hitman 2.
Si le jeu choisit encore SW, l'analyse de son exécutable ou de ses appels audio
est nécessaire pour déterminer son critère de sélection.
