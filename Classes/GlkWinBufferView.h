//
//  GlkWinBufferView.h
//  IosGlk
//
//  Created by Andrew Plotkin on 1/28/11.
//  Copyright 2011 Andrew Plotkin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GlkWinBaseView.h"


@interface GlkWinBufferView : GlkWinBaseView {
	NSURL *cssurl;
	UIWebView *webview;
}

@property (nonatomic, retain) NSURL *cssurl;
@property (nonatomic, retain) UIWebView *webview;

@end
