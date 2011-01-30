//
//  IosGlkViewController.h
//  IosGlk
//
//  Created by Andrew Plotkin on 1/28/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GlkFrameView;

@interface IosGlkViewController : UIViewController {

}

- (GlkFrameView *) viewAsFrameView;

@end

