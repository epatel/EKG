//
//  EKGAppDelegate.h
//  EKG
//
//  Created by Edward Patel on 2009-08-13.
//  Copyright Memention AB 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EAGLView;

@interface EKGAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    EAGLView *glView;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet EAGLView *glView;

@end

