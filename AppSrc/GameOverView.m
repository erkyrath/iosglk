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

- (void) dealloc {
	self.container = nil;
	[super dealloc];
}

- (void) loadContent {
	[[NSBundle mainBundle] loadNibNamed:@"GameOverView" owner:self options:nil];
	[self resizeContentTo:container.frame.size animated:YES];
	[content addSubview:container];

	if (faderview) {
		IosGlkViewController *glkviewc = [IosGlkViewController singleton];
		faderview.alpha = ((glkviewc.glkdelegate.hasDarkTheme) ? 1.0 : 0.0);
		faderview.hidden = NO;
	}
}

- (IBAction) handleRestartButton:(id)sender {
	[self.superviewAsFrameView removePopMenuAnimated:YES];
	[[GlkAppWrapper singleton] acceptEventRestart];
}

@end
