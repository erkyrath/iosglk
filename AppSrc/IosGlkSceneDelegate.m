//
//  IosGlkSceneDelegate.m
//  iosglulxe
//
//  Created by Administrator on 2022-11-05.
//
#import "IosGlkAppDelegate.h"
#import "IosGlkViewController.h"
#import "IosGlkLibDelegate.h"
#import "GlkLibrary.h"
#import "GlkFrameView.h"
#import "GlkAppWrapper.h"

#import "IosGlkSceneDelegate.h"


@implementation IosGlkSceneDelegate

@synthesize mainSceneActivityType = _mainSceneActivityType;


// Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
// If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
// This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    NSUserActivity *userActivity = connectionOptions.userActivities.anyObject;
    if (!userActivity) {
        userActivity = session.stateRestorationActivity;
    }

    UIWindowScene *winScene = (UIWindowScene *)scene;
    if (winScene) {

        scene.userActivity = userActivity;

        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        UITabBarController *vc = (UITabBarController *)[storyboard instantiateViewControllerWithIdentifier:@"RootTabBarController"];

        /* Set library.glkdelegate to a default value, if the glkviewc doesn't provide one. (Remember, from now on, that glkviewc.glkdelegate may be null!) */
        IosGlkAppDelegate *appdel = [IosGlkAppDelegate singleton];

        UINavigationController *gameNavController = vc.viewControllers[0];

        appdel.glkviewc = (IosGlkViewController *)gameNavController.viewControllers[0];

        if (appdel.glkviewc.glkdelegate)
            appdel.library.glkdelegate = appdel.glkviewc.glkdelegate;
        else
            appdel.library.glkdelegate = [DefaultGlkLibDelegate singleton];

        [[NSNotificationCenter defaultCenter] addObserver:appdel.glkviewc
                                                 selector:@selector(keyboardWillBeShown:)
                                                     name:UIKeyboardWillShowNotification object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:appdel.glkviewc
                                                 selector:@selector(keyboardWillBeHidden:)
                                                     name:UIKeyboardWillHideNotification object:nil];

        self.window = [[UIWindow alloc] initWithWindowScene:winScene];
        self.window.rootViewController = vc;

        if (userActivity) {
            NSLog(@"Found userActivity in connectionOptions");
            NSDictionary *activityUserInfo = userActivity.userInfo;
            if (activityUserInfo) {
                NSDictionary *stateOfViews = activityUserInfo[@"GlkWindowViewStates"];
                if (stateOfViews) {
                    appdel.glkviewc.frameview.waitingToRestoreFromState = YES;
                    NSLog(@"scene: willConnectToSession calling frameview updateWithUIStates");
                    [appdel.glkviewc.frameview updateWithUIStates:stateOfViews];
                } else {
                    NSLog(@"No stateOfViews in activityUserInfo");
                }
            } else {
                NSLog(@"No activityUserInfo in userActivity");
            }
        } else {
            NSLog(@"No userActivity in connectionOptions");
        }

        [self.window makeKeyAndVisible];

        [appdel.glkviewc didFinishLaunching];

        CGRect box = appdel.glkviewc.frameview.bounds;
        if (appdel.glkviewc.glkdelegate)
            box = [appdel.glkviewc.glkdelegate adjustFrame:box];
        [appdel.library setMetricsChanged:YES bounds:&box];

        NSLog(@"SceneDelegate launching app thread");

        [appdel.glkapp launchAppThread];

        if (session.stateRestorationActivity == nil)
            NSLog(@"session.stateRestorationActivity is still nil!");

        NSURL *url = connectionOptions.URLContexts.allObjects.firstObject.URL;
        if (url) {
            [self scene:scene openURLContexts:connectionOptions.URLContexts];
        }
    }
}

- (NSUserActivity *)stateRestorationActivityForScene:(UIScene *)scene {

    /** This is the NSUserActivity that you use to restore state when the Scene reconnects.
     It can be the same activity that you use for handoff or spotlight, or it can be a separate activity
     with a different activity type and/or userInfo.

     This object must be lightweight. You should store the key information about what the user was doing last.

     After the system calls this function, and before it saves the activity in the restoration file, if the returned NSUserActivity has a
     delegate (NSUserActivityDelegate), the function userActivityWillSave calls that delegate. Additionally, if any UIResponders have the activity
     set as their userActivity property, the system calls the UIResponder updateUserActivityState function to update the activity.
     This happens synchronously and ensures that the system has filled in all the information for the activity before saving it.
     */

    NSLog(@"stateRestorationActivityForScene %@", scene);
    UITabBarController *vc = (UITabBarController *)_window.rootViewController;
    if (!vc)
        return nil;
    UINavigationController *gameNavController = vc.viewControllers[0];

    IosGlkViewController *glkViewController = (IosGlkViewController *)gameNavController.viewControllers[0];
    if (!glkViewController) {
        NSLog(@"stateRestorationActivityForScene: glkViewController is nil!");
        return nil;
    }
    if (![glkViewController respondsToSelector:@selector(updateUserActivity:)]) {
        NSLog(@"Wanted IosGlkViewController, got %@", NSStringFromClass([gameNavController.viewControllers[0] class]));
        return nil;
    }
//
    NSUserActivity *userActivity = [glkViewController updateUserActivity:nil];
    NSLog(@"Returning userActivity %@", userActivity);

    [userActivity addUserInfoEntriesFromDictionary:@{@"selectedTabIndex":@(vc.selectedIndex)}];
    if ([vc.presentedViewController respondsToSelector:@selector(updateUserActivity:)] && ![vc.presentedViewController isKindOfClass:[IosGlkViewController class]]) {
        [vc.presentedViewController performSelector:@selector(updateUserActivity:) withObject:nil];
    }
    return userActivity;
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    UIOpenURLContext *urlContext = URLContexts.allObjects.firstObject;
    NSURL *url = urlContext.URL;
    if (!url)
        return;

    IosGlkAppDelegate *appdel = [IosGlkAppDelegate singleton];

    [appdel application:(UIApplication *)appdel openURL:url options:@{
        UIApplicationOpenURLOptionsSourceApplicationKey:urlContext.options.sourceApplication,
        UIApplicationOpenURLOptionsAnnotationKey : urlContext.options.annotation,
        UIApplicationOpenURLOptionsOpenInPlaceKey: @(urlContext.options.openInPlace)
    }];
}

