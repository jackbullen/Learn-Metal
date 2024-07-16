#import <AppKit/AppKit.h>
#import "AppDelegate.h"

int main() 
{ 
    @autoreleasepool
    {
        AppDelegate *del = [[AppDelegate alloc] init];

        NSApplication *sharedApp = [NSApplication sharedApplication];
        [sharedApp setDelegate:del];
        [sharedApp run];

        return 0; 
    }
}