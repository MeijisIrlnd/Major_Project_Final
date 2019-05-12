<Cabbage>
form caption("MidiGen") size(300, 350), pluginid("def1"), colour("white")
;DEJANK::

; TODO: (Minor) Remove gkReady
; TODOL (Minor) Tentacles
; TODO: Store output files in a temp folder in documents as opposed to within the plugins folder
; TODO: Make instruments sound cooler than just fucking sine waves. 

; TODO: Tweak note arrays to make them nicer. To be honest, in your thesis, just say that the values are subject to further tweaks. 
; TODO: Fix Python exceptions

;Key 
combobox bounds(30, 40, 60, 20), items("A", "A#/Bb", "B", "C", "C#/Db", "D", "D#/Eb", "E", "F", "F#/Gb", "G", "G#/Ab"), channel("keySelect"), colour(222, 138, 15)
label bounds(29, 20, 60, 15), text("Key"), fontcolour(222, 138, 15)
;Tonality
combobox bounds(90, 40, 60, 20), items("Major", "Minor"), channel("tonalitySelect"), colour(222, 138, 15), identchannel("tonalityIdent")
label bounds(90, 20, 60, 15), text("Tonality"), fontcolour(222, 138, 15), identchannel("tonalityLabelIdent")
;Mod
combobox bounds(150, 40, 120, 20), items("Standard", "True Random", "Eldritch Horror"), channel("modifierSelect"), colour(222, 138, 15), identchannel("modifierIdent")
label bounds(150, 20, 120, 15), text("Modifier"), fontcolour(222, 138, 15), identchannel("modifierLabelIdent")
;Bpm
groupbox bounds(25, 225, 150, 100), colour("white"), outlinecolour(222, 138, 15), text("Midi Parameters"), fontcolour(222, 138, 15)
texteditor bounds(30, 270, 60, 20), channel("customBpm"), text(120), fontcolour(222, 138, 15)
label bounds(20, 252, 60, 15), text("BPM"), fontcolour(222, 138, 15)
;Length
combobox bounds(90, 270, 60, 20), items("1 Bar", "2 Bars", "4 Bars", "8 Bars", "16 Bars"), channel("midiLen"), value(5), colour(222, 138, 15)
label bounds(80, 252, 100, 15), text("Midi Length"), fontcolour(222, 138, 15)
;Start plugin
groupbox bounds(175, 225, 100, 100), text("Generation"), colour("white"), fontcolour(222, 138, 15), outlinecolour("222, 138, 15")
button text("Generate"), bounds(185, 250, 82, 20), channel("generate"), latched(0), identchannel("gen"), colour:0(222, 138, 15), colour:1(222, 138, 15)
;Preview generated midi
button text("Preview"), bounds(190, 260, 80, 20), channel("preview"), latched(0), identchannel("prev"), colour:0(222, 138, 15), colour:1(222, 138, 15)
;DAW Sync
button text("DAW Sync"), colour:0(222, 138, 15), colour:1(111, 138, 15), bounds(60, 300, 65, 20), latched(1), value(0), channel("sync")
;Steal Ryan's technique: move pictures instead of setting visibility
image file("./UI/WindowsField.jpg"), bounds(25, 80, 250, 130) , identchannel("standard"),
image file("./UI/random.jpg"), bounds(25, 80, 250, 130), identchannel("true_random")
image file("./UI/Rhys.jpg"), bounds(25, 80, 250, 130), identchannel("eldritch_horror")


</Cabbage>
<CsoundSynthesizer>
<CsOptions>
-n -d -+rtmidi=NULL -M0 -m0d 
</CsOptions>
<CsInstruments>
; Initialize the global variables. 
ksmps = 1
nchnls = 2
0dbfs = 1

pyinit
pyexeci "MidiGeneration.py"
;create scoreFile.txt
pyruni{{
import os
if(os.path.isfile("./scoreFile.txt") != True):
    with open("scoreFile.txt", "w") as gen_file:
        gen_file.close()
}}

#include "syl_opcodes.udo"

