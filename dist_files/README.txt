===========================================================================
  MECCHA CHAMELEON  -  Low-Frequency Yell Taunt
  A sound mod that replaces the wolf-whistle taunt with a deep yell
===========================================================================

WHAT IT DOES
------------
Replaces the taunt sound (the wolf whistle played when you provoke) with a
yell pitched down so that nearly all of its energy sits BELOW 750 Hz.

This is an accessibility mod. The taunt is a gameplay signal - it tells you
another player is nearby - but a wolf whistle is almost pure high-frequency
tone. Only about 2% of its energy falls below 750 Hz, so for a player with
high-frequency hearing loss it is effectively silent.

Just swapping in a yell does not fix that. Real yells are also high: a
shout's power lives in the 1-4 kHz range, and the raw source recordings
measured only 0.3%-14% of their energy below 750 Hz. So every yell here is
pitched down about 17-19 semitones, then normalised against the low-passed
signal so the part you CAN hear is at full volume.

That is why they sound like deep roars rather than sharp screams. It is the
point, not a mistake.


HOW TO INSTALL
--------------
  1. Quit MECCHA CHAMELEON completely. (The installer will refuse to run
     while the game is open, because Windows locks the files.)
  2. Double-click  INSTALL.bat
  3. Pick a yell from the menu.

It finds your Steam install automatically, including extra Steam library
folders on other drives. If it cannot, it will ask you to paste the path.

To remove it, double-click  UNINSTALL.bat  (or choose R in the installer).

No admin rights needed. Nothing is installed system-wide.


THE FOUR YELLS
--------------
  A_male_scream    Male scream       95.7% of energy below 750 Hz
  B_hey_call       Man calling out   91.8%
  C_wilhelm        Wilhelm scream    88.2%
  D_death_scream   Man's death cry   86.1%

  (the stock wolf whistle, for comparison:  about 2%)

Listen before you install - the previews\ folder has all four as WAV files.

Each one also has a partner file ending "_AS-YOU-HEAR-IT.wav". That is the
same audio with everything above 750 Hz filtered out, so you can hear what
it sounds like to someone who only hears in that range. If it is still loud
and obviously a yell in that version, the mod is doing its job.


IS THIS SAFE?
-------------
Yes, and it is easy to undo.

  - It only ADDS three files, all named zzz_ChameleonYell_P.*
  - It never modifies or overwrites any original game file.
  - Uninstalling deletes only those three files.
  - If anything ever looks wrong, "Verify integrity of game files" in Steam
    restores everything.

It is a local sound swap. It does not touch save files, does not change
gameplay, and does not modify the game executable.

Note for multiplayer: this changes the sound on YOUR machine only. Other
players still hear the normal whistle.


AUDIO CREDITS - ALL PUBLIC DOMAIN
---------------------------------
  A, B, D   "SSE Library: VOICES", released CC0 1.0 (public domain)
            https://archive.org/details/SSE_Library_VOICES

  C         "Wilhelm Scream" from Wikimedia Commons, hosted as CC0
            https://commons.wikimedia.org/wiki/File:Wilhelm_Scream.ogg

No game audio is redistributed in this package.


REBUILDING IT YOURSELF
----------------------
The source\ folder has everything: the audio-processing script, the mod
builder, and notes on how the format was worked out. Requires Python with
numpy, scipy and soundfile. See source\README.md.

You can drop in any WAV of your own and build a mod from it.


KNOWN ISSUE
-----------
If the taunt is completely SILENT after installing, please report it.

The mod retargets the sound to Unreal's ADPCM decoder while shipping plain
PCM audio inside a RIFF/WAVE container. That is believed correct, and it has
been verified offline, but it has not been confirmed by ear on every setup.
There is a documented fallback if it turns out not to work - see the "Known
risk" section in source\README.md.
