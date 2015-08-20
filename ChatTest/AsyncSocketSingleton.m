//
//  AsyncSocketSingleton.m
//  ChatTest
//
//  Created by Vikas Shah on 8/14/15.
//  Copyright (c) 2015 Vikas Shah. All rights reserved.
//

#import "AsyncSocketSingleton.h"
#import <MagicalRecord/MagicalRecord.h>

#define SOCKET_HOST @"127.0.0.1"
#define SOCKET_PORT 3000

typedef NS_ENUM(long, ReadTags) {
    SOCKETIO_HANDSHAKE_HEADER = 0x0,
    SOCKETIO_HANDSHAKE_CHUNKSIZE = 0x1,
    SOCKETIO_HANDSHAKE_BODY = 0x2,
    // reserved
    WEBSOCKET_HANDSHAKE_HEADER = 0x10,
    WEBSOCKET_MESSAGE_HEADER = 0x11,
    WEBSOCKET_MESSAGE_EXTENDED_HEADER = 0x12,
    WEBSOCKET_MESSAGE_MASKING_KEY = 0x13,
    WEBSOCKET_MESSAGE_CONTENT = 0x14,
};

static GCDAsyncSocket *sock = nil;

@implementation AsyncSocketSingleton {
    NSString *_sessionId;
    NSUInteger _timeout;
    NSTimer *_heartbeatTimer;
}

+ (instancetype)sharedSingleton {
    static dispatch_once_t t;
    static AsyncSocketSingleton *sharedSingleton = nil;
    dispatch_once(&t, ^{
        sharedSingleton = [[AsyncSocketSingleton alloc] init];
    });
    return sharedSingleton;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        sock = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        return self;
    }
    return nil;
}

+ (NSData *)CRLFCRLFData {
    return [NSData dataWithBytes:"\x0D\x0A\x0D\x0A" length:4];
}

+ (NSData *)CRLFData {
    return [NSData dataWithBytes:"\x0D\x0A" length:2];
}

- (void)sendWebsocketHandshake {
    NSMutableString *header = [[NSMutableString alloc] init];
    
    [header appendString:@"GET /socket.io/1/websocket/"];
//    [header appendString:_sessionId];
    [header appendString:@" HTTP/1.1\r\n"];
    [header appendString:[NSString stringWithFormat:@"Host: %@\r\n", SOCKET_HOST]];
    [header appendString:@"Upgrade: websocket\r\n"];
    [header appendString:@"Connection: Upgrade\r\n"];
    [header appendString:@"Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n"];
    [header appendString:[NSString stringWithFormat:@"Origin: http://%@\r\n", SOCKET_HOST]];
    [header appendString:@"Sec-WebSocket-Version: 13\r\n\r\n"];
    
    [sock writeData:[header dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:-1];
}

- (void)handshakeIsComplete {
    // set up socket to read the first 16 bits of the next message
    [sock readDataToLength:2 withTimeout:-1 tag:WEBSOCKET_MESSAGE_HEADER];
    
    _heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:_timeout - 5 target:self selector:@selector(sendHeartbeat) userInfo:nil repeats:YES];
}

- (void)connect {
    NSError *err = nil;
    if (![sock connectToHost:SOCKET_HOST onPort:SOCKET_PORT error:&err]) { // Asynchronous!
        // If there was an error, it's likely something like "already connected" or "no delegate set"
        NSLog(@"I goofed: %@", err);
    }
}

- (void)disconnect {
    [sock disconnectAfterReadingAndWriting];
}

- (void)sendHeartbeat {
    [self sendMessage:@"2::"];
    NSLog(@"send heartbeat");
    
}

- (void)read {
    [sock readDataWithTimeout:-1 tag:1];
}

- (void)sendMessage:(NSString *)messageString {
    size_t payloadLength = [messageString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    uint32_t maskKey = arc4random();
    
    uint8_t firstByte = 0b10000001; // text frame
    uint8_t secondByte = 0b10000000; // just preparing with mask bit = 1
    
    [sock writeData:[NSData dataWithBytes:&firstByte length:1] withTimeout:-1 tag:-1];
    
    if (payloadLength <= 125) {
        secondByte += payloadLength;
    }
    
    [sock writeData:[NSData dataWithBytes:&secondByte length:1] withTimeout:-1 tag:-1];
    
    NSData *payload = [self maskString:messageString withMask:maskKey];
    //    maskKey = CFSwapInt32HostToBig(maskKey);
    [sock writeData:[NSData dataWithBytes:&maskKey length:4] withTimeout:-1 tag:-1];
    [sock writeData:payload withTimeout:-1 tag:-1];
}

- (NSData *)maskString:(NSString *)string withMask:(uint32_t)mask {
    NSData *unmaskedData = [string dataUsingEncoding:NSUTF8StringEncoding];
    size_t payloadLength = unmaskedData.length;
    uint8_t payload[payloadLength];
    [unmaskedData getBytes:payload length:payloadLength];
    
    uint8_t maskArray[4];
    maskArray[0] = mask & 0xFF;
    maskArray[1] = (mask >> 8) & 0xFF;
    maskArray[2] = (mask >> 16) & 0xFF;
    maskArray[3] = (mask >> 24) & 0xFF;
    
    for (size_t i = 0; i < payloadLength; i++) {
        payload[i] ^= maskArray[i % 4];
    }
    
    return [NSData dataWithBytes:payload length:payloadLength];
}

#pragma mark - Delegate Methods

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"Did connect.");
    
    [sock readDataToData:[AsyncSocketSingleton CRLFCRLFData] withTimeout:-1 tag: SOCKETIO_HANDSHAKE_HEADER];
    
    NSURL *handshakeURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d/socket.io/1?transport=polling&b64=1", host, port]];
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *delegateFreeSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate: nil delegateQueue:[NSOperationQueue mainQueue]];
    
    [[delegateFreeSession dataTaskWithURL:handshakeURL
                        completionHandler:^(NSData *data, NSURLResponse *response,
                                            NSError *error) {
                            NSString *token = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] componentsSeparatedByString:@":"];
                            NSLog(@"Got response %@ with error %@.\n", response, error);
                            NSLog(@"DATA:\n%@\nEND DATA\n", [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]);
                        }] resume];
    
