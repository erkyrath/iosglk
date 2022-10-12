/* GlkLibraryState.h: A class that encapsulates all the UI-important state of the library
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import <Foundation/Foundation.h>

@interface GlkLibraryState : NSObject {
	NSArray *windows; /* GlkWindowState objects */
	
	BOOL vmexited;
	NSNumber *rootwintag;
	id specialrequest;
	
	BOOL geometrychanged;
	BOOL metricschanged;
	BOOL everythingchanged;
}

@property (nonatomic, strong) NSArray *windows;
@property (nonatomic) BOOL vmexited;
@property (nonatomic, strong) NSNumber *rootwintag;
@property (nonatomic, strong) id specialrequest;
@property (nonatomic) BOOL geometrychanged;
@property (nonatomic) BOOL metricschanged;
@property (nonatomic) BOOL everythingchanged;

@end

