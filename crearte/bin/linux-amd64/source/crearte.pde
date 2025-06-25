import javax.sound.midi.*;
import java.io.File;
import processing.core.PGraphics;
import processing.core.PImage;
import ddf.minim.*;
import ddf.minim.analysis.*;
import javax.swing.JOptionPane;
Minim minim;
AudioPlayer audio;
FFT fft;
PImage spectrogram;
int specHeight = 150;
int canvasW = 800, canvasH = 800;
ArrayList<int[]> notes = new ArrayList<int[]>();
PGraphics pg;
Sequence sequenceOut;
PImage overlayImage;
String audioPath;
String midiTextPath;
String[] midiFiles;
String overlayImagePath;
String scoreImageOutput;
String midiOutput;
String gestureTextPath;
void setup() {
  audioPath = JOptionPane.showInputDialog("Enter full path to audio (e.g., /Users/yourname/Crearte/audio_input.wav):");
  midiTextPath = JOptionPane.showInputDialog("Enter full path to MIDI text file (e.g., /Users/yourname/Crearte/image_notes.txt):");
  String midiFilePath = JOptionPane.showInputDialog("Enter full path to input MIDI file (e.g., /Users/yourname/Crearte/text_output.mid):");
  midiFiles = new String[]{ midiFilePath };
  overlayImagePath = JOptionPane.showInputDialog("Enter full path to overlay image (e.g., /Users/yourname/Crearte/input.png):");
  scoreImageOutput = JOptionPane.showInputDialog("Enter full path to output image (e.g., /Users/yourname/Crearte/output_full_score.png):");
  midiOutput = JOptionPane.showInputDialog("Enter full path to output MIDI file (e.g., /Users/yourname/Crearte/score_output.mid):");
  gestureTextPath = JOptionPane.showInputDialog("Enter full path to gesture text (e.g., /Users/yourname/Crearte/gesture_notes.txt):");
  println("Succeed");
  surface.setSize(canvasW, canvasH);
  pg = createGraphics(canvasW, canvasH);
  pg.beginDraw();
  pg.background(255);
  pg.pushMatrix();
  pg.translate(canvasW / 2, canvasH / 2);
  pg.textFont(createFont("Arial", 12));
  pg.fill(0);
  pg.textAlign(CENTER, CENTER);
  overlayImage = loadImage(overlayImagePath);
  if (overlayImage != null) {
    overlayImage.resize(100, 100);
    pg.imageMode(CENTER);
    pg.image(overlayImage, 0, -340);
  } else {
    println("⚠️ image not found: " + overlayImagePath);
  }
  String[] textLines = loadStrings(midiTextPath);
  if (textLines != null) {
    String allText = join(textLines, " ");
    String[] words = splitTokens(allText, " ,.;:!?()\n\t");
    float radius = 270;
    float angleStep = TWO_PI / max(1, words.length);
    float currentAngle = 0;
    for (String word : words) {
      float x = radius * cos(currentAngle);
      float y = radius * sin(currentAngle);
      pg.pushMatrix();
      pg.translate(x, y);
      pg.rotate(currentAngle + HALF_PI);
      pg.text(word, 0, 0);
      pg.popMatrix();
      currentAngle += angleStep;
    }
  }
  String[] gestureLines = loadStrings(gestureTextPath);
  if (gestureLines != null) {
    String gestureText = join(gestureLines, " ");
    String[] gestureWords = splitTokens(gestureText, " ,.;:!?()\n\t");
    float gestureRadius = 285;
    float gestureAngleStep = TWO_PI / max(1, gestureWords.length);
    float gestureAngle = 0;
    for (String word : gestureWords) {
      float x = gestureRadius * cos(gestureAngle);
      float y = gestureRadius * sin(gestureAngle);
      pg.pushMatrix();
      pg.translate(x, y);
      pg.rotate(gestureAngle + HALF_PI);
      pg.text(word, 0, 0);
      pg.popMatrix();
      gestureAngle += gestureAngleStep;
    }
  }
  for (String path : midiFiles) {
    try {
      Sequence seq = MidiSystem.getSequence(new File(path));
      Track[] tracks = seq.getTracks();
      for (int t = 0; t < tracks.length; t++) {
        for (int i = 0; i < tracks[t].size(); i++) {
          MidiEvent event = tracks[t].get(i);
          MidiMessage msg = event.getMessage();
          if (msg instanceof ShortMessage) {
            ShortMessage sm = (ShortMessage) msg;
            int pitch = sm.getData1();
            int velocity = sm.getData2();
            int tick = (int) event.getTick();
            notes.add(new int[]{pitch, tick, velocity, t});
          }
        }
      }
      sequenceOut = seq;
      addTempoAndTimeSignature(sequenceOut);
      addExpressionAndInstruments(sequenceOut);
    } catch (Exception e) {
      println("❌ MIDI Load Error: " + e.getMessage());
    }
  }
  drawPolarStaffs(pg);
  drawPolarNotes(pg);
  pg.popMatrix();
  pg.endDraw();
  minim = new Minim(this);
  audio = minim.loadFile(audioPath, 2048);
  if (audio == null) {
    println("❌ Audio file not found or unreadable: " + audioPath);
  } else {
    println("✅ Audio loaded: " + audioPath);
    fft = new FFT(audio.bufferSize(), audio.sampleRate());
    spectrogram = createImage(canvasW, specHeight, RGB);
    spectrogram.loadPixels();
    audio.play();
    for (int x = 0; x < canvasW; x++) {
      int ms = (int) map(x, 0, canvasW, 0, audio.length());
      audio.cue(ms);
      delay(10);
      fft.forward(audio.mix);
      for (int y = 0; y < specHeight; y++) {
        int bin = (int) map(y, 0, specHeight, fft.specSize(), 0);
        float amp = fft.getBand(bin);
        int brightness = constrain((int) map(amp, 0, 10, 0, 255), 0, 255);
        spectrogram.pixels[y * canvasW + x] = color(brightness);
      }
    }
    spectrogram.updatePixels();
    audio.pause();
    pg.beginDraw();
    pg.imageMode(CENTER);
    spectrogram.resize((int)(canvasW * 0.8), (int)(specHeight * 0.5));
    int x = canvasW / 2;
    int y = canvasH - specHeight / 2 + 20;
    pg.image(spectrogram, x, y);
    pg.endDraw();
    println("✅ Spectrogram rendered and overlaid.");
  }
  pg.save(scoreImageOutput);
  println("✅ Final full image saved: " + scoreImageOutput);
  try {
    MidiSystem.write(sequenceOut, 1, new File(midiOutput));
    println("✅ MIDI saved: " + midiOutput);
  } catch (Exception e) {
    println("❌ MIDI Write Error: " + e.getMessage());
  }
  noLoop();
}
void draw() {
  image(pg, 0, 0);
}
void addTempoAndTimeSignature(Sequence seq) {
  try {
    Track metaTrack = seq.createTrack();
    MetaMessage tempoMessage = new MetaMessage();
    tempoMessage.setMessage(0x51, new byte[]{0x07, (byte)0xA1, 0x20}, 3);
    metaTrack.add(new MidiEvent(tempoMessage, 0));
    MetaMessage timeSigMessage = new MetaMessage();
    timeSigMessage.setMessage(0x58, new byte[]{4, 2, 24, 8}, 4);
    metaTrack.add(new MidiEvent(timeSigMessage, 0));
  } catch (Exception e) {
    println("❌ Tempo/TimeSignature Insert Error: " + e.getMessage());
  }
}
float customPolarRadius(float angle, float baseRadius) {
  return baseRadius + tan(angle * 4) * 5 + tan(angle * 2.5) * 3;
}
void drawPolarStaffs(PGraphics g) {
  float[] radiiSets = {100, 160, 220};
  int[] lineCounts = {5, 3, 1};
  float lineSpacing = 10;
  g.stroke(0);
  g.strokeWeight(0.5);
  g.textFont(createFont("Arial", 10));
  g.fill(0);
  for (int s = 0; s < radiiSets.length; s++) {
    for (int l = 0; l < lineCounts[s]; l++) {
      float baseRadius = radiiSets[s] + l * lineSpacing;
      for (float angle = 0; angle <= TWO_PI; angle += 0.01) {
        float rt = customPolarRadius(angle, baseRadius);
        float x = rt * cos(angle);
        float y = rt * sin(angle);
        g.point(x, y);
      }
    }
  }
}
void drawPolarNotes(PGraphics g) {
  g.strokeWeight(1);
  colorMode(HSB, 360, 100, 100, 255);
  HashMap<String, Integer> noteOffMap = new HashMap<String, Integer>();
  for (int[] n : notes) {
    int pitch = n[0];
    int tick = n[1];
    int velocity = n[2];
    if (velocity == 0) {
      noteOffMap.put(pitch + "_" + tick, tick);
    }
  }
  for (int i = 0; i < notes.size(); i++) {
    int[] n = notes.get(i);
    int pitch = n[0];
    int tick = n[1];
    int velocity = n[2];
    int track = n[3];
    if (velocity == 0) continue;
    int durationTick = 200;
    for (int j = i + 1; j < notes.size(); j++) {
      int[] m = notes.get(j);
      if (m[0] == pitch && m[2] == 0) {
        durationTick = m[1] - tick;
        break;
      }
    }
    float angle = map(tick % 1000, 0, 1000, 0, TWO_PI);
    float baseRadius = map(pitch, 20, 108, 95, 240);
    float r = customPolarRadius(angle, baseRadius);
    float x = r * cos(angle);
    float y = r * sin(angle);
    float size = map(velocity, 1, 127, 4, 14);
    int alpha = (int)map(velocity, 1, 127, 80, 255);
    int hue = (track * 60) % 360;
    g.fill(hue, 80, 100, alpha);
    g.stroke(hue, 80, 100, alpha);
    g.ellipse(x, y, size, size);
    float len = map(durationTick, 0, 480, 0, 60);
    float x2 = (r + len) * cos(angle);
    float y2 = (r + len) * sin(angle);
    g.stroke(hue, 80, 100, alpha);
    g.line(x, y, x2, y2);
  }
  colorMode(RGB, 255);
}
void addExpressionAndInstruments(Sequence seq) {
  try {
    Track[] tracks = seq.getTracks();
    for (int t = 0; t < tracks.length; t++) {
      Track track = tracks[t];
      int program = t % 16;
      ShortMessage pc = new ShortMessage();
      pc.setMessage(ShortMessage.PROGRAM_CHANGE, t, program, 0);
      track.add(new MidiEvent(pc, 0));
      for (int i = 0; i < track.size(); i++) {
        MidiEvent event = track.get(i);
        MidiMessage msg = event.getMessage();
        if (msg instanceof ShortMessage) {
          ShortMessage sm = (ShortMessage) msg;
          if (sm.getCommand() == ShortMessage.NOTE_ON && sm.getData2() > 0) {
            int velocity = sm.getData2();
            int expression = constrain((int) map(velocity, 1, 127, 30, 127), 30, 127);
            ShortMessage exprMsg = new ShortMessage();
            exprMsg.setMessage(ShortMessage.CONTROL_CHANGE, t, 11, expression);
            track.add(new MidiEvent(exprMsg, event.getTick()));
          }
        }
      }
    }
  } catch (Exception e) {
    println("❌ Expression/Instruments Insert Error: " + e.getMessage());
  }
}
void stop() {
  audio.close();
  minim.stop();
  super.stop();
}
