# UNIV-EAX-XAUDIO
Legacy DirectSound / EAX to XAudio Compatibility Layer

Project description
A compatibility layer that translates legacy DirectSound, DirectSound3D and EAX (1, 2, 3, 4 and 5) audio calls into XAudio-based operations.

The project aims to restore support for legacy audio features in modern Windows environments while leveraging modern audio APIs.

Parts of the audio implementation are based on code from OpenAL and OpenAL Soft.

Technologies
DirectSound / DirectSound3D: Legacy audio API compatibility.

EAX 1–5: Environmental Audio Extensions compatibility.

XAudio: Modern Windows audio processing backend.

OpenAL / OpenAL Soft: partial audio processing code.

Written with FULL A.I 

Works fines with games like Demolition Racer or Hitman 2: Silent Assassin

Installation and Usage
The required files depend on the audio API used by the game.

Required files
The core XAudio implementation requires the following files:

xaudiouniv.dll – Main audio implementation and compatibility layer.

xaudiouniv.ini – Configuration file for the XAudio backend.

For games using EAX
For games using Environmental Audio Extensions (EAX), you also need:

eax.dll – EAX stub/proxy DLL used to intercept and forward EAX calls.

eax.ini – EAX-specific configuration file.

For games using DirectSound
For games using DirectSound or DirectSound3D, you need:

dsound.dll – DirectSound stub/proxy DLL used to intercept and translate DirectSound calls.

dsound.ini – DirectSound-specific configuration file.

Important
The appropriate stub DLL and its corresponding INI configuration file must be placed in the game's directory alongside xaudiouniv.dll and xaudiouniv.ini.

The EAX or DirectSound configuration depends on the audio API used by the game.

Note: The exact DLL names and configuration files may vary depending on the compatibility layer being used and the game's requirements.

If any licensing adjustments, additional attributions or compliance changes are required regarding reused code or third-party components, I am willing to make the necessary modifications to ensure proper license compliance.
