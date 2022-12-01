/* GlkLibraryState.m: A class that encapsulates all the UI-important state of the library
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import "GlkLibraryState.h"

@implementation GlkLibraryState

@synthesize windows;
@synthesize vmexited;
@synthesize rootwintag;
@synthesize specialrequest;
@synthesize geometrychanged;
@synthesize metricschanged;
@synthesize everythingchanged;


@end
