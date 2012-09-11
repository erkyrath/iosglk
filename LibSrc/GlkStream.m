/* GlkStream.m: Stream objc class (and subclasses)
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	GlkStream is the base class representing a Glk stream. The subclasses represent the stream types (window, memory, file.)
	
	The encapsulation isn't very good in this file, because I kept most of the structure of the C Glk implementations -- specifically GlkTerm. The top-level "glk_" functions remained the same, and can be found in GlkStreamLayer.c. The internal "gli_" functions have become methods on the ObjC GlkStream class. So both layers wind up futzing with GlkStream internals.
*/

#import "GlkStream.h"
#import "GlkWindow.h"
#import "GlkFileRef.h"
#import "GlkLibrary.h"

@implementation GlkStream

@synthesize library;
@synthesize tag;
@synthesize disprock;
@synthesize type;
@synthesize rock;
@synthesize unicode;
@synthesize readable;
@synthesize writable;

- (id) initWithType:(GlkStreamType)strtype readable:(BOOL)isreadable writable:(BOOL)iswritable rock:(glui32)strrock {
	self = [super init];
	
	if (self) {
		self.library = [GlkLibrary singleton];
		inlibrary = YES;
		
		self.tag = [library generateTag];
		type = strtype;
		rock = strrock;
		readable = isreadable;
		writable = iswritable;
		
		readcount = 0;
		writecount = 0;
		unicode = NO;
				
		[library.streams addObject:self];
		
		if (library.dispatch_register_obj)
			disprock = (*library.dispatch_register_obj)(self, gidisp_Class_Stream);
	}
	
	return self;
}

- (id) initWithCoder:(NSCoder *)decoder {
	self.tag = [decoder decodeObjectForKey:@"tag"];
	inlibrary = YES;
	// self.library will be set later
	
	type = [decoder decodeInt32ForKey:@"type"];
	rock = [decoder decodeInt32ForKey:@"rock"];
	// disprock is handled by the app

	unicode = [decoder decodeBoolForKey:@"unicode"];

	readcount = [decoder decodeInt32ForKey:@"readcount"];
	writecount = [decoder decodeInt32ForKey:@"writecount"];
	readable = [decoder decodeBoolForKey:@"readable"];
	writable = [decoder decodeBoolForKey:@"writable"];

	return self;
}

- (void) dealloc {
	if (inlibrary)
		[NSException raise:@"GlkException" format:@"GlkStream reached dealloc while in library"];
	if (type == strtype_None)
		[NSException raise:@"GlkException" format:@"GlkStream reached dealloc with type unset"];
	type = strtype_None;
	if (!tag)
		[NSException raise:@"GlkException" format:@"GlkStream reached dealloc with tag unset"];
	self.tag = nil;
	
	self.library = nil;

	[super dealloc];
}

- (NSString *) description {
	return [NSString stringWithFormat:@"<%@ (mode %s%s, tag %@, rock %d): 0x%lx>", self.class, (readable?"r":""), (writable?"w":""), self.tag, self.rock, (long)self];
}

- (void) encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:tag forKey:@"tag"];
	
	[encoder encodeInt32:type forKey:@"type"];
	[encoder encodeInt32:rock forKey:@"rock"];
	// disprock is handled by the app
	
	[encoder encodeBool:unicode forKey:@"unicode"];

	[encoder encodeInt32:readcount forKey:@"readcount"];
	[encoder encodeInt32:writecount forKey:@"writecount"];
	[encoder encodeBool:readable forKey:@"readable"];
	[encoder encodeBool:writable forKey:@"writable"];
};
	
- (void) streamDelete {
	/* We don't want this object to evaporate in the middle of this method. */
	[[self retain] autorelease];
	
	if (library.currentstr == self)
		library.currentstr = nil;
		
	[GlkWindow unEchoStream:self];
	
	if (library.dispatch_unregister_obj)
		(*library.dispatch_unregister_obj)(self, gidisp_Class_Stream, disprock);
		
	if (![library.streams containsObject:self])
		[NSException raise:@"GlkException" format:@"GlkStream was not in library streams list"];
	[library.streams removeObject:self];
	inlibrary = NO;
}

/* Return the number of characters read from and written to the stream. (The result pointer may be NULL, in which case this does nothing.)
*/
- (void) fillResult:(stream_result_t *)result {
	if (result) {
		result->readcount = readcount;
		result->writecount = writecount;
	}
}

- (void) setPosition:(glsi32)pos seekmode:(glui32)seekmode {
	[NSException raise:@"GlkException" format:@"setPosition: stream type not implemented"];
}

- (glui32) getPosition {
	[NSException raise:@"GlkException" format:@"getPosition: stream type not implemented"];
	return 0;
}

- (void) putChar:(unsigned char)ch {
	char sch = ch;
	[self putBuffer:&sch len:1];
}

- (void) putCString:(char *)s {
	[self putBuffer:s len:strlen(s)];
}

/* All the printing methods for 8-bit characters funnel into here. */
- (void) putBuffer:(char *)buf len:(glui32)len {
	[NSException raise:@"GlkException" format:@"putBuffer: stream type not implemented"];
}

- (void) putUChar:(glui32)ch {
	glui32 sch = ch;
	[self putUBuffer:&sch len:1];
}

- (void) putUString:(glui32 *)us {
	int len;
	for (len=0; us[len]; len++) { };
	[self putUBuffer:us len:len];
}

/* All the printing methods for 32-bit characters funnel into here. */
- (void) putUBuffer:(glui32 *)buf len:(glui32)len {
	[NSException raise:@"GlkException" format:@"putUBuffer: stream type not implemented"];
}

/* For non-window streams, we do nothing. The GlkStreamWindow class will override this method.*/
- (void) setStyle:(glui32)styl {
}

/* Again, stream classes will override these get methods. */

- (glsi32) getChar:(BOOL)unicode {
	return -1;
}

- (glui32) getBuffer:(void *)buf buflen:(glui32)buflen unicode:(BOOL)unicode {
	return 0;
}

- (glui32) getLine:(void *)buf buflen:(glui32)buflen unicode:(BOOL)unicode {
	return 0;
}


@end

@implementation GlkStreamWindow

@synthesize win;
@synthesize wintag;

- (id) initWithWindow:(GlkWindow *)winref {
	self = [super initWithType:strtype_Window readable:NO writable:YES rock:0];
	
	if (self) {
		self.win = winref;
		self.wintag = winref.tag;
	}
	
	return self;
}

- (id) initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	
	if (self) {
		self.wintag = [decoder decodeObjectForKey:@"wintag"];
		// win will be set later.
	}
	
	return self;
}

- (void) dealloc {
	self.win = nil;
	self.wintag = nil;
	[super dealloc];
}

