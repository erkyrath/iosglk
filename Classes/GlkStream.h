//
//  GlkStream.h
//  IosGlk
//
//  Created by Andrew Plotkin on 1/31/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "glk.h"
#include "gi_dispa.h"

@class GlkLibrary;
@class GlkWindow;

typedef enum GlkStreamType_enum {
	strtype_None=0,
	strtype_File=1,
	strtype_Window=2,
	strtype_Memory=3
} GlkStreamType;

@interface GlkStream : NSObject {
	GlkLibrary *library;
	BOOL inlibrary;
	
	NSNumber *tag;
	gidispatch_rock_t disprock;

	GlkStreamType type; /* file, window, or memory stream */
	glui32 rock;
	BOOL unicode; /* one-byte or four-byte chars? Not meaningful for windows */

	glui32 readcount, writecount;
	BOOL readable, writable;
}

@property (nonatomic, retain) GlkLibrary *library;
@property (nonatomic, retain) NSNumber *tag;
@property (nonatomic) GlkStreamType type;
@property (nonatomic) glui32 rock;
@property (nonatomic) BOOL unicode;

- (id) initWithType:(GlkStreamType)strtype readable:(BOOL)isreadable writable:(BOOL)iswritable rock:(glui32)strrock;
- (void) streamDelete;
- (void) fillResult:(stream_result_t *)result;
- (void) putChar:(unsigned char)ch;
- (void) putCString:(char *)s;
- (void) putBuffer:(char *)buf len:(glui32)len;

@end


@interface GlkStreamWindow : GlkStream {
	GlkWindow *win;
}

@property (nonatomic, retain) GlkWindow *win;

- (id) initWithWindow:(GlkWindow *)win;

@end

