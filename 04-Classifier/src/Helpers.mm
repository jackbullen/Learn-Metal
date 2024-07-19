#import "Helpers.h"

NSUInteger gDone = 0, gCorrect = 0;

float lossReduceSumAcrossBatch(MPSImageBatch *_Nonnull batch) {
  float ret = 0;
  for (NSUInteger i = 0; i < [batch count]; i++) {
    MPSImage *curr = batch[i];
    float val[1] = {0};
    assert(curr.width * curr.height * curr.featureChannels == 1);
    [curr readBytes:(void *_Nonnull)val
         dataLayout:(MPSDataLayoutFeatureChannelsxHeightxWidth)imageIndex:0];
    ret += val[0] / (float)BATCH_SIZE;
  }
  return ret;
}