- (void) encodeWithCoder:(NSCoder *)encoder {
	[super encodeWithCoder:encoder];
	
	if (win)
		[encoder encodeObject:win.tag forKey:@"wintag"];
}

- (void) streamDelete {
	self.win = nil;
	self.wintag = nil;
	[super streamDelete];
}

- (void) setPosition:(glsi32)pos seekmode:(glui32)seekmode {
	/* Do nothing, not even pass to the echo stream. */
}

- (glui32) getPosition {
	return 0;
}

- (void) putBuffer:(char *)buf len:(glui32)len {
	if (!len)
		return;
	writecount += len;
	
	if (win.line_request) {
		[GlkLibrary strictWarning:@"putBuffer: window has pending line request"];
		return;
	}
	
	[win putBuffer:buf len:len];
	
	if (win.echostream)
		[win.echostream putBuffer:buf len:len];
}

- (void) putUBuffer:(glui32 *)buf len:(glui32)len {
	if (!len)
		return;
	writecount += len;
	
	if (win.line_request) {
		[GlkLibrary strictWarning:@"putUBuffer: window has pending line request"];
		return;
	}
	
	[win putUBuffer:buf len:len];
	
	if (win.echostream)
		[win.echostream putUBuffer:buf len:len];
}

- (void) setStyle:(glui32)styl {
	win.style = styl;
	
	if (win.echostream)
		[win.echostream setStyle:styl];
}

@end


@implementation GlkStreamMemory

@synthesize buflen;
@synthesize buf;
@synthesize ubuf;

- (id) initWithMode:(glui32)fmode rock:(glui32)rockval buf:(char *)bufval len:(glui32)buflenval {
	BOOL isreadable = (fmode != filemode_Write);
	BOOL iswritable = (fmode != filemode_Read);
	self = [super initWithType:strtype_Memory readable:isreadable writable:iswritable rock:rockval];
	
	if (self) {
		unicode = NO;
		buf = (unsigned char *)bufval;
		bufptr = (unsigned char *)bufval;
		buflen = buflenval;
		bufend = buf + buflen;
		if (fmode == filemode_Write)
			bufeof = (unsigned char *)bufval;
		else
			bufeof = bufend;
	
		ubuf = NULL;
		ubufptr = NULL;
		
		if (library.dispatch_register_arr) {
			arrayrock = (*library.dispatch_register_arr)(buf, buflen, "&+#!Cn");
		}
	}
	
	return self;
}

- (id) initUniWithMode:(glui32)fmode rock:(glui32)rockval buf:(glui32 *)ubufval len:(glui32)buflenval {
	BOOL isreadable = (fmode != filemode_Write);
	BOOL iswritable = (fmode != filemode_Read);
	self = [super initWithType:strtype_Memory readable:isreadable writable:iswritable rock:rockval];
	
	if (self) {
		unicode = YES;
		ubuf = ubufval;
		ubufptr = ubufval;
		buflen = buflenval;
		ubufend = ubuf + buflen;
		if (fmode == filemode_Write)
			ubufeof = ubufval;
		else
			ubufeof = ubufend;
	
		buf = NULL;
		bufptr = NULL;
		
		if (library.dispatch_register_arr) {
			arrayrock = (*library.dispatch_register_arr)(ubuf, buflen, "&+#!Iu");
		}
	}
	
	return self;
}

- (id) initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	
	if (self) {
		buflen = [decoder decodeInt32ForKey:@"buflen"];
		if (!unicode) {
			tempbufkey = [decoder decodeInt64ForKey:@"buf"];
			tempbufptr = [decoder decodeInt32ForKey:@"bufptr"];
			tempbufeof = [decoder decodeInt32ForKey:@"bufeof"];
			tempbufend = [decoder decodeInt32ForKey:@"bufend"];
			uint8_t *rawdata;
			NSUInteger rawdatalen;
			rawdata = (uint8_t *)[decoder decodeBytesForKey:@"bufdata" returnedLength:&rawdatalen];
			if (rawdata && rawdatalen) {
				tempbufdatalen = rawdatalen;
				tempbufdata = malloc(rawdatalen);
				memcpy(tempbufdata, rawdata, rawdatalen);
			}
		}
		else {
			tempbufkey = [decoder decodeInt64ForKey:@"ubuf"];
			tempbufptr = [decoder decodeInt32ForKey:@"ubufptr"];
			tempbufeof = [decoder decodeInt32ForKey:@"ubufeof"];
			tempbufend = [decoder decodeInt32ForKey:@"ubufend"];
			uint8_t *rawdata;
			NSUInteger rawdatalen;
			rawdata = (uint8_t *)[decoder decodeBytesForKey:@"ubufdata" returnedLength:&rawdatalen];
			if (rawdata && rawdatalen) {
				tempbufdatalen = rawdatalen;
				tempbufdata = malloc(rawdatalen);
				memcpy(tempbufdata, rawdata, rawdatalen);
			}
		}
	}
	
	return self;
}

- (void) updateRegisterArray {
	if (!library.dispatch_restore_arr) {
		[NSException raise:@"GlkException" format:@"GlkStreamMemory cannot be updated-from without app support"];
	}
	
	if (!unicode) {
		void *voidbuf = nil;
		arrayrock = (*library.dispatch_restore_arr)(tempbufkey, buflen, "&+#!Cn", &voidbuf);
		if (voidbuf) {
			buf = voidbuf;
			bufptr = buf + tempbufptr;
			bufeof = buf + tempbufeof;
			bufend = buf + tempbufend;
			if (tempbufdata) {
				if (tempbufdatalen > buflen)
					tempbufdatalen = buflen;
				memcpy(buf, tempbufdata, tempbufdatalen);
				free(tempbufdata);
				tempbufdata = nil;
			}
		}
	}
	else {
		void *voidbuf = nil;
		arrayrock = (*library.dispatch_restore_arr)(tempbufkey, buflen, "&+#!Iu", &voidbuf);
		if (voidbuf) {
			ubuf = voidbuf;
			ubufptr = ubuf + tempbufptr;
			ubufeof = ubuf + tempbufeof;
			ubufend = ubuf + tempbufend;
			if (tempbufdata) {
				if (tempbufdatalen > sizeof(glui32)*buflen)
					tempbufdatalen = sizeof(glui32)*buflen;
				memcpy(ubuf, tempbufdata, tempbufdatalen);
				free(tempbufdata);
				tempbufdata = nil;
			}
		}
	}
}

