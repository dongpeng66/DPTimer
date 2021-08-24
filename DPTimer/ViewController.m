//
//  ViewController.m
//  DPTimer
//
//  Created by dp on 2021/8/24.
//

#import "ViewController.h"
#import "DPTimer.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSString *name=[DPTimer execTask:^(double time) {
        NSLog(@"----%f",time);
    } finish:^(NSString *identifier) {
        NSLog(@"---%@结束了",identifier);
    } start:0 interval:1 endInterval:100 identifier:@"123" forIsDisk:YES repeats:YES async:YES];
}


@end
