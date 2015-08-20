//
//  SocketIOSingleton.m
//  ChatTest
//
//  Created by WellPledge LLC on 8/19/15.
//  Copyright (c) 2015 Vikas Shah. All rights reserved.
//

#import "SocketIOSingleton.h"

#define SOCKET_URL @"127.0.0.1:3000"

static SocketIOClient *io = nil;

@implementation SocketIOSingleton {
//    NSMutableDictionary *callbacks;
}

+ (instancetype)sharedSingleton {
    static dispatch_once_t t;
    static SocketIOSingleton *sharedSingleton = nil;
    dispatch_once(&t, ^{
        sharedSingleton = [[SocketIOSingleton alloc] init];
    });
    return sharedSingleton;
}

- (instancetype)init {
    self = [super init];
    if (self) {
//        callbacks = [[NSMutableDictionary alloc] init];
        io = [[SocketIOClient alloc] initWithSocketURL:SOCKET_URL options:nil];
        [self setupClient];
        return self;
    }
    return nil;
}

- (void)setupClient {
    [io on:@"connect" callback:^(NSArray *data, void (^ack)(NSArray*)) {
        NSLog(@"connected");
    }];
    
    [io on:@"disconnect" callback:^(NSArray *data, void (^ack)(NSArray*)) {
        NSLog(@"disconnected");
    }];
}

- (void)connect {
    [io connect];
}

- (void)disconnect {
    [io closeWithFast:YES];
}

- (void)sendMessage:(NSString *)message {
    [io emit:@"chat" withItems:@[message]];
}

- (void)setCallback:(void (^ __nonnull)(NSArray * __nullable, void (^ __nullable)(NSArray * __nonnull)))callback forEvent:(NSString * __nonnull)event {
    [io on:event callback:callback];
}

//- (void)setCallback:(void (^)(NSArray *data))callbackBlock forEvent:(NSString *)event {
//    NSArray *callbacksArray = [callbacks objectForKey:event];
//    NSMutableArray *tempCallbacksArray = nil;
//    
//    if (callbacksArray) {
//        tempCallbacksArray = [[NSMutableArray alloc] initWithArray:callbacksArray];
//    } else {
//        tempCallbacksArray = [[NSMutableArray alloc] init];
//    }
//    
//    [tempCallbacksArray addObject:[callbackBlock copy]];
//    
//    [callbacks setValue:tempCallbacksArray forKey:event];
//}

@end
