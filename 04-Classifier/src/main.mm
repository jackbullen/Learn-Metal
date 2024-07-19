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

    MPSImageBatch *outputBatch = @[];
    for (NSUInteger i = 0; i < BATCH_SIZE; i++) {
      outputBatch =
          [outputBatch arrayByAddingObject:[lossStateBatch[i] lossImage]];
    }
    static int iteration = 1;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull cmdBuf) {
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

void evaluateTestSet(NSUInteger iterations) {
  @autoreleasepool {
    gDone = 0;
    gCorrect = 0;

    [graph->inferenceGraph reloadFromDataSources];

    MPSImageDescriptor *inputDesc = [MPSImageDescriptor
        imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatUnorm8
                                   width:IMAGE_WIDTH
                                  height:IMAGE_HEIGHT
                         featureChannels:1
                          numberOfImages:1
                                   usage:MTLTextureUsageShaderRead];

    MPSCommandBuffer *lastcommandBuffer = nil;

    for (NSUInteger currImageIdx = 0;
         currImageIdx < dataset->totalNumberOfTestImages;
         currImageIdx += BATCH_SIZE)
      @autoreleasepool {

        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

        MPSImageBatch *inputBatch = @[];
        for (NSUInteger i = 0; i < BATCH_SIZE; i++) {
          MPSImage *inputImage = [[MPSImage alloc] initWithDevice:gDevice
                                                  imageDescriptor:inputDesc];
          inputBatch = [inputBatch arrayByAddingObject:inputImage];
        }

        MPSCommandBuffer *commandBuffer =
            [MPSCommandBuffer commandBufferFromCommandQueue:gCommandQueue];

        [inputBatch enumerateObjectsUsingBlock:^(MPSImage *_Nonnull inputImage,
                                                 NSUInteger idx,
                                                 BOOL *_Nonnull stop) {
          uint8_t *start =
              ADVANCE_PTR(dataset->testImagePointer,
                          (IMAGE_WIDTH * IMAGE_HEIGHT * (currImageIdx + idx)));
          [inputImage
              writeBytes:start
              dataLayout:(MPSDataLayoutHeightxWidthxFeatureChannels)imageIndex
                        :0];
        }];

        MPSImageBatch *outputBatch =
            [graph encodeInferenceBatchToCommandBuffer:commandBuffer
                                          sourceImages:inputBatch];

        MPSImageBatchSynchronize(outputBatch, commandBuffer);

        [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull) {
          dispatch_semaphore_signal(semaphore);

          [outputBatch enumerateObjectsUsingBlock:^(
                           MPSImage *_Nonnull outputImage, NSUInteger idx,
                           BOOL *_Nonnull stop) {
            uint8_t *labelStart =
                ADVANCE_PTR(dataset->testLabelPointer, currImageIdx + idx);
            checkDigitLabel<IMAGE_T>(outputImage, labelStart);
          }];
        }];

        [commandBuffer commit];
        lastcommandBuffer = commandBuffer;
      }

    [lastcommandBuffer waitUntilCompleted];
    NSLog(@"Test Set Accuracy = %f %f", (float)gCorrect,
          (float)dataset->totalNumberOfTrainImages);
  }
}

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    gDevice = MTLCreateSystemDefaultDevice();
    gCommandQueue = [gDevice newCommandQueue];
    semaphore = dispatch_semaphore_create(2);
    dataset = [[Dataset alloc] init];
    graph = [[Graph alloc] init];
    MPSCNNLossLabelsBatch *lossStateBatch = nil;

    id<MTLCommandBuffer> pCmd = nil;
    for (NSUInteger i = 0; i < TRAIN_ITERATIONS; i++)
      @autoreleasepool {
        if ((i % TEST_SET_EVAL_INTERVAL) == 0) {
          if (pCmd) {
            [pCmd waitUntilCompleted];
          }
          evaluateTestSet(i);
        }
      }
    pCmd = runTrainingIterationBatch();
  }

  evaluateTestSet(TRAIN_ITERATIONS);
}
