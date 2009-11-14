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

- (void) applicationWillFinishLaunching:(NSNotification *)notification {
	KeyMap map;
	GetKeys(map);
	NSLog(@"Shift or Right Shift: %d", KEYMAP_GET(map, kVKC_Shift) || KEYMAP_GET(map, kVKC_rShift));
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	
//	NSLog(@"Dll Version %d\n", RARGetDllVersion());
}

//- (BOOL)application:(id)sender openFileWithoutUI:(NSString *)filename {
//	NSLog(@"openFileWithoutUI with file: %@", filename);
//	return YES;
//}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
	NSLog(@"openFile: %@", filename);
	
	return [self extractRarWith:filename];
}

//- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
//	for (NSString * filename in filenames) {
//		NSLog(@"openFiles: %@", filename);
//	}
//	
//	// If we get passed files don't open the UI
//	[sender replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
//}

- (BOOL) extractRarWith:(NSString *) filename {
	char commentBuffer[BUF_LEN];
	BOOL extractionSuccessful = YES;
	
	//Determine the folder we should extract the archive to. This by default
	//is the <folderContainingTheArchive>/<archiveNameWithPathExtension>
	NSString * defaultFolderToExtractTo = [filename stringByDeletingPathExtension];
	
	char * cstringFilename = (char *)[filename cStringUsingEncoding:NSISOLatin1StringEncoding];
	
	// Open the Archive for extraction, we set the open result to 3 so we can see it has changed
	struct RAROpenArchiveData arcData = { cstringFilename, RAR_OM_EXTRACT, 3, &commentBuffer[0], BUF_LEN, 0, 0};
	
	HANDLE archive = RAROpenArchive(&arcData);
	NSLog(@"Opening Archive %s with result %d", cstringFilename, arcData.OpenResult);
	
	// set call backs for if password needed or need to change volume
	
	// 
	struct RARHeaderData headerData;
	
	while (RARReadHeader(archive, &headerData) != ERAR_END_ARCHIVE) {
		NSLog(@"Attempting to extract %s to %@", headerData.FileName, defaultFolderToExtractTo);
		
		int process_result = RARProcessFile(archive, RAR_EXTRACT, (char *) [defaultFolderToExtractTo cStringUsingEncoding:NSISOLatin1StringEncoding], NULL);
		
		if (process_result != 0) {
			NSLog(@"Process Result was %d", process_result);
			extractionSuccessful = NO;
			
			// DISPLAY ERROR DIALOG, ALERT THE USER
		}
		else {
			NSLog(@"...Extracted");
		}

	}
	
	int close_result = RARCloseArchive(archive);
	
	return extractionSuccessful;
}

@end
