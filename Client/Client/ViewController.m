//
//  ViewController.m
//  Client
//
//  Created by 陈思欣 on 2019/1/15.
//  Copyright © 2019 chensx. All rights reserved.
//

#import "ViewController.h"
#include <netinet/in.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

@interface ViewController ()<UITableViewDataSource, UITabBarDelegate>

@property (nonatomic, assign) int client_socket;
@property (nonatomic, strong) NSMutableArray *userArray;

@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *msgTextField;
@property (weak, nonatomic) IBOutlet UILabel *toNameLabel;
@property (weak, nonatomic) IBOutlet UITextView *chatView;
@property (weak, nonatomic) IBOutlet UITableView *onlineTableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupSubviews];
    [self createdSocket];
}

- (void)setupSubviews {
    [self.userNameTextField becomeFirstResponder];
}

#pragma mark - action

- (IBAction)settingButtonDidClicked:(id)sender {
    NSString *msg = [NSString stringWithFormat:@"name:%@",self.userNameTextField.text] ;
    [self sendMsg:msg];
    [self.msgTextField becomeFirstResponder];
}
- (IBAction)sendButtonDidClicked:(id)sender {
    if ([self.msgTextField.text isEqualToString:@""] || ![self.userArray containsObject:self.userNameTextField.text] || [self.toNameLabel.text isEqualToString:self.userNameTextField.text]) {
        [self showLogsWithString:@"请设置用户名、检查发送对象、消息不能为空"];
        return;
    }
    NSString *msg = [NSString stringWithFormat:@"to:%@*%@",self.toNameLabel.text,self.msgTextField.text];
    [self sendMsg:msg];
    NSString *displayMsg = [NSString stringWithFormat:@"to:%@\n%@",self.toNameLabel.text,self.msgTextField.text];
    [self showLogsWithString:displayMsg];
    self.msgTextField.text = @"";
}

#pragma mark - socket
- (void)createdSocket {
    
    int client_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (client_socket == -1) {
        perror("socket error");
        return;
    }
    int on = 1;
    setsockopt(client_socket, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on) );
    
    
    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = inet_addr("127.0.0.1");//htonl(INADDR_ANY);
    server_addr.sin_port = htons(8099);
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        int aResult = connect(client_socket, (struct sockaddr *)&server_addr, sizeof(struct sockaddr_in));
        if (aResult == -1) {
            perror("connect error");
            return ;
        }
        
        self.client_socket = client_socket;
        [self acceptFromServer];
        
    });
}

- (void)acceptFromServer {
    while (1) {
        char buf[1024];
        long iReturn = recv(self.client_socket, buf, sizeof(buf), 0);
        if (iReturn <= 0) {
            perror("recv error");
            break;
        }
        NSString *str = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];;
        if ([str hasPrefix:@"list:"]) {
            NSString *arrayStr = [str substringFromIndex:5];
            NSArray *list = [arrayStr componentsSeparatedByString:@","];
            self.userArray = [NSMutableArray arrayWithArray:list];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.onlineTableView reloadData];
            });
        }else {
            [self showLogsWithString:str];
        }
    }
}

//给客户端发送信息
- (void)sendMsg:(NSString*)msg {
    char *buf[1024] = {0};
    const char *p1 = (char*)buf;
    p1 = [msg cStringUsingEncoding:NSUTF8StringEncoding];
    send(self.client_socket, p1, 1024, 0);
}

#pragma mark - private
//在界面上显示日志
- (void)showLogsWithString:(NSString*)str {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *newStr = [NSString stringWithFormat:@"\n%@",str];
        self.chatView.text = [self.chatView.text stringByAppendingString:newStr];
    });
}

#pragma mark - TableViewDelegate & dataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.userArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellId = @"onlinetableviewcellid";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    cell.textLabel.text = self.userArray[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    self.toNameLabel.text = self.userArray[indexPath.row];
    [self.msgTextField becomeFirstResponder];
}

#pragma mark - getter
- (NSMutableArray *)userArray {
    if (!_userArray) {
        _userArray = [NSMutableArray array];
    }
    return _userArray;
}

@end