//    [sock writeData:[header dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:-1];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"Did disconnect.");
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (tag == SOCKETIO_HANDSHAKE_HEADER) { // handshake response, chunked transfer-encoding!
        
        NSRange range;
        range.location = 0;
        range.length = data.length - 4; // get rid of \r\n\r\n
        NSString *headerString = [[NSString alloc] initWithData:[data subdataWithRange:range] encoding:NSASCIIStringEncoding];
        
        NSLog(@"socket.io handshake header:\r\n===\r\n%@\r\n===",headerString);
        [sock readDataToData:[AsyncSocketSingleton CRLFData] withTimeout:-1 tag:SOCKETIO_HANDSHAKE_CHUNKSIZE];
        
    } else if (tag == SOCKETIO_HANDSHAKE_CHUNKSIZE) { // length of first chunk, string representation of hex value
        NSRange range;
        range.location = 0;
        range.length = data.length - 2; // get rid of \r\n
        NSString *lengthString = [[NSString alloc] initWithData:[data subdataWithRange:range] encoding:NSASCIIStringEncoding];
        
        NSUInteger length;
        NSScanner *scanner = [NSScanner scannerWithString:lengthString];
        [scanner scanHexInt:&length];
        
        NSLog(@"length of next chunk: %lu",(unsigned long)length);
        [sock readDataToLength:length withTimeout:-1 tag:2];
        
    } else if (tag == SOCKETIO_HANDSHAKE_BODY) { // should be the handshake response from the socket.io server
        
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        NSLog(@"socket.io handshake body: %@",responseString);
        NSArray *responseComponents = [responseString componentsSeparatedByString:@":"];
        _sessionId = [responseComponents objectAtIndex:0];
        _timeout = [((NSString *)[responseComponents objectAtIndex:1]) integerValue];
        NSLog(@"socket.io handshake complete: session id is %@, timeout is %lu",_sessionId,(unsigned long)_timeout);
        [sock readDataToLength:7 withTimeout:-1 tag:-1]; // read seven more bytes (which is \r\n0\r\n\r\n) and discard them
        [sock readDataToData:[AsyncSocketSingleton CRLFCRLFData] withTimeout:-1 tag:WEBSOCKET_HANDSHAKE_HEADER];
        [self sendWebsocketHandshake];
        
    } else if (tag == WEBSOCKET_HANDSHAKE_HEADER) {
        NSRange range;
        range.location = 0;
        range.length = data.length - 4; // get rid of \r\n\r\n
        NSString *headerString = [[NSString alloc] initWithData:[data subdataWithRange:range] encoding:NSASCIIStringEncoding];
        NSLog(@"websocket handshake complete:\r\n===\r\n%@\r\n===",headerString);
        [self handshakeIsComplete];
        
    } else if (tag == WEBSOCKET_MESSAGE_HEADER) {
        
        char firstByte;
        char secondByte;
        [data getBytes:&firstByte range:NSMakeRange(0, 1)];
        [data getBytes:&secondByte range:NSMakeRange(1, 1)];
        
        // check fin bit
        char fin = (firstByte & 0b10000000) << 7;
        NSLog(@"fin bit: %d",fin);
        
        // check rsv1 bit
        char rsv1 = (firstByte & 0b01000000) << 6;
        NSLog(@"rsv1 bit: %d",rsv1);
        
        // check rsv2 bit
        char rsv2 = (firstByte & 0b00100000) << 5;
        NSLog(@"rsv2 bit: %d",rsv2);
        
        // check rsv3 bit
        char rsv3 = (firstByte & 0b00010000) << 4;
        NSLog(@"rsv1 bit: %d",rsv3);
        
        // check opcode
        char opcode;
        opcode = (firstByte & 0b00001111);
        NSLog(@"opcode: %d",opcode);
        
        // check mask
        char mask = (secondByte & 0b10000000) << 7;
        NSLog(@"mask bit: %d",mask);
        
        // TODO: when the mask bit is set to 1, we have to read the mask key from the stream!
        
        // check payload length
        char payloadLength;
        payloadLength = (secondByte & 0b01111111);
        NSLog(@"payload length: %d",payloadLength);
        
        switch (payloadLength) {
            case 126:
                [sock readDataToLength:2 withTimeout:-1 tag:WEBSOCKET_MESSAGE_EXTENDED_HEADER];
                break;
            case 127:
                [sock readDataToLength:8 withTimeout:-1 tag:WEBSOCKET_MESSAGE_EXTENDED_HEADER];
                break;
            default:
                [sock readDataToLength:payloadLength withTimeout:-1 tag:WEBSOCKET_MESSAGE_CONTENT];
                break;
        }
        
    } else if (tag == WEBSOCKET_MESSAGE_CONTENT) {
        
        NSString *messageContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"message content:\r\n===\r\n%@\r\n===",messageContent);
        [sock readDataToLength:2 withTimeout:-1 tag:WEBSOCKET_MESSAGE_HEADER]; // here we go again.
    } else {
        NSString *discardableStuff = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        NSLog(@"discard:\r\n===\r\n%@\r\n===",discardableStuff);
    }
}

@end