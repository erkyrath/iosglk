/* Geometry.m: A size descriptor for a Glk window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	This is the result of an annoying threading issue. I designed the original Glk API on single-threaded systems; I didn't think about what happens when the UI (in one thread) resizes itself while the VM (in another thread) is creating and destroying windows. The result isn't tidy.

	Therefore, the UI and VM have to keep *independent* descriptions of the Glk window geometry. For the VM, these describe the GlkWindow objects; for the UI, they describe the GlkWindowView objects. They sync up at glk_select() time -- see the updateFromLibraryState() method in GlkFrameView; that clones the GlkWindow information over to the GlkWindowViews.

	The Geometry object encapsulates everything a Glk pair window knows about its division model.
	
	(Note that this currently includes a shared pointer to the child windows' StyleSet objects. Since those objects are immutable, it's okay that two threads are reading from them simultaneously. If they ever start mutating, I'll have to clone them too.)
*/

#import "Geometry.h"
#import "GlkLibrary.h"
#import "IosGlkLibDelegate.h"
#import "StyleSet.h"

@implementation Geometry

@synthesize division;
@synthesize keytag;
@synthesize keystyleset;
@synthesize size;
@synthesize hasborder;
@synthesize vertical;
@synthesize backward;
@synthesize child1tag;
@synthesize child2tag;

- (id) init {
	self = [super init];
	
	if (self) {
		keytag = nil;
		keystyleset = nil;
		child1tag = nil;
		child2tag = nil;
	}
	
	return self;
}

- (void) dealloc {
	self.keytag = nil;
	self.keystyleset = nil;
	self.child1tag = nil;
	self.child2tag = nil;
	[super dealloc];
}

/* Standard copy method. Returns a retained object which is a (shallow) copy. */
- (id) copyWithZone:(NSZone *)zone {
	Geometry *copy = [[Geometry allocWithZone: zone] init];
	copy.dir = dir; /* sets vertical, backward */
	copy.division = division;
	copy.hasborder = hasborder;
	copy.keytag = keytag;
	copy.keystyleset = keystyleset;
	copy.size = size;
	copy.child1tag = child1tag;
	copy.child2tag = child2tag;
	return copy;
}

- (glui32) dir {
	return dir;
}

- (void) setDir:(glui32)val {
	dir = val;
	
	vertical = (dir == winmethod_Left || dir == winmethod_Right);
	backward = (dir == winmethod_Left || dir == winmethod_Above);
}

- (void) computeDivision:(CGRect)bbox for1:(CGRect *)boxref1 for2:(CGRect *)boxref2 {
	CGFloat min, max, diff;
	CGFloat split;
	CGFloat splitwid;
	CGSize windowspacing = [GlkLibrary singleton].glkdelegate.interWindowSpacing;
		
	if (vertical) {
		min = bbox.origin.x;
		max = min + bbox.size.width;
		splitwid = windowspacing.width;
	}
	else {
		min = bbox.origin.y;
		max = min + bbox.size.height;
		splitwid = windowspacing.height;
	}
	if (!hasborder)
		splitwid = 0;
	diff = max - min;

	if (division == winmethod_Proportional) {
		split = floorf((diff * size) / 100.0);
	}
	else if (division == winmethod_Fixed) {
		split = 0;
		if (keystyleset) {
			/* This really should depend on the type of the keywin also. Graphics windows are in pixels, etc. But we'll add that later. */
			if (!vertical)
				split = (size * keystyleset.charbox.height + keystyleset.margintotal.height);
			else
				split = (size * keystyleset.charbox.width + keystyleset.margintotal.width);
		}
		split = ceilf(split);
		NSLog(@"### computeDivision: size %d, char height %.1f -> split %.1f", size, keystyleset.charbox.width, split);
	}
	else {
		/* default behavior for unknown division method */
		split = floorf(diff / 2);
	}

	/* Split is now a number between 0 and diff. Convert that to a number
	   between min and max; also apply upside-down-ness. */
	if (!backward) {
		split = max-split-splitwid;
	}
	else {
		split = min+split;
	}

	/* Make sure it's really between min and max. */
	if (min >= max) {
		split = min;
	}
	else {
		split = fminf(fmaxf(split, min), max-splitwid);
	}
	
	CGRect box1 = bbox;
	CGRect box2 = bbox;

	if (vertical) {
		box1.size.width = split - bbox.origin.x;
		box2.origin.x = split + splitwid;
		box2.size.width = (bbox.origin.x+bbox.size.width) - box2.origin.x;
	}
	else {
		box1.size.height = split - bbox.origin.y;
		box2.origin.y = split + splitwid;
		box2.size.height = (bbox.origin.y+bbox.size.height) - box2.origin.y;
	}
	
	*boxref1 = box1;
	*boxref2 = box2;
}

@end
