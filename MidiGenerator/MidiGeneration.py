from midiutil import MIDIFile
import os

# is the error trying to assign to a variable that doesn't exist in the namespace? 
current_line = 0

def check_rest(rest_on_off):
    if(rest_on_off == 1):
        return False
    else:
        return True

def check_chord(chord_on_off):
    if(chord_on_off == 0):
        return False
    else:
        return True

class MidiWriter:
    def __init__(self):
        # Log frequencies and durations to files. We can then parse these in the autochord class. 
        self.file = MIDIFile(1)
        self.chord_file = MIDIFile(3)
        self.rest_length = 0
        self.prev_start_time = 0

    def add_tempo(self, tempo): 
        self.file.addTempo(0, 0, tempo)
        self.chord_file.addTempo(0, 0, tempo)


    def add_midi_note(self, volume, pitch, beat, duration, rest_state, des_len):
        if(check_rest(rest_state) == True):
            self.rest_length = duration
        else:
            if(self.prev_start_time != beat):
                if(duration + beat < des_len):
                    self.file.addNote(0, 0, pitch, beat + self.rest_length, duration, volume)
                    self.prev_start_time = beat + self.rest_length
                    self.rest_length = 0

    def add_midi_chord(self, c, chord_volume, root_n, third_n, fifth_n, chord_beat, chord_duration, desired_length):
        if(check_chord(c) == True):
            if(chord_duration + chord_beat < desired_length):
                self.chord_file.addNote(0, 0, root_n, chord_beat, chord_duration, chord_volume)
                self.chord_file.addNote(0, 0, third_n, chord_beat, chord_duration, chord_volume)
                self.chord_file.addNote(0, 0, fifth_n, chord_beat, chord_duration, chord_volume)

    def write(self):
        with open("midi.mid", "wb") as f:
            self.file.writeFile(f)
        with open("chord_midi.mid", "wb") as f:
            self.chord_file.writeFile(f)

    def close_midi(self):
        self.file.close()
        self.chord_file.close()


class ScoreWriter:
    def __init__(self):
        self.score_file = open("scoreFile.txt", "w")
        self.chord_score_file = open("chordScoreFile.txt", "w")
        self.bpm = 0
        self.start_time_log = open("timeDur.txt", "w")
        self.rest_length = 0
        self.prev_start_t = 0

    def bpm_set(self, bpm):
        self.bpm = bpm
    
    def bar_length_secs(self, midi_length):
        beat = 60/self.bpm 
        bar = beat * 4 
        return float(bar*midi_length)
        
    def bpm_get(self):
        return self.bpm

    def write_score_event(self, instr_num, start_time, note_duration, frequency, rest_state):
        if(check_rest(rest_state) == True):
            self.rest_length = note_duration
        else:
            if(self.prev_start_t != start_time):
                message = "i" + str(int(instr_num)) + " " + str(start_time + self.rest_length) + " " + str(note_duration) + " " + str(int(frequency)) + """\n"""
                self.score_file.write(message)
                self.prev_start_t = start_time + self.rest_length
                self.rest_length = 0

                
    def write_chord_score_event(self, instr_num, start_time, on_off, d, pch_1, pch_2, pch_3):
        if(on_off == 1):
            message_1 = "i" + str(int(instr_num)) + " " + str(start_time) + " " +str(d) + " " + str(int(pch_1)) + """\n"""
            message_2 = "i" + str(int(instr_num)) + " " + str(start_time) + " " +str(d) + " " + str(int(pch_2)) + """\n"""
            message_3 = "i" + str(int(instr_num)) + " " + str(start_time) + " " +str(d) + " " + str(int(pch_3)) + """\n"""
            
            self.chord_score_file.write(message_1)
            self.chord_score_file.write(message_2)
            self.chord_score_file.write(message_3)
        

    def close_file(self):
        self.score_file.close()
        self.start_time_log.close()
        self.chord_score_file.close()
    
    # Remember to call this method before writing a new file!
    def flush_file(self):
        self.score_file.close()
        self.score_file = open("scoreFile.txt", "w").close()
        self.score_file = open("scoreFile.txt", "w")

        self.chord_score_file.close()
        self.chord_score_file = open("chordScoreFile.txt", "w").close()
        self.chord_score_file = open("chordScoreFile.txt", "w")

