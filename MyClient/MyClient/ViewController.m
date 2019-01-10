//
//  ViewController.m
//  MyClient
//
//  Created by 陈思欣 on 2018/11/21.
//  Copyright © 2018年 chensx. All rights reserved.
//

#import "ViewController.h"

@interface ViewController()

@property (unsafe_unretained) IBOutlet NSTextView *textView;

@property (nonatomic, strong) NSMutableArray *clientArray;
@property (nonatomic, strong) NSMutableArray *clientNameshen2Array;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

- (void)createSocket {
    
}

- (void)showLogsWithString:(NSString *)string {
    dispatch_async(dispatch_get_main_queue(), ^{
       NSString *newString = [NSString stringWithFormat:@"\n%@",string];
        self.textView.string = [self.textView.string stringByAppendingString:newString];
    });
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
