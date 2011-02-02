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
	CGRect bounds;
	
	NSInteger tagCounter;
}

@property (nonatomic, retain) NSMutableArray *windows;
@property (nonatomic, retain) GlkWindow *rootwin;
@property (nonatomic) CGRect bounds;

+ (GlkLibrary *) singleton;
+ (void) strictWarning:(NSString *)msg;

- (NSNumber *) newTag;
- (void) setMetrics:(CGRect)box;

@end
