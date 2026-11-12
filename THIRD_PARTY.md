# Pinned dependencies and local modifications — 2026-11-08

| Project | Revision | Integration | License |
|---|---|---|---|
| [OpenAL Soft](https://github.com/kcat/openal-soft) | 1.25.2, `2fc99332b9be52a62c8d7525ce444c70c48e530a` | Full static audio/EAX/EFX engine in the main DLL | LGPL-2.0-or-later, see `vendor/openal-soft/COPYING` |
| [DSOAL](https://github.com/kcat/dsoal) | `e11128250439d586483ee6598d1670ab52ab5e37` | DirectSound interfaces translated into the embedded engine | LGPL-2.1-or-later, see `vendor/dsoal/LICENSE` |
| [eaxefx](https://github.com/bibendovsky/eaxefx) | `6c1abec099d59bf4cb6aef6e2172d232e19798bc` | API definitions, EaxxEaxCall decoder, EaxxFxSlotIndex and exception implementation linked into the core; corresponding source supplied | MIT upstream |

All copyright headers are preserved. OpenAL Soft's bundled fmt (MIT), PFFFT,
GSL, HRTF data and other components retain the notices in that source tree.
See `LICENSE-pffft`, `LICENSE.Apache-2.0.txt`, `LICENSE.BSD-3-Clause.txt`,
`fmt-11.2.0/LICENSE`, and the relevant source headers. The embedded HRTF
resources are included in the corresponding upstream source tree.

Local modifications:

- DSOAL uses the wrapper module handle for its OpenAL entry points rather than
  loading `dsoal-aldrv.dll`; failure paths do not unload their own module.
- DSOAL export annotations can be disabled for the embedded build. Its startup
  runs once at first DirectSound use, outside the Windows loader lock.
- Build definitions rename DSOAL dispatch pointer variables and colliding
  helper symbols, and rename the legacy XAudio2 factory/entry points.
- Both components use the same bundled fmt instance.
- OpenAL Soft's immutable AmbiIndex FromACN tables have explicit 16-byte
  alignment to avoid inconsistent MinGW COMDAT alignment across translation
  units. The audio algorithm is unchanged by this adjustment.
- DirectSound and WinMM output backends of OpenAL Soft are disabled to avoid
  recursive calls through dsound.dll; WASAPI is enabled. EAX and embedded HRTF
  resources are enabled. The OpenAL Soft static library is linked into the core.
- The wrapper exports the OpenAL entry points and supplies two thin relays with
  shared, name-independent local core discovery and an explicit ABI marker.

The complete modified trees and build inputs are supplied in `sources/` of the
binary archive. `patches/` contains the differences to the pinned upstream
snapshots. The original Creative eax.dll is not redistributed. The upstream
code is modified, so these binaries are not official upstream releases.

Version 2.1 adds executable eaxefx source reuse for the partial EAX5 bridge:
`eaxefx_eax_api.cpp`, `eaxefx_eaxx_eax_call.cpp`,
`eaxefx_eaxx_fx_slot_index.cpp`, and `eaxefx_exception.cpp`.
The upstream API is isolated into namespace eaxefx, C-linkage data declarations
are changed to C++ linkage, and long payload fields use explicit 32-bit types
so native Linux tests have the same structure sizes as Windows. The inactive
slot index is initialized to avoid copying indeterminate state. Original MIT
headers and copyright are retained. The complete eaxefx tree is supplied;
its separate driver loader and executable patcher are not linked or invoked.

DSOAL's Buffer property bridge now recognizes EAX50 source/context/slot GUIDs,
uses the shared eaxefx decoder boundary and reports exact Get lengths for this
new path. Its context requests four auxiliary sends. EAX1-4 paths and the
legacy XAudio2 engine are retained. See EAX5_PARTIEL.md for unsupported and
state-only parameters. Upstream DSP remains OpenAL Soft, without a second
copy of the old eaxefx EFX engine running against the same sources.

Version 3.0 changes the physical output architecture to mandatory XAudio2.
The Windows backend registry in OpenAL Soft contains only the new XAudio2
factory. ALSOFT_DRIVERS / drivers backend selection is skipped for this build.
WASAPI/DirectSound/WinMM output backends are not used. The new backend owns
its PCM buffers through XAudio2 completion callbacks and loads the system
XAudio2 2.9/2.8 DLL by absolute system path. DirectSound endpoint GUIDs are
resolved through MMDevice metadata for CreateMasteringVoice device selection.
The metadata lookup does not render audio through WASAPI.

The principal module is xaudiouniv.dll; dsound.dll is now a relay. The old
XAudio2 1.x implementation is retained as historical source, not linked into
the production principal module. All seven relays use v3 ABI validation,
per-relay WrapperMode/RealDllPath and global feature configuration. Native
waveOut/PlaySound compatibility uses XAudio2 directly. Only non-playback
WinMM helpers may resolve the system WinMM, through an absolute system path.

New integration files are LGPL-2.1-or-later under LICENSE_INTEGRATION.txt.
Generated WinMM declarations are from the public-domain MinGW-w64 headers.
No Microsoft runtime or proprietary Creative driver is included.
