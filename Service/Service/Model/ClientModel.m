//
//  ClientModel.m
//  Service
//
//  Created by 陈思欣 on 2019/1/15.
//  Copyright © 2019 chensx. All rights reserved.
//

#import "ClientModel.h"

@implementation ClientModel

+ (instancetype)modelWithSocket:(int)socket name:(NSString *)name {
    ClientModel *model = [[ClientModel alloc] init];
    model.clientSocket = socket;
    model.clientName = name;
    return model;
}

@end