class ScoreParser:
    def __init__(self):
        self.this_line = {}

    def get_n_lines(self):
        self.f = open("scoreFile.txt", "r")
        self.lines = self.f.readlines()
        self.f.close()
        return float(len(self.lines))

    def line_to_ints(self, line_number):
        #i99 0 1 440
        self.this_line = {}
        self.this_line = self.lines[line_number].replace('i', '')
        self.this_line = self.this_line.split()
        instr = float(self.this_line[0])
        st = float(self.this_line[1])
        dur = float(self.this_line[2])
        freq = float(self.this_line[3])
        return instr, st, dur, freq

class ChordScoreParser:

    def __init__(self):
        self.this_chord_line = {}
    def get_n_lines(self):
        self.f = open("chordScoreFile.txt", "r")
        self.lines = self.f.readlines()
        self.f.close()
        return float(len(self.lines))
    
    def line_to_ints(self, line_number):
        self.this_chord_line = {}
        self.this_chord_line = self.lines[line_number].replace('i', '')
        self.this_chord_line = self.this_chord_line.split()
        instr = float(self.this_chord_line[0])
        st = float(self.this_chord_line[1])
        dur = float(self.this_chord_line[2])
        freq = float(self.this_chord_line[3])
        return instr, st, dur, freq
    
class AutoChord:
    def __init__(self, multiplier):
        self.idx = 0
        self.midi_base_array = []
        for i in range(21, 106):
            self.midi_base_array.append(i)
            
        self.root_array = []
        self.third_array = []
        self.fifth_array = []

        self.scale_array = []

        self.first = 0
        self.third = 0
        self.fifth = 0

        self.third_idx = 0
        self.fifth_idx = 0

        self.file_idx = 0
        self.log_file = open("l_file.txt", "w")
        

    def calculate_chords(self, root_note, tonality, modifier):
        tonality = int(tonality) 
        modifier = int(modifier)
        if(modifier < 3):

            if(tonality == 0):
                # Major
                self.scale_array.append(root_note)
                self.scale_array.append(root_note + 2)
                self.scale_array.append(root_note + 4)
                self.scale_array.append(root_note + 5)
                self.scale_array.append(root_note + 7)
                self.scale_array.append(root_note + 9)
                self.scale_array.append(root_note + 11)
            elif(tonality == 1):
                self.scale_array.append(root_note)
                self.scale_array.append(root_note + 2)
                self.scale_array.append(root_note + 3)
                self.scale_array.append(root_note + 5)
                self.scale_array.append(root_note + 7)
                self.scale_array.append(root_note + 8)
                self.scale_array.append(root_note + 10)
                
        elif(modifier == 3):
            self.scale_array.append(root_note - 12)
            self.scale_array.append(root_note - 6)
            self.scale_array.append(root_note)
            self.scale_array.append(root_note + 6)
            self.scale_array.append(root_note + 12)
            self.scale_array.append(root_note + 18)
            self.scale_array.append(root_note + 24)
        
        for element in range(len(self.scale_array)):
            self.scale_array[element] = self.scale_array[element] + 12 * 3

        for i in range(len(self.scale_array)):
            if(modifier < 3):
                self.third_idx = i + 2
                self.fifth_idx = i + 4
            elif(modifier == 3):
                self.third_idx = i + 1
                self.fifth_idx = i + 4

            if(self.third_idx > (len(self.scale_array) - 1)):
                self.third_idx -= 7
            if(self.fifth_idx > (len(self.scale_array) - 1)):
                self.fifth_idx -= 7
                if(self.fifth_idx > (len(self.scale_array) - 1)):
                    self.fifth_idx -= 7   
            self.third_array.append(self.scale_array[self.third_idx])
            self.fifth_array.append(self.scale_array[self.fifth_idx])


    def generate_chord(self, main_note, chord_dur):
        #TODO: Implement a random chord duration. 
        # This shouldn't be that hard.
        # Just initialise a length array depending on the modifier and pass it to this function with the root note. 
        r = int(main_note)
        trd = self.third_array[self.scale_array.index(r)]
        fth = self.fifth_array[self.scale_array.index(r)]
        c_dur = chord_dur
        return r, trd, fth, c_dur

    

            
             
             
                   


