#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MetalAdder.h"

int main () {
    @autoreleasepool {
        float* arr1 = malloc(10 * sizeof(float));
        float* arr2 = malloc(10 * sizeof(float));
        int arrayLength = 10;
        
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

        MetalAdder* adder = [[MetalAdder alloc] initWithDevice:device];
        [adder prepareBuffers:arr1 :arr2 :arrayLength];

        NSLog(@"Started computing");
        [adder compute];
        NSLog(@"Finished computing");

        free(arr1);
        free(arr2);
    }
    return 0;
}