instr initialise
pyrun{{
parser = ScoreParser()
chord_parser = ChordScoreParser()
}}
chnset "bounds(-1000, 0, 0, 0)", "prev"
;Array Initialisation
kIndex = 0
;Create Scale array and fill with zeroes
gkScaleArray[] init 13
scaleFill:
gkScaleArray[kIndex] = 0
loop_lt kIndex, 1, 13, scaleFill
kIndex = 0
;Create Note Length array and fill with zeroes
gkNoteLenArray[] init 20
lengthFill:
gkNoteLenArray[kIndex] = 0
loop_lt kIndex, 1, 20, lengthFill
kIndex = 0
;Create Pitch Value array and fill with pitch values
gkMidiArray[] init 106
kValToAdd init 21
midiFill:
gkMidiArray[kIndex] = kValToAdd
kIndex = kIndex + 1
loop_lt kValToAdd, 1, 106, midiFill
kIndex = 0
;Create Rest Array and fill with zeroes
gkRestArray[] init 20
restFill: 
gkRestArray[kIndex] = 0
loop_lt kIndex, 1, 19, restFill
kIndex = 0
;Create chord length array and fill with zeroes
gkChordLengthArray[] init 8
chordFill:
gkChordLengthArray[kIndex] = 0
loop_lt kIndex, 1, 8, chordFill


turnon "ScaleGenerator"
turnon "MidiListener"
turnon "PreviewScore"
turnoff
endin

