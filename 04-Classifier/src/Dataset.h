#ifndef DATASET_H
#define DATASET_H

#import "DataSources.h"

#define IMAGE_SIZE 28

@interface Dataset : NSObject 
{
@public 
    NSUInteger nTrainImages;
    uint8_t *pTrainImage, *pTrainLabel;
    NSData *dataTrainImage;
    NSData *dataLabelImage;

    NSUInteger nTestImages;
    uint8_t *pTestImage, *pTestLabel;
    NSData *dataTestImage;
    NSData *dataTestLabel;

    unsigned seed;
}

- (nullable instancetype) init;

- (nullable MPSImageBatch *) getRandomTrainingBatchWithDevice: (id<MTLDevice> _Nonnull) device
                                                    batchSize: (NSUInteger) batchSize
                                               lossStateBatch: (MPSCNNLossLabelsBatch * __nonnull * __nullable)lossStateBatch;

@end

#endif