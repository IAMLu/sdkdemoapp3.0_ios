//
//  ConferenceViewController.m
//  IosDemo
//
//  Created by XieYajie on 4/26/16.
//  Copyright © 2016 dxstudio.com. All rights reserved.
//

#import "ConferenceViewController.h"

#import "ChatDemoHelper.h"
#import "StreamTableViewController.h"
#import "UserTableViewController.h"

@interface ConferenceViewController ()<EMConferenceManagerDelegate, EMConferenceBuilderDelegate, StreamTableViewControllerDelegate>
{
    float _ox;
    float _oy;
    float _width;
    float _height;
    
    NSString *_callId;
}

@property (strong, nonatomic) EMCallLocalView *localView;

@property (strong, nonatomic) NSMutableDictionary *remoteViews;

@property (strong, nonatomic) EMCallConference *conference;

@end

@implementation ConferenceViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _callId = nil;
    }
    
    return self;
}

- (instancetype)initWithCallId:(NSString *)aCallId
{
    self = [super init];
    if (self) {
        _callId = aCallId;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UIBarButtonItem *exitItem = [[UIBarButtonItem alloc] initWithTitle:@"退出" style:UIBarButtonItemStylePlain target:self action:@selector(exitConfernece)];
    UIBarButtonItem *subItem = [[UIBarButtonItem alloc] initWithTitle:@"订阅" style:UIBarButtonItemStylePlain target:self action:@selector(subStream)];
    UIBarButtonItem *inviteItem = [[UIBarButtonItem alloc] initWithTitle:@"邀请" style:UIBarButtonItemStylePlain target:self action:@selector(inviteUser)];
    self.navigationItem.rightBarButtonItems = @[exitItem, subItem, inviteItem];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationInviteUser:) name:@"selecteInviteUser" object:nil];
    
    self.remoteViews = [[NSMutableDictionary alloc] init];
    
    [[EMClient sharedClient].conferenceManager setBuilder:self];
    
    _ox = 10;
    _oy = 80;
    _width = 120;
    _height = 140;
    
    self.localView = [[EMCallLocalView alloc] initWithFrame:CGRectMake(_ox, _oy, _width, _height)];
    self.localView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:self.localView];
    _ox = 150;
    
    [[EMClient sharedClient].conferenceManager addDelegate:self delegateQueue:nil];
    
    EMError *error = nil;
    if (_callId == nil) {
        self.conference = [[EMClient sharedClient].conferenceManager createAndJoinConferenceWithType:EMCallTypeVideo password:nil localVideoView:self.localView error:&error];
    } else {
        self.conference = [[EMClient sharedClient].conferenceManager joinConferenceWithId:_callId password:@"" localVideoView:self.localView error:&error];
    }
    
    if (error) {
        self.conference = nil;
        [self.navigationController popViewControllerAnimated:YES];
    }
    else{
        [self _setupSubviews];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private

- (void)_setupSubviews
{
//    //2.自己窗口
//    CGFloat width = 80;
//    CGFloat height = _callSession.remoteView.frame.size.height / _callSession.remoteView.frame.size.width * width;
//    _callSession.localView = [[LocalVideoView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 90, CGRectGetMaxY(_statusLabel.frame), width, height)];
}

#pragma mark - StreamTableViewControllerDelegate

- (void)streamController:(StreamTableViewController *)aController
       didSelectedStream:(EMCallStream *)aStream
{
    if (!aStream) {
        return;
    }
    
    NSString *subName = aStream.userName;
    
    EMError *error = nil;
    
    EMCallRemoteView *remoteView = [[EMCallRemoteView alloc] initWithFrame:CGRectMake(_ox, _oy, _width, _height)];
    remoteView.backgroundColor = [UIColor redColor];
    [self.view addSubview:remoteView];
    
    if (_ox >= 150) {
        _ox = 10;
        _oy += 20 + _height;
    }
    else{
        _ox = 150;
    }
    
//    [[EMClient sharedClient].conferenceManager subscribeConferenceStream:self.conference.callId stream:aStream remoteVideoView:remoteView error:&error];
    if (error) {
        [remoteView removeFromSuperview];
    }
    else{
        [self.remoteViews setObject:remoteView forKey:subName];
    }
}

#pragma mark - EMConferenceBuilderDelegate

- (EMCallRemoteView *)mutilConference:(EMCallConference *)aConference
                     videoViewForUser:(NSString *)aUserName
{
    EMCallRemoteView *remoteView = [[EMCallRemoteView alloc] initWithFrame:CGRectMake(_ox, _oy, _width, _height)];
    remoteView.backgroundColor = [UIColor redColor];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view addSubview:remoteView];
    });
    
    if (_ox >= 150) {
        _ox = 10;
        _oy += 20 + _height;
    }
    else{
        _ox = 150;
    }
    
    [self.remoteViews setObject:remoteView forKey:aUserName];
    
    return remoteView;
}

