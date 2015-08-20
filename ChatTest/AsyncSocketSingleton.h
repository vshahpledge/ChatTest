//
//  AsyncSocketSingleton.h
//  ChatTest
//
//  Created by Vikas Shah on 8/14/15.
//  Copyright (c) 2015 Vikas Shah. All rights reserved.
//

#import <CocoaAsyncSocket/CocoaAsyncSocket.h>

@interface AsyncSocketSingleton : NSObject <GCDAsyncSocketDelegate>

+ (instancetype)sharedSingleton;

- (void)connect;
- (void)disconnect;
- (void)read;
- (void)sendMessage:(NSData *)data;

@end