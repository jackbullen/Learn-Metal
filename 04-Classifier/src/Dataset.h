#ifndef DATASET_H
#define DATASET_H

#import "Data.h"
#import "ImageUtils.h"
#import <AppKit/AppKit.h>

#define IMAGE_SIZE 28
#define IMAGE_METADATA_PREFIX_SIZE 16
#define LABELS_METADATA_PREFIX_SIZE 8
#define IMAGE_WIDTH 28
#define IMAGE_HEIGHT 28
#define IMAGE_BYTES (IMAGE_WIDTH * IMAGE_HEIGHT) // one byte per pixel
#define NUM_IMAGES 10001

@interface Dataset : NSObject {
@public
  NSUInteger totalNumberOfTrainImages;
  uint8_t *trainImagePointer, *trainLabelPointer;
  size_t sizeTrainLabels, sizeTrainImages;
  NSData *dataTrainImage;
  NSData *dataTrainLabel;

  NSUInteger totalNumberOfTestImages;
  uint8_t *testImagePointer, *testLabelPointer;
  size_t sizeTestLabels, sizeTestImages;
  NSData *dataTestImage;
  NSData *dataTestLabel;

  unsigned seed;
}

- (nullable instancetype)init;

- (nullable MPSImageBatch *)
    getRandomTrainingBatchWithDevice:(id<MTLDevice> _Nonnull)device
                           batchSize:(NSUInteger)batchSize
                      lossStateBatch:
                          (MPSCNNLossLabelsBatch *__nonnull *__nullable)
                              lossStateBatch;

@end

#endif