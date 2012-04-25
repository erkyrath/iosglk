/* GameOverView.h: A popmenu subclass for the game-over menu
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import <UIKit/UIKit.h>

#import "PopMenuView.h"

@interface GameOverView : PopMenuView

@property (nonatomic, retain) IBOutlet UIView *container;

- (IBAction) handleRestartButton:(id)sender;

@end