- (void) encodeWithCoder:(NSCoder *)encoder {
	[super encodeWithCoder:encoder];
	
	if (!library.dispatch_locate_arr) {
		[NSException raise:@"GlkException" format:@"GlkStreamMemory cannot be encoded without app support"];
	}
	
	[encoder encodeInt32:buflen forKey:@"buflen"];
	
	long bufaddr;
	int elemsize;
	if (!unicode) {
		if (buf && buflen) {
			bufaddr = (*library.dispatch_locate_arr)(buf, buflen, "&+#!Cn", arrayrock, &elemsize);
			[encoder encodeInt64:bufaddr forKey:@"buf"];
			[encoder encodeInt32:(bufptr-buf) forKey:@"bufptr"];
			[encoder encodeInt32:(bufeof-buf) forKey:@"bufeof"];
			[encoder encodeInt32:(bufend-buf) forKey:@"bufend"];
			if (elemsize) {
				NSAssert(elemsize == 1, @"GlkStreamMemory encoding char array: wrong elemsize");
				// could trim trailing zeroes here
				[encoder encodeBytes:(uint8_t *)buf length:buflen forKey:@"bufdata"];
			}
		}
	}
	else {
		if (ubuf && buflen) {
			bufaddr = (*library.dispatch_locate_arr)(ubuf, buflen, "&+#!Iu", arrayrock, &elemsize);
			[encoder encodeInt64:bufaddr forKey:@"ubuf"];
			[encoder encodeInt32:(ubufptr-ubuf) forKey:@"ubufptr"];
			[encoder encodeInt32:(ubufeof-ubuf) forKey:@"ubufeof"];
			[encoder encodeInt32:(ubufend-ubuf) forKey:@"ubufend"];
			if (elemsize) {
				NSAssert(elemsize == 4, @"GlkStreamMemory encoding uni array: wrong elemsize");
				// could trim trailing zeroes here
				[encoder encodeBytes:(uint8_t *)ubuf length:sizeof(glui32)*buflen forKey:@"ubufdata"];
			}
		}
	}
}

- (void) streamDelete {
	if (library.dispatch_unregister_arr) {
		char *typedesc = (unicode ? "&+#!Iu" : "&+#!Cn");
		void *vbuf = (unicode ? (void*)ubuf : (void*)buf);
		(*library.dispatch_unregister_arr)(vbuf, buflen, typedesc, arrayrock);
	}
	
	buf = NULL;
	bufptr = NULL;
	ubuf = NULL;
	ubufptr = NULL;
	buflen = 0;
	[super streamDelete];
}

- (void) setPosition:(glsi32)pos seekmode:(glui32)seekmode {
	if (!unicode) {
		if (seekmode == seekmode_Current) {
			pos = (bufptr - buf) + pos;
		}
		else if (seekmode == seekmode_End) {
			pos = (bufeof - buf) + pos;
		}
		else {
			/* pos = pos */
		}
		if (pos < 0)
			pos = 0;
		if (pos > (bufeof - buf))
			pos = (bufeof - buf);
		bufptr = buf + pos;
	}
	else {
		if (seekmode == seekmode_Current) {
			pos = (ubufptr - ubuf) + pos;
		}
		else if (seekmode == seekmode_End) {
			pos = (ubufeof - ubuf) + pos;
		}
		else {
			/* pos = pos */
		}
		if (pos < 0)
			pos = 0;
		if (pos > (ubufeof - ubuf))
			pos = (ubufeof - ubuf);
		ubufptr = ubuf + pos;
	}
}

- (glui32) getPosition {
	if (!unicode) {
		return (bufptr - buf);
	}
	else {
		return (ubufptr - ubuf);
	}
}

- (void) putBuffer:(char *)buffer len:(glui32)len {
	glui32 lx;
	
	if (!len)
		return;
	writecount += len;
	
	if (!unicode) {
		if (bufptr >= bufend) {
			len = 0;
		}
		else {
			if (bufptr + len > bufend) {
				lx = (bufptr + len) - bufend;
				if (lx < len)
					len -= lx;
				else
					len = 0;
			}
		}
		if (len) {
			memcpy(bufptr, buffer, len);
			bufptr += len;
			if (bufptr > bufeof)
				bufeof = bufptr;
		}
	}
	else {
		if (ubufptr >= ubufend) {
			len = 0;
		}
		else {
			if (ubufptr + len > ubufend) {
				lx = (ubufptr + len) - ubufend;
				if (lx < len)
					len -= lx;
				else
					len = 0;
			}
		}
		if (len) {
			for (lx=0; lx<len; lx++) {
				*ubufptr = (unsigned char)(buffer[lx]);
				ubufptr++;
			}
			if (ubufptr > ubufeof)
				ubufeof = ubufptr;
		}
	}
}

- (void) putUBuffer:(glui32 *)buffer len:(glui32)len {
	glui32 lx;
	
	if (!len)
		return;
	writecount += len;
	
	if (!unicode) {
		if (bufptr >= bufend) {
			len = 0;
		}
		else {
			if (bufptr + len > bufend) {
				lx = (bufptr + len) - bufend;
				if (lx < len)
					len -= lx;
				else
					len = 0;
			}
		}
		if (len) {
			for (lx=0; lx<len; lx++) {
				glui32 ch = buffer[lx];
				*bufptr = (ch >= 0x100 ? '?' : ch);
				bufptr++;
			}
			if (bufptr > bufeof)
				bufeof = bufptr;
		}
	}
	else {
		if (ubufptr >= ubufend) {
			len = 0;
		}
		else {
			if (ubufptr + len > ubufend) {
				lx = (ubufptr + len) - ubufend;
				if (lx < len)
					len -= lx;
				else
					len = 0;
			}
		}
		if (len) {
			memcpy(ubufptr, buffer, len*sizeof(glui32));
			ubufptr += len;
			if (ubufptr > ubufeof)
				ubufeof = ubufptr;
		}
	}
}

- (glsi32) getChar:(BOOL)wantunicode {
	if (!readable)
		return -1;

	if (!unicode) {
		if (bufptr < bufend) {
			unsigned char ch = *(bufptr);
			bufptr++;
			readcount++;
			return ch;
		}
		else {
			return -1;
		}
	}
	else {
		if (ubufptr < ubufend) {
			glui32 ch = *(ubufptr);
			ubufptr++;
			readcount++;
			if (!wantunicode && ch >= 0x100)
				return '?';
			return ch;
		}
		else {
			return -1;
		}
	}
}

