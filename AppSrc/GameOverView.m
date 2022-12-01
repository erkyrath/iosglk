/* GameOverView.m: A popmenu subclass for the game-over menu
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import "GameOverView.h"
#import "IosGlkViewController.h"
#import "IosGlkLibDelegate.h"
#import "GlkAppWrapper.h"
#import "GlkFrameView.h"

@implementation GameOverView

@synthesize container;


- (NSString *) nibForContent {
	return @"GameOverView";
}

- (void) loadContent {
	[[NSBundle mainBundle] loadNibNamed:self.nibForContent owner:self options:nil];
	[self resizeContentTo:container.frame.size animated:YES];
	[content addSubview:container];

	if (faderview) {
		IosGlkViewController *glkviewc = [IosGlkViewController singleton];
		faderview.alpha = ((glkviewc.hasDarkTheme) ? 1.0 : 0.0);
		faderview.hidden = NO;
	}
}

- (IBAction) handleRestartButton:(id)sender {
	[self.superviewAsFrameView removePopMenuAnimated:YES];
	[[GlkAppWrapper singleton] acceptEventRestart];
}

@end
