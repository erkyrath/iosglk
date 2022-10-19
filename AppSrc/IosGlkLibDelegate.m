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

/* Check whether the given file is a save file for your app (or game). Return one of the GlkSaveFormat constants.
 */
- (GlkSaveFormat) checkGlkSaveFileFormat:(NSString *)path {
	return saveformat_UnknownFormat;
}

/* This is invoked after a file has been imported into the app from another app. You should open the app's usual file display UI (if there is one) and highlight the given file.
 */
- (void) displayGlkFileUsage:(int)usage name:(NSString *)filename {
}

/* Create a GlkWinBufferView instance. Override this method if you want to use a custom subclass in your app.
 */
- (GlkWinBufferView *) viewForBufferWindow:(GlkWindowState *)win frame:(CGRect)box margin:(UIEdgeInsets)margin {
	return nil;
}

/* Create a GlkWinGridView instance. Override this method if you want to use a custom subclass in your app.
 */
- (GlkWinGridView *) viewForGridWindow:(GlkWindowState *)win frame:(CGRect)box margin:(UIEdgeInsets)margin {
	return nil;
}

/* Decide whether a single-tap should open the keyboard (toopen=YES) or close it (toopen=NO). Return YES to allow the change, NO to block it.
 */
- (BOOL) shouldTapSetKeyboard:(BOOL)toopen {
	return YES;
}

/* Set up the tables of styles which will be used for Glk buffer and grid windows. You might take app preferences or device capabilities into account when customizing this method.
 
	This is invoked from both the VM and UI threads.
 */
- (void) prepareStyles:(StyleSet *)styles forWindowType:(glui32)wintype rock:(glui32)rock {
	CGFloat fontsize = (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) ? 14 : 16;
	
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

/* Return whether the app styles are set to a generally dark palette. The app uses this to decide some minor display details, like scroll bar tint.
 */
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

/* If you want a window's "real" bounds to be larger than its apparent bounds, customize this method to return a structure with left and right margins. The rect argument is the window's new frame; the framerect argument is the GlkFrameView's (unadjusted) bounds.
 
	(Top and bottom margins are currently not supported! And by "not supported", I mean "scrolling will go horribly wrong." Leave 'em zero.)
 
	The only reason for this, at the moment, is to spread out a GlkWinBufferView so that its left and right margins permit scroll and select gestures.
 
	Invoked from the UI thread.
 */
- (UIEdgeInsets) viewMarginForWindow:(GlkWindowState *)win rect:(CGRect)rect framebounds:(CGRect)framebounds {
	return UIEdgeInsetsZero;
}

/* This is invoked from the VM thread, when glk_exit() is called. 
 */
- (void) vmHasExited {
}

@end

