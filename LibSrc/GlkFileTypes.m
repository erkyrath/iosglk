/* GlkFileTypes.m: Miscellaneous file-related objc classes
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/


#import "GlkFileTypes.h"

@implementation GlkFileRefPrompt

@synthesize usage;
@synthesize fmode;
@synthesize dirname;
@synthesize filename;
@synthesize pathname;

- (id) initWithUsage:(glui32)usageval fmode:(glui32)fmodeval dirname:(NSString *)dirnameval {
	self = [super init];
	
	if (self) {
		usage = usageval;
		fmode = fmodeval;
		self.dirname = dirnameval;
		self.filename = nil;
		self.pathname = nil;
	}
	
	return self;
}

- (void) dealloc {
	self.dirname = nil;
	self.filename = nil;
	self.pathname = nil;
	[super dealloc];
}

@end

@implementation GlkFileThumb

@synthesize label;
@synthesize filename;
@synthesize pathname;
@synthesize usage;
@synthesize modtime;
@synthesize isfake;

+ (NSString *) labelForFileUsage:(glui32)usage localize:(NSString *)key {
	NSString *res = nil;
	
	switch (usage) {
		case fileusage_SavedGame:
			res = @"use.save";
			break;
		case fileusage_Transcript:
			res = @"use.transcript";
			break;
		case fileusage_InputRecord:
			res = @"use.input";
			break;
		case fileusage_Data:
		default:
			res = @"use.data";
	}
	
	if (key) {
		NSString *lockey = [NSString stringWithFormat:@"%@.%@", res, key];
		res = NSLocalizedString(lockey, nil);
	}
	
	return res;
}

- (void) dealloc {
	self.label = nil;
	self.filename = nil;
	self.pathname = nil;
	self.modtime = nil;
	[super dealloc];
}

- (NSComparisonResult) compareModTime:(GlkFileThumb *)other {
	return [other.modtime compare:modtime];
}

@end

