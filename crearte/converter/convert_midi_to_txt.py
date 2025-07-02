import random
from mido import MidiFile
import os
midi_path = input("Enter full path to MIDI file (e.g., /Users/yourname/Crearte/score_output.mid): ")
if not os.path.isfile(midi_path):
    raise FileNotFoundError(f"❌ MIDI file not found: {midi_path}")
image_notes_path = input("Enter full path to image notes text file (e.g., /Users/yourname/Crearte/image_notes.txt): ")
if not os.path.isfile(image_notes_path):
    raise FileNotFoundError(f"❌ Text file not found: {image_notes_path}")
txt_path = input("Enter full path to output file (e.g., /Users/yourname/Crearte/midi_notes.txt): ")
print("Succeed")

synth_types = [
    "saw", "pulse", "sine"
]
env_params = []
try:
    with open(image_notes_path, "r") as f:
        for line in f:
            synth = random.choice(synth_types)
            atk = round(random.uniform(0.005, 0.1), 3)
            dec = round(random.uniform(0.05, 0.3), 3)
            sus = round(random.uniform(0.3, 0.9), 3)
            rel = round(random.uniform(0.1, 1.0), 3)
            env_params.append([synth, atk, dec, sus, rel])
except Exception as e:
    print(f"⚠️ image_notes.txt Failed: {e}")
    env_params.append(["saw", 0.01, 0.1, 0.6, 0.5])
if not env_params:
    env_params.append(["saw", 0.01, 0.1, 0.6, 0.5])
notes = []
mid = MidiFile(midi_path)
for track in mid.tracks:
    abs_time = 0
    for msg in track:
        abs_time += msg.time
        if msg.type == 'note_on' and msg.velocity > 0:
            notes.append((abs_time, msg.note, msg.velocity))
with open(txt_path, "w") as f:
    for i, (abs_time, note, vel) in enumerate(notes):
        if i < len(env_params):
            synth, atk, dec, sus, rel = env_params[i]
        else:
            synth = random.choice(synth_types)
            atk = round(random.uniform(0.005, 0.1), 3)
            dec = round(random.uniform(0.05, 0.3), 3)
            sus = round(random.uniform(0.3, 0.9), 3)
            rel = round(random.uniform(0.1, 1.0), 3)
        f.write(f"{abs_time:.3f}\t{note}\t{vel}\t{synth}\t{atk}\t{dec}\t{sus}\t{rel}\n")
print("✅ Completed to write midi_notes.txt")