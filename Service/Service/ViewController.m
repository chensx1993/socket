//
//  ViewController.m
//  Service
//
//  Created by 陈思欣 on 2019/1/11.
//  Copyright © 2019 chensx. All rights reserved.
//

#import "ViewController.h"
#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>

#import "ClientModel.h"

static int const kMaxConnectCount = 5;

@interface ViewController()

@property (unsafe_unretained) IBOutlet NSTextView *textView;

@property (nonatomic, strong) NSMutableArray *clientArray;
@property (nonatomic, strong) NSMutableArray *clientNameArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createdSocket];
    
}

- (void)createdSocket {
    int server_socket, ret, on;
    
    // 创建socket
    server_socket = socket(PF_INET, SOCK_STREAM, 0);
    if (server_socket == -1) {
        perror("socket error");
        [self showLogsWithString:@"socket() error"];
        return;
    }
    [self showLogsWithString:@"socket created"];
    
    /* Enable address reuse */
    on = 1;
    ret = setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on) );
    
    //绑定地址和端口
    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = inet_addr("127.0.0.1");//htonl(INADDR_ANY);
    server_addr.sin_port = htons(8099);
    
    ret = bind(server_socket, (struct sockaddr *)&server_addr, sizeof(server_addr));
    if (ret == -1) {
        [self showLogsWithString:@"bind() error"];
        perror("bind error");
        return;
    }
    [self showLogsWithString:@"socket binds ip and port"];
    
    //监听客户端
    if (listen(server_socket, kMaxConnectCount) == -1) {
        [self showLogsWithString:@"listen() error"];
        return;
    }
    [self showLogsWithString:@"scoket is listening"];
    
    //接受客户端的链接
    /* 思路：最多 kMaxConnectCount 个客户端接入
     ** 一个客户端接入就新建一个线程:循环调用 accept, 如果客户端接入，循环调用recv
     ** while(1) {
     accept()
     while(1) {
     recv()
     }
     }
     */
    for (int i = 0; i < kMaxConnectCount; i ++) {
        [self acceptClientWithServiceSocket:server_socket];
    }
}


#pragma mark - private
- (void)acceptClientWithServiceSocket:(int)server_socket {
    struct sockaddr_in client_address;
    socklen_t address_len;
    
    address_len = sizeof(client_address);
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        while (1) {
            int client_socket = accept(server_socket, (struct sockaddr *)&client_address, &address_len);
            if (client_socket == -1) {
                [self showLogsWithString:@"accept error"];
                continue ;
            }
            
            [self showLogsWithString:[NSString stringWithFormat:@"client in, socket:%d", client_socket]];
            //接受客户端数据
            [self recvFromClientWithSocket:client_socket];
        }
    });
}

//接受客户端数据
- (void)recvFromClientWithSocket:(int)client_socket {
    while (1) {
        char buf[1024] = {0};
        long iReturn = recv(client_socket, buf, 1024, 0);
        
        if (iReturn > 0) {
            NSLog(@"客户端来消息了");
            NSString *str = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
            [self showLogsWithString:[NSString stringWithFormat:@"客户端来消息了: %@",str]];
            [self checkRecvStr:str andClientSocket:client_socket];
            
        }else if (iReturn == -1) {
            NSLog(@"读取消息失败");
            [self showLogsWithString:@"读取消息失败"];
            break;
            
        }else if (iReturn == 0) {
            NSLog(@"客户端走了");
            [self showLogsWithString:[NSString stringWithFormat:@"client out, socket: %d",client_socket]];
            NSMutableArray *array = [NSMutableArray arrayWithArray:self.clientArray];
            for (ClientModel *model in array) {
                if (model.clientSocket == client_socket) {
                    [self.clientNameArray removeObject:model.clientName];
                    [self.clientArray removeObject:model];
                }
            }
            close(client_socket);
            break;
        }
    }
}