- (glui32) getBuffer:(void *)getbuf buflen:(glui32)getlen unicode:(BOOL)wantunicode {
	if (!readable)
		return 0;
		
	/* This is messy, because we have to deal with the stream being unicode or not *and* with getbuf being unicode or not. */

	if (!unicode) {
		if (bufptr >= bufend) {
			getlen = 0;
		}
		else {
			if (bufptr + getlen > bufend) {
				glui32 lx;
				lx = (bufptr + getlen) - bufend;
				if (lx < getlen)
					getlen -= lx;
				else
					getlen = 0;
			}
		}
		if (getlen) {
			if (!wantunicode) {
				memcpy(getbuf, bufptr, getlen);
			}
			else {
				glui32 lx;
				glui32 *ugetbuf = getbuf;
				for (lx=0; lx<getlen; lx++) {
					ugetbuf[lx] = (unsigned char)bufptr[lx];
				}
			}
			bufptr += getlen;
			if (bufptr > bufeof)
				bufeof = bufptr;
		}
	}
	else {
		if (ubufptr >= ubufend) {
			getlen = 0;
		}
		else {
			if (ubufptr + getlen > ubufend) {
				glui32 lx;
				lx = (ubufptr + getlen) - ubufend;
				if (lx < getlen)
					getlen -= lx;
				else
					getlen = 0;
			}
		}
		if (getlen) {
			glui32 lx, ch;
			if (!wantunicode) {
				unsigned char *cgetbuf = getbuf;
				for (lx=0; lx<getlen; lx++) {
					ch = ubufptr[lx];
					if (ch >= 0x100)
						ch = '?';
					cgetbuf[lx] = ch;
				}
			}
			else {
				glui32 *ugetbuf = getbuf;
				for (lx=0; lx<getlen; lx++) {
					ugetbuf[lx] = ubufptr[lx];
				}
			}
			ubufptr += getlen;
			if (ubufptr > ubufeof)
				ubufeof = ubufptr;
		}
	}
	readcount += getlen;
	return getlen;
}

- (glui32) getLine:(void *)getbuf buflen:(glui32)getlen unicode:(BOOL)wantunicode {
	if (!readable)
		return 0;
		
	/* This is messy, because we have to deal with the stream being unicode or not *and* with getbuf being unicode or not. */
	
	if (getlen == 0)
		return 0;

	getlen -= 1; /* for the terminal null */
	
	glui32 lx;
	int gotnewline = FALSE;
	
	if (!unicode) {
		if (bufptr >= bufend) {
			getlen = 0;
		}
		else {
			if (bufptr + getlen > bufend) {
				lx = (bufptr + getlen) - bufend;
				if (lx < getlen)
					getlen -= lx;
				else
					getlen = 0;
			}
		}
		gotnewline = FALSE;
		if (!wantunicode) {
			unsigned char *cgetbuf = getbuf;
			for (lx=0; lx<getlen && !gotnewline; lx++) {
				cgetbuf[lx] = bufptr[lx];
				gotnewline = (cgetbuf[lx] == '\n');
			}
			cgetbuf[lx] = '\0';
		}
		else {
			glui32 *ugetbuf = getbuf;
			for (lx=0; lx<getlen && !gotnewline; lx++) {
				ugetbuf[lx] = (unsigned char)(bufptr[lx]);
				gotnewline = (ugetbuf[lx] == '\n');
			}
			ugetbuf[lx] = '\0';
		}
		bufptr += lx;
	}
	else {
		if (ubufptr >= ubufend) {
			getlen = 0;
		}
		else {
			if (ubufptr + getlen > ubufend) {
				lx = (ubufptr + getlen) - ubufend;
				if (lx < getlen)
					getlen -= lx;
				else
					getlen = 0;
			}
		}
		gotnewline = FALSE;
		if (!wantunicode) {
			unsigned char *cgetbuf = getbuf;
			for (lx=0; lx<getlen && !gotnewline; lx++) {
				glui32 ch;
				ch = ubufptr[lx];
				if (ch >= 0x100)
					ch = '?';
				cgetbuf[lx] = ch;
				gotnewline = (ch == '\n');
			}
			cgetbuf[lx] = '\0';
		}
		else {
			glui32 *ugetbuf = getbuf;
			for (lx=0; lx<getlen && !gotnewline; lx++) {
				glui32 ch;
				ch = ubufptr[lx];
				ugetbuf[lx] = ch;
				gotnewline = (ch == '\n');
			}
			ugetbuf[lx] = '\0';
		}
		ubufptr += lx;
	}
	
	readcount += lx;
	return lx;
}

@end


@implementation GlkStreamFile

/*	We handle disk files differently depending on whether they're Unicode or not, and whether they're text-mode or not. (Remember that the Unicode flag depends on whether the call comes from glk_stream_open_file_uni(); the text-mode flag comes from the fileref.)

	A non-Unicode, binary-mode file is a stream of bytes. Characters over 0xFF sent to it are converted to "?".
	
	A Unicode, binary-mode file is a stream of big-endian 32-bit integers. (The get/set_position calls are counted in characters, so they count 32-bit chunks.)
	
	A text-mode file is UTF-8 encoded. The Unicode flag is ignored for text-mode files; they're all just UTF-8. The get/set_position calls count in bytes, and are therefore hard to use. Seeking to beginning/end of file is safe, but jumping around inside the file may land you in the middle of a UTF-8 character.
*/

@synthesize handle;
@synthesize pathname;
@synthesize readbuffer;
@synthesize writebuffer;
@synthesize offsetinfile;

/* This constructor is used by the regular Glk glk_stream_open_file() call.
*/
- (id) initWithMode:(glui32)fmodeval rock:(glui32)rockval unicode:(BOOL)isunicode fileref:(GlkFileRef *)fref {
	self = [self initWithMode:fmodeval rock:rockval unicode:isunicode textmode:fref.textmode dirname:fref.dirname pathname:fref.pathname];
	return self;
}