instr ScaleGenerator
seed 0
;If a combobox has been changed, rewrite the changes into gkScaleArray
if((changed:k(chnget:k("keySelect")) == 1) || (changed:k(chnget:k("tonalitySelect")) == 1) || (changed:k(chnget:k("modifierSelect")) == 1)) then
    kTonality chnget "tonalitySelect"
    kModifier chnget "modifierSelect"
    if(kModifier == 3) then
        chnset "visible(0)", "tonalityIdent"
        chnset "visible(0)", "tonalityLabelIdent"
        chnset "bounds(90, 40, 120, 20)", "modifierIdent"
        chnset "bounds(90, 20, 120, 15)", "modifierLabelIdent"

    else
        chnset "visible(1)", "tonalityIdent"
        chnset "visible(1)", "tonalityLabelIdent"
        chnset "bounds(150, 40, 120, 20)", "modifierIdent"
        chnset "bounds(150, 20, 120, 15)", "modifierLabelIdent"
    endif
    
    kKey chnget "keySelect"
    kStartNote = gkMidiArray[kKey - 1]
    ;Fill Array based on combobox params

    if(kModifier == 1) then
    
    chnset "bounds(25, 80, 250, 130),", "standard"
    chnset "bounds(-1000, 80, 250, 130),", "true_random"
    chnset "bounds(-1000, 80, 250, 130),", "eldritch_horror"


        gkNoteLenArray[0] = 1/2
        gkNoteLenArray[1] = 1/2
        gkNoteLenArray[2] = 1/2
        gkNoteLenArray[3] = 1/2
        gkNoteLenArray[4] = 1/2
        gkNoteLenArray[5] = 1/2
        gkNoteLenArray[6] = 1/2
        gkNoteLenArray[7] = 1/4
        gkNoteLenArray[8] = 1/4
        gkNoteLenArray[9] = 1/4
        gkNoteLenArray[10] = 1/4
        gkNoteLenArray[11] = 1/4
        gkNoteLenArray[12] = 1/4
        gkNoteLenArray[13] = 1/4
        gkNoteLenArray[14] = 1/4

        ;Rests
        gkRestArray[0] = 0
        gkRestArray[1] = 0
        gkRestArray[2] = 0
        gkRestArray[3] = 1
        gkRestArray[4] = 1
        gkRestArray[5] = 1
        gkRestArray[6] = 1
        gkRestArray[7] = 1
        gkRestArray[8] = 1
        gkRestArray[9] = 1
        gkRestArray[10] = 1
        gkRestArray[11] = 1
        gkRestArray[12] = 1
        gkRestArray[13] = 1
        gkRestArray[14] = 1
        gkRestArray[15] = 1
        gkRestArray[16] = 1
        gkRestArray[17] = 1
        gkRestArray[18] = 1
        gkRestArray[19] = 1

        ;Chord Lengths: 
        gkChordLengthArray[0] = 2
        gkChordLengthArray[1] = 2
        gkChordLengthArray[2] = 2
        gkChordLengthArray[3] = 2
        gkChordLengthArray[4] = 1
        gkChordLengthArray[5] = 1
        gkChordLengthArray[6] = 4
        gkChordLengthArray[7] = 4
        
        if(kTonality == 1) then
            ;Major, Standard
            gkScaleArray[0] = kStartNote
            gkScaleArray[1] = kStartNote
            gkScaleArray[2] = kStartNote

            gkScaleArray[3] = kStartNote + 2

            gkScaleArray[4] = kStartNote + 4
            gkScaleArray[5] = kStartNote + 4
            gkScaleArray[6] = kStartNote + 4

            gkScaleArray[7] = kStartNote + 5
            gkScaleArray[8] = kStartNote + 5

            gkScaleArray[9] = kStartNote + 7
            gkScaleArray[10] = kStartNote + 7
            gkScaleArray[11] = kStartNote + 7

            gkScaleArray[12] = kStartNote + 9

            gkScaleArray[13] = kStartNote + 11
            
        elseif(kTonality == 2) then 
            ;Minor, Standard
            gkScaleArray[0] = kStartNote
            gkScaleArray[1] = kStartNote
            gkScaleArray[2] = kStartNote

            gkScaleArray[3] = kStartNote + 2

            gkScaleArray[4] = kStartNote + 3
            gkScaleArray[5] = kStartNote + 3
            gkScaleArray[6] = kStartNote + 3

            gkScaleArray[7] = kStartNote + 5
            gkScaleArray[8] = kStartNote + 5

            gkScaleArray[9] = kStartNote + 7
            gkScaleArray[10] = kStartNote + 7
            gkScaleArray[11] = kStartNote + 7

            gkScaleArray[12] = kStartNote + 8

            gkScaleArray[13] = kStartNote + 10
        endif

    elseif(kModifier == 2) then
    chnset "bounds(-1000, 80, 250, 130),", "standard"
    chnset "bounds(25, 80, 250, 130),", "true_random"
    chnset "bounds(-1000, 80, 250, 130),", "eldritch_horror"
        gkNoteLenArray[0] = 1/2
        gkNoteLenArray[1] = 1/2
        gkNoteLenArray[2] = 1/2
        gkNoteLenArray[3] = 1/2
        gkNoteLenArray[4] = 1/2
        gkNoteLenArray[5] = 1/2
        gkNoteLenArray[6] = 1/2

        gkNoteLenArray[7] = 1/4
        gkNoteLenArray[8] = 1/4
        gkNoteLenArray[9] = 1/4
        gkNoteLenArray[10] = 1/4
        gkNoteLenArray[11] = 1/4
        gkNoteLenArray[12] = 1/4
        gkNoteLenArray[13] = 1/4
        gkNoteLenArray[14] = 1/4

        ;Rests
        gkRestArray[0] = 0
        gkRestArray[1] = 0
        gkRestArray[2] = 0
        gkRestArray[3] = 1
        gkRestArray[4] = 1
        gkRestArray[5] = 1
        gkRestArray[6] = 1
        gkRestArray[7] = 1
        gkRestArray[8] = 1
        gkRestArray[9] = 1
        gkRestArray[10] = 1
        gkRestArray[11] = 1
        gkRestArray[12] = 1
        gkRestArray[13] = 1
        gkRestArray[14] = 1
        gkRestArray[15] = 1
        gkRestArray[16] = 1
        gkRestArray[17] = 1
        gkRestArray[18] = 1
        gkRestArray[19] = 1
        
        gkChordLengthArray[0] = 1
        gkChordLengthArray[1] = 1
        gkChordLengthArray[2] = 2
        gkChordLengthArray[3] = 2
        gkChordLengthArray[4] = 4
        gkChordLengthArray[5] = 4
        gkChordLengthArray[6] = 8
        gkChordLengthArray[7] = 8
        if(kTonality == 1) then

            ;Major, true random
            gkScaleArray[0] = kStartNote
            gkScaleArray[1] = kStartNote

            gkScaleArray[2] = kStartNote + 2
            gkScaleArray[3] = kStartNote + 2

            gkScaleArray[4] = kStartNote + 4
            gkScaleArray[5] = kStartNote + 4

            gkScaleArray[6] = kStartNote + 5
            gkScaleArray[7] = kStartNote + 5

            gkScaleArray[8] = kStartNote + 7
            gkScaleArray[9] = kStartNote + 7

            gkScaleArray[10] = kStartNote + 9
            gkScaleArray[11] = kStartNote + 9

            gkScaleArray[12] = kStartNote + 11
            gkScaleArray[13] = kStartNote + 11
        elseif(kTonality == 2) then
            ;Minor, True Random
            gkScaleArray[0] = kStartNote
            gkScaleArray[1] = kStartNote

            gkScaleArray[2] = kStartNote + 2
            gkScaleArray[3] = kStartNote + 2

            gkScaleArray[4] = kStartNote + 3
            gkScaleArray[5] = kStartNote + 3

            gkScaleArray[6] = kStartNote + 5
            gkScaleArray[7] = kStartNote + 5

            gkScaleArray[8] = kStartNote + 7
            gkScaleArray[9] = kStartNote + 7
        
            gkScaleArray[10] = kStartNote + 8
            gkScaleArray[11] = kStartNote + 8

            gkScaleArray[12] = kStartNote + 10
            gkScaleArray[13] = kStartNote + 10
        endif

    elseif(kModifier == 3) then
        
        chnset "bounds(-1000, 80, 250, 130),", "standard"
        chnset "bounds(-1000, 80, 250, 130),", "true_random"
        chnset "bounds(25, 80, 250, 130),", "eldritch_horror"
    
        gkNoteLenArray[0] = 4
        gkNoteLenArray[1] = 4
        gkNoteLenArray[2] = 4
        gkNoteLenArray[3] = 4
        gkNoteLenArray[4] = 3.8
        gkNoteLenArray[5] = 3.9
        gkNoteLenArray[6] = 3.7

        gkNoteLenArray[7] = 3
        gkNoteLenArray[8] = 6
        gkNoteLenArray[9] = 4
        gkNoteLenArray[10] = 4.5
        gkNoteLenArray[11] = 4
        gkNoteLenArray[12] = 4
        gkNoteLenArray[13] = 2
        gkNoteLenArray[14] = 2

        ;Rests
        gkRestArray[0] = 1
        gkRestArray[1] = 1
        gkRestArray[2] = 1
        gkRestArray[3] = 1
        gkRestArray[4] = 1
        gkRestArray[5] = 1
        gkRestArray[6] = 1
        gkRestArray[7] = 1
        gkRestArray[8] = 1
        gkRestArray[9] = 1
        gkRestArray[10] = 1
        gkRestArray[11] = 1
        gkRestArray[12] = 1
        gkRestArray[13] = 1
        gkRestArray[14] = 1
        gkRestArray[15] = 1
        gkRestArray[16] = 1
        gkRestArray[17] = 1
        gkRestArray[18] = 1
        gkRestArray[19] = 1
        
        gkChordLengthArray[0] = 6
        gkChordLengthArray[1] = 7
        gkChordLengthArray[2] = 8
        gkChordLengthArray[3] = 2
        gkChordLengthArray[4] = 1
        gkChordLengthArray[5] = 1
        gkChordLengthArray[6] = 4
        gkChordLengthArray[7] = 4
        
        
        ;Tritone = root + 6
        gkScaleArray[0] = kStartNote
        gkScaleArray[1] = kStartNote
        gkScaleArray[2] = kStartNote

        gkScaleArray[3] = kStartNote + 6
        gkScaleArray[4] = kStartNote + 6
        gkScaleArray[5] = kStartNote + 6
            
        gkScaleArray[6] = kStartNote + 12
        gkScaleArray[7] = kStartNote + 12

        gkScaleArray[8] = kStartNote + 18
        gkScaleArray[9] = kStartNote + 18

        gkScaleArray[10] = kStartNote + 24
        gkScaleArray[11] = kStartNote + 24

        gkScaleArray[12] = kStartNote + 30
        gkScaleArray[13] = kStartNote + 30
        
    endif
