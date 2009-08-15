//
//  EKGAppDelegate.m
//  EKG
//
//  Created by Edward Patel on 2009-08-13.
//  Copyright Memention AB 2009. All rights reserved.
//

#import "EKGAppDelegate.h"
#import "EAGLView.h"

@implementation EKGAppDelegate

@synthesize window;
@synthesize glView;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    
	glView.animationInterval = 1.0/60.0;
	[glView startAnimation];
}


- (void)applicationWillResignActive:(UIApplication *)application {
//	glView.animationInterval = 1.0 / 5.0;
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
//	glView.animationInterval = 1.0 / 30.0;
}


- (void)dealloc {
	[window release];
	[glView release];
	[super dealloc];
}

@end