/* This constructor is used by iosglk_startup_code(), in iosstart.m.
*/
- (id) initWithMode:(glui32)fmodeval rock:(glui32)rockval unicode:(BOOL)isunicode textmode:(BOOL)istextmode dirname:(NSString *)dirname pathname:(NSString *)path {
	BOOL isreadable = (fmodeval == filemode_Read || fmodeval == filemode_ReadWrite);
	BOOL iswritable = (fmodeval != filemode_Read);

	self = [super initWithType:strtype_File readable:isreadable writable:iswritable rock:rockval];
	
	if (self) {
		fmode = fmodeval;
		
		/* Set up the buffering. */
		maxbuffersize = 512;
		readbuffer = nil;
		writebuffer = nil;
		bufferpos = 0;
		buffermark = 0;
		buffertruepos = 0;
		bufferdirtystart = maxbuffersize;
		bufferdirtyend = 0;
		
		/* Set the easy fields. */
		self.pathname = path;
		unicode = isunicode;
		textmode = istextmode;
		
		if (fmode != filemode_Read) {
			NSFileManager *filemanager = [GlkLibrary singleton].filemanager;
			
			/* Create the directory first, if it doesn't already exist. (If it already exists as a regular file, we won't try the create, the subsequent file-create will fail, and then the filehandle won't open.) */
			if (![filemanager fileExistsAtPath:dirname isDirectory:nil])
				[filemanager createDirectoryAtPath:dirname withIntermediateDirectories:YES attributes:nil error:nil];
			
			/* Create the file first, if it doesn't already exist. */
			if (![filemanager fileExistsAtPath:pathname])
				[filemanager createFileAtPath:pathname contents:nil attributes:nil];
		}

		/* Open the file handle. */
		NSFileHandle *newhandle = nil;
		switch (fmode) {
			case filemode_Read:
				newhandle = [NSFileHandle fileHandleForReadingAtPath:pathname];
				break;
			case filemode_Write:
				newhandle = [NSFileHandle fileHandleForWritingAtPath:pathname];
				break;
			case filemode_ReadWrite:
			case filemode_WriteAppend:
				newhandle = [NSFileHandle fileHandleForUpdatingAtPath:pathname];
				break;
		}
		
		if (!newhandle) {
			/* Failed, probably because the file doesn't exist. */
			[self streamDelete];
			[self release];
			return nil;
		}
		
		if (fmode == filemode_Write)
			[newhandle truncateFileAtOffset:0];
		if (fmode == filemode_WriteAppend)
			[newhandle seekToEndOfFile];
	
		self.handle = newhandle;
	}
	
	return self;
}

- (id) initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	
	if (self) {
		self.pathname = [decoder decodeObjectForKey:@"pathname"];
		fmode = [decoder decodeInt32ForKey:@"fmode"];
		textmode = [decoder decodeBoolForKey:@"textmode"];
		maxbuffersize = [decoder decodeIntForKey:@"maxbuffersize"];
		
		offsetinfile = [decoder decodeInt64ForKey:@"offsetinfile"];
		
		// start out with an empty buffer
		readbuffer = nil;
		writebuffer = nil;
		bufferpos = 0;
		buffermark = 0;
		buffertruepos = 0;
		bufferdirtystart = maxbuffersize;
		bufferdirtyend = 0;
		
		// but we don't open the file itself at this time
	}
	
	return self;
}

- (void) dealloc {
	self.handle = nil;
	self.pathname = nil;
	self.readbuffer = nil;
	self.writebuffer = nil;
	[super dealloc];
}

- (void) encodeWithCoder:(NSCoder *)encoder {
	[super encodeWithCoder:encoder];
	
	[self flush];
	
	[encoder encodeObject:pathname forKey:@"pathname"];
	[encoder encodeInt32:fmode forKey:@"fmode"];
	[encoder encodeBool:textmode forKey:@"textmode"];
	[encoder encodeInt:maxbuffersize forKey:@"maxbuffersize"];
	
	[encoder encodeInt64:[handle offsetInFile] forKey:@"offsetinfile"];

	// skip the buffer fields, since we flushed it.
}

/* Open the file handle after a deserialize, and seek to the appropriate point. Called from GlkLibrary.updateFromLibrary. 
 
	We don't try to create the file (or the directory) here -- if the file doesn't exist, we give up. If this returns failure, handle remains nil and the caller should close the stream.
 */
- (BOOL) reopenInternal {
	NSFileHandle *newhandle = nil;
	switch (fmode) {
		case filemode_Read:
			newhandle = [NSFileHandle fileHandleForReadingAtPath:pathname];
			break;
		case filemode_Write:
			newhandle = [NSFileHandle fileHandleForWritingAtPath:pathname];
			break;
		case filemode_ReadWrite:
		case filemode_WriteAppend:
			newhandle = [NSFileHandle fileHandleForUpdatingAtPath:pathname];
			break;
	}
	
	if (!newhandle)
		return NO;
	
	self.handle = newhandle;
	[handle seekToFileOffset:offsetinfile];
	offsetinfile = 0;
	
	return YES;
}

- (void) streamDelete {
	[self flush];
	[handle closeFile];
	self.handle = nil;
	self.pathname = nil;
	[super streamDelete];
}

/* Here we implement some low-level read/write functions, which put an internal byte buffer on top of the underlying NSFileHandle.

	If the buffer is live, the filehandle's real mark (seek position) is always bufferpos+buffertruepos.

	For read-only files, the buffer can be an NSData of up to maxbuffersize bytes. The bufferrtruepos will always be at the end (equal to buffer.length). A caller can read until the buffer is used up; the next call will trigger a filehandle read. (Note that if you keep reading repeatedly after EOF, you'll trigger repeated filehandle reads, which is slow. Don't do that.)
	
	For writable files, the buffer can be an NSMutableData of up to maxbuffersize bytes. If the caller writes past buffertruepos, the buffer will get longer.

	This isn't the greatest buffering implementation in the world; it doesn't really try to cope with the possibility that some other process might diddle the file while we have it open. Fortunately, on iOS, no other process *will* diddle the file while we have it open.
*/

/* Return one byte (0-255), or -1 for EOF.
*/
- (int) readByte {
	if (writable) {
		if (!writebuffer || buffermark >= writebuffer.length) {
			[self flush];
			bufferpos = [handle offsetInFile];
			NSData *data = [handle readDataOfLength:maxbuffersize];
			if (!data || !data.length) {
				// Must be at the end of the file. Leave the buffer off.
			}
			else {
				self.writebuffer = [NSMutableData dataWithData:data];
				buffermark = 0;
				buffertruepos = writebuffer.length;
				bufferdirtystart = maxbuffersize;
				bufferdirtyend = 0;
			}
		}
		if (writebuffer && buffermark < writebuffer.length) {
			return ((char *)writebuffer.mutableBytes)[buffermark++] & 0xFF;
		}
		return -1;
	}
	else {
		if (!readbuffer || buffermark >= readbuffer.length) {
			[self flush];
			bufferpos = [handle offsetInFile];
			NSData *data = [handle readDataOfLength:maxbuffersize];
			if (!data || !data.length) {
				// Must be at the end of the file. Leave the buffer off.
			}
			else {
				self.readbuffer = data;
				buffermark = 0;
				buffertruepos = readbuffer.length;
				bufferdirtystart = maxbuffersize;
				bufferdirtyend = 0;
			}
		}
		if (readbuffer && buffermark < readbuffer.length) {
			return ((char *)readbuffer.bytes)[buffermark++] & 0xFF;
		}
		return -1;
	}
}

