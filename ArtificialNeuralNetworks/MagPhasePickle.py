from scipy.fftpack import fft, ifft
from scipy.io.wavfile import read, write
import numpy as np
import glob
import pickle
import math
path = "D:/Documents/Development/Python/Major_Project_GAN/venv/Resources/Wavs/KickDrumsEqualLength/*.wav"
max_m_list = []
max_p_list = []
file_compound_list = []
for file in glob.glob(path):
    mag_list = []
    phase_list = []
    print("\nStarting file %s" % file)
    f_list = []
    sr, data = read(file, "rb")
    fourier = fft(data)
    fourier_array = np.asarray(fourier)
    for i in range(22050):
        R = fourier_array[i].real
        I = fourier_array[i].imag
        mag = np.sqrt((R*R) + (I*I))
        mag = mag[0]
        phase = np.arctan2(I, R)
        phase = phase[0]
        mag_list.append(mag)
        phase_list.append(phase)
    max_mag = max(mag_list)
    max_m_list.append(max_mag)
    max_phase = max(phase_list)
    max_p_list.append(max_phase)
    for n in range(len(mag_list)):
        mag_list[n] /= max_mag
        print(mag_list[n])
        phase_list[n] /= max_phase
        f_list.append(mag_list[n])
        f_list.append(phase_list[n])
    temp_arr = np.asarray(f_list)
    file_compound_list.append(temp_arr)
avg_mag = sum(max_m_list) / len(max_m_list)
print(avg_mag)
avg_phase = sum(max_p_list) / len(max_p_list)
scale_factor = complex(avg_mag, avg_phase)
maxes = open("scales.txt", "w")
maxes.write(str(scale_factor))
stored = np.asarray(file_compound_list)
print(stored.shape)
print(stored[0])
with open("compound_pickle", "wb") as f:
    pickle.dump(stored, f)


