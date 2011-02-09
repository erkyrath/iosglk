/* GlkWindow.m: Window objc class (and subclasses)
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "GlkLibrary.h"
#import "GlkWindow.h"
#import "GlkStream.h"
#import "GlkUtilTypes.h"

@implementation GlkWindow

@synthesize library;
@synthesize tag;
@synthesize type;
@synthesize rock;
@synthesize parent;
@synthesize char_request;
@synthesize line_request;
@synthesize style;
@synthesize stream;
@synthesize echostream;
@synthesize bbox;

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
			[GlkLibrary strictWarning:@"window_open: cannot open pair window directly"];
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
		self.library = [GlkLibrary singleton];
		inlibrary = YES;
		
		self.tag = [library newTag];
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
		
		self.stream = [[[GlkStreamWindow alloc] initWithWindow:self] autorelease];
		self.echostream = nil;
		
		[library.windows addObject:self];
		
		if (library.dispatch_register_obj)
			disprock = (*library.dispatch_register_obj)(self, gidisp_Class_Window);
	}
	
	return self;
}

- (void) dealloc {
	NSLog(@"GlkWindow dealloc %x", self);
	
	if (inlibrary)
		[NSException raise:@"GlkException" format:@"GlkWindow reached dealloc while in library"];
	if (!type)
		[NSException raise:@"GlkException" format:@"GlkWindow reached dealloc with type unset"];
	type = 0;
	if (!tag)
		[NSException raise:@"GlkException" format:@"GlkWindow reached dealloc with tag unset"];
	self.tag = nil;
	
	self.stream = nil;
	self.echostream = nil;
	self.parent = nil;
	
	self.library = nil;

	[super dealloc];
}

- (void) windowCloseRecurse:(BOOL)recurse {
	/* We don't want this object to evaporate in the middle of this method. */
	[[self retain] autorelease];
	
	//### subclasses: gidispa unregister inbuf
	
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

	if (library.dispatch_unregister_obj)
		(*library.dispatch_unregister_obj)(self, gidisp_Class_Window, disprock);
		
	if (stream) {
		[stream streamDelete];
		self.stream = nil;
	}
	self.echostream = nil;
	self.parent = nil;
	
	if (![library.windows containsObject:self])
		[NSException raise:@"GlkException" format:@"GlkWindow was not in library windows list"];
	[library.windows removeObject:self];
	inlibrary = NO;
}

+ (void) unEchoStream:(strid_t)str {
	GlkLibrary *library = [GlkLibrary singleton];
	for (GlkWindow *win in library.windows) {
		if (win.echostream == str)
			win.echostream = nil;
	}
}

- (void) windowRearrange:(CGRect)box {
	[NSException raise:@"GlkException" format:@"windowRearrange: not implemented"];
}

/* For non-text windows, we do nothing. The text window classes will override this method.*/
- (void) putString:(NSString *)str {
}

- (void) putBuffer:(char *)buf len:(glui32)len {
	if (!len)
		return;
	
	/* Turn the buffer into an NSString. We'll release this at the end of the function. */
	NSString *str = [[NSString alloc] initWithBytes:buf length:len encoding:NSISOLatin1StringEncoding];
	[self putString:str];	
	[str release];
}

- (void) putUBuffer:(glui32 *)buf len:(glui32)len {
	if (!len)
		return;
	
	/* Turn the buffer into an NSString. We'll release this at the end of the function. 
		This is an endianness dependency; we're telling NSString that our array of 32-bit words in stored little-endian. (True for all iOS, as I write this.) */
	NSString *str = [[NSString alloc] initWithBytes:buf length:len*sizeof(glui32) encoding:NSUTF32LittleEndianStringEncoding];
	[self putString:str];	
	[str release];
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

- (void) windowRearrange:(CGRect)box {
	bbox = box;
	//### count on-screen lines, maybe
}

- (void) putString:(NSString *)str {
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

@synthesize dir;
@synthesize division;
@synthesize key;
@synthesize keydamage;
@synthesize size;
@synthesize hasborder;
@synthesize vertical;
@synthesize backward;
@synthesize child1;
@synthesize child2;

- (id) initWithMethod:(glui32)method keywin:(GlkWindow *)keywin size:(glui32)initsize {
	self = [super initWithType:wintype_Pair rock:0];
	
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

struct temp_metrics_struct {
	CGFloat buffercharwidth, buffercharheight;
	CGFloat buffermarginx, buffermarginy;
	CGFloat gridcharwidth, gridcharheight;
	CGFloat gridmarginx, gridmarginy;
} content_metrics = {
	10, 14, 0, 0,
	10, 14, 0, 0,
};

- (void) windowRearrange:(CGRect)box {
	CGFloat min, max, diff;
	
	bbox = box;

	if (vertical) {
		min = bbox.origin.x;
		max = min + bbox.size.width;
		splitwid = 4; //content_metrics.inspacingx;
	}
	else {
		min = bbox.origin.y;
		max = min + bbox.size.height;
		splitwid = 4; //content_metrics.inspacingy;
	}
	if (!hasborder)
		splitwid = 0;
	diff = max - min;

	if (division == winmethod_Proportional) {
		split = floorf((diff * size) / 100.0);
	}
	else if (division == winmethod_Fixed) {
		split = 0;
		if (key && key.type == wintype_TextBuffer) {
			if (!vertical)
				split = (size * content_metrics.buffercharheight + content_metrics.buffermarginy);
			else
				split = (size * content_metrics.buffercharwidth + content_metrics.buffermarginx);
		}
		if (key && key.type == wintype_TextGrid) {
			if (!vertical)
				split = (size * content_metrics.gridcharheight + content_metrics.gridmarginy);
			else
				split = (size * content_metrics.gridcharwidth + content_metrics.gridmarginx);
		}
		split = ceilf(split);
	}
	else {
		/* default behavior for unknown division method */
		split = floorf(diff / 2);
	}

	/* Split is now a number between 0 and diff. Convert that to a number
	   between min and max; also apply upside-down-ness. */
	if (!backward) {
		split = max-split-splitwid;
	}
	else {
		split = min+split;
	}

	/* Make sure it's really between min and max. */
	if (min >= max) {
		split = min;
	}
	else {
		split = fminf(fmaxf(split, min), max-splitwid);
	}
	
	CGRect box1 = bbox;
	CGRect box2 = bbox;

	if (vertical) {
		box1.size.width = split - bbox.origin.x;
		box2.origin.x = split + splitwid;
		box2.size.width = (bbox.origin.x+bbox.size.width) - box2.origin.x;
	}
	else {
		box1.size.height = split - bbox.origin.y;
		box2.origin.y = split + splitwid;
		box2.size.height = (bbox.origin.y+bbox.size.height) - box2.origin.y;
	}
	
	GlkWindow *ch1, *ch2;

	if (!backward) {
		ch1 = child1;
		ch2 = child2;
	}
	else {
		ch1 = child2;
		ch2 = child1;
	}

	[ch1 windowRearrange:box1];
	[ch2 windowRearrange:box2];
}

@end


