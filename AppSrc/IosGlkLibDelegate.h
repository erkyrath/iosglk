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
- (GlkWinBufferView *) viewForBufferWindow:(GlkWindowState *)win frame:(CGRect)box margin:(UIEdgeInsets)margin;
- (GlkWinGridView *) viewForGridWindow:(GlkWindowState *)win frame:(CGRect)box margin:(UIEdgeInsets)margin;
- (void) prepareStyles:(StyleSet *)styles forWindowType:(glui32)wintype rock:(glui32)rock;
- (BOOL) hasDarkTheme;
- (CGSize) interWindowSpacing;
- (CGRect) adjustFrame:(CGRect)rect;
- (UIEdgeInsets) viewMarginForWindow:(GlkWindowState *)win;
- (void) vmHasExited;

@end


@interface DefaultGlkLibDelegate : NSObject <IosGlkLibDelegate> {
}

+ (DefaultGlkLibDelegate *) singleton;

@end
