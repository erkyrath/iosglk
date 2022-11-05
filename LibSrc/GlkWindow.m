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
#import "GlkWindowState.h"
#import "IosGlkLibDelegate.h"
#import "GlkAppWrapper.h"
#import "GlkStream.h"
#import "StyleSet.h"
#import "Geometry.h"
#import "GlkUtilTypes.h"

@implementation GlkWindow
/* GlkWindow: the base class. */

+ (BOOL) supportsSecureCoding {
    return YES;
}

/* Create a window with a given type. (But not Pair windows -- those use a different path.) This is invoked by glk_window_open().
*/
+ (GlkWindow *) windowWithType:(glui32)type rock:(glui32)rock {
	GlkWindow *win;
	switch (type) {
		case wintype_TextBuffer:
			win = [[GlkWindowBuffer alloc] initWithType:type rock:rock];
			win.styleset = [StyleSet buildForWindowType:type rock:rock];
			break;
		case wintype_TextGrid:
			win = [[GlkWindowGrid alloc] initWithType:type rock:rock];
			win.styleset = [StyleSet buildForWindowType:type rock:rock];
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
- (instancetype) initWithType:(glui32)wintype rock:(glui32)winrock {
	self = [super init];
	
	if (self) {
		self.library = [GlkLibrary singleton];
		inlibrary = YES;
		
		self.tag = _library.generateTag;
		_type = wintype;
		_rock = winrock;
		
		self.parent = nil;
		self.parenttag = nil;
		_input_request_id = 0;
		_line_request_initial = nil;
		line_buffer = nil;
		_char_request = NO;
		_line_request = NO;
		char_request_uni = NO;
		line_request_uni = NO;
		_echo_line_input = YES;
		pending_echo_line_input = NO;
		//terminate_line_input = 0;
		_style = style_Normal;
		
		self.stream = [[GlkStreamWindow alloc] initWithWindow:self];
		self.streamtag = self.stream.tag;
		self.echostream = nil;
		self.echostreamtag = nil;
		
		self.styleset = nil;
		[_library.windows addObject:self];
		
		if (_library.dispatch_register_obj)
			_disprock = (*_library.dispatch_register_obj)((__bridge void *)(self), gidisp_Class_Window);
	}
	
	return self;
}

- (instancetype) initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        self.tag = [decoder decodeObjectForKey:@"tag"];
        inlibrary = YES;
        // self.library will be set later

        _type = [decoder decodeInt32ForKey:@"type"];
        _rock = [decoder decodeInt32ForKey:@"rock"];
        // disprock is handled by the app

        self.parenttag = [decoder decodeObjectForKey:@"parenttag"];
        // parent will be set later

        _input_request_id = [decoder decodeIntForKey:@"input_request_id"];

        _char_request = [decoder decodeBoolForKey:@"char_request"];
        _line_request = [decoder decodeBoolForKey:@"line_request"];
        char_request_uni = [decoder decodeBoolForKey:@"char_request_uni"];
        line_request_uni = [decoder decodeBoolForKey:@"line_request_uni"];

        line_buffer_length = [decoder decodeInt32ForKey:@"line_buffer_length"];
        if (line_buffer_length) {
            // the decoded "line_buffer" values are originally Glulx addresses (glui32), so stuffing them into a long is safe.
            if (!line_request_uni) {
                tempbufkey = (long)[decoder decodeInt64ForKey:@"line_buffer"];
                uint8_t *rawdata;
                NSUInteger rawdatalen;
                rawdata = (uint8_t *)[decoder decodeBytesForKey:@"line_buffer_data" returnedLength:&rawdatalen];
                if (rawdata && rawdatalen) {
                    tempbufdatalen = rawdatalen;
                    tempbufdata = malloc(rawdatalen);
                    memcpy(tempbufdata, rawdata, rawdatalen);
                }
            }
            else {
                tempbufkey = (long)[decoder decodeInt64ForKey:@"line_buffer"];
                uint8_t *rawdata;
                NSUInteger rawdatalen;
                rawdata = (uint8_t *)[decoder decodeBytesForKey:@"line_buffer_data" returnedLength:&rawdatalen];
                if (rawdata && rawdatalen) {
                    tempbufdatalen = rawdatalen;
                    tempbufdata = malloc(rawdatalen);
                    memcpy(tempbufdata, rawdata, rawdatalen);
                }
            }
        }

        self.line_request_initial = [decoder decodeObjectForKey:@"line_request_initial"];
        pending_echo_line_input = [decoder decodeBoolForKey:@"pending_echo_line_input"];
        _echo_line_input = [decoder decodeBoolForKey:@"echo_line_input"];
        _style = [decoder decodeInt32ForKey:@"style"];

        self.streamtag = [decoder decodeObjectForKey:@"streamtag"];
        // streamtag will be set later
        self.echostreamtag = [decoder decodeObjectForKey:@"echostreamtag"];
        // echostreamtag will be set later

        _bbox = [decoder decodeCGRectForKey:@"bbox"];
        // styleset is not deserialized.
    }
	return self;
}

