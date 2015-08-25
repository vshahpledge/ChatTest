//
//  SocketIOSingleton.h
//  ChatTest
//
//  Created by WellPledge LLC on 8/19/15.
//  Copyright (c) 2015 Vikas Shah. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Socket_IO_Client_Swift/Socket_IO_Client_Swift-Swift.h>

@interface SocketIOSingleton : NSObject

+ (instancetype)sharedSingleton;
- (void)connect;
- (void)disconnect;
- (void)sendMessage:(NSArray *)message;
- (void)sendImage:(NSArray *)message;
- (void)sendTyping;
- (void)setCallback:(void (^)(NSArray *, void (^)(NSArray *)))callback forEvent:(NSString *)event;

@end
