#ifndef GRAPH_H
#define GRAPH_H

#import "Data.h"
#import "Dataset.h"

@interface Graph : NSObject {
@public
  id<MTLDevice> device;

  ConvDataSource *conv1Wts, *conv2Wts, *fc1Wts, *fc2Wts;
  MPSNNGraph *trainGraph, *inferenceGraph;
}

- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device;
- (void)initInferenceGraph;
- (nonnull MPSNNFilterNode *)createNodesWithTraining:(BOOL)isTraining;
- (MPSImageBatch *__nullable)
    encodeInferenceBatchToCommandBuffer:
        (nonnull id<MTLCommandBuffer>)commandBuffer
                           sourceImages:(MPSImageBatch *__nonnull)sourceImage;
- (MPSImageBatch *__nullable)
    encodeTrainingBatchToCommandBuffer:
        (nonnull id<MTLCommandBuffer>)commandBuffer
                          sourceImages:(MPSImageBatch *__nonnull)sourceImage
                            lossStates:(MPSCNNLossLabelsBatch *__nonnull)
                                           lossStateBatch;

@end

#endif