#import "Controls.h"
#import "Data.h"
#import "Dataset.h"
#import "Graph.h"
#include "Helpers.h"

float gLearningRate = 1e-3f;
id<MTLDevice> _Nonnull gDevice;
id<MTLCommandQueue> _Nonnull gCommandQueue;

Dataset *dataset;
Graph *graph;
dispatch_semaphore_t semaphore;

id<MTLCommandBuffer> runTrainingIterationBatch() {
  @autoreleasepool {
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    MPSCNNLossLabelsBatch *lossStateBatch = nil;

    MPSImageBatch *randomTrainBatch =
        [dataset getRandomTrainingBatchWithDevice:gDevice
                                        batchSize:BATCH_SIZE
                                   lossStateBatch:&lossStateBatch];

    MPSCommandBuffer *commandBuffer =
        [MPSCommandBuffer commandBufferFromCommandQueue:gCommandQueue];

    MPSImageBatch *returnBatch =
        [graph encodeTrainingBatchToCommandBuffer:commandBuffer
                                     sourceImages:randomTrainBatch
                                       lossStates:lossStateBatch];

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
}

void evaluateTestSet() {
  // Get the image and corresponding label
  for (int i = 0; i < [dataset->_testImages count]; i++) {

    MPSImage *testImg = dataset->_testImages[i];
    NSNumber *testLabel = dataset->_testLabels[i];

    // Prepare inference
    [graph->inferenceGraph reloadFromDataSources];

    MPSCommandBuffer *commandBuffer =
        [MPSCommandBuffer commandBufferFromCommandQueue:gCommandQueue];

    MPSImage *outputImage =
        [graph->inferenceGraph encodeToCommandBuffer:commandBuffer
                                        sourceImages:@[ testImg ]];

    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull) {
      int pred =
          checkDigitLabel<IMAGE_T>(outputImage, [testLabel unsignedCharValue]);
      // printf("%d =? %d\n", [testLabel unsignedIntValue], pred);
    }];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
  }
  NSLog(@"Accuracy = %f", (float)gCorrect / (float)[dataset->_testImages count]);
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
