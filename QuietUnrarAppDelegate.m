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

int changeVolume(char * volumeName, int mode);
int callbackFunction(UINT message, LPARAM userData, LPARAM parameterOne, LPARAM parameterTwo);

int changeVolume(char * volumeName, int mode) {
	NSLog(@"Volume Name: %s and mode %d", volumeName, mode);
	
}

int callbackFunction(UINT message, LPARAM userData, LPARAM parameterOne, LPARAM parameterTwo) {
	NSLog(@"Callback Function, args: %d, %D, %D, %D", message, userData, parameterOne, parameterTwo);
}


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
	
	char * filenameCString = (char *)[filename cStringUsingEncoding:NSISOLatin1StringEncoding];
	
	// Open the Archive for extraction, we set the open result to 3 so we can see it has changed
	struct RAROpenArchiveData arcData = { filenameCString, RAR_OM_EXTRACT, 3, &commentBuffer[0], BUF_LEN, 0, 0};	
	HANDLE archive = RAROpenArchive(&arcData);
	NSLog(@"Opening Archive %s with result %d", filenameCString, arcData.OpenResult);
	
	// set call backs for if password needed or need to change volume
	RARSetChangeVolProc(archive, &changeVolume);
	RARSetCallback(archive, &callbackFunction, 0);
	
	//
	struct RARHeaderData headerData;	
	while (RARReadHeader(archive, &headerData) != ERAR_END_ARCHIVE) {
		NSLog(@"Attempting to extract %s to %@", headerData.FileName, defaultFolderToExtractTo);
		
		int processResult = RARProcessFile(archive, RAR_EXTRACT, (char *) [defaultFolderToExtractTo cStringUsingEncoding:NSISOLatin1StringEncoding], NULL);
		
		if (processResult != 0) {
			NSLog(@"Process Result was %d", processResult);
			extractionSuccessful = NO;
			
			// DISPLAY ERROR DIALOG, ALERT THE USER
		}
		else {
			NSLog(@"...Extracted");
		}

	}
	
	int closeResult = RARCloseArchive(archive);
	NSLog(@"Closing Archive %s with result %d", filenameCString, closeResult);

	
	return extractionSuccessful;
}

@end