#pragma mark - EMCallManagerDelegate

- (void)userDidJoinConference:(EMCallConference *)aConference
                         user:(NSString *)aUsername
{
    if ([aConference.callId isEqualToString: self.conference.callId]) {
        NSString *message = [NSString stringWithFormat:@"%@ 已加入会议", aUsername];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Enter 通知" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
    }
}

- (void)userDidLeaveConference:(EMCallConference *)aConference
                          user:(NSString *)aUsername
{
    if ([aConference.callId isEqualToString: self.conference.callId]) {
        NSString *message = [NSString stringWithFormat:@"%@ 已退出会议", aUsername];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Exit 通知" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
        
        EMCallRemoteView *view = [self.remoteViews objectForKey:aUsername];
        if (view) {
            [view removeFromSuperview];
        }
    }
}

- (void)userDidPubConferenceStream:(EMCallConference *)aConference
                              user:(NSString *)aUsername
{
    if ([aConference.callId isEqualToString: self.conference.callId]) {
        NSString *message = [NSString stringWithFormat:@"%@ 已上传数据流", aUsername];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Pub 通知" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
    }
}

- (void)conferenceMembersDidUpdate:(EMCallConference *)aConference
{
    if ([aConference.callId isEqualToString: self.conference.callId]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"成员通知" message:@"会议成员已更新" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
    }
}

- (void)conferenceDidEnd:(EMCallConference *)aConference
                  reason:(EMCallEndReason)aReason
                   error:(EMError *)aError
{
    if ([aConference.callId isEqualToString: self.conference.callId]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"会议通知" message:@"会议已关闭" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
    }
    
    self.conference = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - notification

- (void)notificationInviteUser:(NSNotification *)notification
{
    NSString *username = (NSString *)notification.object;
//    NSString *from = [[EMClient sharedClient] currentUsername];
//    EMCmdMessageBody *body = [[EMCmdMessageBody alloc] initWithAction:@"inviteToJoinConference"];
//    NSDictionary *ext = @{@"callId": self.conference.callId};
//    EMMessage *message = [[EMMessage alloc] initWithConversationID:username from:from to:username body:body ext:ext];
//    message.chatType = EMChatTypeChat;
//    [[EMClient sharedClient].chatManager sendMessage:message progress:^(int progress) {
//        //
//    } completion:^(EMMessage *message, EMError *error) {
//        //
//    }];
    
    EMError *error = nil;
    [[EMClient sharedClient].conferenceManager inviteUserToJoinConference:self.conference.callId userName:username ext:nil error:&error];
    if (error) {
        [self showHint:@"邀请发送失败，请重新发送"];
    }
    else {
        [self showHint:@"邀请发送成功"];
    }
}


#pragma mark - action

- (void)exitConfernece
{
    if (!self.conference) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    if (_callId == nil) {
         [[EMClient sharedClient].conferenceManager destroyConferenceWithId:self.conference.callId error:nil];
    } else {
         [[EMClient sharedClient].conferenceManager leaveConferenceWithId:self.conference.callId error:nil];
    }
   
    self.conference = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)subStream
{
    NSArray *streams = [self.conference getSubscribableStreams];
    if ([streams count] == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"没有可订阅的数据流" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
    }
    else{
        StreamTableViewController *controller = [[StreamTableViewController alloc] initWithDataSource:streams];
        controller.delegate = self;
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (void)inviteUser
{
    NSArray *contacts = [[EMClient sharedClient].contactManager getContacts];
    UserTableViewController *controller = [[UserTableViewController alloc] initWithDataSource:contacts];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
