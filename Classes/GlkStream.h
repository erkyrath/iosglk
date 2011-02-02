//
//  GlkStream.h
//  IosGlk
//
//  Created by Andrew Plotkin on 1/31/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "glk.h"

@class GlkWindow;

@interface GlkStream : NSObject {

}

+ (GlkStream *) openForWindow:(GlkWindow *)win;
+ (void) setCurrentStream:(GlkStream *)str;

- (void) delete;
- (void) fillResult:(stream_result_t *)result;

@end

