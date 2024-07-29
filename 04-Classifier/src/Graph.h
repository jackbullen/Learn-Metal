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

- (instancetype)initWithDevice:(id<MTLDevice>)device;
- (void)initInferenceGraph;
- (MPSNNFilterNode *)createNodesWithTraining:(BOOL)isTraining;
- (MPSImageBatch *)
    encodeInferenceBatchToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                           sourceImages:(MPSImageBatch *)sourceImage;
- (MPSImageBatch *)
    encodeTrainingBatchToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                          sourceImages:(MPSImageBatch *)sourceImage
                            lossStates:(MPSCNNLossLabelsBatch *)lossStateBatch;

@end

#endif