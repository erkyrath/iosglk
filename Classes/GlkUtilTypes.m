/* GlkUtilTypes.m: Miscellaneous objc classes
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "GlkUtilTypes.h"

@implementation GlkStyledLine

@synthesize status;
@synthesize arr;

- (id) initWithStatus:(GlkStyledLineStatus) initstatus {
	self = [super init];
	
	if (self) {
		status = initstatus;
		self.arr = [NSMutableArray arrayWithCapacity:16];
	}
	
	return self;
}

- (id) init {
	return [self initWithStatus:linestat_Continue];
}

- (void) dealloc {
	self.arr = nil;
	[super dealloc];
}

@end


@implementation GlkStyledString

@synthesize str;
@synthesize style;

- (id) initWithText:(NSString *)initstr style:(glui32)initstyle {
	self = [super init];
	
	if (self) {
		self.str = initstr;
		style = initstyle;
		ismutable = NO;
	}
	
	return self;
}

- (void) dealloc {
	self.str = nil;
	[super dealloc];
}

- (void) appendString:(NSString *)newstr {
	if (!ismutable) {
		self.str = [NSMutableString stringWithString:str];
		ismutable = YES;
	}
	[(NSMutableString*)str appendString:newstr];
}

- (void) freeze {
	if (ismutable) {
		self.str = [NSString stringWithString:str];
		ismutable = NO;
	}
}

@end
