#ifndef HELPERS_H
#define HELPERS_H

#import "Dataset.h"

extern NSUInteger Help, gCorrect, gDone;

float lossReduceSumAcrossBatch(MPSImageBatch *batch);

int checkDigitLabel(MPSImage *image, uint8_t label);

#endif