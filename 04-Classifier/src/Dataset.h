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

  id<MTLDevice> _device;

  NSArray<MPSImage *> *_trainImages;
  NSArray<NSNumber *> *_trainLabels;
  NSArray<MPSImage *> *_testImages;
  NSArray<NSNumber *> *_testLabels;
  NSUInteger _nTrain;
  NSUInteger _nTest;

  // Old

  NSData *dataTrainImage;
  NSData *dataTrainLabel;

  NSData *dataTestImage;
  NSData *dataTestLabel;

  unsigned seed;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device;
- (NSArray<MPSImage *> *)loadMNISTImagesFromFile:(NSString *)filepath;
- (MPSImageBatch *)getRandomTrainingBatchWithDevice:(id<MTLDevice>)device
                                          batchSize:(NSUInteger)batchSize
                                     lossStateBatch:(MPSCNNLossLabelsBatch **)
                                                        lossStateBatch;

@end

#endif