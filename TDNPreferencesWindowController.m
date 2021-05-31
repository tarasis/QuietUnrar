//
//  TDNPreferencesWindowController.m
//  QuietUnrar
//
//  Created by Robert McGovern on 2021/05/30.
//

#import "TDNPreferencesWindowController.h"

@interface TDNPreferencesWindowController ()

@end

@implementation TDNPreferencesWindowController

- (id) init {
    return [super initWithWindowNibName:@"PreferencesWindow"];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

BOOL showingDock = TRUE;

- (IBAction)showHideButtonPressed:(id)sender {
    if (showingDock) {
        showingDock = FALSE;
        NSLog(@"Setting Policy to Accesosry");
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];

        NSLog(@"%@", [[[NSApplication sharedApplication]delegate] description]);
    } else {
        showingDock = TRUE;
        NSLog(@"Setting Policy to Regular");
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    }
}

@end
