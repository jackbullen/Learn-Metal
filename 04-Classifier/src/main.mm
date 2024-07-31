#import "Data.h"
#import "Dataset.h"
#import "Graph.h"
#include "Helpers.h"
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

#define TRAIN_ITERATIONS 60

float gLearningRate = 1e-3f;
id<MTLDevice> _Nonnull gDevice;
id<MTLCommandQueue> _Nonnull gCommandQueue;

Dataset *dataset;
Graph *graph;
dispatch_semaphore_t semaphore;

// Run one training iteration with BATCH_SIZE
id<MTLCommandBuffer> runTrainingIterationBatch() {
  dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

  MPSCNNLossLabelsBatch *lossStateBatch = nil;

  // Get the training batch
  MPSImageBatch *randomTrainBatch =
      [dataset getRandomTrainingBatchWithDevice:gDevice
                                      batchSize:BATCH_SIZE
                                 lossStateBatch:&lossStateBatch];

  // Prepare training
  MPSCommandBuffer *commandBuffer =
      [MPSCommandBuffer commandBufferFromCommandQueue:gCommandQueue];
  MPSImageBatch *returnBatch =
      [graph encodeTrainingBatchToCommandBuffer:commandBuffer
                                   sourceImages:randomTrainBatch
                                     lossStates:lossStateBatch];

  // Store lossImages to compute training loss
  NSMutableArray *outputBatch = [NSMutableArray arrayWithCapacity:BATCH_SIZE];
  for (NSUInteger i = 0; i < BATCH_SIZE; i++) {
    [outputBatch addObject:[lossStateBatch[i] lossImage]];
  }

  static int iteration = 1;
  [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> cmdBuf) {
    dispatch_semaphore_signal(semaphore);

    float trainingLoss = lossReduceSumAcrossBatch(outputBatch);
    NSLog(@"Iteration %d, Training loss = %f\n", iteration, trainingLoss);

    iteration++;

    NSError *err = cmdBuf.error;
    if (err) {
      NSLog(@"%@", err);
    }
  }];

  MPSImageBatchSynchronize(returnBatch, commandBuffer);
  MPSImageBatchSynchronize(outputBatch, commandBuffer);

  [commandBuffer commit];

  return commandBuffer;
}

// Evaluation the test set
void evaluateTestSet() {

  // Update inference graph weights
  [graph->inferenceGraph reloadFromDataSources];

  // Loop over test images running through inference graph and checking digits
  for (int i = 0; i < [dataset->_testImages count]; i++) {

    // Get the image and corresponding label
    MPSImage *testImg = dataset->_testImages[i];
    NSNumber *testLabel = dataset->_testLabels[i];

    // Prepare inference
    MPSCommandBuffer *commandBuffer =
        [MPSCommandBuffer commandBufferFromCommandQueue:gCommandQueue];
    MPSImage *outputImage =
        [graph->inferenceGraph encodeToCommandBuffer:commandBuffer
                                        sourceImages:@[ testImg ]];

    // Add completion handler to check correctness
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull) {
      int pred = checkDigitLabel(outputImage, [testLabel unsignedCharValue]);
      // printf("%d =? %d\n", [testLabel unsignedIntValue], pred);
    }];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
  }
  NSLog(@"Accuracy = %f",
        (float)gCorrect / (float)[dataset->_testImages count]);
}

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    gDevice = MTLCreateSystemDefaultDevice();
    gCommandQueue = [gDevice newCommandQueue];

    semaphore = dispatch_semaphore_create(2);

    dataset = [[Dataset alloc] initWithDevice:gDevice];
    graph = [[Graph alloc] initWithDevice:gDevice];

    // Training
    id<MTLCommandBuffer> pCmd = nil;
    for (NSUInteger i = 0; i < TRAIN_ITERATIONS; i++)
      @autoreleasepool {
        pCmd = runTrainingIterationBatch();
      }

    // Evaluation
    evaluateTestSet();
  }

  return 0;
}