/* Read (up to) len bytes. Returns the number of bytes read. The array returned in byteref will be this many bytes long, and temporary (on autorelease). If at end of file, this returns 0 and byteref should be ignored.
*/
- (glui32) readBytes:(void **)byteref len:(glui32)len {
	if (writable) {
		if (writebuffer && writebuffer.length - buffermark >= len) {
			*byteref = writebuffer.mutableBytes+buffermark;
			buffermark += len;
			return len;
		}
		NSMutableData *resultdata = [NSMutableData dataWithLength:len];
		*byteref = resultdata.mutableBytes;
		glui32 addlen = writebuffer.length - buffermark;
		if (addlen) {
			memcpy(resultdata.mutableBytes, writebuffer.mutableBytes+buffermark, addlen);
			buffermark += addlen;
		}
		glui32 sofar = addlen;
		[self flush];
		if (len-sofar > maxbuffersize) {
			NSData *data = [handle readDataOfLength:len-sofar];
			memcpy(resultdata.mutableBytes+sofar, data.bytes, data.length);
			sofar += data.length;
			return sofar;
		}
		bufferpos = [handle offsetInFile];
		NSData *data = [handle readDataOfLength:maxbuffersize];
		if (!data || !data.length) {
			// Must be at the end of the file. Leave the buffer off.
		}
		else {
			self.writebuffer = [NSMutableData dataWithData:data];
			buffermark = 0;
			buffertruepos = writebuffer.length;
			bufferdirtystart = maxbuffersize;
			bufferdirtyend = 0;
		}
		glui32 gotlen = 0;
		if (writebuffer)
			gotlen = writebuffer.length;
		if (gotlen > len-sofar)
			gotlen = len-sofar;
		if (gotlen) {
			memcpy(resultdata.mutableBytes+sofar, data.bytes+buffermark, gotlen);
			buffermark += gotlen;
		}
		sofar += gotlen;
		return sofar;
	}
	else {
		if (readbuffer && readbuffer.length - buffermark >= len) {
			*byteref = (char *)readbuffer.bytes+buffermark;
			buffermark += len;
			return len;
		}
		NSMutableData *resultdata = [NSMutableData dataWithLength:len];
		*byteref = resultdata.mutableBytes;
		glui32 addlen = readbuffer.length - buffermark;
		if (addlen) {
			memcpy(resultdata.mutableBytes, readbuffer.bytes+buffermark, addlen);
			buffermark += addlen;
		}
		glui32 sofar = addlen;
		[self flush];
		if (len-sofar > maxbuffersize) {
			NSData *data = [handle readDataOfLength:len-sofar];
			memcpy(resultdata.mutableBytes+sofar, data.bytes, data.length);
			sofar += data.length;
			return sofar;
		}
		bufferpos = [handle offsetInFile];
		NSData *data = [handle readDataOfLength:maxbuffersize];
		if (!data || !data.length) {
			// Must be at the end of the file. Leave the buffer off.
		}
		else {
			self.readbuffer = [NSMutableData dataWithData:data];
			buffermark = 0;
			buffertruepos = readbuffer.length;
			bufferdirtystart = maxbuffersize;
			bufferdirtyend = 0;
		}
		glui32 gotlen = 0;
		if (readbuffer)
			gotlen = readbuffer.length;
		if (gotlen > len-sofar)
			gotlen = len-sofar;
		if (gotlen) {
			memcpy(resultdata.mutableBytes+sofar, data.bytes+buffermark, gotlen);
			buffermark += gotlen;
		}
		sofar += gotlen;
		return sofar;
	}
}

/* Write out one byte.
*/
- (void) writeByte:(char)ch {
	if (writable) {
		if (!writebuffer || buffermark >= maxbuffersize) {
			[self flush];
			bufferpos = [handle offsetInFile];
			NSData *data = nil;
			if (readable)
				data = [handle readDataOfLength:maxbuffersize];
			if (!data || !data.length) {
				// Must be at the end of the file, or it's a write-only file.
				self.writebuffer = [NSMutableData dataWithCapacity:maxbuffersize];
				buffermark = 0;
				buffertruepos = 0;
				bufferdirtystart = maxbuffersize;
				bufferdirtyend = 0;
			}
			else {
				self.writebuffer = [NSMutableData dataWithCapacity:maxbuffersize];
				[writebuffer setLength:data.length];
				memcpy(writebuffer.mutableBytes, data.bytes, data.length);
				buffermark = 0;
				buffertruepos = writebuffer.length;
				bufferdirtystart = maxbuffersize;
				bufferdirtyend = 0;
			}
		}
		if (writebuffer && buffermark < maxbuffersize) {
			if (buffermark < bufferdirtystart)
				bufferdirtystart = buffermark;
			if (buffermark+1 > writebuffer.length)
				[writebuffer setLength:buffermark+1];
			((char *)writebuffer.mutableBytes)[buffermark++] = ch;
			if (buffermark > bufferdirtyend)
				bufferdirtyend = buffermark;
		}
	}
}

/* Write out len bytes.
*/
- (void) writeBytes:(void *)bytes len:(glui32)len {
	if (writable) {
		if (writebuffer && buffermark < maxbuffersize) {
			glui32 addlen = maxbuffersize - buffermark;
			if (addlen > len)
				addlen = len;
			if (buffermark < bufferdirtystart)
				bufferdirtystart = buffermark;
			if (buffermark+addlen > writebuffer.length)
				[writebuffer setLength:buffermark+addlen];
			memcpy(writebuffer.mutableBytes+buffermark, bytes, addlen);
			buffermark += addlen;
			if (buffermark > bufferdirtyend)
				bufferdirtyend = buffermark;
			bytes += addlen;
			len -= addlen;
			if (!len)
				return;
		}
		[self flush];
		if (len >= maxbuffersize) {
			NSData *data = [NSData dataWithBytesNoCopy:bytes length:len freeWhenDone:NO];
			[handle writeData:data];
			return;
		}
		bufferpos = [handle offsetInFile];
		NSData *data = nil;
		if (readable)
			data = [handle readDataOfLength:maxbuffersize];
		if (!data || !data.length) {
			// Must be at the end of the file, or it's a write-only file.
			self.writebuffer = [NSMutableData dataWithCapacity:maxbuffersize];
			buffermark = 0;
			buffertruepos = 0;
			bufferdirtystart = maxbuffersize;
			bufferdirtyend = 0;
		}
		else {
			self.writebuffer = [NSMutableData dataWithCapacity:maxbuffersize];
			[writebuffer setLength:data.length];
			memcpy(writebuffer.mutableBytes, data.bytes, data.length);
			buffermark = 0;
			buffertruepos = writebuffer.length;
			bufferdirtystart = maxbuffersize;
			bufferdirtyend = 0;
		}
		/* Yeah, buffermark will always be zero at this point. I still write the code based on it, for clarity. */
		if (writebuffer && len <= maxbuffersize - buffermark) {
			if (buffermark < bufferdirtystart)
				bufferdirtystart = buffermark;
			if (buffermark+len > writebuffer.length)
				[writebuffer setLength:buffermark+len];
			memcpy(writebuffer.mutableBytes+buffermark, bytes, len);
			buffermark += len;
			if (buffermark > bufferdirtyend)
				bufferdirtyend = buffermark;
		}
	}
}


