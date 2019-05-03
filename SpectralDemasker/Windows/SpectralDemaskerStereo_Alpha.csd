<Cabbage>
form caption("SpectralDemaskerStereo") size(420, 670), colour("pink"), pluginid("spectral_demasker"), identchannel("main"),
groupbox text("Depth"), bounds(10, 310, 100, 320), outlinethickness(1), identchannel("depthboxIdent") colour("pink"), fontcolour("teal"),
rslider bounds(20, 350, 75, 75), channel("LowDepth"),  identchannel("low_depth"), range(0, 1, 0.5, 1, .01), text("Low Depth"), textcolour("black"), trackercolour("teal"), outlinecolour("pink"), textcolour("white"), trackerthickness(0),
rslider bounds(20, 425, 75, 75),  channel("MidDepth"), identchannel("mid_depth"), range(0, 1, 0.5, 1, .01), text("Mid Depth"), textcolour("black"), trackercolour("teal"), outlinecolour("pink"), textcolour("white"), trackerthickness(0),
rslider bounds(20, 505, 75, 75),  channel("HighDepth"), identchannel("high_depth"), range(0, 1, 0.5, 1, .01), text("High Depth"), textcolour("black"), trackercolour("teal"), outlinecolour("pink"), textcolour("white"), trackerthickness(0),
groupbox text("Bands"), bounds(110, 310, 100, 320), colour("pink"), fontcolour("teal")
rslider bounds(125, 350, 75, 75), channel("band_1"), identchannel("lowbandwidth"), range(60, 500, 200, 1, .01), text("Band 1"), trackercolour("teal"), outlinecolour("pink"), textcolour("white"), trackerthickness(0)
rslider bounds(125, 425, 75, 75), channel("band_2"), identchannel("highbandwidth") range(1800, 5000, 3000, 1, .01), text("Band 2"), trackercolour("teal"), outlinecolour("pink"), textcolour("white"),  trackerthickness(0)
signaldisplay bounds(10, 10, 200, 280), displaytype("spectrogram"), signalvariable("a_out_l"), alpha(0.3)
signaldisplay bounds(210, 10, 200, 280), displaytype("spectrogram"), signalvariable("a_out_r"),alpha(0.3)


image file("./UI/Sakura.png"), bounds(220, 310, 190, 320), alpha(0.5), identchannel("imageIdent"), 
button bounds(25, 590, 70, 30), text("Link Off", "Link On"), channel("link_button"), value(0), colour:0("pink"), colour:1("pink")
groupbox text("Modifier Amp"), bounds(110, 555, 100, 75), colour("pink"), fontcolour("teal")
combobox bounds(125, 590, 70, 30), items("x1", "x2", "x4"), channel("mod_amp"), value(1), colour("pink"), fontcolour("teal")

</Cabbage>
<CsoundSynthesizer>
<CsOptions>
-n -d -+rtmidi=NULL -M0 -m0d --displays
</CsOptions>
<CsInstruments>
sr = 44100
ksmps = 1
nchnls = 4
0dbfs = 1

;Initialise outside of instruments for efficiency
gi_n_bins = 512
gi_sr = 48000
gi_div = gi_n_bins / 2
gk_increment = gi_sr / 2
gk_increment = gk_increment / gi_div
gi_ft_size = gi_n_bins / 2
gi_ft_size = gi_ft_size + 1
gk_mod_mult init 0

instr GUIThread 

k_button chnget "link_button"
if k_button == 1 then
    if changed:k(chnget:k("LowDepth")) == 1 then
        chnset chnget:k("LowDepth"), "MidDepth"
        chnset chnget:k("MidDepth"), "HighDepth"
    elseif changed:k(chnget:k("MidDepth")) == 1 then
        chnset chnget:k("MidDepth"), "LowDepth"
        chnset chnget:k("LowDepth"), "HighDepth"
    else
        chnset chnget:k("HighDepth"), "LowDepth"
        chnset chnget:k("LowDepth"), "MidDepth"
    endif
endif

gk_low chnget "band_1"
gk_low = gk_low/gk_increment
gk_mid chnget "band_2"
gk_mid = gk_mid/gk_increment
gk_high = 20000

gk_low_depth chnget "LowDepth"
gk_mid_depth chnget "MidDepth"
gk_high_depth chnget "HighDepth"

k_sig_mod chnget "mod_amp"

if(k_sig_mod == 1) then 
    gk_mod_mult = 1
elseif(k_sig_mod == 2) then 
    gk_mod_mult = 2
elseif(k_sig_mod == 3) then 
    gk_mod_mult = 4
else
    gk_mod_mult = 1
endif

endin 

instr SpectralDemaskerLeft

; function table size = (n_bins/2)+1
; FFT only uses 1/2 of the values as the other half are zeros. +1 for Nyquist guard point to fit in ftable