- (void)sceneDidDisconnect:(UIScene *)scene {

}

- (void)sceneDidBecomeActive:(UIScene *)scene {
    NSUserActivity *userActivity = self.window.windowScene.userActivity;
    if (userActivity) {
        [userActivity becomeCurrent];
    }
    IosGlkAppDelegate *appdel = [IosGlkAppDelegate singleton];
    [appdel.glkviewc becameActive];
}

- (void)sceneWillResignActive:(UIScene *)scene {

    NSUserActivity *userActivity = self.window.windowScene.userActivity;
    if (userActivity) {
        [userActivity resignCurrent];
    }

    IosGlkAppDelegate *appdel = [IosGlkAppDelegate singleton];
    [appdel.glkviewc becameInactive];

    /* I think maybe this happens automatically, but I'm not positive. Doesn't hurt to be sure. */
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.window.windowScene.userActivity = [[NSUserActivity alloc] initWithActivityType:[self mainSceneActivityType]];

    UITabBarController *vc = (UITabBarController *)_window.rootViewController;
    UINavigationController *gameNavController = vc.viewControllers[0];
    IosGlkViewController *glkViewController = (IosGlkViewController *)gameNavController.viewControllers[0];
    [glkViewController updateUserActivity:nil];
}

- (void)sceneWillEnterForeground:(UIScene *)scene {

}

- (void)sceneDidEnterBackground:(UIScene *)scene {
    IosGlkAppDelegate *appdel = [IosGlkAppDelegate singleton];
    [appdel.glkviewc enteredBackground];
}

- (NSString *)mainSceneActivityType {
    if (!_mainSceneActivityType) {
        NSArray *activityTypes = NSBundle.mainBundle.infoDictionary[@"NSUserActivityTypes"];
        NSLog(@" _mainSceneActivityType = %@", activityTypes[0]);
        _mainSceneActivityType = activityTypes[0];
    }
    return _mainSceneActivityType;
}

- (BOOL)configureWindow:(UIWindow *)window session: (UISceneSession *)session withActivity: (NSUserActivity *)activity {
    BOOL succeeded = NO;

    // Check the user activity type to know which part of the app to restore.
    if (activity.activityType == self.mainSceneActivityType) {
        // The activity type is for restoring DetailParentViewController.

        // Present a parent detail view controller with the specified product and selected tab.
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        UITabBarController *vc = (UITabBarController *)[storyboard instantiateViewControllerWithIdentifier:@"RootTabBarController"];

        /* Set library.glkdelegate to a default value, if the glkviewc doesn't provide one. (Remember, from now on, that glkviewc.glkdelegate may be null!) */
        IosGlkAppDelegate *appdel = [IosGlkAppDelegate singleton];

        UINavigationController *gameNavController = vc.viewControllers[0];

        appdel.glkviewc = (IosGlkViewController *)gameNavController.viewControllers[0];

//        guard let detailParentViewController =
//        storyboard.instantiateViewController(withIdentifier: DetailParentViewController.viewControllerIdentifier)
//        as? DetailParentViewController else { return false }

        NSDictionary *userInfo = activity.userInfo;
        if (userInfo) {
            //            // Decode the user activity product identifier from the userInfo.
            //            if let productIdentifier = userInfo[SceneDelegate.productKey] as? String {
            //                let product = DataModelManager.sharedInstance.product(fromIdentifier: productIdentifier)
            //                detailParentViewController.product = product
            //            }
            //
            //                // Decode the selected tab bar controller tab from the userInfo.
            //                if let selectedTab = userInfo[SceneDelegate.selectedTabKey] as? Int {
            //                    detailParentViewController.restoredSelectedTab = selectedTab
            //                }
            //
            //                // Push the detail view controller for the user activity product.
            //                if let navigationController = window?.rootViewController as? UINavigationController {
            //                    navigationController.pushViewController(detailParentViewController, animated: false)
            //                }

            succeeded = YES;
        }
    } else {
        NSLog(@"The incoming userActivity (%@) is not recognizable here.", activity.activityType);
    }

    return succeeded;
}

@end
