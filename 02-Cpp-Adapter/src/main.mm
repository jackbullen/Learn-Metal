#import "AppKit/AppKit.h"
#import "AppDelegate.h"

int main(int argc, const char *argv[])
{
    @autoreleasepool 
    {
        AppDelegate *del = [[AppDelegate alloc] init];

        NSApplication *sharedApplication = [NSApplication sharedApplication];
        [sharedApplication setDelegate:del];
        [sharedApplication run];

        return 0;
    }
}