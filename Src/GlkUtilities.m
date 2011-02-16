/* GlkUtilities.m: Miscellaneous C-callable functions
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	A few utility functions that don't fit into any ObjC classes. (Either because they need to be C-callable, or just because.)
*/

#import "GlkUtilities.h"

/* Return a string showing the size of a rectangle. (For debugging.) */
NSString *StringFromRect(CGRect rect) {
	return [NSString stringWithFormat:@"%.1fx%.1f at %.1f,%.1f", 
		rect.size.width, rect.size.height, rect.origin.x, rect.origin.y];
}

/* Return a string showing a size. (For debugging.) */
extern NSString *StringFromSize(CGSize size) {
	return [NSString stringWithFormat:@"%.1fx%.1f", size.width, size.height];
}

/* Return a string showing a point. (For debugging.) */
NSString *StringFromPoint(CGPoint pt) {
	return [NSString stringWithFormat:@"%.1f,%.1f", pt.x, pt.y];
}

/* Log a C string to console. */
extern void nslogc(char *str) {
	NSLog(@"%s", str);
}
