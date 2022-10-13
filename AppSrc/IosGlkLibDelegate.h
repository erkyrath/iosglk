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

/* The return value of the checkGlkSaveFileFormat method. */
typedef enum GlkSaveFormat_enum {
	saveformat_Ok = 0,
	saveformat_Unreadable = 1,
	saveformat_UnknownFormat = 2,
	saveformat_WrongGame = 3,
	saveformat_WrongVersion = 4,	
} GlkSaveFormat;

@protocol IosGlkLibDelegate <NSObject>

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *gameId;
- (GlkSaveFormat) checkGlkSaveFileFormat:(NSString *)path;
- (void) displayGlkFileUsage:(int)usage name:(NSString *)filename;
- (GlkWinBufferView *) viewForBufferWindow:(GlkWindowState *)win frame:(CGRect)box margin:(UIEdgeInsets)margin;
- (GlkWinGridView *) viewForGridWindow:(GlkWindowState *)win frame:(CGRect)box margin:(UIEdgeInsets)margin;
- (BOOL) shouldTapSetKeyboard:(BOOL)toopen;
- (void) prepareStyles:(StyleSet *)styles forWindowType:(glui32)wintype rock:(glui32)rock;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasDarkTheme;
@property (NS_NONATOMIC_IOSONLY, readonly) CGSize interWindowSpacing;
- (CGRect) adjustFrame:(CGRect)rect;
- (UIEdgeInsets) viewMarginForWindow:(GlkWindowState *)win rect:(CGRect)rect framebounds:(CGRect)framebounds;
- (void) vmHasExited;

@end


@interface DefaultGlkLibDelegate : NSObject <IosGlkLibDelegate> {
}

+ (DefaultGlkLibDelegate *) singleton;

@end
