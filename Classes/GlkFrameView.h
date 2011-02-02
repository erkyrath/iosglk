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
	/* Maps tags (NSNumbers) to GlkWindowViews. (But pair windows are excluded.) */
	NSMutableDictionary *windowviews;
}

@property (nonatomic, retain) NSMutableDictionary *windowviews;

- (void) updateFromLibraryState:(GlkLibrary *)library;

@end
