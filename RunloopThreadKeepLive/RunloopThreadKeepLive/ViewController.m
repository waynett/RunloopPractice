//  线程保活&退出runloop方法
//  ViewController.m
//  RunloopThreadKeepLive
//
//  Created by wenwei wan on 2020/4/21.
//  Copyright © 2020 wenwei wan. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property(nonatomic,strong) NSThread * subTread1;
@property(nonatomic,strong) NSThread * subTread2;
@property(nonatomic,strong) NSThread * subTread3;

@property(nonatomic,assign) BOOL keepRunloopRun;

@property(nonatomic,strong) NSRunLoop  * subTread1Runloop;
@property(nonatomic,strong) NSRunLoop  * subTread2Runloop;
@property(nonatomic,strong) NSRunLoop  * subTread3Runloop;

@property(nonatomic,strong) NSPort * subTreadPort;
@property(nonatomic,strong) NSTimer * subTreadTimer;


@end

static const int buttonHeight = 80;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.keepRunloopRun = YES;
    
    UIButton * button1 = [UIButton buttonWithType:UIButtonTypeCustom];
    [button1 setTitle:@"退出runloop 方法1(去掉所有source,timer)" forState:UIControlStateNormal];
    [button1 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    button1.frame = CGRectMake(0, 0, 360, buttonHeight);
    
    button1.tag = 1;
    
    [self.view addSubview:button1];
    
    button1.center = self.view.center;
    
    [button1 addTarget:self action:@selector(exitRunloop:) forControlEvents:UIControlEventTouchUpInside];

    
    UIButton * button2 = [UIButton buttonWithType:UIButtonTypeCustom];
    [button2 setTitle:@"退出runloop 方法2(执行CFRunLoopStop)" forState:UIControlStateNormal];
    [button2 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    button2.frame = CGRectMake(0, 0, 360, buttonHeight);

    button2.tag = 2;
    [self.view addSubview:button2];

    button2.center = CGPointMake(self.view.center.x, CGRectGetMaxY(button1.frame) + 40);

    [button2 addTarget:self action:@selector(exitRunloop:) forControlEvents:UIControlEventTouchUpInside];



    UIButton * button3 = [UIButton buttonWithType:UIButtonTypeCustom];
    [button3 setTitle:@"退出runloop 方法3(自定义逻辑条件退出)" forState:UIControlStateNormal];
    [button3 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    button3.frame = CGRectMake(0, 0, 360, buttonHeight);

    button3.tag = 3;
    [self.view addSubview:button3];

    button3.center = CGPointMake(self.view.center.x, CGRectGetMaxY(button2.frame) + 40);

    [button3 addTarget:self action:@selector(exitRunloop:) forControlEvents:UIControlEventTouchUpInside];
    
    
    // Do any additional setup after loading the view.
    
//    CFRunLoopRef rl = CFRunLoopGetCurrent();
//    CFRunLoopMode rlm = CFRunLoopCopyCurrentMode(rl);
//    CFArrayRef modes = CFRunLoopCopyAllModes(rl);
//    NSLog(@"MainRunLoop中的current mode:%@",rlm);
//    NSLog(@"MainRunLoop中的modes:%@",modes);
//    NSLog(@"MainRunLoop对象：%@",rl);
    
    self.subTread1 = [[NSThread alloc] initWithTarget:self selector:@selector(subThreadEntryPoint1) object:nil];
    
    [self.subTread1 setName:@"subTread1"];
    
    [self.subTread1 start];
    
    
    self.subTread2 = [[NSThread alloc] initWithTarget:self selector:@selector(subThreadEntryPoint2) object:nil];

    [self.subTread2 setName:@"subTread2"];

    [self.subTread2 start];


    self.subTread3 = [[NSThread alloc] initWithTarget:self selector:@selector(subThreadEntryPoint3) object:nil];

    [self.subTread3 setName:@"subTread3"];

    [self.subTread3 start];

}

- (void)exitRunloop:(id)sender;
{
    UIButton * button = (UIButton*)sender;
    if (button.tag == 1) {
        NSLog(@"%@",self.subTread1Runloop);
        [self.subTreadTimer invalidate];
        [self.subTreadPort invalidate];
    } else if (button.tag == 2) {
        CFRunLoopStop([self.subTread2Runloop getCFRunLoop]);
    } else if (button.tag == 3) {
        self.keepRunloopRun = NO;
    } else {
        
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
{
    NSLog(@"%@=%@",self.subTread1.name,[self.subTread1 isFinished]?@"线程已结束":@"线程保活状态");
    NSLog(@"%@=%@",self.subTread2.name,[self.subTread2 isFinished]?@"线程已结束":@"线程保活状态");
    NSLog(@"%@=%@",self.subTread3.name,[self.subTread3 isFinished]?@"线程已结束":@"线程保活状态");

}

- (void)subThreadEntryPoint1
{
    @autoreleasepool {
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        //如果注释了下面添加timer到Mode的这1行，子线程中的任务并不能正常执行，因为运行[runLoop run]后，runloop就直接退出了，线程保活也就失效了，
        //所以，如果想退出runloop，可以通过使Mode中所有source0，source1，timer都删掉（失效）做到
        self.subTreadTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(subThreadOperation) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.subTreadTimer forMode:NSDefaultRunLoopMode];
        
        self.subTreadPort = [NSMachPort port];
        [[NSRunLoop currentRunLoop] addPort:self.subTreadPort forMode:NSDefaultRunLoopMode];
        
        
        NSLog(@"启动RunLoop前currentMode--%@",runLoop.currentMode);
        NSLog(@"currentRunLoop:%@",[NSRunLoop currentRunLoop]);
        
        self.subTread1Runloop = runLoop;
        

        [runLoop run];
        
        NSLog(@"结束RunLoop前currentMode--%@",runLoop.currentMode);
        NSLog(@"currentRunLoop:%@",[NSRunLoop currentRunLoop]);
        
        NSLog(@"%@=%@",self.subTread1.name,@"线程已结束");

    }
}

/**
 子线程任务
 */
- (void)subThreadOperation
{
    NSLog(@"启动RunLoop后--%@",[NSRunLoop currentRunLoop].currentMode);
    NSLog(@"%@----子线程任务开始",[NSThread currentThread].name);
    [NSThread sleepForTimeInterval:3.0];
    NSLog(@"%@----子线程任务结束",[NSThread currentThread].name);
}
                 

- (void)subThreadEntryPoint2
{
    @autoreleasepool {

        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        //如果注释了下面添加source到Mode的这一行，子线程中的任务并不能正常执行，因为运行[runLoop run]后，runloop就直接退出了，线程保活也就失效了，
        NSMachPort * port = [[NSMachPort alloc] init];
        [[NSRunLoop currentRunLoop] addPort:port forMode:NSDefaultRunLoopMode];
        NSLog(@"启动RunLoop前currentMode--%@",runLoop.currentMode);
        NSLog(@"currentRunLoop:%@",[NSRunLoop currentRunLoop]);

        self.subTread2Runloop = runLoop;

        [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];

        NSLog(@"%@=%@",self.subTread2.name,@"线程已结束");

    }
}

- (void)subThreadEntryPoint3
{
    @autoreleasepool {
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        //如果注释了下面添加source到Mode的这一行，子线程中的任务并不能正常执行，因为运行[runLoop run]后，runloop就直接退出了，线程保活也就失效了，
        NSMachPort * port = [[NSMachPort alloc] init];
        [[NSRunLoop currentRunLoop] addPort:port forMode:NSDefaultRunLoopMode];
        NSLog(@"启动RunLoop前currentMode--%@",runLoop.currentMode);
        NSLog(@"currentRunLoop:%@",[NSRunLoop currentRunLoop]);
        
        self.subTread3Runloop = runLoop;

        do {
            [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:3]];
        } while (self.keepRunloopRun);
        
        
        NSLog(@"%@=%@",self.subTread3.name,@"线程已结束");

    }
}

                            

@end
