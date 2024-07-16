#import "Dataset.h"

#define IMAGE_WIDTH 28
#define IMAGE_HEIGHT 28
#define IMAGE_BYTES (IMAGE_WIDTH * IMAGE_HEIGHT) // one byte per pixel
#define NUM_IMAGES 1000

@implementation Dataset

- (nullable instancetype)init {

  self = [super init];
  if (self == nil)
    return self;

  // NSString *filepath = @"/Users/jackbullen/LearnMetal/04-Classifier/data/data0";
  // saveImages(filepath, IMAGE_BYTES);

  return self;
}

- (nullable NSArray<MPSImage *> *)
    loadMNISTImagesWithDevice:(id<MTLDevice>)device
                     fromFile:(NSString *)filepath
                    batchSize:(NSUInteger)batchSize {

  NSFileManager *fileManager = [NSFileManager defaultManager];
  if (![fileManager fileExistsAtPath:filepath]) {
    NSLog(@"File does not exist");
    return nil;
  }

  NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filepath];
  if (!fileHandle) {
    NSLog(@"Failed to open file");
    return nil;
  }

  NSData *fileData = [fileHandle readDataToEndOfFile];
  [fileHandle closeFile];

  NSMutableArray<MPSImage *> *images = [NSMutableArray array];

  for (NSUInteger i = 0; i < NUM_IMAGES; i++) {
    const unsigned char *imageBytes = (const unsigned char *)[fileData bytes] + i * IMAGE_BYTES;

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

    if ([images count] >= batchSize) {
      break;
    }
  }
  return images;
}

- (nullable MPSImageBatch *)
    getRandomTrainingBatchWithDevice:(id<MTLDevice>)device
                           batchSize:(NSUInteger)batchSize
                      lossStateBatch:(MPSCNNLossLabelsBatch **)lossStateBatch {

  NSArray<MPSImage *> *trainBatch =
      [self loadMNISTImagesWithDevice:device
                             fromFile:@"/Users/jackbullen/LearnMetal/"
                                      @"04-Classifier/data/data0"
                            batchSize:batchSize];

  if (!trainBatch) {
    NSLog(@"Failed to load training batch");
    return nil;
  }

  NSMutableArray<MPSCNNLossLabels *> *lossStateBatchOut =
      [NSMutableArray array];

  for (NSUInteger i = 0; i < batchSize; i++) {
    float labelsBuffer[1] = {0.f};

    NSData *labelsData = [NSData dataWithBytes:labelsBuffer
                                        length:sizeof(labelsBuffer)];

    MPSCNNLossDataDescriptor *labelsDesc = [MPSCNNLossDataDescriptor
        cnnLossDataDescriptorWithData:labelsData
                               layout:MPSDataLayoutHeightxWidthxFeatureChannels
                                 size:{1, 1, 1}];

    MPSCNNLossLabels *lossState =
        [[MPSCNNLossLabels alloc] initWithDevice:device
                                labelsDescriptor:labelsDesc];

    [lossStateBatchOut addObject:lossState];
  }

  *lossStateBatch = lossStateBatchOut;

  return trainBatch;
}

@end
