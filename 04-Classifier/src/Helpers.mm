#import "Helpers.h"

NSUInteger gDone = 0, gCorrect = 0;

// Compute the total loss across a batch of loss images
float lossReduceSumAcrossBatch(MPSImageBatch *batch) {
  float ret = 0;
  for (NSUInteger i = 0; i < [batch count]; i++) {
    MPSImage *curr = batch[i];
    float val[1] = {0};
    assert(curr.width * curr.height * curr.featureChannels == 1);
    [batch[i] readBytes:(void *)val
         dataLayout:(MPSDataLayoutHeightxWidthxFeatureChannels)imageIndex:0];

    ret += val[0] / [batch count];
  }
  return ret;
}

// Check the digit after running inference
//  on an image against ground truth label
//
// Return the predicted digit and increment
//  gCorrect if the prediction equals label
int checkDigitLabel(MPSImage *image, uint8_t label) {

  assert(image.numberOfImages == 1);

  NSUInteger numActualValues =
      image.height * image.width * image.featureChannels;

  float *vals = (float *)malloc(sizeof(float) * numActualValues);

  float setVal = -22.f;
  memset_pattern4(vals, &setVal, numActualValues * sizeof(float));

  float max = -100.f;
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
        float mpsVal = (float)vals[(i * image.height + j) * image.width + k];
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
