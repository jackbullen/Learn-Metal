#ifndef CONTROLS_H
#define CONTROLS_H

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

#define TRAIN_ITERATIONS 10
#define TEST_SET_EVAL_INTERVAL 100
#define BATCH_SIZE 5
#define IMAGE_T __fp16
static MPSImageFeatureChannelFormat fcFormat =
    MPSImageFeatureChannelFormatFloat16;

#endif