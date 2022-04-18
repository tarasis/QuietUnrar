//
//  QuietUnrarAppDelegate.m
//  QuietUnrar
//
//  Created by Robert McGovern on 2009/09/06.
//  Copyright 2009 Tarasis. All rights reserved.
//

#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>
#import <UserNotifications/UserNotifications.h>

#import "QuietUnrarAppDelegate.h"
#import "TDNUnarchiver.h"
#import "TDNUserDefaults.h"
#import "TDNPreferencesWindowController.h"

@interface QuietUnrarAppDelegate ()

@property TDNUnarchiver * unarchiver;
@property TDNUserDefaults * userDefaults;
@property NSStatusItem * statusBarItem;

@property NSArray * arrayOfFilesToProcess;

@end

#pragma mark
@implementation QuietUnrarAppDelegate

@synthesize window, passwordView, passwordField, preferencesWindowController, unarchiver, userDefaults, statusBarItem, arrayOfFilesToProcess;

BOOL appRunning = NO;

- (void) applicationWillFinishLaunching:(NSNotification *)notification {
    NSLog(@"applicationWillFinishLaunching");
    // The following is used to determine is the left or right shift keys were depressed
    // as the application was launched. Could be used to display a gui on Application start.
    KeyMap map;
    GetKeys(map);
    if (KEYMAP_GET(map, kVKC_Shift) || KEYMAP_GET(map, kVKC_rShift))
        NSLog(@"Shift or Right Shift");

    userDefaults = [TDNUserDefaults sharedInstance];

    if (userDefaults.hideDock) {
        [self hideDockIcon:TRUE];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSLog(@"applicationDidFinishLaunching");

    [self requestUserPermissionForNotifications];

    if (arrayOfFilesToProcess == nil || arrayOfFilesToProcess.count == 0) {
        preferencesWindowController = [[TDNPreferencesWindowController alloc] init];
        preferencesWindowController.quietUnrar = self;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self->preferencesWindowController.window makeKeyAndOrderFront:self];
            [NSApp activateIgnoringOtherApps:YES];
        });

        appRunning = YES;

    } else {
        unarchiver = [[TDNUnarchiver alloc] init];
        unarchiver.quietUnrar = self;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            for (NSString * filename in self->arrayOfFilesToProcess) {
                BOOL extracted = [self->unarchiver extractArchiveWithFilename:filename];
                if (extracted) {
                    // post notification based on user preference
                    if (self->userDefaults.showNotification && self->userDefaults.notificationsAllowed) { // if show notification + permission granted ...
                        [self postNotificationUncompressedFile:filename];
                        // maybe don't want to spam lots of notifications if unarchiving a lot of archives
                    }
                }
            }

            [[NSApplication sharedApplication] terminate:self];
        });
    }
}

// Call one at a time for each file selected when app is run
// This is seemingly never called, even when only selecting a single file.
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    //NSLog(@"openFile: %@", filename);

    //[self extractRarWith:filename];
    //    [self extractRarUsingUnrarKitWithFilename:filename];
    // Always return YES even if there is an error to avoid dialog indicating unable to
    // handle files of type RAR if the archive is corrupt or part of it is missing
    return YES;
}

- (void)application:(NSApplication *)theApplication openFiles:(NSArray *) arrayOfFilenames {
    NSLog(@"openFiles: %@", arrayOfFilenames);

    arrayOfFilesToProcess = arrayOfFilenames;

    if (appRunning) {
        if (!unarchiver) {
            unarchiver = [[TDNUnarchiver alloc] init];
            unarchiver.quietUnrar = self;
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            for (NSString * filename in self->arrayOfFilesToProcess) {
                BOOL extracted = [self->unarchiver extractArchiveWithFilename:filename];
                if (extracted) {
                    // post notification based on user preference
                    if (self->userDefaults.showNotification && self->userDefaults.notificationsAllowed) { // if show notification + permission granted ...
                        [self postNotificationUncompressedFile:filename];
                        // maybe don't want to spam lots of notifications if unarchiving a lot of archives
                    }
                }
            }

            // If we're in the foreground, hide and return focus to whereever
            // has side effect of making the preferences window disappear after a short time
            // which is not what I want.
            //
            // I'd like to use the frontmostApplication trick to store old app, and restore
            // focus to it, but if app already running it appears to be my app, even though
            // I did the open from Finder. Hmm
            // NSRunningApplication * oldApp = [[NSWorkspace sharedWorkspace] frontmostApplication];
            // do activity
            // [_oldApp activateWithOptions:NSApplicationActivateIgnoringOtherApps];
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSApp hide:self];
            });
        });
    }
}

- (void)applicationWillBecomeActive:(NSNotification *)notification {
    //no use, if app is already running when I try and openfile it is my apps bundle id
    NSLog(@"%@", [[NSWorkspace sharedWorkspace] frontmostApplication].bundleIdentifier);
}