- (void) updateRegisterArray {
	if (!_library.dispatch_restore_arr)
		return;
	if (!line_buffer_length)
		return;
	
	if (!line_request_uni) {
		void *voidbuf = nil;
		inarrayrock = (*_library.dispatch_restore_arr)(tempbufkey, line_buffer_length, "&+#!Cn", &voidbuf);
		if (voidbuf) {
			line_buffer = voidbuf;
			if (tempbufdata) {
				if (tempbufdatalen > line_buffer_length)
					tempbufdatalen = line_buffer_length;
				memcpy(line_buffer, tempbufdata, tempbufdatalen);
				free(tempbufdata);
				tempbufdata = nil;
			}
		}
	}
	else {
		void *voidbuf = nil;
		inarrayrock = (*_library.dispatch_restore_arr)(tempbufkey, line_buffer_length, "&+#!Iu", &voidbuf);
		if (voidbuf) {
			line_buffer = voidbuf;
			if (tempbufdata) {
				if (tempbufdatalen > sizeof(glui32)*line_buffer_length)
					tempbufdatalen = sizeof(glui32)*line_buffer_length;
				memcpy(line_buffer, tempbufdata, tempbufdatalen);
				free(tempbufdata);
				tempbufdata = nil;
			}
		}
	}
}

- (void) dealloc {
	if (inlibrary)
		[NSException raise:@"GlkException" format:@"GlkWindow reached dealloc while in library"];
	if (!_type)
		[NSException raise:@"GlkException" format:@"GlkWindow reached dealloc with type unset"];
	_type = 0;
	if (!_tag)
		[NSException raise:@"GlkException" format:@"GlkWindow reached dealloc with tag unset"];
}

