#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MetalAdder.h"

const int arrayLength = 5;

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

        MetalAdder* mCPU = [[MetalAdder alloc] initWithDevice:device arrayLength:arrayLength];

        NSLog(@"Starting compute");
        NSDate *start = [NSDate date];

        for (int i = 0; i < arrayLength; i++)
        {
            float* result = [mCPU add:arr1 to:arr2];

            printf("i = %d\n", i);
            for (int j = 0; j < arrayLength; j++)
            {
                printf("%.0f + %.0f = %.0f, ", arr1[j], arr2[j], result[j]);
                arr1[j] = arr1[j] * 2;
                arr2[j] = arr2[j] * 2;
            }
            printf("\n\n");
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
// 1: 3.666322, 3.232403, 3.372905, 2.976294, 2.957553, 2.912545, 2.816415, 2.597899, 2.669619, 2.586802, 2.567505, 3.681278, 3.420288
// 2: 1.461082, 1.468802, 1.462119, 1.474305, 1.581916, 1.787467, 1.604432, 1.646424, 1.614299, 1.853456, 1.694726, 1.670197, 2.056988