endif


endin 

instr MidiListener

if(chnget:k("tonalitySelect") == 1) then
    kTonality = 0
elseif(chnget:k("tonalitySelect") == 2) then
    kTonality = 1
endif


if((changed:k(chnget:k("generate")) == 1) && (chnget:k("generate") != 0)) then
kMod chnget "modifierSelect"
pyassign "rn", gkScaleArray[0]
pyassign "ton", kTonality
pyassign "mod", kMod
pyrun{{
writer = MidiWriter()
score_writer = ScoreWriter()
score_writer.flush_file()
auto_chord = AutoChord(3)
auto_chord.calculate_chords(rn, ton, mod)
}}
gkBeat = 0
event "i", "sched", 0, 100000
endif
endin

instr sched

seed 0
kMult = 3

SBpm chnget "customBpm"
;> 47 && 58 >
kElementOne strchark SBpm, 0
kElementTwo strchark SBpm, 1
kElementThree strchark SBpm, 2
kElementFour strchark SBpm, 3

if((kElementOne != 0) && (kElementOne > 47) && (kElementOne < 58)) then 
    if((kElementTwo > 47) && (kElementTwo < 58) || (kElementTwo == 0)) then
        if((kElementThree > 47) && (kElementThree < 58) || (kElementThree == 0)) then 
            if((kElementFour > 47) && (kElementFour < 58) || (kElementFour == 0)) then 
                kBpm strtodk SBpm
            endif
        endif
    endif
