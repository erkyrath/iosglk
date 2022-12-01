/* GlkEventState.h
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import "GlkEventState.h"

@implementation GlkEventState

@synthesize type;
@synthesize ch;
@synthesize genval1;
@synthesize genval2;
@synthesize line;
@synthesize tag;

+ (GlkEventState *) charEvent:(glui32)ch inWindow:(NSNumber *)tag {
    GlkEventState *event = [[GlkEventState alloc] init];
    event.type = evtype_CharInput;
    event.tag = tag;
    event.ch = ch;
    return event;
}

+ (GlkEventState *) lineEvent:(NSString *)line inWindow:(NSNumber *)tag {
    GlkEventState *event = [[GlkEventState alloc] init];
    event.type = evtype_LineInput;
    event.tag = tag;
    event.line = line;
    return event;
}

+ (GlkEventState *) timerEvent {
    GlkEventState *event = [[GlkEventState alloc] init];
    event.type = evtype_Timer;
    return event;
}

@end
