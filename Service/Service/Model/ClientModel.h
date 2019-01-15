//
//  ClientModel.h
//  Service
//
//  Created by 陈思欣 on 2019/1/15.
//  Copyright © 2019 chensx. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ClientModel : NSObject

@property(nonatomic, assign) int clientSocket;
@property(nonatomic, copy) NSString *clientName;

+ (instancetype)modelWithSocket:(int)socket name:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
