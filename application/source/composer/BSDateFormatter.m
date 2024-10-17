//
//  BSDateFormatter.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 06/12/05.
//  Copyright 2006-2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSDateFormatter.h"
#import <CocoMonar/CMRSingletonObject.h>

@implementation BSDateFormatter
@synthesize usesRelativeDateFormat = m_usesRelativeDateFormat;

APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(sharedDateFormatter);

- (NSString *)niceStringFromDate:(NSDate *)date useTab:(BOOL)flag
{
	static CFDateFormatterRef	timFmtRef;
	static CFDateFormatterRef	dayFmtRef;
    static BOOL currentSettingsForRelativeDateFormat;
	NSString	*result_ = nil;
	NSString	*dayStr_ = nil;
	NSString	*format;

    CFStringRef			dayStrRef;

    if ((dayFmtRef == NULL) || (self.usesRelativeDateFormat != currentSettingsForRelativeDateFormat)) {
        if (dayFmtRef != NULL) {
            CFRelease(dayFmtRef);
            dayFmtRef = NULL;
        }
        CFLocaleRef	localeRef = CFLocaleCopyCurrent();
        dayFmtRef = CFDateFormatterCreate(kCFAllocatorDefault, localeRef, kCFDateFormatterShortStyle, kCFDateFormatterNoStyle);
        CFRelease(localeRef);
        CFDateFormatterSetProperty(dayFmtRef, kCFDateFormatterDoesRelativeDateFormattingKey, (self.usesRelativeDateFormat ? kCFBooleanTrue : kCFBooleanFalse));
        currentSettingsForRelativeDateFormat = self.usesRelativeDateFormat;
    }

    dayStrRef = CFDateFormatterCreateStringWithDate(kCFAllocatorDefault, dayFmtRef, (CFDateRef)date);

    if (dayStrRef != NULL) {
        dayStr_ = [NSString stringWithString:(NSString *)dayStrRef];
        CFRelease(dayStrRef);
    }

	if (timFmtRef == NULL) {
		CFLocaleRef	localeRef2 = CFLocaleCopyCurrent();
		timFmtRef = CFDateFormatterCreate(kCFAllocatorDefault, localeRef2, kCFDateFormatterNoStyle, kCFDateFormatterShortStyle);
		CFRelease(localeRef2);
	}

	CFStringRef			timStrRef = CFDateFormatterCreateStringWithDate(kCFAllocatorDefault, timFmtRef, (CFDateRef)date);

	if (timStrRef == NULL) {
		return nil;
	}
	format = flag ? @"%@\t%@" : @"%@ %@";
	result_ = [NSString stringWithFormat:format, dayStr_, (NSString *)timStrRef];

	CFRelease(timStrRef);
	
	return result_;
}

- (NSString *)stringForObjectValue:(id)anObject
{
	if (![anObject isKindOfClass:[NSDate class]]) {
		return nil;
	}
	return [self niceStringFromDate:anObject useTab:NO];
}

- (NSAttributedString *)attributedStringForObjectValue:(id)anObject withDefaultAttributes:(NSDictionary *)attributes
{
	if (![anObject isKindOfClass:[NSDate class]]) {
		return nil;
	}
	NSString *stringValue = [self niceStringFromDate:anObject useTab:YES];
	if (!stringValue) return nil;

	return [[[NSAttributedString alloc] initWithString:stringValue attributes:attributes] autorelease];
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error
{
	*error = @"BSDateFormatter does not support reverse conversion.";
	return NO;
}

- (NSDate *)baseDateOfToday
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:[NSDate date]];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];
    return [calendar dateFromComponents:components];
}
@end


@implementation BSStringFromDateTransformer
+ (Class)transformedValueClass
{
    return [NSString class];
}
 
+ (BOOL)allowsReverseTransformation
{
    return NO;
}
 
- (id)transformedValue:(id)beforeObject
{
	NSString	*stringValue = nil;

	if (beforeObject) {
		if ([beforeObject isKindOfClass:[NSDate class]]) {
			stringValue = [[BSDateFormatter sharedDateFormatter] niceStringFromDate:beforeObject useTab:NO];
		} else {
			[NSException raise:NSInternalInconsistencyException
						format:@"Value (%@) is not an instance of NSDate.", [beforeObject class]];
		}
	}

	return stringValue;
}
@end
