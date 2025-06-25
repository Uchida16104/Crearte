# Crearte
![Crearte](https://github.com/Uchida16104/Crearte/blob/5ed6023b7a236017dd8bdbee3ec26b7434932192/Crearte.png "Crearte")
Crearte is software that helps to create musical scores using music generated from images and poems. The etymology of Crearte comes from the combination of "create" and "art".The directory contains sample .mid files, .wav files, .png files, and .txt files.

## Requirements
- Python
- Java / Processing
- SuperCollider
- Node.js
- Browser software

## Usage
1. ``` cd Crearte ```
2. ``` source scripts/install.sh ``` (First time)
3. ``` python3 -m venv venv ```
4. ``` source venv/bin/activate ```
5. ``` open crearte/hydra/launch.sh ```
6. edit and run script.js on [hydra](https://hydra.ojack.xyz)
7. save and generate input.png from hydra by screencap() function
8. move input.png to Crearte directory
9. edit and save image_notes.txt and gesture_notes.txt
10. ``` python3 image2score/image2score.py ```
11. ``` python3 text2midi/text2midi.py ```
12. run crearte/bin/crearte.pde
13. ``` python3 crearte/converter/convert_midi_to_txt.py ```
14. perform with crearte/player/player.scd, hydra-processing-bridge/index.html, and score_output.mid.

Hirotoshi Uchida