- (void) encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:_tag forKey:@"tag"];
	
	[encoder encodeInt32:_type forKey:@"type"];
	[encoder encodeInt32:_rock forKey:@"rock"];
	// disprock is handled by the app
	
	[encoder encodeObject:_parenttag forKey:@"parenttag"];

	[encoder encodeInt:_input_request_id forKey:@"input_request_id"];

	[encoder encodeBool:_char_request forKey:@"char_request"];
	[encoder encodeBool:_line_request forKey:@"line_request"];
	[encoder encodeBool:char_request_uni forKey:@"char_request_uni"];
	[encoder encodeBool:line_request_uni forKey:@"line_request_uni"];

	if (line_buffer && line_buffer_length && _library.dispatch_locate_arr) {
		long bufaddr;
		int elemsize;
		[encoder encodeInt:line_buffer_length forKey:@"line_buffer_length"];
		if (!line_request_uni) {
			bufaddr = (*_library.dispatch_locate_arr)(line_buffer, line_buffer_length, "&+#!Cn", inarrayrock, &elemsize);
			[encoder encodeInt64:bufaddr forKey:@"line_buffer"];
			if (elemsize) {
				NSAssert(elemsize == 1, @"GlkWindow encoding char array: wrong elemsize");
				// could trim trailing zeroes here
				[encoder encodeBytes:(uint8_t *)line_buffer length:line_buffer_length forKey:@"line_buffer_data"];
			}
		}
		else {
			bufaddr = (*_library.dispatch_locate_arr)(line_buffer, line_buffer_length, "&+#!Iu", inarrayrock, &elemsize);
			[encoder encodeInt64:bufaddr forKey:@"line_buffer"];
			if (elemsize) {
				NSAssert(elemsize == 4, @"GlkWindow encoding uni array: wrong elemsize");
				// could trim trailing zeroes here
				[encoder encodeBytes:(uint8_t *)line_buffer length:sizeof(glui32)*line_buffer_length forKey:@"line_buffer_data"];
			}
		}
	}

	[encoder encodeObject:_line_request_initial forKey:@"line_request_initial"];
	[encoder encodeBool:pending_echo_line_input forKey:@"pending_echo_line_input"];
	[encoder encodeBool:_echo_line_input forKey:@"echo_line_input"];
	[encoder encodeInt32:_style forKey:@"style"];

	[encoder encodeObject:_streamtag forKey:@"streamtag"];
	[encoder encodeObject:_echostreamtag forKey:@"echostreamtag"];

	[encoder encodeCGRect:_bbox forKey:@"bbox"];
}