//检查接受到的字符串
- (void)checkRecvStr:(NSString *)str andClientSocket:(int)socket {
    
    
    if ([str hasPrefix:@"name:"]) {//=========用户名=======
        NSString *name = [str substringFromIndex:5];
        
        ClientModel *model = [ClientModel modelWithSocket:socket name:name];
        
        for (int i = 0; i < self.clientArray.count; i ++) {
            ClientModel *client = self.clientArray[i];
            
            if (client.clientSocket == socket) { //修改名字
                //相当于修改数据库数据
                NSString *oldName = self.clientNameArray[i];
                self.clientNameArray[i] = name;
                self.clientArray[i] = model;
                
                //向其他客户端推送改名情况
                for (ClientModel *oldclient in self.clientArray) {
                    [self sendMsg:[NSString stringWithFormat:@"%@ 改名 %@",oldName,name] toClient:oldclient.clientSocket];
                    [self showLogsWithString:[NSString stringWithFormat:@"%@ 改名 %@",oldName,name]];
                    
                    NSString *list = [self.clientNameArray componentsJoinedByString:@","];
                    [self sendMsg:[NSString stringWithFormat:@"list:%@",list] toClient:oldclient.clientSocket];
                }
                return;
                
            }else if ([client.clientName isEqualToString:model.clientName]) { //用户名已存在
                [self sendMsg:@"注册用户名失败，用户名已经存在，请重新设置用户名" toClient:socket];
                [self showLogsWithString:[NSString stringWithFormat:@"socket %d 注册用户名失败，设置的用户名已经存在",socket]];
                return;
            }
        }
        
        [self.clientArray addObject:model];
        [self.clientNameArray addObject:model.clientName];
        
        //向客户端推送当前在线列表
        for (ClientModel *client in self.clientArray) {
            [self sendMsg:[NSString stringWithFormat:@"%@,上线了",name] toClient:client.clientSocket];
        
            NSString *list = [self.clientNameArray componentsJoinedByString:@","];
            [self sendMsg:[NSString stringWithFormat:@"list:%@",list] toClient:client.clientSocket];
        }
        
        
        //给当前客户端发送一条欢迎信息
        NSString *msg = [NSString stringWithFormat:@"welcome %@ !", name];
        [self sendMsg:msg toClient:socket];
        [self showLogsWithString:msg];

        
    }
    else if ([str hasPrefix:@"to:"]) { //=========发送消息=========
        NSRange nameRang = [str rangeOfString:@"*"];
        NSString *name = [str substringWithRange:NSMakeRange(3, nameRang.location - 3)];
        NSString *content = [str substringFromIndex:nameRang.location + 1];
        NSString *fromClientName = @"";
        
        //找出发送者
        for (ClientModel *model in self.clientArray) {
            if (socket == model.clientSocket) {
                fromClientName = model.clientName;
                break;
            }
        }
        
        //给目标发送信息
        for (ClientModel *model in self.clientArray) {
            if ([name isEqualToString:model.clientName]) {
                NSString *msg = [NSString stringWithFormat:@"%@ to you\n%@",fromClientName,content];
                [self sendMsg:msg toClient:model.clientSocket];
                
                [self showLogsWithString:[NSString stringWithFormat:@"%@ 发送给 %@ 内容是：%@",fromClientName,name,content]];
                break;
                
            }
        }
        
    }
}

- (void)sendMsg:(NSString *)msg toClient:(int)socket {
    char *buf[1024] = {0};
    const char *p1 = (char*)buf;
    p1 = [msg cStringUsingEncoding:NSUTF8StringEncoding];
    send(socket, p1, 1024, 0);
}

- (ClientModel *)searchModelWithSocket:(int)socket {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"clientSocket == %d", socket];
    NSArray *filteredArray = [self.clientArray filteredArrayUsingPredicate:predicate];
    return filteredArray.firstObject;
}

- (void)showLogsWithString:(NSString *)string {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *newString = [NSString stringWithFormat:@"\n%@",string];
        self.textView.string = [self.textView.string stringByAppendingString:newString];
    });
}

#pragma mark - socket
- (void)closeSocket {
    
}


#pragma mark - setter
- (NSMutableArray *)clientArray {
    if (!_clientArray) {
        _clientArray = [NSMutableArray array];
    }
    return _clientArray;
}

- (NSMutableArray *)clientNameArray {
    if (!_clientNameArray) {
        _clientNameArray = [NSMutableArray array];
    }
    return _clientNameArray;
}


@end
