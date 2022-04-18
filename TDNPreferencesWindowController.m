//
//  TDNPreferencesWindowController.m
//  QuietUnrar
//
//  Created by Robert McGovern on 2021/05/30.
//

#import "TDNPreferencesWindowController.h"
#import "TDNUserDefaults.h"
//#import "QuietUnrarAppDelegate.h"

@interface TDNPreferencesWindowController ()

@property (weak) IBOutlet NSSwitch *showNotificationsSwitch;
@property (weak) IBOutlet NSSwitch *playSoundSwitch;
@property (weak) IBOutlet NSSwitch *hideDockIconSwitch;

@property TDNUserDefaults * userDefaults;

@end

@implementation TDNPreferencesWindowController

@synthesize userDefaults, showNotificationsSwitch, playSoundSwitch, hideDockIconSwitch;
@synthesize quietUnrar;

- (instancetype) init {
    return [super initWithWindowNibName:@"PreferencesWindow"];
}

- (void)windowDidLoad {
    [super windowDidLoad];

    userDefaults = [TDNUserDefaults sharedInstance];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    (self.window).title = @"QuietUnarchiver Preferences";

    if (userDefaults.hideDock) {
        hideDockIconSwitch.state = NSControlStateValueOn;
    }

    if (userDefaults.showNotification) {
        showNotificationsSwitch.state = NSControlStateValueOn;
    }

    if (userDefaults.playSounds) {
        playSoundSwitch.state = NSControlStateValueOn;
    }
}

- (IBAction)showNotificationsSwitchToggled:(id)sender {
    userDefaults.showNotification = showNotificationsSwitch.state;
}

- (IBAction)playSoundSwitchToggled:(id)sender {
    userDefaults.playSounds = playSoundSwitch.state;
}

- (IBAction)hideDockIconSwitchToggled:(id)sender {
    userDefaults.hideDock = hideDockIconSwitch.state;
    [quietUnrar hideDockIcon: userDefaults.hideDock];
}

@end
