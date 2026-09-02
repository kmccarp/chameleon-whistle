# MECCHA CHAMELEON — Low-Frequency Yell Taunt

Replaces the game's wolf-whistle taunt with a **yell whose energy sits below 750 Hz**,
so it is audible to a listener with high-frequency hearing loss.

## Why

The stock taunt is `freesound_community-wolf-whistle-6777`, played by the
`SC_Provoaction` sound cue. A wolf whistle is almost pure high-frequency tone —
**only ~2% of its energy falls below 750 Hz**. For a player who can only hear below
750 Hz it is effectively silent, which matters because the taunt is a gameplay signal
that tells you another player is nearby.

Simply dropping in a yell does **not** fix this. Real yells are also high: the source
recordings measured 0.3%–14% of their energy below 750 Hz, because a shout's power sits
in the 1–4 kHz "shout formant". Every variant here is therefore pitched down by
resampling (a factor of 2.7–3.0, roughly 17–19 semitones) so the fundamental *and* its
strong harmonics land inside the audible band, then normalised against the low-passed
signal so the part you can actually hear is at full level.

| Variant | Source | Energy below 750 Hz | Centroid |
|---|---|---|---|
| `A_male_scream`  | male scream        | **95.7%** | 542 Hz |
| `B_hey_call`     | man calling out    | **91.8%** | 492 Hz |
| `C_wilhelm`      | Wilhelm scream     | **88.2%** | 579 Hz |
| `D_death_scream` | man's death scream | **86.1%** | 520 Hz |

(stock wolf whistle, for comparison: ~2%)

`A_male_scream` is installed by default. Each variant also ships a
`*_AS-YOU-HEAR-IT.wav` preview — the same audio low-passed at 750 Hz, so you can
confirm it is still loud and clearly a yell through your hearing range.

## Audio sources — all public domain

- **A, B, D** — [SSE Library: VOICES](https://archive.org/details/SSE_Library_VOICES),
  released **CC0 1.0 (public domain dedication)**.
- **C** — [Wilhelm Scream](https://commons.wikimedia.org/wiki/File:Wilhelm_Scream.ogg)
  from Wikimedia Commons, hosted as **CC0**, sourced from the same CC0 archive.

No audio from the game is redistributed here, and the build extracts the stock asset
from your own install at build time.

## Install

```bash
bash src/install.sh A_male_scream     # or B_hey_call / C_wilhelm / D_death_scream
bash src/uninstall.sh                 # removes it again
```

Install is purely additive — it writes three new `zzz_ChameleonYell_P.*` files and
never modifies or overwrites a stock game file. Uninstalling deletes only those three.
Set `GAME=...` if the game is not at the default Steam path.

## Sharing it

`MecchaChameleon-LowFreqYell-v1.0.zip` (4.3 MB) is a self-contained package for people
who do not have Git Bash or Python. Rebuild it with `bash src/make_package.sh`.

It contains a double-click `INSTALL.bat` that auto-detects the Steam install (including
extra library folders on other drives), offers the four variants by menu, refuses to run
while the game holds the files open, and SHA256-verifies every file after copying.
`UNINSTALL.bat` reverts. All four prebuilt variants, the previews, `CHECKSUMS.txt` and
the full source are included.

The package `README.txt` is written for non-technical users and presents the sub-750 Hz
design as a general accessibility feature, without attributing it to any individual.

## Rebuild

```bash
bash src/build_all.sh                 # extract stock asset, rebuild all variants
python src/make_audio.py              # regenerate the audio previews
```

To use your own recording, drop a WAV into `previews/` and run
`python src/build_mod.py previews/yours.wav build/yours`, then pack with
`tools/retoc.exe to-zen --version UE5_6 build/yours dist/yours/zzz_ChameleonYell_P.utoc`.

## How it works

The game is Unreal Engine 5.6 using IoStore (`.utoc`/`.ucas`), unencrypted, Oodle
compressed. [retoc](https://github.com/trumank/retoc) converts the stock package to
legacy cooked form and back.

All 150 sound waves in the game are **Bink Audio**, which has no open-source encoder —
it ships only with the Unreal editor. So instead of re-encoding, the mod **retargets the
SoundWave to a different decoder that the shipping build already links**. The shipping
executable contains `BinkAudioDecoder`, `AdpcmAudioDecoder`, `VorbisAudioDecoder`,
`OpusAudioDecoder` and `RadAudioDecoder`; UE feeds the ADPCM module a plain **RIFF/WAVE**
buffer, so the mod ships uncompressed PCM16 and needs no proprietary encoder at all.

Conveniently `BINKA` and `ADPCM` are both 5 characters, so the format name is patched in
place in the name table and **no package offsets move**. The audio is authored at exactly
24000 Hz / 2 channels / 35584 frames — matching the stock asset — so **no SoundWave
property is modified**, only the codec name and the cooked payload.

Patched fields (offsets decoded from the stock package):

| Offset | Field | Change |
|---|---|---|
| `0x132` | name table entry | `BINKA` → `ADPCM` |
| `0x106` | `BulkDataStartOffset` | 990 → 1006 |
| `0x2aa` | export `SerialSize` | 126 → 142 |
| `0x31a`/`0x322` | chunk 0 bulk size | 28 → 44 (RIFF header) |
| `0x346`/`0x34e` | chunk 1 bulk size | 17991 → 142336 (PCM data) |

The streamed wave has two chunks: chunk 0 is inlined in the `.uexp` and holds the codec
header (the 44-byte RIFF header), chunk 1 is the `.ubulk` payload. The decoder
concatenates them, which reconstitutes a valid RIFF/WAVE file.

## Verification

`src/build_all.sh` output was checked by:

- **retoc `verify`** on the produced container — passes.
- **Full round-trip** — repacking to IoStore and converting back to legacy reproduces
  the `.uasset`, `.uexp` and `.ubulk` **byte-identically**.
- **Decode simulation** — reconstructing the cooked buffer the way the engine does
  yields a valid RIFF/WAVE (`tag=1 PCM, 2ch, 24000 Hz, 35584 frames, 1.483 s`) that is
  **bit-identical** to the audited preview WAV.

**Not verified:** the mod has not been heard in-game. See below.

## Known risk

The format name is `ADPCM` while the RIFF payload declares `WAVE_FORMAT_PCM` (tag 1).
This relies on UE's ADPCM audio-info class branching on the RIFF `wFormatTag` rather
than on the format name — which is why UE registers `ADPCM` and `PCM` to the same
decoder module. If the taunt is silent in game, the fallback is to rename the format to
`PCM`; because `PCM` is 3 characters rather than 5, that also requires shifting every
package offset after the name table, so it is a larger change and was not the first
choice.
