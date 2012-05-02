/* IosGlkLibDelegate.h: Library delegate protocol
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import <Foundation/Foundation.h>
#include "glk.h"

@class StyleSet;
@class GlkWinBufferView;
@class GlkWinGridView;
@class GlkWindowState;

@protocol IosGlkLibDelegate <NSObject>

- (NSString *) gameId;
- (GlkWinBufferView *) viewForBufferWindow:(GlkWindowState *)win frame:(CGRect)box;
- (GlkWinGridView *) viewForGridWindow:(GlkWindowState *)win frame:(CGRect)box;
- (void) prepareStyles:(StyleSet *)styles forWindowType:(glui32)wintype rock:(glui32)rock;
- (BOOL) hasDarkTheme;
- (CGSize) interWindowSpacing;
- (CGRect) adjustFrame:(CGRect)rect;
- (void) vmHasExited;

@end


@interface DefaultGlkLibDelegate : NSObject <IosGlkLibDelegate> {
}

+ (DefaultGlkLibDelegate *) singleton;

@end
