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
@synthesize type;
@synthesize rock;
@synthesize unicode;

- (id) initWithType:(GlkStreamType)strtype readable:(BOOL)isreadable writable:(BOOL)iswritable rock:(glui32)strrock {
	self = [super init];
	
	if (self) {
		self.library = [GlkLibrary singleton];
		inlibrary = YES;
		
		self.tag = [library newTag];
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

- (void) dealloc {
	NSLog(@"GlkStream dealloc %x", self);
	
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

- (id) initWithWindow:(GlkWindow *)winref {
	self = [super initWithType:strtype_Window readable:NO writable:YES rock:0];
	
	if (self) {
		self.win = winref;
	}
	
	return self;
}

- (void) dealloc {
	self.win = nil;
	[super dealloc];
}

- (void) streamDelete {
	self.win = nil;
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
			arrayrock = (*library.dispatch_register_arr)(buf, buflen, "&+#!Iu");
		}
	}
	
	return self;
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
				*bufptr = (ch >= 100 ? '?' : ch);
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

- (id) initWithMode:(glui32)fmode rock:(glui32)rockval unicode:(BOOL)isunicode fileref:(GlkFileRef *)fref {
	BOOL isreadable = (fmode == filemode_Read || fmode == filemode_ReadWrite);
	BOOL iswritable = (fmode != filemode_Read);

	self = [super initWithType:strtype_File readable:isreadable writable:iswritable rock:rockval];
	
	if (self) {
		/* Set the easy fields. */
		unicode = isunicode;
		textmode = fref.textmode;
		
		if (fmode != filemode_Read) {
			NSFileManager *filemanager = [GlkLibrary singleton].filemanager;
			
			/* Create the directory first, if it doesn't already exist. (If it already exists as a regular file, we won't try the create, the subsequent file-create will fail, and then the filehandle won't open.) */
			if (![filemanager fileExistsAtPath:fref.dirname isDirectory:nil])
				[filemanager createDirectoryAtPath:fref.dirname withIntermediateDirectories:YES attributes:nil error:nil];
			
			/* Create the file first, if it doesn't already exist. */
			if (![filemanager fileExistsAtPath:fref.pathname])
				[filemanager createFileAtPath:fref.pathname contents:nil attributes:nil];
		}

		/* Open the file handle. */
		NSFileHandle *newhandle = nil;
		switch (fmode) {
			case filemode_Read:
				newhandle = [NSFileHandle fileHandleForReadingAtPath:fref.pathname];
				break;
			case filemode_Write:
				newhandle = [NSFileHandle fileHandleForWritingAtPath:fref.pathname];
				break;
			case filemode_ReadWrite:
			case filemode_WriteAppend:
				newhandle = [NSFileHandle fileHandleForUpdatingAtPath:fref.pathname];
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

- (void) dealloc {
	self.handle = nil;
	[super dealloc];
}

- (void) streamDelete {
	[handle closeFile];
	self.handle = nil;
	[super streamDelete];
}

- (void) putBuffer:(char *)buf len:(glui32)len {
	if (!len)
		return;
	writecount += len;

	if (!textmode) {
		NSData *data;
		if (!unicode) {
			/* byte stream */
			data = [NSData dataWithBytesNoCopy:buf length:len freeWhenDone:NO];
		}
		else {
			/* cheap big-endian stream */
			char *ubuf = malloc(4*len);
			bzero(ubuf, 4*len);
			for (int ix=0; ix<len; ix++)
				ubuf[4*ix+3] = buf[ix];
			data = [NSData dataWithBytesNoCopy:ubuf length:4*len freeWhenDone:YES];
		}
		[handle writeData:data];
	}
	else {
		/* UTF8 stream (whether the unicode flag is set or not) */
		/* Turn the buffer into an NSString. We'll release this at the end of the function. */
		NSString *str = [[NSString alloc] initWithBytes:buf length:len encoding:NSISOLatin1StringEncoding];
		NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
		[handle writeData:data];
		[str release];
	}
}

- (void) putUBuffer:(glui32 *)buf len:(glui32)len {
	if (!len)
		return;
	writecount += len;

	if (!textmode) {
		NSData *data;
		if (!unicode) {
			/* byte stream */
			char *ubuf = malloc(len);
			for (int ix=0; ix<len; ix++) {
				glui32 ch = buf[ix];
				ubuf[ix] = (ch < 0x100) ? ch : '?';
			}
			data = [NSData dataWithBytesNoCopy:ubuf length:len freeWhenDone:YES];
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
			data = [NSData dataWithBytesNoCopy:ubuf length:4*len freeWhenDone:YES];
		}
		[handle writeData:data];
	}
	else {
		/* UTF8 stream (whether the unicode flag is set or not) */
		/* Turn the buffer into an NSString. We'll release this at the end of the function. 
			This is an endianness dependency; we're telling NSString that our array of 32-bit words in stored little-endian. (True for all iOS, as I write this.) */
		NSString *str = [[NSString alloc] initWithBytes:buf length:len*sizeof(glui32) encoding:NSUTF32LittleEndianStringEncoding];
		NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
		[handle writeData:data];
		[str release];
	}
}

- (glsi32) getChar:(BOOL)wantunicode {
	if (!readable)
		return -1;

	if (!textmode) {
		NSData *data;
		if (!unicode) {
			/* byte stream */
			data = [handle readDataOfLength:1];
			if (data.length < 1)
				return -1;
			readcount++;
			char *buf = (char *)data.bytes;
			return (buf[0] & 0xFF);
		}
		else {
			/* cheap big-endian stream */
			data = [handle readDataOfLength:4];
			if (data.length < 4)
				return -1;
			readcount++;
			char *buf = (char *)data.bytes;
			glui32 ch = ((buf[0] & 0xFF) << 24) | ((buf[1] & 0xFF) << 16) | ((buf[2] & 0xFF) << 8) | ((buf[3] & 0xFF));
			if (!wantunicode && ch >= 0x100)
				return '?';
			return ch;
		}		
	}
	else {
		/* UTF8 stream (whether the unicode flag is set or not) */
		/* We have to do our own UTF8 decoding here. There's no NSFileHandle method to read a variable-length UTF8 character. I'm very sorry. */
		NSData *data = [handle readDataOfLength:1];
		if (data.length < 1)
			return -1;
		glui32 val0 = ((char *)data.bytes)[0] & 0xFF;
		if (val0 < 0x80) {
			readcount++;
			return val0;
		}
		if ((val0 & 0xE0) == 0xC0) {
			data = [handle readDataOfLength:1];
			if (data.length < 1)
				return -1;
			glui32 val1 = ((char *)data.bytes)[0] & 0xFF;
			glui32 res = (val0 & 0x1f) << 6;
			res |= (val1 & 0x3f);
			readcount++;
			if (!wantunicode && res >= 0x100)
				return '?';
			return res;
		}
		if ((val0 & 0xF0) == 0xE0) {
			data = [handle readDataOfLength:2];
			if (data.length < 2)
				return -1;
			glui32 val1 = ((char *)data.bytes)[0] & 0xFF;
			glui32 val2 = ((char *)data.bytes)[1] & 0xFF;
			glui32 res = (((val0 & 0xf)<<12)  & 0x0000f000);
			res |= (((val1 & 0x3f)<<6) & 0x00000fc0);
			res |= (((val2 & 0x3f))    & 0x0000003f);
			readcount++;
			if (!wantunicode && res >= 0x100)
				return '?';
			return res;
		}
		if ((val0 & 0xF0) == 0xF0) {
			data = [handle readDataOfLength:3];
			if (data.length < 3)
				return -1;
			glui32 val1 = ((char *)data.bytes)[0] & 0xFF;
			glui32 val2 = ((char *)data.bytes)[1] & 0xFF;
			glui32 val3 = ((char *)data.bytes)[2] & 0xFF;
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
		
	BOOL gotnewline = NO;
		
	if (!textmode) {
		NSData *data;
		if (!unicode) {
			/* byte stream */
			int ix;
			for (ix=0; !gotnewline && ix<getlen; ix++) {
				data = [handle readDataOfLength:1];
				if (data.length < 1)
					break;
				readcount++;
				char *buf = (char *)data.bytes;
				char ch = (buf[0] & 0xFF);
				if (!wantunicode)
					((char *)getbuf)[ix] = ch;
				else
					((glui32 *)getbuf)[ix] = ch;
				if (ch == '\n')
					gotnewline = YES;
			}
			return ix;
		}
		else {
			/* cheap big-endian stream */
			int ix;
			for (ix=0; !gotnewline && ix<getlen; ix++) {
				data = [handle readDataOfLength:4];
				if (data.length < 4)
					break;
				readcount++;
				char *buf = (char *)data.bytes;
				glui32 ch = ((buf[0] & 0xFF) << 24) | ((buf[1] & 0xFF) << 16) | ((buf[2] & 0xFF) << 8) | ((buf[3] & 0xFF));
				if (!wantunicode)
					((char *)getbuf)[ix] = (ch >= 0x100) ? '?' : ch;
				else
					((glui32 *)getbuf)[ix] = ch;
				if (ch == '\n')
					gotnewline = YES;
			}
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
		}
		return count;
	}
}

- (glui32) getBuffer:(void *)getbuf buflen:(glui32)getlen unicode:(BOOL)wantunicode {
	if (!readable)
		return 0;
		
	if (!textmode) {
		NSData *data;
		if (!unicode) {
			/* byte stream */
			data = [handle readDataOfLength:getlen];
			glui32 gotlen = data.length;
			readcount += gotlen;
			char *buf = (char *)data.bytes;
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
			data = [handle readDataOfLength:4*getlen];
			glui32 gotlen = data.length / 4;
			readcount += gotlen;
			char *buf = (char *)data.bytes;
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
	glui32 pos = [handle offsetInFile];
	if (!textmode && unicode) {
		/* This file is in four-byte chunks. */
		pos /= 4;
	}
	return pos;
}


@end

