/* GlkWindowState.m: A class (and subclasses) that encapsulates all the UI-important state of a window
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import "GlkWindowState.h"
#import "GlkLibrary.h"

@implementation GlkWindowState

@synthesize library;
@synthesize type;
@synthesize rock;
@synthesize styleset;
@synthesize bbox;
@synthesize tag;
@synthesize input_request_id;
@synthesize char_request;
@synthesize line_request;
@synthesize line_request_initial;

+ (GlkWindowState *) windowStateWithType:(glui32)type rock:(glui32)rock {
	GlkWindowState *state = nil;
	
	switch (type) {
		case wintype_TextBuffer:
			state = [[[GlkWindowBufferState alloc] initWithType:type rock:rock] autorelease];
			break;
		case wintype_TextGrid:
			state = [[[GlkWindowGridState alloc] initWithType:type rock:rock] autorelease];
			break;
		case wintype_Pair:
			state = [[[GlkWindowPairState alloc] initWithType:type rock:rock] autorelease];
			break;
		default:
			[GlkLibrary strictWarning:@"windowStateWithType: unknown type"];
			break;
			return nil;
	}
	
	return state;
}

- (id) initWithType:(glui32)typeval rock:(glui32)rockval {
	self = [super init];
	if (self) {
		type = typeval;
		rock = rockval;
	}
	return self;
}

- (void) dealloc {
	self.library = nil;
	self.tag = nil;
	self.styleset = nil;
	self.line_request_initial = nil;
	[super dealloc];
}


@end


@implementation GlkWindowGridState

@synthesize lines;
@synthesize width;
@synthesize height;
@synthesize curx;
@synthesize cury;

- (void) dealloc {
	self.lines = nil;
	[super dealloc];
}

@end


@implementation GlkWindowBufferState

@synthesize lines;
@synthesize linesdirtyfrom;
@synthesize linesdirtyto;
@synthesize clearcount;

- (void) dealloc {
	self.lines = nil;
	[super dealloc];
}

@end


@implementation GlkWindowPairState

@synthesize geometry;

- (void) dealloc {
	self.geometry = nil;
	[super dealloc];
}

@end


