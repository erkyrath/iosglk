//
//  GlkWindow.h
//  IosGlk
//
//  Created by Andrew Plotkin on 1/28/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "glk.h"

@class GlkLibrary;
@class GlkStream;
@class GlkWindowPair;

@interface GlkWindow : NSObject {
	glui32 dispid;
	
	GlkLibrary *library;
	
	glui32 type;
	glui32 rock;
	
	GlkWindowPair *parent;
	BOOL char_request;
	BOOL line_request;
	BOOL char_request_uni;
	BOOL line_request_uni;
	BOOL echo_line_input;
	glui32 style;
	
	GlkStream *stream;
	GlkStream *echostream;
}

@property (nonatomic, retain) GlkLibrary *library;
@property (nonatomic) glui32 type;
@property (nonatomic, retain) GlkWindowPair *parent;
@property (nonatomic) glui32 style;
@property (nonatomic, retain) GlkStream *stream;
@property (nonatomic, retain) GlkStream *echostream;

+ (void) initialize;
+ (GlkWindow *) windowWithType:(glui32)type rock:(glui32)rock;

- (id) initWithType:(glui32)type rock:(glui32)rock;
- (void) delete;
- (void) windowCloseRecurse:(BOOL)recurse;

//- (void) put_string:(char *)str;

@end


@interface GlkWindowBuffer : GlkWindow {
	NSMutableArray *updatetext; /* array of GlkStyledLine */
}

@property (nonatomic, retain) NSMutableArray *updatetext;

@end


@interface GlkWindowPair : GlkWindow {
	glui32 dir;
	glui32 division;
	BOOL hasborder;
	GlkWindow *key;
	glui32 size;
	BOOL keydamage;
	BOOL vertical;
	BOOL backward;
	
	GlkWindow *child1;
	GlkWindow *child2;
}

@property (nonatomic, retain) GlkWindow *child1;
@property (nonatomic, retain) GlkWindow *child2;
@property (nonatomic, retain) GlkWindow *key;
@property (nonatomic) BOOL keydamage;

- (id) initWithType:(glui32)type rock:(glui32)rock method:(glui32)method keywin:(GlkWindow *)keywin size:(glui32)size;

@end


