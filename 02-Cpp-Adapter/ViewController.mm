#import "ViewController.h"
#import "AppAdapter.h"

@implementation ViewController
{
    MTKView *_pView;
    AppAdapter *_pAppAdapter;
}

- (void)viewDidLoad 
{
    [super viewDidLoad]; 

    _pView = (MTKView *)self.view;
    _pView.device = MTLCreateSystemDefaultDevice();
    _pAppAdapter = [AppAdapter alloc];
    [_pAppAdapter draw:_pView.currentDrawable device:_pView.device];
}

@end