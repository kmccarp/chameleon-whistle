"""Rebuild the MECCHA CHAMELEON taunt SoundWave with new audio.

The original asset is Bink Audio (no open encoder), so we retarget the wave to
the ADPCM decoder module - which UE feeds a plain RIFF/WAVE - and ship
uncompressed PCM16. 'BINKA' and 'ADPCM' are both 5 chars, so the name table is
patched in place and no package offsets move.
"""
import struct, os, shutil, sys
import numpy as np, soundfile as sf

SRC = os.environ.get('ORIG_DIR', 'original') + '/Chameleon/Content/audios/cLeon/game/freesound_community-wolf-whistle-6777'
REL = 'Chameleon/Content/audios/cLeon/game/freesound_community-wolf-whistle-6777'

# --- offsets discovered by decoding the original package -------------------
OFF_BINKA        = 0x132   # name table entry, 5 chars, same length as ADPCM
OFF_SERIAL_SIZE  = 0x2aa   # export SerialSize (int64)
OFF_C0_ELEMS     = 0x31a   # chunk0 bulk ElementCount (int64)
OFF_C0_DISK      = 0x322   # chunk0 bulk SizeOnDisk   (int64)
OFF_C1_ELEMS     = 0x346   # chunk1 bulk ElementCount (int64)
OFF_C1_DISK      = 0x34e   # chunk1 bulk SizeOnDisk   (int64)
OFF_BULK_START   = 0x106   # BulkDataStartOffset = header + exports (int64)

UEXP_PREFIX_END  = 0x46    # props+flags+cuepoints+guid+numchunks+fname+chunk0 hdr
ORIG_HDR_LEN     = 28      # original inlined Bink header length
PKG_TAG          = 0x9E2A83C1

SAMPLE_RATE, CHANNELS, N_FRAMES = 24000, 2, 35584   # must match untouched properties


def riff_wave(pcm_i16, sr, ch):
    """Standard 44-byte RIFF/WAVE PCM16 header + data."""
    data = pcm_i16.tobytes()
    hdr = b'RIFF' + struct.pack('<I', 36+len(data)) + b'WAVE'
    hdr += b'fmt ' + struct.pack('<IHHIIHH', 16, 1, ch, sr, sr*ch*2, ch*2, 16)
    hdr += b'data' + struct.pack('<I', len(data))
    assert len(hdr) == 44, len(hdr)
    return hdr, data


def load_audio(wav_path):
    # read int16 directly: no float round-trip, so the shipped audio is
    # bit-identical to the preview the user auditioned
    x, sr = sf.read(wav_path, dtype='int16', always_2d=True)
    assert sr == SAMPLE_RATE, f'{wav_path}: expected {SAMPLE_RATE} Hz, got {sr}'
    if x.shape[1] == 1: x = np.repeat(x, CHANNELS, axis=1)
    x = x[:, :CHANNELS]
    # pad/trim to the exact frame count the untouched properties declare
    if len(x) < N_FRAMES:
        x = np.vstack([x, np.zeros((N_FRAMES-len(x), CHANNELS), dtype=x.dtype)])
    return np.ascontiguousarray(x[:N_FRAMES], dtype='<i2')


def build(wav_path, outdir):
    pcm = load_audio(wav_path)
    hdr, data = riff_wave(pcm, SAMPLE_RATE, CHANNELS)

    ua = bytearray(open(SRC+'.uasset', 'rb').read())
    ue = bytearray(open(SRC+'.uexp',  'rb').read())

    # 1. retarget the codec: BINKA -> ADPCM (same length, zero name hashes)
    assert bytes(ua[OFF_BINKA:OFF_BINKA+5]) == b'BINKA'
    ua[OFF_BINKA:OFF_BINKA+5] = b'ADPCM'

    # 2. rebuild the uexp: same prefix, new inlined RIFF header, new sizes
    tail_orig = ue[UEXP_PREFIX_END+ORIG_HDR_LEN:]
    tail = bytearray(tail_orig)
    struct.pack_into('<i', tail, 0, len(hdr))      # chunk0 DataSize
    struct.pack_into('<i', tail, 4, len(hdr))      # chunk0 AudioDataSize
    struct.pack_into('<i', tail, 16, len(data))    # chunk1 DataSize
    struct.pack_into('<i', tail, 20, len(data))    # chunk1 AudioDataSize
    new_ue = bytearray(ue[:UEXP_PREFIX_END]) + bytearray(hdr) + tail
    assert struct.unpack_from('<I', new_ue, len(new_ue)-4)[0] == PKG_TAG, 'package tag lost'

    # 3. patch the package header to match the new sizes
    struct.pack_into('<q', ua, OFF_SERIAL_SIZE, len(new_ue)-4)
    for o in (OFF_C0_ELEMS, OFF_C0_DISK): struct.pack_into('<q', ua, o, len(hdr))
    for o in (OFF_C1_ELEMS, OFF_C1_DISK): struct.pack_into('<q', ua, o, len(data))
    struct.pack_into('<q', ua, OFF_BULK_START, len(ua) + len(new_ue) - 4)

    d = os.path.join(outdir, os.path.dirname(REL)); os.makedirs(d, exist_ok=True)
    base = os.path.join(outdir, REL)
    open(base+'.uasset','wb').write(bytes(ua))
    open(base+'.uexp','wb').write(bytes(new_ue))
    open(base+'.ubulk','wb').write(data)
    print(f"  audio      : {wav_path}")
    print(f"  frames     : {len(pcm)} @ {SAMPLE_RATE} Hz x{CHANNELS}  ({len(pcm)/SAMPLE_RATE:.3f}s)")
    print(f"  uasset {len(ua)}b  uexp {len(ue)}->{len(new_ue)}b  ubulk {len(data)}b")
    return outdir

if __name__ == '__main__':
    wav = sys.argv[1]; out = sys.argv[2]
    if os.path.isdir(out): shutil.rmtree(out)
    os.makedirs(out, exist_ok=True)
    build(wav, out)
