/* GlkWinBufferView.h: Glk textbuffer window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <UIKit/UIKit.h>
#import "GlkWindowView.h"


@interface GlkWinBufferView : GlkWindowView {
	NSURL *cssurl;
	UIWebView *webview;

	NSMutableArray *lines; /* array of NSString containing lines (paragraphs, really) of HTML */
	NSString *lastline; /* if the last line doesn't end with a newline, it sits here */
}

@property (nonatomic, retain) NSURL *cssurl;
@property (nonatomic, retain) UIWebView *webview;

@property (nonatomic, retain) NSMutableArray *lines;
@property (nonatomic, retain) NSString *lastline;

@end
