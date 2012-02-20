//
//  PopBoxView.h
//  IosFizmo
//
//  Created by Andrew Plotkin on 2/20/12.
//  Copyright (c) 2012 Zarfhome. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GlkFrameView;

@interface PopMenuView : UIView {
	UIView *frameview;
	UIView *content;
	UIEdgeInsets framemargins; /* The distance around the content view on all sides */
	CGRect buttonrect; /* The bounds of the button that launched this menu */
}

@property (nonatomic, retain) IBOutlet UIView *frameview;
@property (nonatomic, retain) IBOutlet UIView *content;
@property (nonatomic) UIEdgeInsets framemargins;
@property (nonatomic, readonly) CGRect buttonrect;

- (id) initWithFrame:(CGRect)frame buttonFrame:(CGRect)rect;
- (GlkFrameView *) superviewAsFrameView;
- (void) loadContent;
- (void) resizeContentTo:(CGSize)size animated:(BOOL)animated;

@end