/* Flush and clear the internal buffer. */
- (void) flush {
	if (!(readbuffer || writebuffer))
		return;
		
	if (writable && writebuffer && bufferdirtystart < bufferdirtyend) {
		/* Write out the dirty part of the buffer. */
		[handle seekToFileOffset:bufferpos+bufferdirtystart];
		glui32 len = bufferdirtyend - bufferdirtystart;
		void *bytes = ((char *)writebuffer.bytes) + bufferdirtystart;
		NSData *data = [NSData dataWithBytesNoCopy:bytes length:len freeWhenDone:NO];
		[handle writeData:data];
		/* Adjust buffertruepos, which we will need in a moment to be correct. */
		buffertruepos = bufferdirtyend;
	}
	if (buffermark != buffertruepos) {
		/* Seek the filehandle pos to where the buffer thinks it ought to be. (We need this to be correct, because we might be doing a relative seek next.) */
		[handle seekToFileOffset:bufferpos+buffermark];
	}
	self.writebuffer = nil;
	self.readbuffer = nil;
	bufferpos = 0;
	buffermark = 0;
	buffertruepos = 0;
	bufferdirtystart = maxbuffersize;
	bufferdirtyend = 0;
}

/* The following are the external APIs for reading and writing the stream. They are all written in terms of the internal (buffer-smart) byte calls.
*/

- (void) putBuffer:(char *)buf len:(glui32)len {
	if (!len)
		return;
	writecount += len;

	if (!textmode) {
		if (!unicode) {
			/* byte stream */
			if (len == 1)
				[self writeByte:buf[0]];
			else
				[self writeBytes:buf len:len];
		}
		else {
			/* cheap big-endian stream */
			char *ubuf = malloc(4*len);
			bzero(ubuf, 4*len);
			for (int ix=0; ix<len; ix++)
				ubuf[4*ix+3] = buf[ix];
			[self writeBytes:ubuf len:4*len];
			free(ubuf);
		}
	}
	else {
		/* UTF8 stream (whether the unicode flag is set or not) */
		/* Turn the buffer into an NSString. We'll release this at the end of the function. */
		NSString *str = [[NSString alloc] initWithBytes:buf length:len encoding:NSISOLatin1StringEncoding];
		NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
		[self writeBytes:(void *)data.bytes len:data.length];
		[str release];
	}
}

- (void) putUBuffer:(glui32 *)buf len:(glui32)len {
	if (!len)
		return;
	writecount += len;

	if (!textmode) {
		if (!unicode) {
			/* byte stream */
			char *ubuf = malloc(len);
			for (int ix=0; ix<len; ix++) {
				glui32 ch = buf[ix];
				ubuf[ix] = (ch < 0x100) ? ch : '?';
			}
			[self writeBytes:ubuf len:len];
			free(ubuf);
		}
		else {
			/* cheap big-endian stream */
			char *ubuf = malloc(4*len);
			for (int ix=0; ix<len; ix++) {
				glui32 ch = buf[ix];
				ubuf[4*ix+0] = (ch >> 24) & 0xFF;
				ubuf[4*ix+1] = (ch >> 16) & 0xFF;
				ubuf[4*ix+2] = (ch >> 8) & 0xFF;
				ubuf[4*ix+3] = ch & 0xFF;
			}
			[self writeBytes:ubuf len:4*len];
			free(ubuf);
		}
	}
	else {
		/* UTF8 stream (whether the unicode flag is set or not) */
		/* Turn the buffer into an NSString. We'll release this at the end of the function. 
			This is an endianness dependency; we're telling NSString that our array of 32-bit words in stored little-endian. (True for all iOS, as I write this.) */
		NSString *str = [[NSString alloc] initWithBytes:buf length:len*sizeof(glui32) encoding:NSUTF32LittleEndianStringEncoding];
		NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
		[self writeBytes:(void *)data.bytes len:data.length];
		[str release];
	}
}

- (glsi32) getChar:(BOOL)wantunicode {
	if (!readable)
		return -1;

	if (!textmode) {
		if (!unicode) {
			/* byte stream */
			int ch = [self readByte];
			if (ch < 0)
				return -1;
			readcount++;
			return ch;
		}
		else {
			/* cheap big-endian stream */
			void *bytes;
			glui32 readlen = [self readBytes:&bytes len:4];
			if (readlen < 4)
				return -1;
			readcount++;
			char *buf = (char *)bytes;
			glui32 ch = ((buf[0] & 0xFF) << 24) | ((buf[1] & 0xFF) << 16) | ((buf[2] & 0xFF) << 8) | ((buf[3] & 0xFF));
			if (!wantunicode && ch >= 0x100)
				return '?';
			return ch;
		}		
	}
	else {
		/* UTF8 stream (whether the unicode flag is set or not) */
		/* We have to do our own UTF8 decoding here. There's no NSFileHandle method to read a variable-length UTF8 character. I'm very sorry. */
		int ch = [self readByte];
		if (ch < 0)
			return -1;
		glui32 val0 = ch;
		if (val0 < 0x80) {
			readcount++;
			return val0;
		}
		if ((val0 & 0xE0) == 0xC0) {
			ch = [self readByte];
			if (ch < 0)
				return -1;
			glui32 val1 = ch;
			glui32 res = (val0 & 0x1f) << 6;
			res |= (val1 & 0x3f);
			readcount++;
			if (!wantunicode && res >= 0x100)
				return '?';
			return res;
		}
		if ((val0 & 0xF0) == 0xE0) {
			ch = [self readByte];
			if (ch < 0)
				return -1;
			glui32 val1 = ch;
			ch = [self readByte];
			if (ch < 0)
				return -1;
			glui32 val2 = ch;
			glui32 res = (((val0 & 0xf)<<12)  & 0x0000f000);
			res |= (((val1 & 0x3f)<<6) & 0x00000fc0);
			res |= (((val2 & 0x3f))    & 0x0000003f);
			readcount++;
			if (!wantunicode && res >= 0x100)
				return '?';
			return res;
		}
		if ((val0 & 0xF0) == 0xF0) {
			ch = [self readByte];
			if (ch < 0)
				return -1;
			glui32 val1 = ch;
			ch = [self readByte];
			if (ch < 0)
				return -1;
			glui32 val2 = ch;
			ch = [self readByte];
			if (ch < 0)
				return -1;
			glui32 val3 = ch;
			glui32 res = (((val0 & 0x7)<<18)   & 0x1c0000);
			res |= (((val1 & 0x3f)<<12) & 0x03f000);
			res |= (((val2 & 0x3f)<<6)  & 0x000fc0);
			res |= (((val3 & 0x3f))     & 0x00003f);
			readcount++;
			if (!wantunicode && res >= 0x100)
				return '?';
			return res;
		}
		return -1;
	}
}

