//
//  GlkLibrary.h
//  IosGlk
//
//  Created by Andrew Plotkin on 1/28/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "glk.h"
#include "gi_dispa.h"

@class GlkWindow;
@class GlkStream;

@interface GlkLibrary : NSObject {
	NSMutableArray *windows; /* GlkWindow objects */
	NSMutableArray *streams; /* GlkStream objects */
	
	GlkWindow *rootwin;
	GlkStream *currentstr;
	CGRect bounds;
	
	NSInteger tagCounter;
	gidispatch_rock_t (*dispatch_register_obj)(void *obj, glui32 objclass);
	void (*dispatch_unregister_obj)(void *obj, glui32 objclass, gidispatch_rock_t objrock);
}

@property (nonatomic, retain) NSMutableArray *windows;
@property (nonatomic, retain) NSMutableArray *streams;
@property (nonatomic, retain) GlkWindow *rootwin;
@property (nonatomic, retain) GlkStream *currentstr;
@property (nonatomic) CGRect bounds;
@property (nonatomic) gidispatch_rock_t (*dispatch_register_obj)(void *obj, glui32 objclass);
@property (nonatomic) void (*dispatch_unregister_obj)(void *obj, glui32 objclass, gidispatch_rock_t objrock);

+ (GlkLibrary *) singleton;
+ (void) strictWarning:(NSString *)msg;

- (NSNumber *) newTag;
- (void) setMetrics:(CGRect)box;

@end
