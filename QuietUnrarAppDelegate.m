//
//  QuietUnrarAppDelegate.m
//  QuietUnrar
//
//  Created by Robert McGovern on 2009/09/06.
//  Copyright 2009 Tarasis. All rights reserved.
//

#import <Carbon/Carbon.h>
#import "QuietUnrarAppDelegate.h"
#import "libunrar/dll.hpp"

@implementation QuietUnrarAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	KeyMap map;
	GetKeys(map);
	NSLog(@"Shift or Right Shift: %d", KEYMAP_GET(map, kVKC_Shift) || KEYMAP_GET(map, kVKC_rShift));
	
	NSLog(@"Dll Version %d\n", RARGetDllVersion());
}

- (BOOL)application:(id)sender openFileWithoutUI:(NSString *)filename {
	NSLog(@"openFileWithoutUI with file: %@", filename);
	return YES;
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
	NSLog(@"openFile: %@", filename);
	return YES;
}

//- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
//	for (NSString * filename in filenames) {
//		NSLog(@"openFiles: %@", filename);
//	}
//	
//	// If we get passed files don't open the UI
//	[sender replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
//}

@end