- (glui32) getLine:(void *)getbuf buflen:(glui32)getlen unicode:(BOOL)wantunicode {
	if (!readable)
		return 0;
		
	if (getlen == 0)
		return 0;
	
	getlen -= 1; /* for the terminal null */
	
	BOOL gotnewline = NO;
		
	if (!textmode) {
		if (!unicode) {
			/* byte stream */
			int ix;
			for (ix=0; !gotnewline && ix<getlen; ix++) {
				int ch = [self readByte];
				if (ch < 0)
					break;
				readcount++;
				if (!wantunicode)
					((char *)getbuf)[ix] = ch;
				else
					((glui32 *)getbuf)[ix] = ch;
				if (ch == '\n')
					gotnewline = YES;
			}
			if (!wantunicode)
				((char *)getbuf)[ix] = '\0';
			else
				((glui32 *)getbuf)[ix] = '\0';
			return ix;
		}
		else {
			/* cheap big-endian stream */
			int ix;
			for (ix=0; !gotnewline && ix<getlen; ix++) {
				void *bytes;
				glui32 readlen = [self readBytes:&bytes len:4];
				if (readlen < 4)
					break;
				readcount++;
				char *buf = (char *)bytes;
				glui32 ch = ((buf[0] & 0xFF) << 24) | ((buf[1] & 0xFF) << 16) | ((buf[2] & 0xFF) << 8) | ((buf[3] & 0xFF));
				if (!wantunicode)
					((char *)getbuf)[ix] = (ch >= 0x100) ? '?' : ch;
				else
					((glui32 *)getbuf)[ix] = ch;
				if (ch == '\n')
					gotnewline = YES;
			}
			if (!wantunicode)
				((char *)getbuf)[ix] = '\0';
			else
				((glui32 *)getbuf)[ix] = '\0';
			return ix;
		}		
	}
	else {
		/* UTF8 stream (whether the unicode flag is set or not) */
		/* Here we shamelessly rely on getChar to do our UTF-8 decoding. */
		glui32 count = 0;
		if (wantunicode) {
			glui32 *ugetbuf = getbuf;
			while (count < getlen) {
				glsi32 ch = [self getChar:YES];
				if (ch < 0)
					break;
				ugetbuf[count++] = ch;
				if (ch == '\n')
					break;
			}
			ugetbuf[count] = '\0';
		}
		else {
			char *cgetbuf = getbuf;
			while (count < getlen) {
				glsi32 ch = [self getChar:NO];
				if (ch < 0)
					break;
				cgetbuf[count++] = ch;
				if (ch == '\n')
					break;
			}
			cgetbuf[count] = '\0';
		}
		return count;
	}
}

- (glui32) getBuffer:(void *)getbuf buflen:(glui32)getlen unicode:(BOOL)wantunicode {
	if (!readable)
		return 0;
		
	if (!textmode) {
		if (!unicode) {
			/* byte stream */
			void *bytes;
			glui32 readlen = [self readBytes:&bytes len:getlen];
			if (!readlen)
				return 0;
			glui32 gotlen = readlen;
			readcount += gotlen;
			char *buf = (char *)bytes;
			if (wantunicode) {
				glui32 *ugetbuf = getbuf;
				for (int ix=0; ix<gotlen; ix++) {
					ugetbuf[ix] = (buf[ix] & 0xFF);
				}
			}
			else {
				memcpy(getbuf, buf, gotlen);
			}
			return gotlen;
		}
		else {
			/* cheap big-endian stream */
			void *bytes;
			glui32 readlen = [self readBytes:&bytes len:4*getlen];
			if (!readlen)
				return 0;
			glui32 gotlen = readlen / 4;
			readcount += gotlen;
			char *buf = (char *)bytes;
			if (wantunicode) {
				glui32 *ugetbuf = getbuf;
				for (int ix=0; ix<gotlen; ix++) {
					ugetbuf[ix] = ((buf[4*ix+0] & 0xFF) << 24) | ((buf[4*ix+1] & 0xFF) << 16) | ((buf[4*ix+2] & 0xFF) << 8) | ((buf[4*ix+3] & 0xFF));
				}
			}
			else {
				char *cgetbuf = getbuf;
				for (int ix=0; ix<gotlen; ix++) {
					glui32 ch = ((buf[4*ix+0] & 0xFF) << 24) | ((buf[4*ix+1] & 0xFF) << 16) | ((buf[4*ix+2] & 0xFF) << 8) | ((buf[4*ix+3] & 0xFF));
					if (ch >= 0x100)
						cgetbuf[ix] = '?';
					else
						cgetbuf[ix] = ch;
				}
			}
			return gotlen;
		}		
	}
	else {
		/* UTF8 stream (whether the unicode flag is set or not) */
		/* Here we shamelessly rely on getChar to do our UTF-8 decoding. */
		glui32 count = 0;
		if (wantunicode) {
			glui32 *ugetbuf = getbuf;
			while (count < getlen) {
				glsi32 ch = [self getChar:YES];
				if (ch < 0)
					break;
				ugetbuf[count++] = ch;
			}
		}
		else {
			char *cgetbuf = getbuf;
			while (count < getlen) {
				glsi32 ch = [self getChar:NO];
				if (ch < 0)
					break;
				cgetbuf[count++] = ch;
			}
		}
		return count;
	}
}

- (void) setPosition:(glsi32)pos seekmode:(glui32)seekmode {
	if (!textmode && unicode) {
		/* This file is in four-byte chunks. */
		pos *= 4;
	}
	
	/* We don't try to handle seeks efficiently within the buffered data. We just flush and seek on the underlying handle. */
	[self flush];
	
	switch (seekmode) {
		case seekmode_Start:
			[handle seekToFileOffset:pos];
			break;
		case seekmode_Current:
			pos += [handle offsetInFile];
			[handle seekToFileOffset:pos];
			break;
		case seekmode_End:
			[handle seekToEndOfFile];
			pos += [handle offsetInFile];
			[handle seekToFileOffset:pos];
			break;
	}
}

- (glui32) getPosition {
	glui32 pos;
	if (readbuffer || writebuffer) {
		pos = bufferpos+buffermark;
	}
	else {
		pos = [handle offsetInFile];
	}
	
	if (!textmode && unicode) {
		/* This file is in four-byte chunks. */
		pos /= 4;
	}
	return pos;
}


@end

