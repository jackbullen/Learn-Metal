import os 
import json
import random
import numpy as np
import matplotlib.pyplot as plt

WIDTH = 28
HEIGHT = 28
IMAGE_BYTES = WIDTH * HEIGHT

def gater_images(filepath):
    images = []
    with open(filepath, "rb") as f:
        while (image := f.read(IMAGE_BYTES)):
            images.append(image)
    return images

def plot_image(image):
    plt.imshow(np.array([list(image)[WIDTH*(i-1):WIDTH*(i)]
                for i in range(1, WIDTH)]))
    plt.show()

if __name__ == "__main__":
    # Gather images and labels from seperate files
    images, labels = [], []
    for dirs, subdirs, files in os.walk('.'):
        for file in files:
            if file.startswith('data'):
                curr_char_images = gater_images(file)
                images.extend(curr_char_images)
                labels.extend([int(file[-1]) 
                                for _ in range(len(curr_char_images))])
    
    # Permute the images and labels
    indices = list(range(len(images)))
    random.shuffle(indices)
    images = [images[i] for i in indices]
    labels = [labels[i] for i in indices]
    
    # Sanity check
    # for i in range(1, 100, 10):
    #     print(labels[i])
    #     plot_image(images[i])

    # Write train and test sets
    train_prop = 0.8
    with open("train_images.mnist", "wb") as f:
        f.write(b"".join(images[:int(len(images)*train_prop)]))
    with open("train_labels.mnist", "w") as f:
        f.write(json.dumps(labels[:int(len(images)*train_prop)]))# not very efficient, but whatever
    with open("test_images.mnist", "wb") as f:
        f.write(b"".join(images[int(len(images)*train_prop):]))
    with open("test_labels.mnist", "w") as f:
        f.write(json.dumps(labels[int(len(images)*train_prop):]))