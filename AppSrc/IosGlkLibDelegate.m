/* IosGlkLibDelegate.m: Library delegate protocol -- default implementation
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import "IosGlkLibDelegate.h"
#import "GlkWindowState.h"
#import "GlkWinBufferView.h"
#import "GlkWinGridView.h"
#import "StyleSet.h"

@implementation DefaultGlkLibDelegate

DefaultGlkLibDelegate *_DefaultGlkLibDelegate_singleton = nil; // retained forever

+ (DefaultGlkLibDelegate *) singleton {
	if (!_DefaultGlkLibDelegate_singleton)
		_DefaultGlkLibDelegate_singleton = [[DefaultGlkLibDelegate alloc] init]; // retained
	return _DefaultGlkLibDelegate_singleton;
}

- (NSString *) gameId {
	return nil;
}

- (GlkWinBufferView *) viewForBufferWindow:(GlkWindowState *)win frame:(CGRect)box margin:(UIEdgeInsets)margin {
	return nil;
}

- (GlkWinGridView *) viewForGridWindow:(GlkWindowState *)win frame:(CGRect)box margin:(UIEdgeInsets)margin {
	return nil;
}

/* This is invoked from both the VM and UI threads.
 */
- (void) prepareStyles:(StyleSet *)styles forWindowType:(glui32)wintype rock:(glui32)rock {
	CGFloat fontsize = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? 14 : 16;
	
	if (wintype == wintype_TextGrid) {
		styles.margins = UIEdgeInsetsMake(4, 6, 4, 6);
		
		FontVariants variants = [StyleSet fontVariantsForSize:fontsize name:@"Courier", nil];
		styles.fonts[style_Normal] = variants.normal;
		styles.fonts[style_Emphasized] = variants.italic;
		styles.fonts[style_Preformatted] = variants.normal;
		styles.fonts[style_Header] = variants.bold;
		styles.fonts[style_Subheader] = variants.bold;
		styles.fonts[style_Alert] = variants.italic;
		styles.fonts[style_Note] = variants.italic;
		
	}
	else {
		styles.margins = UIEdgeInsetsMake(4, 6, 4, 6);
		
		FontVariants variants = [StyleSet fontVariantsForSize:fontsize name:@"HelveticaNeue", @"Helvetica", nil];
		styles.fonts[style_Normal] = variants.normal;
		styles.fonts[style_Emphasized] = variants.italic;
		styles.fonts[style_Preformatted] = [UIFont fontWithName:@"Courier" size:fontsize];
		styles.fonts[style_Header] = [variants.bold fontWithSize:fontsize+3];
		styles.fonts[style_Subheader] = variants.bold;
		styles.fonts[style_Alert] = variants.italic;
		styles.fonts[style_Note] = variants.italic;
		
	}
}

- (BOOL) hasDarkTheme {
	return NO;
}

/* Define the width/height of the blank space between windows.
 
	This is invoked from both the VM and UI threads.
 */
- (CGSize) interWindowSpacing {
	return CGSizeMake(4, 4);
}

/* If you want your game content to occupy only a part of the GlkFrameView bounds, customize this method to return a subrectangle.
 */
- (CGRect) adjustFrame:(CGRect)rect {
	return rect;
}

/* If you want a window's "real" bounds to be larger than its apparent bounds, customize this method to return a structure with left and right margins. (Top and bottom margins are currently not supported! And by "not supported", I mean "scrolling will go horribly wrong." Leave 'em zero.)
 
	The only reason for this, at the moment, is to spread out a GlkWinBufferView so that its left and right margins permit scroll and select gestures.
 
	Invoked from the UI thread.
 */
- (UIEdgeInsets) viewMarginForWindow:(GlkWindowState *)win {
	return UIEdgeInsetsZero;
}

/* This is invoked from the VM thread, when glk_exit() is called. 
 */
- (void) vmHasExited {
}

@end

