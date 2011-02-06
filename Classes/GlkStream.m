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
	
	//### subclasses: gidispa unregister memory, deref window

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

@end

