/* GlkLibrary.m: Library context object
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "GlkLibrary.h"
#import "GlkWindow.h"
#include "GlkUtilities.h"
#include "glk.h"

@implementation GlkLibrary

@synthesize windows;
@synthesize streams;
@synthesize rootwin;
@synthesize currentstr;
@synthesize bounds;
@synthesize dispatch_register_obj;
@synthesize dispatch_unregister_obj;

static GlkLibrary *singleton = nil;

+ (GlkLibrary *) singleton {
	return singleton;
}

- (id) init {
	self = [super init];
	
	if (self) {
		if (singleton)
			[NSException raise:@"GlkException" format:@"cannot create two GlkLibrary objects"];
		singleton = self;
		
		tagCounter = 0;
		dispatch_register_obj = nil;
		dispatch_unregister_obj = nil;
		
		self.windows = [NSMutableArray arrayWithCapacity:8];
		self.streams = [NSMutableArray arrayWithCapacity:8];
		self.rootwin = nil;
		self.currentstr = nil;
	}
	
	return self;
}

- (void) dealloc {
	NSLog(@"GlkLibrary dealloc %x", self);
	if (singleton == self)
		singleton = nil;
	self.windows = nil;
	self.streams = nil;
	self.rootwin = nil;
	[super dealloc];
}

- (NSNumber *) newTag {
	tagCounter++;
	return [NSNumber numberWithInteger:tagCounter];
}

- (void) setMetrics:(CGRect)box {
	bounds = box;
	NSLog(@"library metrics now %@", StringFromRect(bounds));
}

+ (void) strictWarning:(NSString *)msg {
	NSLog(@"strict warning: %@", msg);
}

@end

