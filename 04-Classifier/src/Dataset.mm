#import "Dataset.h"

@implementation Dataset

- (instancetype)initWithDevice:(id<MTLDevice>)device {

  self = [super init];
  if (self) {
    _device = device;
    _trainImages = [self loadMNISTImagesFromFile:@"mnist/train_images.mnist"];
    _trainLabels = [self loadMNISTLabelsFrom:@"mnist/train_labels.mnist"];
    _testImages = [self loadMNISTImagesFromFile:@"mnist/test_images.mnist"];
    _testLabels = [self loadMNISTLabelsFrom:@"mnist/test_labels.mnist"];
    _nTrain = _trainImages.count;
    _nTest = _testImages.count;
  }
  return self;
}

// Load MNIST images from a provided filepath
//  Assumes the images are stored as
//  bytestring of length IMAGE_BYTES
//  one after the other.
- (NSArray<MPSImage *> *)loadMNISTImagesFromFile:(NSString *)filepath {

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

  int nImages = (int)([fileData length] / IMAGE_BYTES);

  // Loop over number of images, create MPSImage, and add to images array

  NSMutableArray<MPSImage *> *images = [NSMutableArray array];

  for (NSUInteger i = 0; i < nImages; i++) {
    const unsigned char *imageBytes =
        (const unsigned char *)[fileData bytes] + i * IMAGE_BYTES;

    MPSImageDescriptor *imageDesc = [MPSImageDescriptor
        imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatUnorm8
                                   width:IMAGE_WIDTH
                                  height:IMAGE_HEIGHT
                         featureChannels:1];

    MPSImage *image = [[MPSImage alloc] initWithDevice:_device
                                       imageDescriptor:imageDesc];

    [image writeBytes:imageBytes
           dataLayout:MPSDataLayoutHeightxWidthxFeatureChannels
           imageIndex:0];

    [images addObject:image];
  }

  return images;
}

// Load MNIST labels from provided filepath
//  Assumes each label is stored as
//  unsigned char (one byte)
- (NSArray<NSNumber *> *)loadMNISTLabelsFrom:(NSString *)filepath {

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
      [NSMutableArray arrayWithCapacity:[fileData length]];

  for (NSUInteger i = 0; i < [fileData length]; i++) {
    unsigned char label = labelBytes[i];
    [labels addObject:@(label)];
  }

  return labels;
}

// Uniformly make batchSize random sample of image/label pairs
//  Returns the MPSImageBatch containing images
//  and adds MPSCNNLossLabels to lossStateBatch
- (MPSImageBatch *)getRandomTrainingBatchWithDevice:(id<MTLDevice>)device
                                          batchSize:(NSUInteger)batchSize
                                     lossStateBatch:(MPSCNNLossLabelsBatch **)
                                                        lossStateBatch {
  MPSImageBatch *trainBatch = @[];

  NSMutableArray<MPSCNNLossLabels *> *lossStateBatchOut =
      [NSMutableArray array];

  // Loop batchSizes times adding a random image and label
  for (NSUInteger i = 0; i < batchSize; i++) {
    NSUInteger randomIdx = arc4random_uniform(_nTrain);

    MPSImage *image = _trainImages[randomIdx];
    NSNumber *label = _trainLabels[randomIdx];

    // one-hot-encoding of label
    float labelFloat[12] = {0.f};
    labelFloat[[label intValue]] = 1.f;
    NSData *labelsData = [NSData dataWithBytes:&labelFloat
                                        length:12 * sizeof(float)];

    // create loss state
    MPSCNNLossDataDescriptor *labelsDesc = [MPSCNNLossDataDescriptor
        cnnLossDataDescriptorWithData:labelsData
                               layout:MPSDataLayoutHeightxWidthxFeatureChannels
                                 size:{1, 1, 12}];
    MPSCNNLossLabels *lossState =
        [[MPSCNNLossLabels alloc] initWithDevice:device
                                labelsDescriptor:labelsDesc];

    // add items
    trainBatch = [trainBatch arrayByAddingObject:image];
    [lossStateBatchOut addObject:lossState];
  }

  *lossStateBatch = lossStateBatchOut;
  return trainBatch;
}

@end
