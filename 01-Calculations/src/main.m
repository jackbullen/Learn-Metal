#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MetalAdder.h"

const int arrayLength = 10000000;

int main () {
    @autoreleasepool 
    {
        float* arr1 = malloc(arrayLength * sizeof(float));
        float* arr2 = malloc(arrayLength * sizeof(float));
        
        for (int i = 0; i < arrayLength; i++)
        {
            arr1[i] = (float)i;
            arr2[i] = (float)i;
        }
        
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device)
        {
            NSLog(@"Device failed to be created");
            assert(false);
        }

        MetalAdder* mCPU = [[MetalAdder alloc] initWithDevice:device];

        NSLog(@"Starting compute");
        NSDate *start = [NSDate date];
        for (int i = 0; i < 30; i++)
        {
            float* result = [mCPU add:arr1 to:arr2 length:arrayLength];
        }
        NSDate *end = [NSDate date];
        NSLog(@"Finished compute in %f", 
            [end timeIntervalSinceDate:start]);

        // [mCPU display];

        free(arr1);
        free(arr2);
    }
    return 0;
}
// 3.666322, 3.232403, 3.372905, 2.976294, 2.957553, 2.912545, 2.816415, 2.597899, 2.669619, 2.586802, 2.567505, 3.681278, 3.420288