#ifndef DATASOURCES_H
#define DATASOURCES_H

#import "Controls.h"

#ifndef ADVANCE_PTR
#define ADVANCE_PTR(_a, _size) (__typeof__(_a))((uintptr_t) (_a) + (size_t)(_size))
#endif

extern float gLearningRate;

extern id<MTLDevice> _Nonnull gDevice;
extern id<MTLCommandQueue> _Nonnull gCommandQueue;



#endif 