#import "AppDelegate.h"
#import <AppKit/AppKit.h>

int main() {
  @autoreleasepool {
    AppDelegate *del = [[AppDelegate alloc] init];

    NSApplication *app = [NSApplication sharedApplication];
    [app setDelegate:del];
    [app run];
  }
}