/* Close a window, and perhaps its subwindows too. 
*/
- (void) windowCloseRecurse:(BOOL)recurse {
	/* We don't want this object to evaporate in the middle of this method. */	
	if (line_buffer) {
		if (_library.dispatch_unregister_arr) {
			char *typedesc = (line_request_uni ? "&+#!Iu" : "&+#!Cn");
			(*_library.dispatch_unregister_arr)(line_buffer, line_buffer_length, typedesc, inarrayrock);
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
	
	if (recurse && _type == wintype_Pair) {
		GlkWindowPair *pwx = (GlkWindowPair *)self;
		if (pwx.child1)
			[pwx.child1 windowCloseRecurse:YES];
		if (pwx.child2)
			[pwx.child2 windowCloseRecurse:YES];
	}

	if (_library.dispatch_unregister_obj)
		(*_library.dispatch_unregister_obj)((__bridge void *)(self), gidisp_Class_Window, _disprock);
		
	if (_stream) {
		[_stream streamDelete];
		self.stream = nil;
		self.streamtag = nil;
	}
	self.echostream = nil;
	self.echostreamtag = nil;
	self.parent = nil;
	self.parenttag = nil;
	
	if (![_library.windows containsObject:self])
		[NSException raise:@"GlkException" format:@"GlkWindow was not in library windows list"];
	[_library.windows removeObject:self];
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

/* Mark all the window's data as dirty, so that the windowview will fetch it all properly.
 */
- (void) dirtyAllData {
	/* Subclasses will override this. */
}

- (GlkWindowState *) cloneState {
	GlkWindowState *state = [GlkWindowState windowStateWithType:_type rock:_rock];
	// state.library will be set later
	state.tag = _tag;
	state.styleset = _styleset;
	state.input_request_id = _input_request_id;
	state.char_request = _char_request;
	state.line_request = _line_request;
	state.bbox = _bbox;
	return state;
}

/* When a stram is closed, we call this to detach it from any windows who have it as their echostream.
*/
+ (void) unEchoStream:(strid_t)str {
	GlkLibrary *library = [GlkLibrary singleton];
	for (GlkWindow *win in library.windows) {
		if (win.echostream == str) {
			win.echostream = nil;
			win.echostreamtag = nil;
		}
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
	if (!self.supportsInput) {
		[GlkLibrary strictWarning:@"beginCharInput: window does not support keyboard input"];
		return;
	}
	if (_char_request || _line_request) {
		[GlkLibrary strictWarning:@"beginCharInput: window already has keyboard request"];
		return;
	}
	
	_char_request = YES;
	char_request_uni = unicode;
	_input_request_id++;
}

/* Complete character input. Returns YES if the window is accepting char input right now. This also changes the character, if necessary, if non-unicode input was requested originally.
*/
- (BOOL) acceptCharInput:(glui32 *)chref {
	if (!_char_request)
		return NO;
		
	glui32 ch = *chref;
	if (!char_request_uni && (ch > 0xFF && ch < keycode_Func12))
		ch = '?';
	*chref = ch;
		
	_char_request = NO;
	char_request_uni = NO;
	return YES;
}

- (void) cancelCharInput {
	_char_request = NO;
	char_request_uni = NO;
}

/* Set up the window for line input. (The next updateFromWindowInputs call will make use of this information.)
*/
- (void) beginLineInput:(void *)buf unicode:(BOOL)unicode maxlen:(glui32)maxlen initlen:(glui32)initlen {
	if (!self.supportsInput) {
		[GlkLibrary strictWarning:@"beginLineInput: window does not support keyboard input"];
		return;
	}
	if (_char_request || _line_request) {
		[GlkLibrary strictWarning:@"beginLineInput: window already has keyboard request"];
		return;
	}
	
	_line_request = YES;
	line_request_uni = unicode;
	line_buffer = buf;
	line_buffer_length = maxlen;
	_input_request_id++;
	
	if (self.type == wintype_TextBuffer)
		pending_echo_line_input = _echo_line_input;
	else
		pending_echo_line_input = NO;
	
	self.line_request_initial = nil;
	if (initlen) {
		NSString *str;
		if (!unicode)
			str = [[NSString alloc] initWithBytes:buf length:initlen encoding:NSISOLatin1StringEncoding];
		else
			str = [[NSString alloc] initWithBytes:buf length:initlen*sizeof(glui32) encoding:NSUTF32LittleEndianStringEncoding];
		_line_request_initial = str; // retained
	}
	
	if (_library.dispatch_register_arr) {
		char *typedesc = (line_request_uni ? "&+#!Iu" : "&+#!Cn");
		inarrayrock = (*_library.dispatch_register_arr)(line_buffer, maxlen, typedesc);
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
	
	if (!line_buffer || !_line_request)
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
	
	_line_request = NO;
	line_request_uni = NO;
	line_buffer = nil;
	line_buffer_length = 0;
	self.line_request_initial = nil;
	
	/* Echo the input, if needed. (On a grid window, it won't be needed.) */
	if (pending_echo_line_input) {
		glui32 origstyle = _style;
		_style = style_Input;
		
		if (!unicode) {
			[self putBuffer:buf len:buflen];
			if (_echostream)
				[_echostream putBuffer:buf len:buflen];
		}
		else {
			[self putUBuffer:ubuf len:buflen];
			if (_echostream)
				[_echostream putUBuffer:ubuf len:buflen];
		}
		[self putBuffer:"\n" len:1];
		if (_echostream)
			[_echostream putBuffer:"\n" len:1];
			
		_style = origstyle;
	}
	pending_echo_line_input = NO;
	
    if (_library.dispatch_unregister_arr) {
        char *typedesc = (unicode ? "&+#!Iu" : "&+#!Cn");
        (*_library.dispatch_unregister_arr)(vbuf, maxlen, typedesc, inarrayrock);
    }
	
	return buflen;
}

- (void) cancelLineInput:(event_t *)event {
    event->type = 0;
    event->win = NULL;
    event->val1 = 0;
    event->val2 = 0;
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

+ (BOOL) supportsSecureCoding {
    return YES;
}

- (instancetype) initWithType:(glui32)wintype rock:(glui32)winrock {
	self = [super initWithType:wintype rock:winrock];
	
	if (self) {
		_clearcount = 1; // contents start out clear
		self.attrstring = [NSMutableAttributedString new];
        self.savedattrstring = [NSMutableAttributedString new];
	}
	
	return self;
}

- (instancetype) initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	
	if (self) {
		_clearcount = [decoder decodeIntForKey:@"clearcount"];
		self.attrstring = [decoder decodeObjectForKey:@"attrstring"];
        self.savedattrstring = [self.attrstring mutableCopy];

//		[self dirtyAllData];
	}
	
	return self;
}


- (void) encodeWithCoder:(NSCoder *)encoder {
	[super encodeWithCoder:encoder];
	
	[encoder encodeInt:_clearcount forKey:@"clearcount"];
	[encoder encodeObject:self.savedattrstring forKey:@"attrstring"];

	//### should we cap the number of lines written out?
}

- (GlkWindowState *) cloneState {
	GlkWindowBufferState *state = (GlkWindowBufferState *)[super cloneState];
	
    state.attrstring = [self.attrstring copy];
    self.attrstring = [NSMutableAttributedString new];

	state.clearcount = _clearcount;
	state.line_request_initial = self.line_request_initial;

	return state;
}

- (void) windowRearrange:(CGRect)box {
	self.bbox = box;
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
}

- (void) putUBuffer:(glui32 *)buf len:(glui32)len {
	if (!len)
		return;
	
	/* Turn the buffer into an NSString. We'll release this at the end of the function. 
		This is an endianness dependency; we're telling NSString that our array of 32-bit words in stored little-endian. (True for all iOS, as I write this.) */
	NSString *str = [[NSString alloc] initWithBytes:buf length:len*sizeof(glui32) encoding:NSUTF32LittleEndianStringEncoding];
	[self putString:str];	
}

/* Break the string up into GlkStyledLines. When the GlkWinBufferView updates, it will pluck these out and make use of them.
*/
- (void) putString:(NSString *)str {
    NSDictionary *attributes = self.styleset.bufferattributes[self.style];
    if (!self.attrstring) {
        NSLog(@"GlkWindowBuffer: no attrstring!");
        self.attrstring = [[NSMutableAttributedString alloc] initWithString:str attributes:attributes];
    }
    if (!self.savedattrstring) {
        self.savedattrstring = [self.attrstring mutableCopy];
    }

    NSAttributedString *attrstr = [[NSAttributedString alloc] initWithString:str attributes:attributes];
    [self.attrstring appendAttributedString:attrstr];
    [self.savedattrstring appendAttributedString:attrstr];
}

- (BOOL) supportsInput {
	return YES;
}

- (void) clearWindow {
	_clearcount++;
    self.attrstring = [NSMutableAttributedString new];
    self.savedattrstring = [NSMutableAttributedString new];
}

@end


@implementation GlkWindowGrid
/* GlkWindowGrid: a textgrid window. */

@synthesize width;
@synthesize height;
@synthesize curx;
@synthesize cury;

+ (BOOL) supportsSecureCoding {
    return YES;
}

- (instancetype) initWithType:(glui32)wintype rock:(glui32)winrock {
	self = [super initWithType:wintype rock:winrock];
	
	if (self) {
		width = 0;
		height = 0;
		curx = 0;
		cury = 0;
		
		self.attrstring = [NSMutableAttributedString new];
	}
	
	return self;
}

- (instancetype) initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	
	if (self) {
		width = [decoder decodeIntForKey:@"width"];
		height = [decoder decodeIntForKey:@"height"];
		_attrstring = [decoder decodeObjectForKey:@"attrstring"];
		curx = [decoder decodeIntForKey:@"curx"];
		cury = [decoder decodeIntForKey:@"cury"];
		
		[self dirtyAllData];
	}
	
	return self;
}


- (void) encodeWithCoder:(NSCoder *)encoder {
	[super encodeWithCoder:encoder];
	
	[encoder encodeInt:width forKey:@"width"];
	[encoder encodeInt:height forKey:@"height"];
	[encoder encodeObject:_attrstring forKey:@"attrstring"];
	[encoder encodeInt:curx forKey:@"curx"];
	[encoder encodeInt:cury forKey:@"cury"];
}

- (GlkWindowState *) cloneState {
	GlkWindowGridState *state = (GlkWindowGridState *)super.cloneState;
	
	state.width = width;
	state.height = height;
	state.curx = curx;
	state.cury = cury;
	
	/* Canonicalize a little */
	if (state.curx >= width) {
		state.curx = 0;
		state.cury++;
		if (state.cury >= height) {
			state.curx = width-1;
			state.cury = height-1;
		}
	}
	
	state.attrstring = [self.attrstring copy];
	
	return state;
}

- (void) windowRearrange:(CGRect)box {
	self.bbox = box;
	
	int newwidth = ((self.bbox.size.width-self.styleset.margintotal.width) / self.styleset.charbox.width);
	int newheight = ((self.bbox.size.height-self.styleset.margintotal.height) / self.styleset.charbox.height);
	if (newwidth < 0)
		newwidth = 0;
	if (newheight < 0)
		newheight = 0;

    if (!_attrstring || _attrstring.length == 0)
        _attrstring = [self blankAttributedString];

    if (newwidth < width) {
        // Delete characters if the window has become narrower
        NSUInteger diff = width - newwidth;
        for (NSUInteger i = width - 1; i < _attrstring.length; i += width + 1 - diff) {
            if (i < diff)
                continue;
            NSRange deleteRange =
            NSMakeRange(i - diff, diff);
            if (NSMaxRange(deleteRange) > _attrstring.length)
                deleteRange =
                NSMakeRange(i - diff,
                            _attrstring.length - (i - diff));

            [_attrstring deleteCharactersInRange:deleteRange];
        }
    } else if (newwidth > width) {
        // Pad with spaces if the window has become wider
        NSUInteger diff = newwidth - width;
        NSString *spaces =
        [[[NSString alloc] init] stringByPaddingToLength:diff
                                              withString:@"\u00a0" /* Non-breaking space */
                                         startingAtIndex:0];
        NSAttributedString *padding;
        for (NSUInteger i = width; i < _attrstring.length - 1; i += width + 1 + diff) {
            padding = [[NSAttributedString alloc]
                      initWithString:spaces
                      attributes:self.styleset.gridattributes[self.style]];
            [_attrstring insertAttributedString:padding atIndex:i];
        }
    }
    width = newwidth;
    height = newheight;

    NSUInteger desiredLength =
    height * (width + 1) - 1; // -1 because we don't want a newline at the very end
    if (desiredLength < 1 || height == 1)
        desiredLength = width;

    // Cut off characters or pad with spaces if height has changed
    if (_attrstring.length < desiredLength) {
        NSString *spaces = [[[NSString alloc] init]
                            stringByPaddingToLength:desiredLength - _attrstring.length
                            withString:@"\u00a0" /* Non-breaking space */
                            startingAtIndex:0];
        NSAttributedString *string = [[NSAttributedString alloc]
                                      initWithString:spaces
                                      attributes:self.styleset.gridattributes[self.style]];
        [_attrstring appendAttributedString:string];
    } else if (_attrstring.length > desiredLength)
        [_attrstring
         deleteCharactersInRange:NSMakeRange(desiredLength,
                                             _attrstring.length -
                                             desiredLength)];

    [self insertNewlines];
    //NSLog(@"grid window now %dx%d", width, height);
}

- (void) insertNewlines {
    NSAttributedString *newlinestring = [[NSAttributedString alloc]
                                         initWithString:@"\n"
                                         attributes:self.styleset.gridattributes[self.style]];

    // Instert a newline character at the end of each line to avoid reflow when the view size changes.
    // (We carefully have to print around these in the putUChar method)
    for (NSUInteger i = width; i < _attrstring.length; i += width + 1) {
        [_attrstring replaceCharactersInRange:NSMakeRange(i, 1)
                         withAttributedString:newlinestring];
    }
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
    _attrstring = [self blankAttributedString];
    [self insertNewlines];
}

- (NSMutableAttributedString *) blankAttributedString {
    NSString *spaces = [[[NSString alloc] init]
                        stringByPaddingToLength:(NSUInteger)(height * (width + 1) - (width > 1))
                        withString:@"\u00a0" /* Non-breaking space */
                        startingAtIndex:0];
    return [[NSMutableAttributedString alloc]
                   initWithString:spaces
                   attributes:self.styleset.gridattributes[self.style]];
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
	
	curx++;

    // Sometimes the text layout system seems to "collapse" spaces-only lines into a single space.
    // Not sure if this actually matters currently, but it doesn't hurt to replace all standard spaces
    // with non-breakable ones.
    if (ch == ' ')
        ch = 0xa0;

    NSUInteger location = cury * (width + 1) + curx;
    if ([_attrstring.string characterAtIndex:location] == '\n' || location >= _attrstring.length)
        return;
    NSRange replaceRange = NSMakeRange(location, 1);
    NSAttributedString *attrch = [[NSAttributedString alloc]
                                  initWithString:[NSString stringWithFormat:@"%c", ch]
                                  attributes:self.styleset.gridattributes[self.style]];
    [_attrstring
     replaceCharactersInRange:replaceRange withAttributedString:attrch];

	/* We can leave the cursor outside the window, since it will be canonicalized next time a character is printed. */
}

@end


@implementation GlkWindowPair
/* GlkWindowPair: a pair window (the kind of window that has subwindows). */

+ (BOOL) supportsSecureCoding {
    return YES;
}

/* GlkWindowPair gets a special initializer. (Only called from glk_window_open() when a window is split.)
*/
- (instancetype) initWithMethod:(glui32)method keywin:(GlkWindow *)keywin size:(glui32)initsize {
	self = [super initWithType:wintype_Pair rock:0];
	
	if (self) {
		_geometry = [[Geometry alloc] init]; // retained
		_geometry.dir = method & winmethod_DirMask;
		_geometry.division = method & winmethod_DivisionMask;
		_geometry.hasborder = ((method & winmethod_BorderMask) == winmethod_Border);
		_geometry.keytag = keywin.tag;
		_geometry.keystyleset = keywin.styleset;
		_keydamage = FALSE;
		_geometry.size = initsize;

		self.child1 = nil;
		self.child2 = nil;
	}
	
	return self;
}

- (instancetype) initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	
	if (self) {
		self.geometry = [decoder decodeObjectForKey:@"geometry"];
		// child1 and child2 will be set from the geometry.
		// keydamage is false outside of a close call.
	}
	
	return self;
}

- (void) dealloc {
	_child1 = nil;
	_child2 = nil;
}

- (void) encodeWithCoder:(NSCoder *)encoder {
	[super encodeWithCoder:encoder];
	
	[encoder encodeObject:_geometry forKey:@"geometry"];
	// child1 and child2 tags are serialized from inside the geometry.
}

- (GlkWindowState *) cloneState {
	GlkWindowPairState *state = (GlkWindowPairState *)super.cloneState;
	/* Clone the geometry object, since it's not immutable */
	state.geometry = [_geometry copy];
	return state;
}

- (void) setChild1:(GlkWindow *)newwin {
	if (newwin) {
		_geometry.child1tag = newwin.tag;
	}
	else {
		_geometry.child1tag = nil;
	}
	_child1 = newwin;
}

- (void) setChild2:(GlkWindow *)newwin {
	if (newwin) {
		_geometry.child2tag = newwin.tag;
	}
	else {
		_geometry.child2tag = nil;
	}
	_child2 = newwin;
}

/* For a pair window, the task is to figure out how to divide the box between its children. Then recursively call windowRearrange on them.
*/
- (void) windowRearrange:(CGRect)box {
    self.bbox = box;

	CGRect box1;
	CGRect box2;
	GlkWindow *ch1, *ch2;
	
	[_geometry computeDivision:self.bbox for1:&box1 for2:&box2];

	if (!_geometry.backward) {
		ch1 = _child1;
		ch2 = _child2;
	}
	else {
		ch1 = _child2;
		ch2 = _child1;
	}

	[ch1 windowRearrange:box1];
	[ch2 windowRearrange:box2];
}

@end
