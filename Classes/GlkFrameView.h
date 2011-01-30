//
//  GlkFrameView.h
//  IosGlk
//
//  Created by Andrew Plotkin on 1/28/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GlkLibrary;

@interface GlkFrameView : UIView {
	/* Maps Glk window IDs (as NSNumber objects) to GlkWin*View objects. */
	NSMutableDictionary *windows;
}

@property (nonatomic, retain) NSMutableDictionary *windows;

- (void) updateFromLibraryState:(GlkLibrary *)library;

@end
