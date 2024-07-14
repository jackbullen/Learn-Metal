// #import "Helpers.h"
#import "DataSources.h"
#import "Dataset.h"
#import "Graph.h"

float gLearningRate = 1e-3f;

id<MTLDevice> _Nonnull gDevice;
id<MTLCommandQueue> _Nonnull gCommandQueue;

Dataset *dataset;
// Graph *graph;
dispatch_semaphore_t semaphore;

int main(int argc, const char *argv[])
{
    @autoreleasepool 
    {
        gDevice = MTLCreateSystemDefaultDevice();
        gCommandQueue = [gDevice newCommandQueue];

        semaphore = dispatch_semaphore_create(2);

        // dataset = [[Dataset alloc] init];

        // graph = [[Graph alloc] init];
    }
}