i_ft_l ftgen 1, 0, gi_ft_size, 2, 0
i_low_ft_l ftgen 3, 0, gi_ft_size, 2, 0
i_mid_ft_l ftgen 5, 0, gi_ft_size, 2, 0
i_high_ft_l ftgen 7, 0 , gi_ft_size, 2, 0

; FFT main and carrier signals
a_mag_signal_l inch 3
a_mag_signal_l = a_mag_signal_l * gk_mod_mult
a_master_signal_l inch 1

f_main_l pvsanal a_master_signal_l, gi_n_bins, gi_n_bins/4, gi_n_bins, 1
f_sig_l pvsanal a_mag_signal_l, gi_n_bins, gi_n_bins/4, gi_n_bins, 1
k_flag_l pvsftw f_sig_l, 1
if k_flag_l == 0 kgoto contin
k_n = 0

; fill table with inverted mag bins
loop:
k_temp_l table k_n, i_ft_l

k_temp_l = 1 - k_temp_l

if(k_temp_l < 0) then 
    k_temp_l = 0
endif

if k_n <= gk_low then
    tablew k_temp_l, k_n, i_low_ft_l

    tablew 1, k_n, i_mid_ft_l
    tablew 1, k_n, i_high_ft_l

elseif k_n > gk_low && k_n <= gk_mid then
    tablew 1, k_n, i_low_ft_l
 
    tablew k_temp_l, k_n, i_mid_ft_l
 
    tablew 1, k_n, i_high_ft_l
 
elseif k_n > gk_mid then
    tablew 1, k_n, i_low_ft_l
  
    tablew 1, k_n, i_mid_ft_l
  
    tablew k_temp_l, k_n, i_high_ft_l
  
endif
loop_lt k_n, 1, gi_ft_size, loop
 
contin:
; Filter by low, mid and high mag bins


pvsftr f_sig_l, i_low_ft_l

f_low_filtered_l pvsfilter f_main_l, f_sig_l, gk_low_depth

pvsftr f_sig_l, i_mid_ft_l

f_mid_filtered_l pvsfilter f_low_filtered_l, f_sig_l, gk_mid_depth

pvsftr f_sig_l, i_high_ft_l

f_high_filtered_l pvsfilter f_mid_filtered_l, f_sig_l, gk_high_depth

a_out_l pvsynth f_high_filtered_l


; Display fft
dispfft a_out_l, 0.01, 256, 0, 1

outs1 a_out_l
endin


instr SpectralDemaskerRight

i_ft_r ftgen 2, 0, gi_ft_size, 2, 0
i_low_ft_r ftgen 4, 0, gi_ft_size, 2, 0
i_mid_ft_r ftgen 6, 0, gi_ft_size, 2, 0
i_high_ft_r ftgen 8, 0 , gi_ft_size, 2, 0

a_mag_signal_r inch 4
a_mag_signal_r = a_mag_signal_r * gk_mod_mult
a_master_signal_r inch 2

f_main_r pvsanal a_master_signal_r, gi_n_bins, gi_n_bins/4, gi_n_bins, 1
f_sig_r pvsanal a_mag_signal_r, gi_n_bins, gi_n_bins/4, gi_n_bins, 1

k_flag_r pvsftw f_sig_r, 2
if k_flag_r == 0 kgoto contin
k_n = 0

loop:

k_temp_r table k_n, i_ft_r

k_temp_r = 1 - k_temp_r

if(k_temp_r < 0) then 
    k_temp_r = 0
endif

if k_n <= gk_low then
    
    tablew k_temp_r, k_n, i_low_ft_r
    tablew 1, k_n, i_mid_ft_r
    tablew 1, k_n, i_high_ft_r
elseif k_n > gk_low && k_n <= gk_mid then    
    tablew 1, k_n, i_low_ft_r    
    tablew k_temp_r, k_n, i_mid_ft_r
    tablew 1, k_n, i_high_ft_r
elseif k_n > gk_mid then
    tablew 1, k_n, i_low_ft_r
    tablew 1, k_n, i_mid_ft_r
    tablew k_temp_r, k_n, i_high_ft_r
endif
loop_lt k_n, 1, gi_ft_size, loop

contin:
; Filter by low, mid and high mag bins

pvsftr f_sig_r, i_low_ft_r
f_low_filtered_r pvsfilter f_main_r, f_sig_r, gk_low_depth
pvsftr f_sig_r, i_mid_ft_r
f_mid_filtered_r pvsfilter f_low_filtered_r, f_sig_r, gk_mid_depth
pvsftr f_sig_r, i_high_ft_r
f_high_filtered_r pvsfilter f_mid_filtered_r, f_sig_r, gk_high_depth
a_out_r pvsynth f_high_filtered_r
; Display fft
dispfft a_out_r, 0.01, 256, 0, 1
outs2 a_out_r
endin
</CsInstruments>
<CsScore>
f0 z
i"GUIThread" 0 [60*60*24*365]
i"SpectralDemaskerLeft" 0 [60*60*24*365]
i"SpectralDemaskerRight" 0 [60*60*24*365]
</CsScore>
</CsoundSynthesizer>