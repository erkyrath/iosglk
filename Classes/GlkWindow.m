//
//  GlkWindow.m
//  IosGlk
//
//  Created by Andrew Plotkin on 1/28/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import "GlkWindow.h"
#import "GlkUtilTypes.h"

@implementation GlkWindowBase

static NSCharacterSet *newlineCharSet; /* retained forever */

+ (void) initialize {
	newlineCharSet = [[NSCharacterSet characterSetWithCharactersInString:@"\n"] retain];
}

+ (GlkWindowBase *) windowWithType:(glui32)type rock:(glui32)rock {
	GlkWindowBase *win;
	win = [[[GlkWindowBuffer alloc] initWithType:type rock:rock] autorelease];
	return win;
}

- (id) initWithType:(glui32)type rock:(glui32)rock {
	self = [super init];
	
	if (self) {
		curstyle = style_Normal;
	}
	
	return self;
}

- (void) dealloc {
	[super dealloc];
}

- (void) put_string:(char *)cstr {
}

@end

@implementation GlkWindowBuffer

@synthesize updatetext;
//@synthesize uncapturedtext;

- (id) initWithType:(glui32)type rock:(glui32)rock {
	self = [super initWithType:type rock:rock];
	
	if (self) {
		//uncapturedstyle = -1;
		self.updatetext = [NSMutableArray arrayWithCapacity:32];
		//self.uncapturedtext = [NSMutableArray arrayWithCapacity:64];
	}
	
	return self;
}

- (void) dealloc {
	self.updatetext = nil;
	//self.uncapturedtext = nil;
	[super dealloc];
}

/*
- (void) captureText {
	NSString *joinstr = [uncapturedtext componentsJoinedByString:@""];
	GlkStyledString *stystr = [[[GlkStyledString alloc] initWithText:joinstr style:uncapturedstyle] autorelease];
	[updatetext addObject:stystr];
	[uncapturedtext removeAllObjects];
	uncapturedstyle = -1;
}
*/

- (void) put_string:(char *)cstr {
	NSString *str = [NSString stringWithCString:cstr encoding:NSISOLatin1StringEncoding];
	if (!str.length)
		return;
		
	//NSRange range = [str rangeOfCharacterFromSet:newlineCharSet];
	
	NSArray *linearr = [str componentsSeparatedByCharactersInSet:newlineCharSet];
	BOOL isfirst = YES;
	for (NSString *ln in linearr) {
		if (isfirst) {
			isfirst = NO;
		}
		else {
			/* The very first line was a paragraph continuation, but this is a succeeding line, so it's the start of a new paragraph. */
			GlkStyledLine *sln = [[[GlkStyledLine alloc] initWithStatus:linestat_NewLine] autorelease];
			[updatetext addObject:sln];
		}
		
		if (ln.length == 0) {
			/* This line has no content. (We've already added the new paragraph.) */
			continue;
		}
		
		GlkStyledLine *lastsln = [updatetext lastObject];
		if (!lastsln) {
			lastsln = [[[GlkStyledLine alloc] initWithStatus:linestat_Continue] autorelease];
			[updatetext addObject:lastsln];
		}
		
		GlkStyledString *laststr = [lastsln.arr lastObject];
		if (laststr && laststr.style == curstyle) {
			[laststr appendString:ln];
		}
		else {
			GlkStyledString *newstr = [[[GlkStyledString alloc] initWithText:ln style:curstyle] autorelease];
			[lastsln.arr addObject:newstr];
		}
	}
	
	/*###
	if (uncapturedtext.count && uncapturedstyle != curstyle) {
		[self captureText];
	}
	
	uncapturedstyle = curstyle;
	[uncapturedtext addObject:str];
	###*/
}


@end

