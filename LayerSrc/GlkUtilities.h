/* GlkUtilities.h: Miscellaneous C-callable functions
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <Foundation/Foundation.h>


extern NSString *StringFromRect(CGRect rect);
extern NSString *StringFromRectAlt(CGRect rect);
extern NSString *StringFromSize(CGSize size);
extern NSString *StringFromPoint(CGPoint pt);
extern NSString *StringToCondensedString(NSString *str);
extern NSString *StringFromDumbEncoding(NSString *str);
extern NSString *StringToDumbEncoding(NSString *str);

extern BOOL NumberMatch(NSNumber *num1, NSNumber *num2);
extern BOOL StringsMatch(NSString *val1, NSString *val2);

extern CGSize CGSizeEven(CGSize size);
extern CGPoint RectCenter(CGRect rect);
extern CGFloat DistancePoints(CGPoint p1, CGPoint p2);
extern UIEdgeInsets UIEdgeInsetsInvert(UIEdgeInsets margins);
extern UIEdgeInsets UIEdgeInsetsRectDiff(CGRect rect1, CGRect rect2);

extern void nslogc(char *str);
extern void sleep_curthread(NSTimeInterval val);
