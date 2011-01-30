//
//  GlkWindow.h
//  IosGlk
//
//  Created by Andrew Plotkin on 1/28/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "glk.h"

@interface GlkWindowBase : NSObject {
	glui32 id;
	
	glui32 curstyle;
}

+ (void) initialize;
+ (GlkWindowBase *) windowWithType:(glui32)type rock:(glui32)rock;

- (id) initWithType:(glui32)type rock:(glui32)rock;
- (void) put_string:(char *)str;

@end

@interface GlkWindowBuffer : GlkWindowBase {
	NSMutableArray *updatetext; /* array of GlkStyledLine */
	//glui32 uncapturedstyle;
	//NSMutableArray *uncapturedtext; /* array of NSString (not yet joined into updatetext) */
}

@property (nonatomic, retain) NSMutableArray *updatetext;
//@property (nonatomic, retain) NSMutableArray *uncapturedtext;

//- (void) captureText;

@end
