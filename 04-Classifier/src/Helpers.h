#ifndef HELPERS_H
#define HELPERS_H

#import "Dataset.h"

extern NSUInteger Help, gCorrect, gDone;

float lossReduceSumAcrossBatch(MPSImageBatch *batch);

template <typename T> int checkDigitLabel(MPSImage *image, uint8_t label) {

  assert(image.numberOfImages == 1);

  NSUInteger numActualValues =
      image.height * image.width * image.featureChannels;

  T *vals = (T *)malloc(sizeof(T) * numActualValues);

  float setVal = -22.f;
  memset_pattern4(vals, &setVal, numActualValues * sizeof(T));

  T max = -100.f;
  int index = -1;

  [image readBytes:vals
        dataLayout:(MPSDataLayoutFeatureChannelsxHeightxWidth)imageIndex:0];

  // Print raw values to debug
  // for (NSUInteger i = 0; i < image.featureChannels; i++) {
  //   NSLog(@"Feature Channel %lu:", (unsigned long)i);
  //   for (NSUInteger j = 0; j < image.height; j++) {
  //     for (NSUInteger k = 0; k < image.width; k++) {
  //       T value = vals[(i * image.height + j) * image.width + k];
  //       NSLog(@"Value at (%lu, %lu, %lu): %f", (unsigned long)i,
  //             (unsigned long)j, (unsigned long)k, value);
  //     }
  //   }
  // }

  // NSLog(@"%@", [image debugDescription]);

  for (NSUInteger i = 0; i < (NSUInteger)image.featureChannels; i++) {
    for (NSUInteger j = 0; j < image.height; j++) {
      for (NSUInteger k = 0; k < image.width; k++) {
        T mpsVal = (T)vals[(i * image.height + j) * image.width + k];
        if (mpsVal > max) {
          max = mpsVal;
          index = (int)((i * image.height + j) * image.width + k);
        }
      }
    }
  }

  if (index == label)
    gCorrect++;

  gDone++;
  free(vals);
  return index;
}

#endif