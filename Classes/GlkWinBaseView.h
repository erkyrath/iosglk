//
//  GlkWinBaseView.h
//  IosGlk
//
//  Created by Andrew Plotkin on 1/28/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "glk.h"

@interface GlkWinBaseView : UIView {
	glui32 dispid;
}

@property (nonatomic) glui32 dispid;

@end
