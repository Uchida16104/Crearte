(
Routine {
    var midiTxtPath, audioOutPath;
    var midiLines, notes;
    var buf, rec, pan, freqMul, totalDuration;
    var validSynths = [\saw, \pulse, \sine];
    validSynths.do { |type|
        SynthDef(type, { |freq=440, amp=0.3, gate=1, atk=0.01, dec=0.1, sus=0.6, rel=0.5, pan=0|
            var env = Env.adsr(atk, dec, sus, rel).kr(gate, doneAction:2);
            var sig;
            switch(type,
                \saw,   { sig = Saw.ar(freq * [1, 1.01]) },
                \pulse, { sig = Pulse.ar(freq, 0.5) },
                \sine,  { sig = SinOsc.ar(freq) },
                { sig = WhiteNoise.ar }
            );
            sig = sig * env * amp;
            sig = Pan2.ar(sig, pan);
            Out.ar(0, sig);
        }).add;
    };
    SynthDef(\RecordBuf, { |bufnum=0|
        var inSig = In.ar(0, 2);
        RecordBuf.ar(inSig, bufnum, loop:0);
    }).add;
    s.waitForBoot({
        s.sync;
        midiTxtPath = "/Users/hirotoshiuchida/Crearte/midi_notes.txt";
        audioOutPath = "/Users/hirotoshiuchida/Crearte/supercollider_output.aiff";
        midiLines = File.readAllString(midiTxtPath).split($\n);
        notes = midiLines.collect { |line|
            var parts = line.split($\t);
            if (parts.size >= 8) {
                var synthSym = parts[3].asSymbol;
                if (validSynths.includes(synthSym).not) {
                    synthSym = \saw;
                };
                [
                    parts[0].asFloat,
                    parts[1].asInteger,
                    parts[2].asFloat,
                    synthSym,
                    parts[4].asFloat,
                    parts[5].asFloat,
                    parts[6].asFloat,
                    parts[7].asFloat
                ]
            } {
                nil
            }
        }.reject(_.isNil);
        "✅ Load midi_notes.txt: Note %".format(notes.size).postln;
        pan = 0.0;
        freqMul = 1.0;
        buf = Buffer.alloc(s, s.sampleRate * 60, 2);
        rec = Synth(\RecordBuf, [\bufnum, buf.bufnum]);
        notes.do { |note, i|
            var time = note[0];
            var pitch = note[1];
            var vel = note[2];
            var synthType = note[3];
            var atk = note[4], dec = note[5], sus = note[6], rel = note[7];
            var dur = atk + dec + rel + 0.1;
            var synth;
            AppClock.sched(time, {
                synth = Synth(synthType, [
                    \freq, pitch.midicps * freqMul,
                    \amp, vel / 127 * 0.5,
                    \atk, atk,
                    \dec, dec,
                    \sus, sus,
                    \rel, rel,
                    \pan, pan,
                    \gate, 1
                ]);
                AppClock.sched(dur, {
                    synth.set(\gate, 0);
                });
            });
        };
        totalDuration = notes.collect({ |n| n[0] + n[4] + n[5] + n[7] }).maxItem + 2.0;
        AppClock.sched(totalDuration, {
            buf.write(audioOutPath, "AIFF", "int16");
            rec.free;
            "✅ Completed to write: %".format(audioOutPath).postln;
        });
    });
}.play;
)