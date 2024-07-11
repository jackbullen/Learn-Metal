#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@interface MetalAdder : NSObject
- (instancetype)initWithDevice:(id<MTLDevice>)device;
- (void)prepareBuffers:(float*)arr1 :(float*)arr2 :(int)arrayLength;
- (void)compute;
@end
