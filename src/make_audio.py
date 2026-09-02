import soundfile as sf, numpy as np
from scipy.signal import resample_poly, butter, sosfilt, sosfiltfilt
from fractions import Fraction
import os

OUT = r"C:/Users/kwcar/dev/git/chameleon-whistle/previews"
TARGET_SR   = 24000     # match original asset
N_FRAMES    = 35584     # exact frame count declared by the untouched asset properties
TARGET_DUR  = N_FRAMES/TARGET_SR

def load_mono(p):
    x, sr = sf.read(p)
    if x.ndim > 1: x = x.mean(axis=1)
    return x.astype(np.float64), sr

def peak_segment(x, sr, dur):
    """Pick the window with the highest RMS, snapped to a rising edge."""
    n = int(dur*sr); hop = int(sr*0.01)
    if len(x) <= n: return x
    best, bi = -1, 0
    for s in range(0, len(x)-n, hop):
        r = np.sqrt((x[s:s+n]**2).mean())
        if r > best: best, bi = r, s
    # back up to where energy starts rising, so we don't clip the attack
    env = np.abs(x)
    thr = env[bi:bi+n].max()*0.06
    j = bi
    while j > 0 and env[max(0,j-200):j].max() > thr: j -= 200
    return x[j:j+n]

def pitch_down(x, factor):
    """Lower pitch by `factor` via resampling (also lengthens by `factor`)."""
    fr = Fraction(factor).limit_denominator(50)
    return resample_poly(x, fr.numerator, fr.denominator)

def fade(x, sr, fin=0.008, fout=0.12):
    y = x.copy()
    a, b = int(fin*sr), int(fout*sr)
    if a: y[:a] *= np.linspace(0,1,a)**0.5
    if b: y[-b:] *= np.linspace(1,0,b)**0.7
    return y

def lowpass(x, sr, fc=750, order=8):
    return sosfiltfilt(butter(order, fc/(sr/2), btype='low', output='sos'), x)

def energy_report(x, sr):
    w = np.hanning(len(x)); X = np.abs(np.fft.rfft(x*w))**2
    f = np.fft.rfftfreq(len(x), 1/sr); tot = X.sum()+1e-30
    band = lambda lo,hi: 100*X[(f>=lo)&(f<hi)].sum()/tot
    return band(0,750), (f*X).sum()/tot

def build(name, path, factor, src_dur):
    x, sr = load_mono(path)
    seg = peak_segment(x, sr, src_dur)
    seg = seg/(np.max(np.abs(seg))+1e-12)
    y = pitch_down(seg, factor)
    y = resample_poly(y, TARGET_SR, sr) if sr != TARGET_SR else y
    if len(y) < N_FRAMES: y = np.concatenate([y, np.zeros(N_FRAMES-len(y))])
    y = y[:N_FRAMES]
    y = fade(y, TARGET_SR)
    # normalise on the AUDIBLE band so the sub-750 content is loud
    lp = lowpass(y, TARGET_SR)
    y = y / (np.max(np.abs(lp))+1e-12) * 0.89
    y = np.clip(y, -1.0, 1.0)
    sub, cen = energy_report(y, TARGET_SR)
    st = np.stack([y,y], axis=1)
    sf.write(f"{OUT}/{name}.wav", st, TARGET_SR, subtype='PCM_16')
    # simulation of what it sounds like with only sub-750 hearing
    sim = lowpass(y, TARGET_SR); sim = sim/(np.max(np.abs(sim))+1e-12)*0.89
    sf.write(f"{OUT}/{name}_AS-YOU-HEAR-IT.wav", np.stack([sim,sim],axis=1), TARGET_SR, subtype='PCM_16')
    print(f"{name:22} shift/{factor:<4} dur={len(y)/TARGET_SR:4.2f}s  sub750={sub:5.1f}%  centroid={cen:4.0f}Hz")

if __name__ == "__main__":
    src = int(TARGET_DUR/2.7*1000)/1000
    build("A_male_scream",  "audio/male_scream.flac",  2.7, src)
    build("B_hey_call",     "audio/calling.flac",      2.7, src)
    build("C_wilhelm",      "audio/wilhelm.ogg",       2.7, src)
    build("D_death_scream", "audio/death_scream.flac", 3.0, TARGET_DUR/3.0)
