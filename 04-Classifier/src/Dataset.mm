#import "Dataset.h"

@implementation Dataset

- (nullable instancetype)init {

  self = [super init];
  if (self == nil)
    return self;

  NSString *dataPath = @"/Users/jackbullen/LearnMetal/04-Classifier/data";

  return self;
}

- (nullable MPSImageBatch *)
    getRandomTrainingBatchWithDevice:(id<MTLDevice>)device
                           batchSize:(NSUInteger)batchSize
                      lossStateBatch:(MPSCNNLossLabelsBatch **)lossStateBatch {

  MPSImageDescriptor *trainImageDesc = [MPSImageDescriptor
      imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatUnorm8
                                 width:IMAGE_SIZE
                                height:IMAGE_SIZE
                       featureChannels:1
                        numberOfImages:1
                                 usage:MTLTextureUsageShaderWrite |
                                       MTLTextureUsageShaderRead];
  MPSImageBatch *trainBatch = @[];

  MPSCNNLossLabelsBatch *lossStateBatchOut = @[];

  for (NSUInteger i = 0; i < batchSize; i++) {

    // Fetch a random index between 0 and totalNumberOfTrainImages to sample an
    // image from training set.
    float randomNormVal = (float)rand_r(&seed) / (float)RAND_MAX;
    NSUInteger randomImageIdx =
        (NSUInteger)(randomNormVal * (float)totalNumberOfTrainImages);
    seed++;

    // Create an MPSImage to put in the training image.
    MPSImage *trainImage = [[MPSImage alloc] initWithDevice:device
                                            imageDescriptor:trainImageDesc];
    trainImage.label = [@"trainImage"
        stringByAppendingString:[NSString stringWithFormat:@"[%lu]", i]];
    trainBatch = [trainBatch arrayByAddingObject:trainImage];

    // Write values to the training image.
    [trainImage
        writeBytes:(void *)ADVANCE_PTR(trainImagePointer,
                                       (IMAGE_METADATA_PREFIX_SIZE +
                                        randomImageIdx * IMAGE_SIZE *
                                            IMAGE_SIZE * sizeof(uint8_t)))
        dataLayout:(MPSDataLayoutHeightxWidthxFeatureChannels)imageIndex:0];

    // Making a LossStateBatch.
    uint8_t *labelStart = ADVANCE_PTR(
        trainLabelPointer, LABELS_METADATA_PREFIX_SIZE + randomImageIdx);
    float labelsBuffer[12] = {0.f};
    labelsBuffer[*labelStart] = 1.f;

    // 12 because we need the closest multiple of 4 greater than 10.
    NSData *labelsData = [NSData dataWithBytes:labelsBuffer
                                        length:12 * sizeof(float)];

    // Labels are put in here to be added to the MPSCNNLossLabels.
    MPSCNNLossDataDescriptor *labelsDescriptor = [MPSCNNLossDataDescriptor
        cnnLossDataDescriptorWithData:labelsData
                               layout:MPSDataLayoutHeightxWidthxFeatureChannels
                                 size:{1, 1, 12}];
    // Create loss labels.
    MPSCNNLossLabels *lossState =
        [[MPSCNNLossLabels alloc] initWithDevice:gDevice
                                labelsDescriptor:labelsDescriptor];

    lossStateBatchOut = [lossStateBatchOut arrayByAddingObject:lossState];
  }

  *lossStateBatch = lossStateBatchOut;

  return trainBatch;
}

@end
