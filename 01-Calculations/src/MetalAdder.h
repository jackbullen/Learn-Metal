#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@interface MetalAdder : NSObject
- (instancetype)initWithDevice:(id<MTLDevice>)device;
- (float*)add:(float*)arr1 to:(float*)arr2 length:(int)length;
- (void)display;
@end
