#import "Graph.h"

@implementation Graph

- (instancetype)initWithDevice:(id<MTLDevice>)inputDevice {
  self = [super init];
  device = inputDevice;

  conv1Wts = [[ConvDataSource alloc] initWithKernelWidth:5
                                            kernelHeight:5
                                    inputFeatureChannels:1
                                   outputFeatureChannels:32
                                                  stride:1
                                                   label:@"conv1"];

  conv2Wts = [[ConvDataSource alloc] initWithKernelWidth:5
                                            kernelHeight:5
                                    inputFeatureChannels:32
                                   outputFeatureChannels:64
                                                  stride:1
                                                   label:@"conv2"];

  fc1Wts = [[ConvDataSource alloc] initWithKernelWidth:7
                                          kernelHeight:7
                                  inputFeatureChannels:64
                                 outputFeatureChannels:1024
                                                stride:1
                                                 label:@"fc1"];

  fc2Wts = [[ConvDataSource alloc] initWithKernelWidth:1
                                          kernelHeight:1
                                  inputFeatureChannels:1024
                                 outputFeatureChannels:10
                                                stride:1
                                                 label:@"fc2"];

  MPSNNFilterNode *finalNode = [self createNodesWithTraining:true];

  // Backward pass

  NSArray<MPSNNFilterNode *> *lossExitPoints = [finalNode
      trainingGraphWithSourceGradient:nil
                          nodeHandler:^(
                              MPSNNFilterNode *_Nonnull gradientNode,
                              MPSNNFilterNode *_Nonnull inferenceNode,
                              MPSNNImageNode *_Nonnull inferenceSource,
                              MPSNNImageNode *_Nonnull gradientSource) {
                            gradientNode.resultImage.format =
                                MPSImageFeatureChannelFormatFloat32;
                          }];

  assert(lossExitPoints.count == 1);

  trainGraph = [[MPSNNGraph alloc] initWithDevice:device
                                      resultImage:lossExitPoints[0].resultImage
                              resultImageIsNeeded:YES];

  trainGraph.format = fcFormat;

  [self initInferenceGraph];

  return self;
}

- (void)initInferenceGraph {

  MPSNNFilterNode *finalNode = [self createNodesWithTraining:YES];

  inferenceGraph = [[MPSNNGraph alloc] initWithDevice:device
                                          resultImage:finalNode.resultImage
                                  resultImageIsNeeded:YES];

  inferenceGraph.format = fcFormat;
}

- (MPSNNFilterNode *)createNodesWithTraining:(BOOL)isTraining {

  MPSCNNConvolutionNode *conv1Node =
      [MPSCNNConvolutionNode nodeWithSource:[MPSNNImageNode nodeWithHandle:nil]
                                    weights:conv1Wts];

  conv1Node.paddingPolicy = sameConvPadding;

  MPSCNNNeuronReLUNode *relu1 =
      [MPSCNNNeuronReLUNode nodeWithSource:conv1Node.resultImage a:0.f];

  MPSCNNPoolingMaxNode *pool1 =
      [MPSCNNPoolingMaxNode nodeWithSource:relu1.resultImage
                                filterSize:2
                                    stride:2];
  pool1.paddingPolicy = samePoolingPadding;

  MPSCNNConvolutionNode *conv2Node =
      [MPSCNNConvolutionNode nodeWithSource:pool1.resultImage weights:conv2Wts];
  conv2Node.paddingPolicy = sameConvPadding;

  MPSCNNNeuronReLUNode *relu2 =
      [MPSCNNNeuronReLUNode nodeWithSource:conv2Node.resultImage a:0.f];

  MPSCNNPoolingMaxNode *pool2 =
      [MPSCNNPoolingMaxNode nodeWithSource:relu2.resultImage
                                filterSize:2
                                    stride:2];
  pool2.paddingPolicy = samePoolingPadding;

  MPSCNNFullyConnectedNode *fc1Node =
      [MPSCNNFullyConnectedNode nodeWithSource:pool2.resultImage
                                       weights:fc1Wts];

  MPSCNNNeuronReLUNode *relu3 =
      [MPSCNNNeuronReLUNode nodeWithSource:fc1Node.resultImage a:0.f];

  MPSNNFilterNode *f2InputNode = relu3;
  if (isTraining) {
    MPSCNNDropoutNode *dropNode = [MPSCNNDropoutNode
            nodeWithSource:relu3.resultImage
           keepProbability:0.5
                      seed:1
        maskStrideInPixels:MTLSize{.width = 1, .height = 1, .depth = 1}];
    f2InputNode = dropNode;
  }

  MPSCNNFullyConnectedNode *fc2Node =
      [MPSCNNFullyConnectedNode nodeWithSource:f2InputNode.resultImage
                                       weights:fc2Wts];

  if (isTraining) {
    MPSCNNLossDescriptor *lossDesc = [MPSCNNLossDescriptor
        cnnLossDescriptorWithType:MPSCNNLossTypeSoftMaxCrossEntropy
                    reductionType:MPSCNNReductionTypeSum];
    lossDesc.weight = 1.f / (float)BATCH_SIZE;
    MPSCNNLossNode *lossNode =
        [MPSCNNLossNode nodeWithSource:fc2Node.resultImage
                        lossDescriptor:lossDesc];
    return lossNode;
  } else {
    MPSCNNSoftMaxNode *sftNode =
        [MPSCNNSoftMaxNode nodeWithSource:fc2Node.resultImage];
    return sftNode;
  }
}

- (MPSImageBatch *)
    encodeTrainingBatchToCommandBuffer:
        (nonnull id<MTLCommandBuffer>)commandBuffer
                          sourceImages:(MPSImageBatch *)sourceImage
                            lossStates:(MPSCNNLossLabelsBatch *)lossStateBatch {

  MPSImageBatch *returnImage =
      [trainGraph encodeBatchToCommandBuffer:commandBuffer
                                sourceImages:@[ sourceImage ]
                                sourceStates:@[ lossStateBatch ]
                          intermediateImages:nil
                           destinationStates:nil];

  MPSImageBatchSynchronize(returnImage, commandBuffer);

  return returnImage;
}

- (MPSImageBatch *)encodeInferenceBatchToCommandBuffer:
                       (nonnull id<MTLCommandBuffer>)commandBuffer
                                          sourceImages:
                                              (MPSImageBatch *)sourceImage {

  MPSImageBatch *returnImage =
      [inferenceGraph encodeBatchToCommandBuffer:commandBuffer
                                    sourceImages:@[ sourceImage ]
                                    sourceStates:nil
                              intermediateImages:nil
                               destinationStates:nil];

  return returnImage;
}

@end