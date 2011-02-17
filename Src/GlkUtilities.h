/* GlkUtilities.h: Miscellaneous C-callable functions
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <Foundation/Foundation.h>


extern NSString *StringFromRect(CGRect rect);
extern NSString *StringFromSize(CGSize size);
extern NSString *StringFromPoint(CGPoint pt);
extern void nslogc(char *str);
extern void sleep_curthread(NSTimeInterval val);
