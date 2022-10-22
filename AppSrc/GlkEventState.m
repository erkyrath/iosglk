//
//  GlkEventState.m
//  iosglulxe
//
//  Created by Administrator on 2022-10-22.
//

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
