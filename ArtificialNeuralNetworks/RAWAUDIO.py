import numpy as np
from scipy.io.wavfile import read
import pickle
import glob


mono_list = []
max_list = []
n = 1
path = "D:/Documents/Development/Python/Major_Project_GAN/venv/Resources/Wavs/KickDrumsEqualLength/*.wav"


def convert_to_mono(audio_data):
    audio_data = audio_data.astype(float)
    new_audio_data = []
    for i in range(len(audio_data)):
        d = (audio_data[i][0] + audio_data[i][1]) / 2
        new_audio_data.append(d)
    return np.array(new_audio_data, dtype='int16')


for file in glob.glob(path):
    sr, data = read(file)
    print("\nConverting file %d to mono" % n)
    data = convert_to_mono(data)
    data_array = np.asarray(data)
    max_list.append(max(data_array))
    n += 1


overall_max = max(max_list)
max_file = open("scale.txt", "w")
max_file.write(str(overall_max))
print("\nMaximum = %d" % overall_max)
n = 1


for file in glob.glob(path):
    sr, data = read(file)
    data = convert_to_mono(data)
    for i in range(len(data)):
        data[i] /= overall_max
    data_array = np.asarray(data)
    print(data_array.shape)
    mono_list.append(data)
    n += 1

print("\nPickling Data!")
with open("pickle", "wb") as f:
    pickle.dump(mono_list, f)



