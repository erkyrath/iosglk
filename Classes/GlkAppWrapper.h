//
//  GlkAppWrapper.h
//  IosGlk
//
//  Created by Andrew Plotkin on 1/28/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GlkAppWrapper : NSObject {
	BOOL iowait; /* true when waiting for an event; becomes false when one arrives */
	NSCondition *iowaitcond;
	NSThread *thread;
}

@property (nonatomic, retain) NSCondition *iowaitcond;
@property BOOL iowait; /* atomic */

+ (GlkAppWrapper *) singleton;

- (void) launchAppThread;
- (void) appThreadMain:(id)rock;
- (void) select;

@end
