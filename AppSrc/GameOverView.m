/* GameOverView.m: A popmenu subclass for the game-over menu
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import "GameOverView.h"
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
}

- (IBAction) handleRestartButton:(id)sender {
	[self.superviewAsFrameView removePopMenuAnimated:YES];
	[[GlkAppWrapper singleton] acceptEventRestart];
}

@end
