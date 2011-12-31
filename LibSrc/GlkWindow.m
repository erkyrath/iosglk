/* GlkWindow.m: Window objc class (and subclasses)
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	GlkWindow is the base class representing a Glk window. The subclasses represent the window types (textgrid, textbuffer, etc.)

	(The iOS View classes for these window types are GlkWinGridView, GlkWinBufferView, etc.)
	
	The encapsulation isn't very good in this file, because I kept most of the structure of the C Glk implementations -- specifically GlkTerm. The top-level "glk_" functions remained the same, and can be found in GlkWindowLayer.c. The internal "gli_" functions have become methods on the ObjC GlkWindow class. So both layers wind up futzing with GlkWindow internals.
*/

#import "GlkLibrary.h"
#import "GlkWindow.h"
#import "GlkAppWrapper.h"
#import "GlkStream.h"
#import "StyleSet.h"
#import "Geometry.h"
#import "GlkUtilTypes.h"

@implementation GlkWindow
/* GlkWindow: the base class. */

@synthesize library;
@synthesize tag;
@synthesize disprock;
@synthesize type;
@synthesize rock;
@synthesize parent;
@synthesize line_request_initial;
@synthesize input_request_id;
@synthesize char_request;
@synthesize line_request;
@synthesize style;
@synthesize stream;
@synthesize echostream;
@synthesize styleset;
@synthesize bbox;

static NSCharacterSet *newlineCharSet; /* retained forever */

+ (void) initialize {
	/* We need this for breaking up printing strings, so we set it up at class init time. I think this shows up as a memory leak in Apple's tools -- sorry about that. */
	newlineCharSet = [[NSCharacterSet characterSetWithCharactersInString:@"\n"] retain];
}

