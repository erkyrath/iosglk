//
//  GlkWindowView.h
//  IosGlk
//
//  Created by Andrew Plotkin on 1/28/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "glk.h"

@class GlkWindow;

@interface GlkWindowView : UIView {
	GlkWindow *win;
}

@property (nonatomic, retain) GlkWindow *win;

+ (GlkWindowView *) viewForWindow:(GlkWindow *)win;

- (id) initWithWindow:(GlkWindow *)winref frame:(CGRect)box;

@end
