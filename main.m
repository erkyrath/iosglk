/* main.m: Top main() function
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*
IosGlk -- an iOS implementation	of the Glk API.

IosGlk library:	version	0.3.0.
Glk API which this implements: version 0.7.3.

The source code in this package is copyright 2011 by Andrew Plotkin. You
may copy and distribute it freely, by any means and under any conditions,
as long as the code and documentation is not changed. You may also
incorporate this code into your own program and distribute that, or modify
this code and use and distribute the modified version, as long as you retain
a notice in your program or documentation which mentions my name and the
URL shown above.
*/

#import <UIKit/UIKit.h>

int main(int argc, char *argv[]) {
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, nil);
    [pool release];
    return retVal;
}
