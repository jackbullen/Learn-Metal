// #import "Helpers.h"
#import "Data.h"
#import "Dataset.h"
#import "Graph.h"

float gLearningRate = 1e-3f;

id<MTLDevice> _Nonnull gDevice;
id<MTLCommandQueue> _Nonnull gCommandQueue;

Dataset *dataset;
// Graph *graph;
dispatch_semaphore_t semaphore;

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    gDevice = MTLCreateSystemDefaultDevice();
    gCommandQueue = [gDevice newCommandQueue];

    semaphore = dispatch_semaphore_create(2);

    // Make the MNIST dataset
    dataset = [[Dataset alloc] init];

    MPSCNNLossLabelsBatch *lossStateBatch = nil;

    MPSImageBatch *batch =
        [dataset getRandomTrainingBatchWithDevice:gDevice
                                        batchSize:32
                                   lossStateBatch:&lossStateBatch];
    
    // Create the classifier network
    // graph = [[Graph alloc] init];

    // id<MTLCommandBuffer> pCmd = nil;
    // for (NSUInteger i = 0; i < TRAIN_ITERATIONS; i++) @autoreleasepool
    // {
    //     if ((i % TEST_SET_EVAL_INTERVAL) == 0)
    //     {
    //         if (pCmd)
    //         {
    //             [pCmd waitUntilCompleted];
    //         }
    //         // Current evaluation set
    //         evaluateTestSet(i);
    //     }

    // }
    // // Current train set
    // pCmd = runTrainingIterationBatch();
  }

  // Final test set evaluation
  // evaluateTestSet(TRAIN_ITERATIONS);
}