- (BOOL)application:(id)sender openFileWithoutUI:(NSString *)filename {
    NSLog(@"called openFileWithoutUI %@", filename);
    return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    // Possibly not the behaviour wanted
    if (userDefaults.hideDock) {
        NSLog(@"applicationShouldTerminateAfterLastWindowClosed -- NO");
        return NO;
    } else {
        NSLog(@"applicationShouldTerminateAfterLastWindowClosed -- YES");
        return YES;
    }
}

#pragma mark UI Methods

// Presents a dialog to the user allowing them to Skip a file or overwrite an existing version
// returns YES or NO
- (BOOL) shouldFileBeReplaced:(NSString *) filename {
    BOOL result = NO;

    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Overwrite"];
    NSButton * skipButton = [alert addButtonWithTitle:@"Skip"];
    [skipButton setKeyEquivalent:@"\e"];
    [alert setMessageText:[NSString stringWithFormat:@"Overwrite %@?", filename]];
    [alert setInformativeText:[NSString stringWithFormat:@"The file %@ already exists. Do you wish to extract it again, overwriting the original file?", filename]];
    [alert setAlertStyle:NSAlertStyleWarning];

    if ([alert runModal] == NSAlertFirstButtonReturn) {
        result = YES;
    }


    return result;
}

// Indicate to the user that part of the RAR volume is missing.
- (void) alertUserOfMissing:(const char *) volume {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:[NSString stringWithFormat:@"Archive part %s is missing.", volume]];
    [alert setInformativeText:@"Unable to extract all files from RAR archive as part of it is missing"];
    [alert setAlertStyle:NSAlertStyleCritical];

    [alert runModal];

}

// Creates a dialog with a custom view with a NSSecureTextField which is displayed
// to the user so they can provide a password. Returns the entered password or nil
- (NSString *) requestArchivePassword {
    if (!passwordView) {

        NSBundle* bundle = [NSBundle bundleForClass:[self class]];

        [bundle loadNibNamed:@"PasswordView" owner:self topLevelObjects: nil];
    } else {
        [passwordField setStringValue:@""];
    }

    NSString * password = nil;

    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Archive Requires a password"];
    [alert setInformativeText:@"To extract the contents of this archive a password is required."];
    [alert setAccessoryView:passwordView];
    [alert setAlertStyle:NSAlertStyleWarning];

    if ([alert runModal] == NSAlertFirstButtonReturn) {
        password = [passwordField stringValue];
    }

    return password;
}

- (void) hideDockIcon: (BOOL) hide {
    BOOL result;
    if (hide) {
        NSLog(@"Setting Policy to Accessory");
        result = [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
        NSLog(@"Result of setting ActivationPolicy %d", result);
        [self showStatusBarItem:TRUE];
    } else {
        NSLog(@"Setting Policy to Regular");
        result = [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        NSLog(@"Result of setting ActivationPolicy %d", result);
        [self showStatusBarItem:FALSE];
    }
}

- (void) showStatusBarItem: (BOOL) show {
    if (show) {
        statusBarItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
        statusBarItem.button.title = @"🎫"; //RMCG change to something more appropriate
        [statusBarItem setMenu:[self makeStatusBarMenu]];
    } else {
        [NSStatusBar.systemStatusBar removeStatusItem:statusBarItem];
    }
}

- (NSMenu *) makeStatusBarMenu {
    NSMenu * statusBarMenu = [[NSMenu alloc] init];
    [statusBarMenu setTitle:@"QuietUnarchiver Menu"];

    NSMenuItem * preferencesMenuItem = [[NSMenuItem alloc] initWithTitle:@"Show Preferences" action:@selector(showPreferencesWindow) keyEquivalent:@""];
    [statusBarMenu addItem:preferencesMenuItem];

//    NSMenuItem * showDockItem = [[NSMenuItem alloc] initWithTitle:@"Show Dock " action:@selector(showPreferencesWindow) keyEquivalent:@""];
//    [statusBarMenu addItem:showDockItem];
//
    NSMenuItem * quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit QuietUnarchiver" action:@selector(quit) keyEquivalent:@""];
    [statusBarMenu addItem:quitMenuItem];

    return statusBarMenu;
}

- (void) showPreferencesWindow {
    if (preferencesWindowController == nil) {
        preferencesWindowController = [[TDNPreferencesWindowController alloc] init];
        preferencesWindowController.quietUnrar = self;
    }

    [preferencesWindowController.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void) quit {
    [[NSApplication sharedApplication] terminate:self];
}

#pragma mark "Notifications"

- (void) requestUserPermissionForNotifications {
    UNUserNotificationCenter * center = [UNUserNotificationCenter currentNotificationCenter];

    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound)
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
        // Enable or disable features based on authorization.
        if (granted) {
            // set some flag, that would be used to see if notifications should be posted
            NSLog(@"Notification Permission Granted");
            self->userDefaults.notificationsAllowed = TRUE;
        }
    }];
}

- (void) postNotificationUncompressedFile:(NSString *) filename {
    // add details of notification
    NSLog(@"Posting notification for %@", filename);
}
@end
