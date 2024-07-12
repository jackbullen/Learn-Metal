#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@interface MetalAdder : NSObject
- (instancetype)initWithDevice:(id<MTLDevice>)device arrayLength:(int)arrayLength;
- (float*)add:(float*)arr1 to:(float*)arr2;
- (void)display;
@end
