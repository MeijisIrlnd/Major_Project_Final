#  TODO: Test!
#  pep-8-ed
import pickle
import numpy as np
import datetime
import keras
import matplotlib.pyplot as plt
from keras.preprocessing.image import ImageDataGenerator
from keras.layers import Input
from keras.models import Model, Sequential
from keras.layers.core import Dense, Dropout
from keras.layers.advanced_activations import LeakyReLU
from keras.optimizers import Adam
from keras import initializers
from tqdm import tqdm
from keras.models import model_from_json
from scipy.fftpack import fft, ifft
from scipy.io.wavfile import read, write
datatype_path = "D:/Documents/Development/Python/Major_Project_GAN/venv/Resources/Wavs/KickDrumsEqualLength/Kick - 01 - Audio - kick-01-01-01.wav"
generator_weights_path = "29_10_2018-GEN-EPOCH-500.h5"
discriminator_weights_path = "29_10_2018-DISC-EPOCH-500.h5"
gan_weights_path = "24_10_2018-GAN-EPOCH-500.h5"
maxes = open("scale.txt", "r").read()
print(maxes)
maxes = np.float(maxes)
sr, datatype = read(datatype_path, "rb")
date = "24_10_2018"
num_epochs = 2000


def plt_imgs(epoch, generator):
    gen_audio_list = []
    noise = np.random.normal(0, 1, size=[1, random_dim])
    generated = generator.predict(noise)
    generated.reshape(22050)
    print(generated.shape)
    print(generated)
    for i in range(22050):  # mags
        gen_audio_list.append(generated[0, i] * maxes)  # Rescales by scaling factor
    gen_array = np.asarray(gen_audio_list)
    filename = "generated_audio_%d.wav" % epoch
    write(filename, sr, gen_array.astype(np.int16))


def load_pickled_data():
    with open("pickle", "rb") as f:
        wav_list = pickle.load(f)
    wav_array = np.array(wav_list)
    test_array = np.array(wav_list)
    print(wav_array.shape)
    return wav_array, test_array


def train(epochs=1, batch_size=8):
    x_train, x_test = load_pickled_data()
    batch_count = x_train.shape[0] / batch_size
    for e in range(1, epochs+1):
        print('-'*10, 'Epoch %d' % e, '-'*10)
        for _ in tqdm(range(int(batch_count))):
            noise = np.random.normal(0,1, size = [batch_size, random_dim])
            image_batch = x_train[np.random.randint(0, x_train.shape[0], size=batch_size)]
            print(image_batch)
            generated_images = generator.predict(noise)
            print("\nBatch Shape: ", image_batch.shape)
            print("\nGenerated Shape: ", generated_images.shape)
            X = np.concatenate([image_batch, generated_images])
            y_dis = np.zeros(2*batch_size)
            y_dis[:batch_size] = 0.9  # here I still don't get this
            discriminator.trainable = True
            discriminator.train_on_batch(X, y_dis)
            noise = np.random.normal(0, 1, size = [batch_size, random_dim])
            y_gen = np.ones(batch_size)
            discriminator.trainable = False
            gan.train_on_batch(noise, y_gen)
        plt_imgs(e, generator)


np.random.seed(1000)
random_dim = 100
flat_size = 22050  # Changes depending on input, TODO: read array lengths, possibly from maxes.txt
optimizer= Adam(lr=0.0002, beta_1=0.5)
generator = Sequential()
generator.add(Dense(256, input_dim=random_dim, kernel_initializer=initializers.RandomNormal(stddev=0.02)))
generator.add(LeakyReLU(0.2))
generator.add(Dense(512))
generator.add(LeakyReLU(0.2))
generator.add(Dense(1024))
generator.add(LeakyReLU(0.2))
generator.add(Dense(flat_size, activation='tanh'))
generator.compile(loss='binary_crossentropy', optimizer=optimizer)
#generator.load_weights(generator_weights_path)
#print("\nGenerator Weights Loaded from h5!")
discriminator = Sequential()
discriminator.add(Dense(2048, input_dim=flat_size, kernel_initializer=initializers.RandomNormal(stddev=0.02)))
discriminator.add(LeakyReLU(0.2))
discriminator.add(Dropout(0.3))
discriminator.add(Dense(512))
discriminator.add(LeakyReLU(0.2))
discriminator.add(Dropout(0.3))
discriminator.add(Dense(256))
discriminator.add(LeakyReLU(0.2))
discriminator.add(Dropout(0.3))
discriminator.add(Dense(1, activation='sigmoid'))
discriminator.compile(loss='binary_crossentropy', optimizer=optimizer)
#discriminator.load_weights(discriminator_weights_path)
#print("\nDiscriminator Weights Loaded from h5!")
discriminator.trainable = False
ganInput = Input(shape=(random_dim,))
x = generator(ganInput)
ganOutput = discriminator(x)
gan = Model(inputs=ganInput, outputs=ganOutput)
gan.compile(loss='binary_crossentropy', optimizer=optimizer)
#gan.load_weights(gan_weights_path)
#print("\nGAN Weights Loaded from h5!")
train(num_epochs, 16)
generator.save_weights("{0}-GEN-EPOCH-{1}.h5".format(date, num_epochs))
discriminator.save_weights("{0}-DISC-EPOCH-{1}.h5".format(date, num_epochs))
gan.save_weights("{0}-GAN-EPOCH-{1}.h5".format(date, num_epochs))
print("\nAll weights saved to h5")

# resource code:
# model_json = gan.to_json()
# with open("GAN_model.json", "w") as json_file:
# json_file.write(model_json)
# print("\nGAN model saved")
# model_json = generator.to_json()
# with open("GEN_model.json", "w") as json_file:
#  json_file.write(model_json)
# print("\nGenerator model saved")
# model_json = discriminator.to_json()
# with open("DIS_model.json", "w") as json_file:
# json_file.write(model_json)
# print("\nDiscriminator model saved")