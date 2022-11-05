/* GlkWindowState.m: A class (and subclasses) that encapsulates all the UI-important state of a window
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import "GlkWindowState.h"
#import "GlkLibrary.h"

@implementation GlkWindowState

+ (GlkWindowState *) windowStateWithType:(glui32)type rock:(glui32)rock {
	GlkWindowState *state = nil;
	
	switch (type) {
		case wintype_TextBuffer:
			state = [[GlkWindowBufferState alloc] initWithType:type rock:rock];
			break;
		case wintype_TextGrid:
			state = [[GlkWindowGridState alloc] initWithType:type rock:rock];
			break;
		case wintype_Pair:
			state = [[GlkWindowPairState alloc] initWithType:type rock:rock];
			break;
		default:
			[GlkLibrary strictWarning:@"windowStateWithType: unknown type"];
			break;
			return nil;
	}
	
	return state;
}

- (instancetype) initWithType:(glui32)typeval rock:(glui32)rockval {
	self = [super init];
	if (self) {
		_type = typeval;
		_rock = rockval;
	}
	return self;
}

- (void) dealloc {
	self.library = nil;
}


@end


@implementation GlkWindowGridState
@end


@implementation GlkWindowBufferState
@end


@implementation GlkWindowPairState
@end


