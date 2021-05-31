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

- (void) applicationWillFinishLaunching:(NSNotification *)notification {
    NSLog(@"applicationWillFinishLaunching");
	// The following is used to determine is the left or right shift keys were depressed
	// as the application was launched. Could be used to display a gui on Application start.
	KeyMap map;
	GetKeys(map);
	if (KEYMAP_GET(map, kVKC_Shift) || KEYMAP_GET(map, kVKC_rShift))
		NSLog(@"Shift or Right Shift");

    userDefaults = [TDNUserDefaults sharedInstance];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSLog(@"applicationDidFinishLaunching");

    [self requestUserPermissionForNotifications];

    if (arrayOfFilesToProcess == nil || arrayOfFilesToProcess.count == 0) {
        if (userDefaults.hideDock) {
            [self hideDockIcon:TRUE];
        }

        preferencesWindowController = [[TDNPreferencesWindowController alloc] init];
        preferencesWindowController.quietUnrar = self;

        [preferencesWindowController showWindow:nil];

    } else {
        unarchiver = [[TDNUnarchiver alloc] init];
        unarchiver.quietUnrar = self;

        [self requestUserPermissionForNotifications];

        if (userDefaults.hideDock) {
            [self hideDockIcon:TRUE];
        }

        for (NSString * filename in arrayOfFilesToProcess) {
            BOOL extracted = [unarchiver extractArchiveWithFilename:filename];
            if (extracted) {
                // post notification based on user preference
                if (userDefaults.showNotification && userDefaults.notificationsAllowed) { // if show notification + permission granted ...
                    [self postNotificationUncompressedFile:filename];
                }
            }
        }

        [[NSApplication sharedApplication] terminate:self];
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

//    unarchiver = [[TDNUnarchiver alloc] init];
//    unarchiver.quietUnrar = self;
//
//    userDefaults = [TDNUserDefaults sharedInstance];
//
//    [self requestUserPermissionForNotifications];
//
//    if (userDefaults.hideDock) {
//        [self hideDockIcon:TRUE];
//    }
//
//	for (NSString * filename in arrayOfFilenames) {
//		BOOL extracted = [unarchiver extractArchiveWithFilename:filename];
//		if (extracted) {
//            // post notification based on user preference
//            if (userDefaults.showNotification && userDefaults.notificationsAllowed) { // if show notification + permission granted ...
//                [self postNotificationUncompressedFile:filename];
//            }
//		}
//	}
//
//    [[NSApplication sharedApplication] terminate:self];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
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
        NSLog(@"Setting Policy to Accesosry");
        result = [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];

        NSLog(@"Result of setting ActivationPolicy %d", result);

        NSLog(@"%@", [[[NSApplication sharedApplication]delegate] description]);
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
//        if (statusBarItem == nil) {
            statusBarItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
            statusBarItem.button.title = @"🎫"; //RMCG

        // optional create a menu for the button
        NSMenu * statusBarMenu = [[NSMenu alloc] init];
        [statusBarMenu setTitle:@"QuietUnrar Menu"];

        NSMenuItem * preferencesMenuItem = [[NSMenuItem alloc] initWithTitle:@"Show Preferences" action:@selector(showPreferencesWindow) keyEquivalent:@""];
        [statusBarMenu addItem:preferencesMenuItem];

        NSMenuItem * showDockItem = [[NSMenuItem alloc] initWithTitle:@"Show Dock" action:@selector(showPreferencesWindow) keyEquivalent:@""];
        [statusBarMenu addItem:showDockItem];

        NSMenuItem * quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit QuietUnrar" action:@selector(quit) keyEquivalent:@""];
        [statusBarMenu addItem:quitMenuItem];

        [statusBarItem setMenu:statusBarMenu];
//        }
    } else {
        [NSStatusBar.systemStatusBar removeStatusItem:statusBarItem];
    }
}

- (void) showPreferencesWindow {
    if (preferencesWindowController == nil) {
        preferencesWindowController = [[TDNPreferencesWindowController alloc] init];
        preferencesWindowController.quietUnrar = self;
    }

    [preferencesWindowController showWindow:nil];
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
