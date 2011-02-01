//
//  GlkWindow.m
//  IosGlk
//
//  Created by Andrew Plotkin on 1/28/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import "GlkLibrary.h"
#import "GlkWindow.h"
#import "GlkStream.h"
#import "GlkUtilTypes.h"

@implementation GlkWindow

@synthesize library;
@synthesize type;
@synthesize parent;
@synthesize style;
@synthesize stream;
@synthesize echostream;

static NSCharacterSet *newlineCharSet; /* retained forever */

+ (void) initialize {
	newlineCharSet = [[NSCharacterSet characterSetWithCharactersInString:@"\n"] retain];
}

+ (GlkWindow *) windowWithType:(glui32)type rock:(glui32)rock {
	GlkWindow *win;
	switch (type) {
		case wintype_TextBuffer:
			win = [[[GlkWindowBuffer alloc] initWithType:type rock:rock] autorelease];
			break;
		case wintype_Pair:
			/* You can't create a pair window this way. */
			[GlkLibrary strict_warning:@"window_open: cannot open pair window directly"];
			win = nil;
			break;
		default:
			/* Unknown window type -- do not print a warning, just return nil to indicate that it's not possible. */
			win = nil;
			break;
	}
	return win;
}

- (id) initWithType:(glui32)wintype rock:(glui32)winrock {
	self = [super init];
	
	if (self) {
		library = [GlkLibrary singleton];
		
		type = wintype;
		rock = winrock;
		
		parent = nil;
		char_request = NO;
		line_request = NO;
		char_request_uni = NO;
		line_request_uni = NO;
		echo_line_input = YES;
		//terminate_line_input = 0;
		style = style_Normal;
		
		self.stream = [GlkStream openForWindow:self];
		echostream = nil;
		
		[library.windows addObject:self];
		
		//### gidispa add self
	}
	
	return self;
}

- (void) dealloc {
	self.stream = nil;
	self.echostream = nil;
	self.parent = nil;
	
	self.library = nil;

	[super dealloc];
}

- (void) delete {
	//### gidispa remove self
		
	if (stream) {
		[stream delete];
		self.stream = nil;
	}
	self.echostream = nil;
	self.parent = nil;
	
	if (![library.windows containsObject:self])
		[NSException raise:@"GlkException" format:@"GlkWindow was not in library windows list"];
	[library.windows removeObject:self];
}

- (void) windowCloseRecurse:(BOOL)recurse {	
	for (GlkWindowPair *wx=self.parent; wx; wx=wx.parent) {
		if (wx.type == wintype_Pair) {
			if (wx.key == self) {
				wx.key = nil;
				wx.keydamage = YES;
			}
		}
	}
	
	if (recurse && type == wintype_Pair) {
		GlkWindowPair *pwx = (GlkWindowPair *)self;
		if (pwx.child1)
			[pwx.child1 windowCloseRecurse:YES];
		if (pwx.child2)
			[pwx.child2 windowCloseRecurse:YES];
	}

	[self delete];
}

@end

@implementation GlkWindowBuffer

@synthesize updatetext;

- (id) initWithType:(glui32)wintype rock:(glui32)winrock {
	self = [super initWithType:wintype rock:winrock];
	
	if (self) {
		self.updatetext = [NSMutableArray arrayWithCapacity:32];
	}
	
	return self;
}

- (void) dealloc {
	self.updatetext = nil;
	[super dealloc];
}

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
		if (laststr && laststr.style == style) {
			[laststr appendString:ln];
		}
		else {
			GlkStyledString *newstr = [[[GlkStyledString alloc] initWithText:ln style:style] autorelease];
			[lastsln.arr addObject:newstr];
		}
	}
}


@end


@implementation GlkWindowPair

@synthesize child1;
@synthesize child2;
@synthesize key;
@synthesize keydamage;

- (id) initWithType:(glui32)wintype rock:(glui32)winrock method:(glui32)method keywin:(GlkWindow *)keywin size:(glui32)initsize {
	self = [super initWithType:wintype rock:winrock];
	
	if (self) {
		dir = method & winmethod_DirMask;
		division = method & winmethod_DivisionMask;
		hasborder = ((method & winmethod_BorderMask) == winmethod_Border);
		self.key = keywin;
		keydamage = FALSE;
		size = initsize;

		vertical = (dir == winmethod_Left || dir == winmethod_Right);
		backward = (dir == winmethod_Left || dir == winmethod_Above);

		self.child1 = nil;
		self.child2 = nil;
	}
	
	return self;
}

- (void) dealloc {
	self.key = nil;
	self.child1 = nil;
	self.child2 = nil;
	[super dealloc];
}


@end