endif




if(chnget:k("sync") == 1) then
    kBpm chnget "HOST_BPM"
endif

kMidiLen chnget "midiLen"
if(kMidiLen == 1) then 
    kMidiLen = 4
elseif(kMidiLen == 2) then 
    kMidiLen = 8
elseif(kMidiLen == 3) then
    kMidiLen = 16
elseif(kMidiLen == 4) then
    kMidiLen = 32
elseif(kMidiLen == 5) then
    kMidiLen = 64
endif

pyassign "current_bpm", kBpm
pyrun{{
writer.add_tempo(current_bpm)
score_writer.bpm_set(current_bpm)
}}
pyassign "current_midi_len", kMidiLen
pyrun{{
duration_secs = score_writer.bar_length_secs(current_midi_len)
}}
kDuration pyeval "duration_secs"

while gkBeat < kMidiLen do
kRandomNoteIdx random 0, 20
kMidiNote = gkScaleArray[int(kRandomNoteIdx)]
kMidiNote = kMidiNote + 12 * kMult

kNoteLenIdx random 0, 14
kNoteLength = gkNoteLenArray[kNoteLenIdx]
kRestIndex random 0, 18
kRest = gkRestArray[int(kRestIndex)]
if(gkBeat == 0) then 
    kRest = 1
endif

kChordDecision random 0, 10
if(chnget:k("modifierSelect") == 1) then
    if(kChordDecision > 6) then
        kGenerate = 1
    else
        kGenerate = 0
    endif
elseif(chnget:k("modifierSelect") == 2) then
    if(kChordDecision > 5) then
        kGenerate = 1
    else
        kGenerate = 0
    endif
elseif(chnget:k("modifierSelect") == 3) then
    if(kChordDecision > 2) then
        kGenerate = 1
    else
        kGenerate = 0
    endif
endif

kChordLenIndex random 0, 8
kCLen = gkChordLengthArray[kChordLenIndex]

pyassign "rand_pitch", kMidiNote
pyassign "current_beat", gkBeat
pyassign "n_length", kNoteLength
pyassign "r_oo", kRest
pyassign "c_oo", kGenerate
pyassign "chord_length", kCLen
pyrun{{
writer.add_midi_note(100, rand_pitch, current_beat, n_length, r_oo, current_midi_len)
root_no, third_no, fifth_no, dur_no = auto_chord.generate_chord(rand_pitch, chord_length)
writer.add_midi_chord(c_oo, 100, root_no, third_no, fifth_no, current_beat, chord_length, current_midi_len)
b_len = 60.0 / float(score_writer.bpm_get())
time_beat = current_beat * b_len
time_duration = n_length * b_len
chord_time_duration = chord_length * b_len
score_writer.write_score_event(99, time_beat, time_duration, rand_pitch, r_oo)
score_writer.write_chord_score_event(98, time_beat, c_oo, chord_time_duration, root_no, third_no, fifth_no)
}}

gkBeat = gkBeat + kNoteLength

chnset "bounds(-1000, 260, 80, 20),", "prev"
chnset "bounds(-1000, 240, 80, 20),", "gen"
od

pyrun{{
writer.write()
writer.close_midi()
score_writer.close_file()
}}

chnset "bounds(185, 250, 82, 20),", "gen"
chnset "bounds(185, 275, 82, 20),", "prev"
turnon "PreviewScore"
pyrun{{
del writer
del score_writer
del auto_chord
}}
turnoff
endin


instr PreviewScore
kLine = 0
kFlag = 0

if((changed:k(chnget:k("preview")) == 1) && (chnget:k("preview") != 0)) then

kEndTime readscore 0
kChordEndTime readchordscore 0
endif
endin

instr 98
kFreq = p4
kFreq = kFreq - 12
kVol = 0.1
kFreq sylMtof kFreq
aSignal vco2 kVol, kFreq
aSignal lowpass2 aSignal, 400, 250
outs aSignal, aSignal
endin

instr 99
kFreq = p4
kVol = 0.3
kFreq sylMtof kFreq
kEnv linen kVol, p3 * 0.3, p3, p3 * 0.3
aSignal oscil kVol, kFreq, 1
outs aSignal, aSignal
endin

</CsInstruments>
<CsScore>
f0 z
f1 0 1024 10 1

i"initialise" 0 [60*60*24*7]
</CsScore>
</CsoundSynthesizer>
