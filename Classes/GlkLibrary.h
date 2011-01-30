//
//  GlkLibrary.h
//  IosGlk
//
//  Created by Andrew Plotkin on 1/28/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GlkWindowBase;

@interface GlkLibrary : NSObject {
	/* Maps Glk window IDs (as NSNumber objects) to GlkWin objects. */
	NSMutableArray *windows;
	GlkWindowBase *rootwin;
}

@property (nonatomic, retain) NSMutableArray *windows;
@property (nonatomic, retain) GlkWindowBase *rootwin;

+ (GlkLibrary *) singleton;

@end

