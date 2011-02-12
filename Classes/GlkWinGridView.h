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
	
	NSMutableArray *lines; /* array of NSString containing lines of HTML */
}

@property (nonatomic, retain) NSURL *cssurl;
@property (nonatomic, retain) UIWebView *webview;

@property (nonatomic, retain) NSMutableArray *lines;

@end