/* Create a window with a given type. (But not Pair windows -- those use a different path.) This is invoked by glk_window_open().
*/
+ (GlkWindow *) windowWithType:(glui32)type rock:(glui32)rock {
	GlkWindow *win;
	switch (type) {
		case wintype_TextBuffer:
			win = [[[GlkWindowBuffer alloc] initWithType:type rock:rock] autorelease];
			win.styleset = [[[StyleSet alloc] init] autorelease];
			/* Helvetica Neue is not available in iOS 3.1.3! */
			@try {
				[win.styleset setFontFamily:@"Helvetica Neue" size:14.0];
			} @catch (NSException *ex) {
				NSLog(@"Backing off to Helvetica");
				[win.styleset setFontFamily:@"Helvetica" size:14.0];
			}
			break;
		case wintype_TextGrid:
			win = [[[GlkWindowGrid alloc] initWithType:type rock:rock] autorelease];
			win.styleset = [[[StyleSet alloc] init] autorelease];
			[win.styleset setFontFamily:@"Courier" size:14.0];
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

/* GlkWindow designated initializer. */
- (id) initWithType:(glui32)wintype rock:(glui32)winrock {
	self = [super init];
	
	if (self) {
		self.library = [GlkLibrary singleton];
		inlibrary = YES;
		
		self.tag = [library generateTag];
		type = wintype;
		rock = winrock;
		
		parent = nil;
		input_request_id = 0;
		line_request_initial = nil;
		line_buffer = nil;
		char_request = NO;
		line_request = NO;
		char_request_uni = NO;
		line_request_uni = NO;
		echo_line_input = YES;
		//terminate_line_input = 0;
		style = style_Normal;
		
		self.stream = [[[GlkStreamWindow alloc] initWithWindow:self] autorelease];
		self.echostream = nil;
		
		styleset = nil;
		[library.windows addObject:self];
		
		if (library.dispatch_register_obj)
			disprock = (*library.dispatch_register_obj)(self, gidisp_Class_Window);
	}
	
	return self;
}

- (void) dealloc {
	NSLog(@"GlkWindow dealloc %x", (unsigned int)self);
	
	if (inlibrary)
		[NSException raise:@"GlkException" format:@"GlkWindow reached dealloc while in library"];
	if (!type)
		[NSException raise:@"GlkException" format:@"GlkWindow reached dealloc with type unset"];
	type = 0;
	if (!tag)
		[NSException raise:@"GlkException" format:@"GlkWindow reached dealloc with tag unset"];
	self.tag = nil;
	
	self.line_request_initial = nil;
	
	self.stream = nil;
	self.echostream = nil;
	self.parent = nil;
	
	self.styleset = nil;
	self.library = nil;

	[super dealloc];
}

/* Close a window, and perhaps its subwindows too. 
*/
- (void) windowCloseRecurse:(BOOL)recurse {
	/* We don't want this object to evaporate in the middle of this method. */
	[[self retain] autorelease];
	
	if (line_buffer) {
		if (library.dispatch_unregister_arr) {
			char *typedesc = (line_request_uni ? "&+#!Iu" : "&+#!Cn");
			(*library.dispatch_unregister_arr)(line_buffer, line_buffer_length, typedesc, inarrayrock);
		}
	}
	
	for (GlkWindowPair *wx=self.parent; wx; wx=wx.parent) {
		if (wx.type == wintype_Pair) {
			if ([wx.geometry.keytag isEqualToNumber:self.tag]) {
				wx.geometry.keytag = nil;
				wx.geometry.keystyleset = nil;
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

- (void) getWidth:(glui32 *)widthref height:(glui32 *)heightref {
	*widthref = 0;
	*heightref = 0;
}

/* The text-window classes will override this with YES. 
*/
- (BOOL) supportsInput {
	return NO;
}

/* When a stram is closed, we call this to detach it from any windows who have it as their echostream.
*/
+ (void) unEchoStream:(strid_t)str {
	GlkLibrary *library = [GlkLibrary singleton];
	for (GlkWindow *win in library.windows) {
		if (win.echostream == str)
			win.echostream = nil;
	}
}

/* When a window changes size for any reason -- device rotation, or new windows appearing -- this is invoked. (For pair windows, it's recursive.) The argument is the rectangle that the window is given.
*/
- (void) windowRearrange:(CGRect)box {
	[NSException raise:@"GlkException" format:@"windowRearrange: not implemented"];
}

/*	And now the printing methods. All of this are invoked from the printing methods of GlkStreamWindow.

	Note that putChar, putCString, etc have already been collapsed into putBuffer and putUBuffer calls. The text window classes only have to customize those. (The non-text windows just ignore them.)
*/

- (void) putBuffer:(char *)buf len:(glui32)len {
}

- (void) putUBuffer:(glui32 *)buf len:(glui32)len {
}

/* For non-text windows, we do nothing. The text window classes will override this method.*/
- (void) clearWindow {
}

/* Set up the window for character input. (The next updateFromWindowInputs call will make use of this information.)
*/
- (void) beginCharInput:(BOOL)unicode {
	if (![self supportsInput]) {
		[GlkLibrary strictWarning:@"beginCharInput: window does not support keyboard input"];
		return;
	}
	if (char_request || line_request) {
		[GlkLibrary strictWarning:@"beginCharInput: window already has keyboard request"];
		return;
	}
	
	char_request = YES;
	char_request_uni = unicode;
	input_request_id++;
}

/* Complete character input. Returns YES if the window is accepting char input right now. This also changes the character, if necessary, if non-unicode input was requested originally.
*/
- (BOOL) acceptCharInput:(glui32 *)chref {
	if (!char_request)
		return NO;
		
	glui32 ch = *chref;
	if (!char_request_uni && (ch > 0xFF))
		ch = '?';
	*chref = ch;
		
	char_request = NO;
	char_request_uni = NO;
	return YES;
}

- (void) cancelCharInput {
	char_request = NO;
	char_request_uni = NO;
}

/* Set up the window for line input. (The next updateFromWindowInputs call will make use of this information.)
*/
- (void) beginLineInput:(void *)buf unicode:(BOOL)unicode maxlen:(glui32)maxlen initlen:(glui32)initlen {
	if (![self supportsInput]) {
		[GlkLibrary strictWarning:@"beginLineInput: window does not support keyboard input"];
		return;
	}
	if (char_request || line_request) {
		[GlkLibrary strictWarning:@"beginLineInput: window already has keyboard request"];
		return;
	}
	
	line_request = YES;
	line_request_uni = unicode;
	line_buffer = buf;
	line_buffer_length = maxlen;
	input_request_id++;
	
	self.line_request_initial = nil;
	if (initlen) {
		NSString *str;
		if (!unicode)
			str = [[NSString alloc] initWithBytes:buf length:initlen encoding:NSISOLatin1StringEncoding];
		else
			str = [[NSString alloc] initWithBytes:buf length:initlen*sizeof(glui32) encoding:NSUTF32LittleEndianStringEncoding];
		line_request_initial = str; // retained
	}
	
	if (library.dispatch_register_arr) {
		char *typedesc = (line_request_uni ? "&+#!Iu" : "&+#!Cn");
		inarrayrock = (*library.dispatch_register_arr)(line_buffer, maxlen, typedesc);
	}
}

/* Complete line input. Returns the number of characters that were accepted, or -1 if the window is not accepting line input right now.
*/
- (int) acceptLineInput:(NSString *)str {
	int ix, buflen;
	char *buf = NULL;
	glui32 *ubuf = NULL;
	void *vbuf = line_buffer;
	glui32 maxlen = line_buffer_length;
	
	if (!line_buffer || !line_request)
		return -1;
	
	/* Stash this in a local, because we're about to clear the line_buffer field. */
	BOOL unicode = line_request_uni;
	if (!unicode)
		buf = (char *)line_buffer;
	else
		ubuf = (glui32 *)line_buffer;
	
	for (ix=0; ix<str.length; ix++) {
		if (ix >= line_buffer_length)
			break;
		glui32 ch = [str characterAtIndex:ix];
		//### we should crunch utf16 characters into utf32 if needed
		if (!unicode) {
			if (ch > 0xFF)
				ch = '?';
			buf[ix] = ch;
		}
		else {
			ubuf[ix] = ch;
		}
	}
	
	buflen = ix;
	
	line_request = NO;
	line_request_uni = NO;
	line_buffer = nil;
	line_buffer_length = 0;
	self.line_request_initial = nil;
	
	/* Echo the input. ### stash echo_line_input in a per-input flag */
	if (TRUE) {
		glui32 origstyle = style;
		
		if (!unicode) {
			[self putBuffer:buf len:buflen];
			if (echostream)
				[echostream putBuffer:buf len:buflen];
		}
		else {
			[self putUBuffer:ubuf len:buflen];
			if (echostream)
				[echostream putUBuffer:ubuf len:buflen];
		}
		[self putBuffer:"\n" len:1];
		if (echostream)
			[echostream putBuffer:"\n" len:1];
			
		style = origstyle;
	}
	
    if (library.dispatch_unregister_arr) {
        char *typedesc = (unicode ? "&+#!Iu" : "&+#!Cn");
        (*library.dispatch_unregister_arr)(vbuf, maxlen, typedesc, inarrayrock);
    }
	
	return buflen;
}

- (void) cancelLineInput:(event_t *)event {
	bzero(event, sizeof(event_t));
	
	/* We have to get the current editing state of the text field. That really should be touched only by the main thread, but we'll sneak it out. */

	NSString *str = [[GlkAppWrapper singleton] editingTextForWindow:self.tag];
	if (!str)
		str = @"";
		
	int buflen = [self acceptLineInput:str];
	if (buflen < 0) {
		/* The window wasn't accepting input, turns out. */
		return;
	}
	
	event->type = evtype_LineInput;
	event->win = self;
	event->val1 = buflen;
}

@end


@implementation GlkWindowBuffer
/* GlkWindowBuffer: a textbuffer window. */

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

- (void) getWidth:(glui32 *)widthref height:(glui32 *)heightref {
	*widthref = 0;
	*heightref = 0;
	//### count on-screen lines, maybe
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

/* Break the string up into GlkStyledLines. When the GlkWinBufferView updates, it will pluck these out and make use of them.
*/
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

- (BOOL) supportsInput {
	return YES;
}

- (void) clearWindow {
	//####
}

@end


@implementation GlkWindowGrid
/* GlkWindowGrid: a textgrid window. */

@synthesize lines;
@synthesize width;
@synthesize height;
@synthesize curx;
@synthesize cury;

- (id) initWithType:(glui32)wintype rock:(glui32)winrock {
	self = [super initWithType:wintype rock:winrock];
	
	if (self) {
		width = 0;
		height = 0;
		curx = 0;
		cury = 0;
		
		self.lines = [NSMutableArray arrayWithCapacity:8];
	}
	
	return self;
}

- (void) dealloc {
	self.lines = nil;
	[super dealloc];
}

- (void) windowRearrange:(CGRect)box {
	bbox = box;
	
	int newwidth = ((bbox.size.width-styleset.marginframe.size.width) / styleset.charbox.width);
	int newheight = ((bbox.size.height-styleset.marginframe.size.height) / styleset.charbox.height);
	if (newwidth < 0)
		newwidth = 0;
	if (newheight < 0)
		newheight = 0;
		
	width = newwidth;
	height = newheight;
	
	NSLog(@"grid window now %dx%d", width, height);
	
	while (lines.count > height)
		[lines removeLastObject];
	while (lines.count < height)
		[lines addObject:[[[GlkGridLine alloc] init] autorelease]];
		
	for (GlkGridLine *ln in lines)
		[ln setWidth:width];
}

- (void) getWidth:(glui32 *)widthref height:(glui32 *)heightref {
	*widthref = width;
	*heightref = height;
}

- (BOOL) supportsInput {
	return YES;
}

- (void) moveCursorToX:(glui32)xpos Y:(glui32)ypos {
	/* Don't worry about large numbers, or numbers that the caller might have thought were negative. The canonicalization will fix this. */
	if (xpos > 0x7FFF)
		xpos = 0x7FFF;
	if (ypos > 0x7FFF)
		ypos = 0x7FFF;
		
	curx = xpos;
	cury = ypos;
}

- (void) clearWindow {
	for (GlkGridLine *ln in lines) {
		[ln clear];
	}
}

- (void) putBuffer:(char *)buf len:(glui32)len {
	for (int ix=0; ix<len; ix++)
		[self putUChar:(unsigned char)(buf[ix])];
}

- (void) putUBuffer:(glui32 *)buf len:(glui32)len {
	for (int ix=0; ix<len; ix++)
		[self putUChar:buf[ix]];
}

- (void) putUChar:(glui32)ch {
	/* Canonicalize the cursor position. That is, the cursor may have been left outside the window area, or may be too close to the edge to print the next character. Wrap it if necessary. */
	if (curx < 0)
		curx = 0;
	else if (curx >= width) {
		curx = 0;
		cury++;
	}
	if (cury < 0)
		cury = 0;
	else if (cury >= height)
		return; /* outside the window */

	if (ch == '\n') {
		/* a newline just moves the cursor. */
		cury++;
		curx = 0;
		return;
	}
	
	GlkGridLine *ln = [lines objectAtIndex:cury];
	ln.chars[curx] = ch;
	ln.styles[curx] = style;
	ln.dirty = YES;
	
	curx++;
	
	/* We can leave the cursor outside the window, since it will be canonicalized next time a character is printed. */
}

@end


@implementation GlkWindowPair
/* GlkWindowPair: a pair window (the kind of window that has subwindows). */

@synthesize geometry;
@synthesize keydamage;

/* GlkWindowPair gets a special initializer. (Only called from glk_window_open() when a window is split.)
*/
- (id) initWithMethod:(glui32)method keywin:(GlkWindow *)keywin size:(glui32)initsize {
	self = [super initWithType:wintype_Pair rock:0];
	
	if (self) {
		geometry = [[Geometry alloc] init]; // retained
		geometry.dir = method & winmethod_DirMask;
		geometry.division = method & winmethod_DivisionMask;
		geometry.hasborder = ((method & winmethod_BorderMask) == winmethod_Border);
		geometry.keytag = keywin.tag;
		geometry.keystyleset = keywin.styleset;
		keydamage = FALSE;
		geometry.size = initsize;

		self.child1 = nil;
		self.child2 = nil;
	}
	
	return self;
}

- (void) dealloc {
	self.geometry = nil;
	self.child1 = nil;
	self.child2 = nil;
	[super dealloc];
}

- (GlkWindow *) child1 {
	return child1;
}

- (GlkWindow *) child2 {
	return child2;
}

- (void) setChild1:(GlkWindow *)newwin {
	if (newwin) {
		[newwin retain];
		geometry.child1tag = newwin.tag;
	}
	else {
		geometry.child1tag = nil;
	}
	[child1 release];
	child1 = newwin;
}

- (void) setChild2:(GlkWindow *)newwin {
	if (newwin) {
		[newwin retain];
		geometry.child2tag = newwin.tag;
	}
	else {
		geometry.child2tag = nil;
	}
	[child2 release];
	child2 = newwin;
}

/* For a pair window, the task is to figure out how to divide the box between its children. Then recursively call windowRearrange on them.
*/
- (void) windowRearrange:(CGRect)box {
	bbox = box;

	CGRect box1;
	CGRect box2;
	GlkWindow *ch1, *ch2;
	
	[geometry computeDivision:bbox for1:&box1 for2:&box2];

	if (!geometry.backward) {
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


