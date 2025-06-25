import cv2
import librosa
import numpy as np
import soundfile as sf
image_path = input("Enter full path to input image (e.g., /Users/yourname/Crearte/input.png): ")
img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
if img is None:
    raise FileNotFoundError("❌ input image not found or cannot be read: " + image_path)
print("Succeed")
height, width = img.shape
contours, _ = cv2.findContours(img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
sr = 44100
notes = []
for i, c in enumerate(contours):
    if cv2.contourArea(c) < 10:
        continue
    M = cv2.moments(c)
    if M["m00"] == 0:
        continue
    x = int(M["m10"] / M["m00"])
    y = int(M["m01"] / M["m00"])
    area = cv2.contourArea(c)
    x, y = np.clip(x, 0, width-1), np.clip(y, 0, height-1)
    rel_y = (height - y) / height
    freq = 220 + rel_y * 1760
    midi_note = librosa.hz_to_midi(freq)
    freq = librosa.midi_to_hz(midi_note)
    _, _, w, h = cv2.boundingRect(c)
    duration = float(np.clip(h / height * 3.0, 0.1, 3.0))
    velocity = np.clip(area / (width * height), 0.05, 1.0)
    aspect_ratio = float(w) / h
    if aspect_ratio < 0.8:
        waveform = 'triangle'
    elif aspect_ratio > 1.2:
        waveform = 'sine'
    else:
        waveform = 'saw'
    ratio = x / width
    if ratio < 0.125:
        fx = 'reverb'
    elif ratio < 0.25:
        fx = 'delay'
    elif ratio < 0.375:
        fx = 'tremolo'
    elif ratio < 0.5:
        fx = 'vibrato'
    elif ratio < 0.625:
        fx = 'trill'
    elif ratio < 0.75:
        fx = 'glissando'
    elif ratio < 0.875:
        fx = 'chorus'
    else:
        fx = 'ringmod' if i % 2 == 0 else 'arpeggio'
    notes.append((x, freq, duration, velocity, waveform, fx))
notes.sort(key=lambda n: n[0])
def synth(freq, dur, amp, wave='sine', fx='none'):
    t = np.linspace(0, dur, int(sr * dur), endpoint=False)
    if wave == 'sine':
        sig = np.sin(2 * np.pi * freq * t)
    elif wave == 'saw':
        sig = 2 * (t * freq - np.floor(0.5 + t * freq))
    elif wave == 'triangle':
        sig = 2 * np.abs(2 * (t * freq - np.floor(0.5 + t * freq))) - 1
    else:
        sig = np.sin(2 * np.pi * freq * t)
    if fx == 'tremolo':
        sig *= 0.5 * (1 + np.sin(2 * np.pi * 5 * t))
    elif fx == 'vibrato':
        sig = np.sin(2 * np.pi * (freq + 10 * np.sin(2 * np.pi * 5 * t)) * t)
    elif fx == 'trill':
        alt = freq * 1.06
        toggle = np.floor(t * 10) % 2 == 0
        sig = np.where(toggle, np.sin(2 * np.pi * freq * t), np.sin(2 * np.pi * alt * t))
    elif fx == 'delay':
        delay = int(sr * 0.2)
        echo = np.zeros_like(sig)
        if len(sig) > delay:
            echo[delay:] = 0.5 * sig[:-delay]
        sig = sig + echo
    elif fx == 'reverb':
        impulse = np.exp(-0.3 * np.arange(0, int(sr * 0.3)) / sr)
        echo = np.convolve(sig, impulse, mode='full')[:len(sig)]
        sig = sig + 0.5 * echo
    elif fx == 'glissando':
        freq_end = freq * 1.5
        f = np.linspace(freq, freq_end, len(t))
        sig = np.sin(2 * np.pi * f * t)
    elif fx == 'chorus':
        detune = np.sin(2 * np.pi * 0.3 * t) * 5
        sig2 = np.sin(2 * np.pi * (freq + detune) * t)
        sig = (sig + sig2) / 2
    elif fx == 'ringmod':
        mod = np.sin(2 * np.pi * 30 * t)
        sig *= mod
    elif fx == 'arpeggio':
        arp_freqs = [freq, freq * 5/4, freq * 3/2, freq * 2]
        steps = np.floor(t * 8).astype(int) % len(arp_freqs)
        f = np.array([arp_freqs[i] for i in steps])
        sig = np.sin(2 * np.pi * f * t)
    return amp * sig
audio = np.zeros(sr * 30)
cursor = 0
for x, freq, dur, amp, wave, fx in notes:
    start = cursor
    samples = synth(freq, dur, amp, wave, fx)
    end = start + len(samples)
    if end > len(audio):
        audio = np.pad(audio, (0, end - len(audio)))
    audio[start:end] += samples
    cursor += int(dur * sr * 0.9)
audio /= np.max(np.abs(audio))
sf.write("audio_input.wav", audio, sr)
print("✅ Completed: Save sound to audio_input.wav")
