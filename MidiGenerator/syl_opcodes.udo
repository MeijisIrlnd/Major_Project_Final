;Find the index of the first instance of a number in an array. Usage: 
;kIdx indexof kQuery, kArray[]
#include "TtoString.udo"
opcode indexof, k, kk[]
kQuery, kDict[] xin
kFound = 0
kIdx = 0
while kFound==0 do
    if(kDict[kIdx] == kQuery) then
        kFound = 1
    else
        kIdx = kIdx + 1
    endif
od
xout kIdx
endop

;Generates chords given a root note, calculates 1st 3rd and 5th from said note, and returns them in midi values. 
;k1, k2, k3 setChord kTonality, kRoot, kMajorArray[], kMinorArray[]

opcode setChord, kkk, kkk[]k[]
kTonality, kRoot, kMajorArr[], kMinorArr[] xin
kOutOne init 0
kOutTwo init 0
kOutThree init 0
if(kTonality == 1) then
kLocation indexof kRoot, kMajorArr
    if((kLocation+2) > 6) then
        kLocation2 = (kLocation + 2) - 6
    else
        kLocation2 = kLocation + 2
    endif
    if((kLocation+4) > 6) then
        kLocation3 = (kLocation + 4) - 6
    else
        kLocation3 = kLocation + 4
    endif
    kOutOne = kMajorArr[kLocation]
    kOutTwo = kMajorArr[kLocation2]
    kOutThree = kMajorArr[kLocation3]
elseif(kTonality == 2) then
kLocation indexof kRoot, kMinorArr
    if((kLocation+2) > 6) then
        kLocation2 = (kLocation + 2) - 6
    else
        kLocation2 = kLocation + 2
    endif
    if((kLocation+4) > 6) then
        kLocation3 = (kLocation + 4) - 6
    else
        kLocation3 = kLocation + 4
    endif
    kOutOne = kMinorArr[kLocation]
    kOutTwo = kMinorArr[kLocation2]
    kOutThree = kMinorArr[kLocation3]
endif
xout kOutOne, kOutTwo, kOutThree
endop

;Just mtof but cooler because it has Syl in it 
;kFreq sylMtof kMidi

opcode sylMtof, k, k
kMidi xin
;Calculate frequency (f = 440(2^(d-69)/12))
kPower = kMidi - 69
kPower = kPower / 12
kFreq pow 2, kPower
kFreq = kFreq * 440
xout kFreq
endop

;finds the length of an interval of a beat in seconds. 
;kLengthInSecs beattotime kBpm, kMultiplier

opcode beattotime, k, kk
kBpm, kMult xin 
kTime = 60/kBpm
kDivider = kTime * kMult
xout kDivider
endop

;Reads a score (Specific to this vst)
;kTotalDur readscore kCount
opcode readscore, k, k
kCount xin
kReturn = 0
Sscore strcpyk ""
pyrun{{
n_lines = parser.get_n_lines()
}}
kNLines pyeval "n_lines"
kReturn = 0 

while kCount < kNLines do
pyassign "current_line", kCount
pyrun{{
current_line = int(current_line)
ins, s, d, f = parser.line_to_ints(current_line)
}}
kINum pyeval "ins"
kINum = int(kINum)
kStart pyeval "s"
kDur pyeval "d"
kFreq pyeval "f"
kReturn = kReturn + kDur
Sscore strcatk Sscore, "i"
SiNum inttostring kINum
Sscore strcatk Sscore, SiNum
Sscore strcatk Sscore, " "
SstartTime floattostring kStart
Sscore strcatk Sscore, SstartTime
Sscore strcatk Sscore, " "
Sdur floattostring kDur
Sscore strcatk Sscore, Sdur
Sscore strcatk Sscore, " "
Sfreq floattostring kFreq
Sscore strcatk Sscore, Sfreq
Sscore strcatk Sscore, "\n"
scoreline Sscore, 1
Sscore strcpyk ""
kCount = kCount + 1
od
xout kReturn
endop

opcode readchordscore, k, k
kCount xin
kReturn = 0
Sscore strcpyk ""
pyrun{{
n_lines = chord_parser.get_n_lines()
}}
kNLines pyeval "n_lines"
kReturn = 0 

while kCount < kNLines do
pyassign "current_line", kCount
pyrun{{
current_line = int(current_line)
ins, s, d, f = chord_parser.line_to_ints(current_line)
}}
kINum pyeval "ins"
kINum = int(kINum)
kStart pyeval "s"
kDur pyeval "d"
kFreq pyeval "f"
kReturn = kReturn + kDur
Sscore strcatk Sscore, "i"
SiNum inttostring kINum
Sscore strcatk Sscore, SiNum
Sscore strcatk Sscore, " "
SstartTime floattostring kStart
Sscore strcatk Sscore, SstartTime
Sscore strcatk Sscore, " "
Sdur floattostring kDur
Sscore strcatk Sscore, Sdur
Sscore strcatk Sscore, " "
Sfreq floattostring kFreq
Sscore strcatk Sscore, Sfreq
Sscore strcatk Sscore, "\n"
k_Tara active 98 
if(k_Tara < 3) then     
    scoreline Sscore, 1
endif
Sscore strcpyk ""
kCount = kCount + 1
od
xout kReturn
endop



