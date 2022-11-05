/* GlkUtilTypes.m: Miscellaneous objc classes
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	Some utility classes that are small and boring and don't fit anywhere else.
*/

#import "GlkUtilTypes.h"
#import "GlkAccessTypes.h"

@implementation GlkTagString

@synthesize tag;
@synthesize str;

- (instancetype) initWithTag:(NSNumber *)tagval text:(NSString *)strval {
	self = [super init];
	
	if (self) {
		self.tag = tagval;
		self.str = strval;
	}
	
	return self;
}


@end



