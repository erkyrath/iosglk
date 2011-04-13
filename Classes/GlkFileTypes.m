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

- (id) initWithUsage:(glui32)usageval fmode:(glui32)fmodeval dirname:(NSString *)dirnameval {
	self = [super init];
	
	if (self) {
		usage = usageval;
		fmode = fmodeval;
		self.dirname = dirnameval;
		self.filename = nil;
	}
	
	return self;
}

- (void) dealloc {
	self.dirname = nil;
	self.filename = nil;
	[super dealloc];
}

@end

@implementation GlkFileThumb

@synthesize label;
@synthesize pathname;

@end

