import mido
import os
import random
text_file_path = input("Enter full path to text file (e.g., /Users/yourname/Crearte/image_notes.txt): ")
if not os.path.isfile(text_file_path):
    raise FileNotFoundError(f"❌ File not found: {text_file_path}")
print("Succeed")
with open(text_file_path, "r", encoding="utf-8") as f:
    text = f.read()
def char_to_pitch(c):
    return 48 + (ord(c) % 36)
def char_to_velocity(c):
    return 40 + (ord(c) % 87)
def char_to_duration(c):
    return 60 + (ord(c) % 180)
def char_is_rest(c):
    return c in [' ', '\n', '\t', '.', ',', '。', '、', '・']
def add_expression(track, note):
    effect = random.choice(['none', 'arpeggio', 'glissando', 'trill', 'mordent'])
    if effect == 'arpeggio':
        for i in range(3):
            track.append(mido.Message('note_on', note=note + i * 4, velocity=64, time=20))
            track.append(mido.Message('note_off', note=note + i * 4, velocity=64, time=20))
    elif effect == 'glissando':
        for i in range(5):
            track.append(mido.Message('note_on', note=note + i, velocity=50, time=10))
            track.append(mido.Message('note_off', note=note + i, velocity=50, time=10))
    elif effect == 'trill':
        for i in range(4):
            trill_note = note + (1 if i % 2 == 0 else 3)
            track.append(mido.Message('note_on', note=trill_note, velocity=70, time=15))
            track.append(mido.Message('note_off', note=trill_note, velocity=70, time=15))
    elif effect == 'mordent':
        track.append(mido.Message('note_on', note=note, velocity=64, time=10))
        track.append(mido.Message('note_off', note=note, velocity=64, time=10))
        track.append(mido.Message('note_on', note=note + 1, velocity=64, time=10))
        track.append(mido.Message('note_off', note=note + 1, velocity=64, time=10))
mid = mido.MidiFile()
track = mido.MidiTrack()
mid.tracks.append(track)
track.append(mido.Message('pitchwheel', pitch=0, time=0))
time = 0
for c in text:
    if char_is_rest(c):
        time += char_to_duration(c)
        continue
    note = char_to_pitch(c)
    velocity = char_to_velocity(c)
    duration = char_to_duration(c)
    track.append(mido.Message('note_on', note=note, velocity=velocity, time=time))
    add_expression(track, note)
    track.append(mido.Message('note_off', note=note, velocity=velocity, time=duration))
    if random.random() < 0.2:
        bend_val = random.randint(-8192, 8191)
        track.append(mido.Message('pitchwheel', pitch=bend_val, time=0))
        track.append(mido.Message('pitchwheel', pitch=0, time=duration // 2))
    time = 0
mid.save("text_output.mid")
print("✅ MIDI saved as 'text_output.mid'")