//
//  GlkStream.m
//  IosGlk
//
//  Created by Andrew Plotkin on 1/31/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import "GlkStream.h"
#import "GlkWindow.h"
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
	
	//### subclasses: for file, close and deref the file

	if (library.dispatch_unregister_obj)
		(*library.dispatch_unregister_obj)(self, gidisp_Class_Stream, disprock);
		
	if (![library.streams containsObject:self])
		[NSException raise:@"GlkException" format:@"GlkStream was not in library streams list"];
	[library.streams removeObject:self];
	inlibrary = NO;
}

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
	if (styl >= style_NUMSTYLES)
		styl = 0;
		
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
		
		//### gidispa register array
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
		
		//### gidispa register array
	}
	
	return self;
}

- (void) streamDelete {
	//### gidispa unregister array
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

@end

