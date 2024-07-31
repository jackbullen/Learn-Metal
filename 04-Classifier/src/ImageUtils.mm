#import "ImageUtils.h"

// Save a binary image stored as unsigned char* to PNG
void createAndSaveImage(NSString *name, const unsigned char *pixels, int width,
                        int height) {
  NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc]
      initWithBitmapDataPlanes:NULL
                    pixelsWide:width
                    pixelsHigh:height
                 bitsPerSample:8
               samplesPerPixel:1
                      hasAlpha:NO
                      isPlanar:NO
                colorSpaceName:NSCalibratedWhiteColorSpace
                   bytesPerRow:width
                  bitsPerPixel:8];
  unsigned char *bitmapData = [bitmapRep bitmapData];
  memcpy(bitmapData, pixels, width * height);

  NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
  [image addRepresentation:bitmapRep];

  NSData *imageData = [image TIFFRepresentation];
  NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
  NSDictionary *props = @{};
  imageData = [imageRep representationUsingType:NSBitmapImageFileTypePNG
                                     properties:props];
  if (![imageData writeToFile:name atomically:YES]) {
    NSLog(@"Failed to write image to %@", name);
  } 
}

// Save all of the images contained in a file
void saveImages(NSString *filepath, int imageBytes) {
  unsigned char pixels[imageBytes];

  NSFileManager *fileManager = [NSFileManager defaultManager];
  if (![fileManager fileExistsAtPath:filepath]) {
    NSLog(@"Failed to create file manager");
    return;
  }

  NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filepath];
  if (!fileHandle) {
    NSLog(@"Failed to open file");
    return;
  }

  NSData *fileData = [fileHandle readDataToEndOfFile];
  if (!fileData) {
    NSLog(@"Failed to read data from file %@", filepath);
    return;
  }

  NSUInteger lastSlashIndex =
      [filepath rangeOfString:@"/" options:NSBackwardsSearch].location;
  NSString *dataDir =
      [filepath substringFromIndex:lastSlashIndex + 1];

  NSUInteger dataLength = [fileData length];
  const unsigned char *bytes = (const unsigned char *)[fileData bytes];

  int idx = 0;
  for (int i = 0; i < dataLength; i++) {
    pixels[idx] = bytes[i];
    idx++;
    if (i % imageBytes == 0) {
      createAndSaveImage([NSString stringWithFormat:@"data/images/%@_%d.png", dataDir,
                                                    (int)(i / imageBytes)],
                         pixels, 28, 28);
      idx = 0;
    }
  }

  [fileHandle closeFile];
}