#ifndef DATASET_H
#define DATASET_H

#import "Data.h"
#import "ImageUtils.h"
#import <Foundation/Foundation.h>

#define IMAGE_WIDTH 28
#define IMAGE_HEIGHT 28
#define IMAGE_BYTES (IMAGE_WIDTH * IMAGE_HEIGHT) // one byte per pixel

@interface Dataset : NSObject {
@public
  id<MTLDevice> _device;
  NSArray<MPSImage *> *_trainImages;
  NSArray<NSNumber *> *_trainLabels;
  NSArray<MPSImage *> *_testImages;
  NSArray<NSNumber *> *_testLabels;
  NSUInteger _nTrain;
  NSUInteger _nTest;
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