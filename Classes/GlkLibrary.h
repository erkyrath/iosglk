//
//  GlkLibrary.h
//  IosGlk
//
//  Created by Andrew Plotkin on 1/28/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GlkWindow;

@interface GlkLibrary : NSObject {
	NSMutableArray *windows; /* GlkWindow objects */
	GlkWindow *rootwin;
}

@property (nonatomic, retain) NSMutableArray *windows;
@property (nonatomic, retain) GlkWindow *rootwin;

+ (GlkLibrary *) singleton;
+ (void) strict_warning:(NSString *)msg;

@end
