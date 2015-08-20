//
//  ChatUtilities.h
//  ChatTest
//
//  Created by WellPledge LLC on 8/20/15.
//  Copyright (c) 2015 Vikas Shah. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChatUtilities : NSObject

+ (instancetype)sharedUtilities;
- (NSString *)relativeStringFromDate:(NSDate *)date;

@end
