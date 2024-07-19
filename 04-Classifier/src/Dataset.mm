#import "Dataset.h"

@implementation Dataset

- (nullable instancetype)init {

  self = [super init];
  if (self == nil)
    return self;

  return self;
}

- (nullable NSArray<MPSImage *> *)
    loadMNISTImagesWithDevice:(id<MTLDevice>)device
                     fromFile:(NSString *)filepath {

  NSFileManager *fileManager = [NSFileManager defaultManager];
  if (![fileManager fileExistsAtPath:filepath]) {
    NSLog(@"File does not exist");
    assert(false);
  }

  NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filepath];
  if (!fileHandle) {
    NSLog(@"Failed to open file");
    assert(false);
  }

  NSData *fileData = [fileHandle readDataToEndOfFile];
  [fileHandle closeFile];

  NSMutableArray<MPSImage *> *images = [NSMutableArray array];

  for (NSUInteger i = 0; i < 32; i++) {
    const unsigned char *imageBytes =
        (const unsigned char *)[fileData bytes] + i * IMAGE_BYTES;

    MPSImageDescriptor *imageDesc = [MPSImageDescriptor
        imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatUnorm8
                                   width:IMAGE_WIDTH
                                  height:IMAGE_HEIGHT
                         featureChannels:1];

    MPSImage *image = [[MPSImage alloc] initWithDevice:device
                                       imageDescriptor:imageDesc];

    [image writeBytes:imageBytes
           dataLayout:MPSDataLayoutHeightxWidthxFeatureChannels
           imageIndex:0];

    [images addObject:image];
  }

  return images;
}

- (nullable NSArray<NSNumber *> *)loadMNISTLabelsFrom:(NSString *)filepath {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if (![fileManager fileExistsAtPath:filepath]) {
    NSLog(@"File does not exist");
    assert(false);
  }

  NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filepath];
  if (!fileHandle) {
    NSLog(@"File failed to be opened");
    assert(false);
  }

  NSData *fileData = [fileHandle readDataToEndOfFile];
  [fileHandle closeFile];

  const unsigned char *labelBytes = (const unsigned char *)[fileData bytes];
  NSMutableArray<NSNumber *> *labels =
      [NSMutableArray arrayWithCapacity:NUM_IMAGES];
  for (NSUInteger i = 0; i < NUM_IMAGES; i++) {
    unsigned char label = labelBytes[i];
    [labels addObject:@(label)];
  }

  return [labels copy];
}

- (nullable MPSImageBatch *)
    getRandomTrainingBatchWithDevice:(id<MTLDevice>)device
                           batchSize:(NSUInteger)batchSize
                      lossStateBatch:(MPSCNNLossLabelsBatch **)lossStateBatch {

  // Load Images
  // could be expensive loading all images into MPSImage,
  // and only use the batchSize few of them that are randomly selected
  // instead should do something similar to sample code (just make MPSImages for
  // the desired images...)
  NSArray<MPSImage *> *trainImages =
      [self loadMNISTImagesWithDevice:device
                             fromFile:@"mnist/train_images.mnist"];
  if (!trainImages) {
    NSLog(@"Failed to load training images");
    assert(false);
  }

  // Load Labels
  NSArray<NSNumber *> *trainLabels =
      [self loadMNISTLabelsFrom:@"mnist/train_labels.mnist"];
  if (!trainLabels) {
    NSLog(@"Failed to load training labels");
    assert(false);
  }

  // Create the batch

  MPSImageBatch *trainBatch = @[];

  NSMutableArray<MPSCNNLossLabels *> *lossStateBatchOut =
      [NSMutableArray array];

  for (NSUInteger i = 0; i < batchSize; i++) {
    NSUInteger randomIdx = arc4random_uniform((uint32_t)trainImages.count);

    MPSImage *image = trainImages[randomIdx];
    NSNumber *label = trainLabels[randomIdx];

    trainBatch = [trainBatch arrayByAddingObject:image];

    float labelFloat = [label floatValue];
    NSData *labelsData = [NSData dataWithBytes:&labelFloat
                                        length:sizeof(float)];
    MPSCNNLossDataDescriptor *labelsDesc = [MPSCNNLossDataDescriptor
        cnnLossDataDescriptorWithData:labelsData
                               layout:MPSDataLayoutHeightxWidthxFeatureChannels
                                 size:{1, 1, 1}];

    MPSCNNLossLabels *lossState =
        [[MPSCNNLossLabels alloc] initWithDevice:device
                                labelsDescriptor:labelsDesc];
    [lossStateBatchOut addObject:lossState];
  }

  *lossStateBatch = [lossStateBatchOut copy];

  return trainBatch;
}

@end
