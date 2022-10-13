/* RelDateFormatter.h: Date formatter subclass with relative times
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/* This is a simple subclass of NSDateFormatter which has one tweak: if the NSDate is less than twelve hours old, the time printed is of the form "10 seconds ago" or "2 hours, 10 minutes ago". (These strings are not currently localized.) Dates in the future are formatted normally.

	The class also defaults to doesRelativeDateFormatting, so dates more than twelve hours old can appear as "today" or "yesterday".	
*/

#import "RelDateFormatter.h"


@implementation RelDateFormatter

- (instancetype) init {
	self = [super init];
	if (self) {
		[self setDoesRelativeDateFormatting:YES];
	}
	return self;
}

- (NSString *) stringFromDate:(NSDate *)date {
	NSTimeInterval interval = -date.timeIntervalSinceNow;
	if (interval < 0 || interval >= 12*60*60) {
		return [super stringFromDate:date];
	}
	
	if (interval < 60) {
		long sec = (int)interval;
		return [NSString stringWithFormat:@"%ld second%s ago", sec, ((sec==1)?"":"s")];
	}
	
	if (interval < 60*60) {
		long min = (int)(interval / 60);
		interval -= min*60;
		long sec = (int)interval;
		if (!sec)
			return [NSString stringWithFormat:@"%ld minute%s ago", min, ((min==1)?"":"s")];
		else
			return [NSString stringWithFormat:@"%ld minute%s, %ld second%s ago", min, ((min==1)?"":"s"), sec, ((sec==1)?"":"s")];
	}
	
	if (1) {
		interval /= 60;
		long hour = (int)(interval / 60);
		interval -= hour*60;
		long min = (int)interval;
		if (!min)
			return [NSString stringWithFormat:@"%ld hour%s ago", hour, ((hour==1)?"":"s")];
		else
			return [NSString stringWithFormat:@"%ld hour%s, %ld minute%s ago", hour, ((hour==1)?"":"s"), min, ((min==1)?"":"s")];
	}
}

@end
