//
//  ChatUtilities.m
//  ChatTest
//
//  Created by WellPledge LLC on 8/20/15.
//  Copyright (c) 2015 Vikas Shah. All rights reserved.
//

#import "ChatUtilities.h"

@implementation ChatUtilities

+ (instancetype)sharedUtilities {
    static dispatch_once_t t;
    static ChatUtilities *sharedSingleton = nil;
    dispatch_once(&t, ^{
        sharedSingleton = [[ChatUtilities alloc] init];
    });
    return sharedSingleton;
}

- (NSString *)relativeStringFromDate:(NSDate *)date {
    if ([self dateIsToday:date])
        return [self dateAsStringTime:date];
    else if ([self dateIsYesterday:date])
        return [self dateAsStringDate:date];
    else if ([self dateIsTwoToSixDaysAgo:date])
        return [self dateAsStringDay:date];
    else
        return [self dateAsStringDate:date];
}

- (BOOL)date:(NSDate *)date
isDayWithTimeIntervalSinceNow:(NSTimeInterval)interval {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd"];
    
    NSDate *other_date;
    other_date = [NSDate dateWithTimeIntervalSinceNow:interval];
    
    NSString *d1, *d2;
    d1 = [df stringFromDate:date];
    d2 = [df stringFromDate:other_date];
    return [d1 isEqualToString:d2];
}

- (BOOL)dateIsToday:(NSDate *)date {
    return [self date:date isDayWithTimeIntervalSinceNow:0];
}

- (BOOL)dateIsYesterday:(NSDate *)date {
    return [self date:date isDayWithTimeIntervalSinceNow:-86400];
}

- (BOOL)dateIsTwoToSixDaysAgo:(NSDate *)date {
    for (int i = 2; i <= 6; i += 1)
        if ([self date:date isDayWithTimeIntervalSinceNow:i*-86400])
            return YES;
    return NO;
}

- (NSString *)dateAsStringDate:(NSDate *)date {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateStyle:NSDateFormatterShortStyle];
    [df setDoesRelativeDateFormatting:YES];
    NSString *str = [df stringFromDate:date];
    return str;
}

- (NSString *)dateAsStringTime:(NSDate *)date {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setTimeStyle:NSDateFormatterShortStyle];
    NSString *str = [df stringFromDate:date];
    return str;
}

- (NSString *)dateAsStringDay:(NSDate *)date {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"EEEE"];
    NSString *str_day = [df stringFromDate:date];
    return str_day;
}

@end
