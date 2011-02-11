/* GlkWinGridView.h: Glk textgrid window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <UIKit/UIKit.h>
#import "GlkWindowView.h"


@interface GlkWinGridView : GlkWindowView {
	NSURL *cssurl;
	UIWebView *webview;
}

@property (nonatomic, retain) NSURL *cssurl;
@property (nonatomic, retain) UIWebView *webview;

@end
