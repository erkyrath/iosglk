/* GlkWindowView.h: Base class for a Glk window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <UIKit/UIKit.h>
#include "glk.h"

@class GlkWindow;

@interface GlkWindowView : UIView {
	GlkWindow *win;
}

@property (nonatomic, retain) GlkWindow *win;

+ (GlkWindowView *) viewForWindow:(GlkWindow *)win;

- (id) initWithWindow:(GlkWindow *)winref frame:(CGRect)box;
- (void) updateFromWindowState;
- (NSString *) htmlEscapeString:(NSString *)val;

@end
