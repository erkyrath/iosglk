/* GlkUtilities.m: Miscellaneous C-callable functions
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "GlkUtilities.h"


NSString *StringFromRect(CGRect rect) {
	return [NSString stringWithFormat:@"%.1fx%.1f at %.1f,%.1f", 
		rect.size.width, rect.size.height, rect.origin.x, rect.origin.y];
}

extern void nslogc(char *str) {
	NSLog(@"%s", str);
}
