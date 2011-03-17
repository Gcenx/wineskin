//
//  Wineskin_WineryAppDelegate.m
//  Wineskin Winery
//
//  Copyright 2010 by The Wineskin Project and doh123@doh1223.com. All rights reserved.
//  Licensed for use under the LGPL <http://www.gnu.org/licenses/lgpl-2.1.txt>
//

#import "Wineskin_WineryAppDelegate.h"

@implementation Wineskin_WineryAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	srand(time(NULL));
	[waitWheel startAnimation:self];
	[self refreshButtonPressed:self];
	[self checkForUpdates];	
}
- (IBAction)aboutWindow:(id)sender
{
	NSDictionary* plistDictionary = [[NSDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/Contents/Info.plist",[[NSBundle mainBundle] bundlePath]]];
	[aboutWindowVersionNumber setStringValue:[plistDictionary valueForKey:@"CFBundleVersion"]];
	[plistDictionary release];
	[aboutWindow makeKeyAndOrderFront:self];
}
- (IBAction)helpWindow:(id)sender
{
	[helpWindow makeKeyAndOrderFront:self];
}
- (void)makeFoldersAndFiles
{
	NSString *applicationPath = [[NSBundle mainBundle] bundlePath];
	NSFileManager *filemgr = [NSFileManager defaultManager];
	[filemgr createDirectoryAtPath:[NSHomeDirectory() stringByAppendingString:@"/Library/Application Support/Wineskin/Engines"] withIntermediateDirectories:YES attributes:nil error:nil];
	[filemgr createDirectoryAtPath:[NSHomeDirectory() stringByAppendingString:@"/Library/Application Support/Wineskin/Wrapper"] withIntermediateDirectories:YES attributes:nil error:nil];
	[filemgr createDirectoryAtPath:[NSHomeDirectory() stringByAppendingString:@"/Library/Application Support/Wineskin/EngineBase"] withIntermediateDirectories:YES attributes:nil error:nil];
	[filemgr createDirectoryAtPath:[NSHomeDirectory() stringByAppendingString:@"/Applications/Wineskin"] withIntermediateDirectories:YES attributes:nil error:nil];
	if (!([filemgr fileExistsAtPath:[NSHomeDirectory() stringByAppendingString:@"/Library/Application Support/Wineskin/7za"]]))
		[filemgr copyItemAtPath:[applicationPath stringByAppendingString:@"/Contents/Resources/7za"] toPath:[NSHomeDirectory() stringByAppendingString:@"/Library/Application Support/Wineskin/7za"] error:nil];
}
- (void)checkForUpdates
{
	//get current version number
	NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
	//get latest available version number
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://wineskin.doh123.com/WineskinWinery/NewestVersion.txt?%@",[[NSNumber numberWithLong:rand()] stringValue]]];
	NSString *newVersion = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
	newVersion = [newVersion stringByReplacingOccurrencesOfString:@"\n" withString:@""]; //remove \n
	if (!([newVersion hasPrefix:@"Wineskin"]) || ([currentVersion isEqualToString:newVersion]))
	{
		[window makeKeyAndOrderFront:self];
		return;
	}
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"Do Update"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText:@"Update Available!"];
	[alert setInformativeText:@"An Update to Wineskin Winery is available, would you like to update now?"];
	[alert setAlertStyle:NSInformationalAlertStyle];
	if ([alert runModal] != NSAlertFirstButtonReturn)
	{
		//display warning about not updating.
		NSAlert *warning = [[NSAlert alloc] init];
		[warning addButtonWithTitle:@"OK"];
		[warning setMessageText:@"Warning!"];
		[warning setInformativeText:@"Some things may not function properly with new Wrappers or Engines until you update!"];
		[warning runModal];
		[warning release];
		[alert release];
		//bring main window up
		[window makeKeyAndOrderFront:self];
		return;
	}
	[alert release];
	//try removing files that might already exist
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm removeItemAtPath:@"/tmp/WineskinWinery.app.tar.7z" error:nil];
	[fm removeItemAtPath:@"/tmp/WineskinWinery.app.tar" error:nil];
	[fm removeItemAtPath:@"/tmp/WineskinWinery.app" error:nil];
	//update selected, download update
	[urlInput setStringValue:[NSString stringWithFormat:@"http://wineskin.doh123.com/WineskinWinery/WineskinWinery.app.tar.7z?%@",[[NSNumber numberWithLong:rand()] stringValue]]];
	[urlOutput setStringValue:@"file:///tmp/WineskinWinery.app.tar.7z"];
	[fileName setStringValue:@"Wineskin Winery Update"];
	[window orderOut:self];
	[downloadingWindow makeKeyAndOrderFront:self];
}

- (IBAction)createNewBlankWrapperButtonPressed:(id)sender
{
	NSString *selectedEngine = [[NSString alloc] initWithString:[installedEnginesList objectAtIndex:[installedEngines selectedRow]]];
	[createWrapperEngine setStringValue:selectedEngine];
	[selectedEngine release];
	[window orderOut:self];
	[createWrapperWindow makeKeyAndOrderFront:self];
}

- (IBAction)refreshButtonPressed:(id)sender
{
	//make sure files and folders are created
	[self makeFoldersAndFiles];
	//set installed engines list
	[self getInstalledEngines];
	[installedEngines setAllowsEmptySelection:NO];
	[installedEngines reloadData];
	//check if engine updates are available
	[self setEnginesAvailablePrompt];
	//set current wrapper version blank
	[wrapperVersion setStringValue:[self getCurrentWrapperVersion]];
	//check if wrapper update is available
	[self setWrapperAvailablePrompt];
	// make sure an engine and master wrapper are both installed first, or have CREATE button disabled!
	if (([installedEnginesList count] == 0) || ([[wrapperVersion stringValue] isEqualToString:@"No Wrapper Installed"]))
		[createWrapperButton setEnabled:NO];
	else
		[createWrapperButton setEnabled:YES];
}

- (IBAction)downloadPackagesManuallyButtonPressed:(id)sender;
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://wineskin.doh123.com/Latest_Update.html?%@",[[NSNumber numberWithLong:rand()] stringValue]]];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)plusButtonPressed:(id)sender
{
	//populate engines list in engines window
	[engineWindowEngineList removeAllItems];
	NSMutableArray *availableEngines = [NSMutableArray arrayWithCapacity:5];
	availableEngines = [self getAvailableEngines];
	NSMutableArray *testList = [NSMutableArray arrayWithCapacity:[availableEngines count]];
	for (NSString *itemAE in availableEngines)
	{
		BOOL matchFound=NO;
		for (NSString *itemIE in installedEnginesList)
		{
			if ([itemAE isEqualToString:itemIE])
			{
				matchFound=YES;
				break;
			}
		}
		if (!matchFound) [testList addObject:itemAE];
	}
	for (NSString *item in testList)
		[engineWindowEngineList addItemWithTitle:item];
	if ([[engineWindowEngineList selectedItem] title] == nil)
	{
		[engineWindowDownloadAndInstallButton setEnabled:NO];
		[engineWindowViewWineReleaseNotesButton setEnabled:NO];
		[engineWindowDontPromptAsNewButton setEnabled:NO];
	}
	else
	{
		[engineWindowDontPromptAsNewButton setEnabled:YES];
		[engineWindowDownloadAndInstallButton setEnabled:YES];
		[engineWindowViewWineReleaseNotesButton setEnabled:YES];
		[self engineWindowEngineListChanged:self];
	}
	//show the engines window
	[window orderOut:self];
	[addEngineWindow makeKeyAndOrderFront:self];
}


- (IBAction)minusButtonPressed:(id)sender
{
	NSString *selectedEngine = [[NSString alloc] initWithString:[installedEnginesList objectAtIndex:[installedEngines selectedRow]]];
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"Yes"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText:@"Confirm Deletion"];
	[alert setInformativeText:[NSString stringWithFormat:@"Are you sure you want to delete the engine \"%@\"",selectedEngine]];
	[alert setAlertStyle:NSInformationalAlertStyle];
	if ([alert runModal] != NSAlertFirstButtonReturn) return;
	//move file to trash
	NSArray *filenamesArray = [NSArray arrayWithObject:[NSString stringWithFormat:@"%@.tar.7z",selectedEngine]];
	[[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:[NSString stringWithFormat:@"%@/Library/Application Support/Wineskin/Engines",NSHomeDirectory()] destination:@"" files:filenamesArray tag:nil];
	[self refreshButtonPressed:self];
	//remove engine from ignored list
	NSString *ignoreList = [NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@/Library/Application Support/Wineskin/IgnoredEngines.txt",NSHomeDirectory()] encoding:NSUTF8StringEncoding error:nil];
	ignoreList = [ignoreList stringByReplacingOccurrencesOfString:selectedEngine withString:@""];
	[ignoreList writeToFile:[NSHomeDirectory() stringByAppendingString:@"/Library/Application Support/Wineskin/IgnoredEngines.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
	[selectedEngine release];
}

- (IBAction)updateButtonPressed:(id)sender
{
	//get latest available version number
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://wineskin.doh123.com/WineskinWrapper/NewestVersion.txt?%@",[[NSNumber numberWithLong:rand()] stringValue]]];
	NSString *newVersion = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
	newVersion = [newVersion stringByReplacingOccurrencesOfString:@"\n" withString:@""]; //remove \n
	if (newVersion == nil || ![[newVersion substringToIndex:8] isEqualToString:@"Wineskin"])
	{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"Oops!"];
		[alert setInformativeText:@"Error, connection to download failed!"];
		[alert setAlertStyle:NSInformationalAlertStyle];
		[alert runModal];
		[alert release];
		return;
	}
	//download new wrapper to /tmp
	[urlInput setStringValue:[NSString stringWithFormat:@"http://wineskin.doh123.com/WineskinWrapper/%@.app.tar.7z?%@",newVersion,[[NSNumber numberWithLong:rand()] stringValue]]];
	[urlOutput setStringValue:[NSString stringWithFormat:@"file:///tmp/%@.app.tar.7z",newVersion]];
	[fileName setStringValue:newVersion];
	[fileNameDestination setStringValue:@"Wrapper"];
	[window orderOut:self];
	[downloadingWindow makeKeyAndOrderFront:self];
}

- (IBAction)wineskinWebsiteButtonPressed:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://wineskin.doh123.com/?"]];
}

- (void)getInstalledEngines
{
	//clear the array
	[installedEnginesList removeAllObjects];
	//get files in folder and put in array
	NSString *folder = [NSString stringWithFormat:@"%@/Library/Application Support/Wineskin/Engines",NSHomeDirectory()];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray *filesTEMP = [fm contentsOfDirectoryAtPath:folder error:nil];
	NSArray *files = [[filesTEMP reverseObjectEnumerator] allObjects];
	for(NSString *file in files) // standard first
		if ([file hasSuffix:@".tar.7z"] && (NSEqualRanges([file rangeOfString:@"CX"],NSMakeRange(NSNotFound, 0)))) [installedEnginesList addObject:[file stringByReplacingOccurrencesOfString:@".tar.7z" withString:@""]];
	for(NSString *file in files) // CX at end of list
		if ([file hasSuffix:@".tar.7z"] && !(NSEqualRanges([file rangeOfString:@"CX"],NSMakeRange(NSNotFound, 0)))) [installedEnginesList addObject:[file stringByReplacingOccurrencesOfString:@".tar.7z" withString:@""]];
}

- (NSArray *)getEnginesToIgnore
{
	NSString *fileString = [NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@/Library/Application Support/Wineskin/IgnoredEngines.txt",NSHomeDirectory()] encoding:NSUTF8StringEncoding error:nil];
	if ([fileString hasSuffix:@"\n"])
	{
		fileString = [fileString stringByAppendingString:@":!:!:"];
		fileString = [fileString stringByReplacingOccurrencesOfString:@"\n:!:!:" withString:@""];
	}
	return [fileString componentsSeparatedByString:@"\n"];
}

- (NSMutableArray *)getAvailableEngines
{
	NSString *fileString = [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://wineskin.doh123.com/WineskinEngines/EngineList.txt?%@",[[NSNumber numberWithLong:rand()] stringValue]]] encoding:NSUTF8StringEncoding error:nil];
	if ([fileString hasSuffix:@"\n"])
	{
		fileString = [fileString stringByAppendingString:@":!:!:"];
		fileString = [fileString stringByReplacingOccurrencesOfString:@"\n:!:!:" withString:@""];
	}
	NSArray *tempA = [fileString componentsSeparatedByString:@"\n"];
	NSMutableArray *tempMA = [NSMutableArray arrayWithCapacity:[tempA count]];
	for(NSString *item in tempA) [tempMA addObject:item];
	return tempMA;	
}

- (NSString *)getCurrentWrapperVersion
{
	NSString *folder = [NSString stringWithFormat:@"%@/Library/Application Support/Wineskin/Wrapper",NSHomeDirectory()];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray *filesArray = [fm contentsOfDirectoryAtPath:folder error:nil];
	NSMutableArray *files = [NSMutableArray arrayWithCapacity:2];
	for(NSString *file in filesArray)
	{
		if (!([file isEqualToString:@".DS_Store"])) [files addObject:file];
	}
	
	if ([files count] < 1) return @"No Wrapper Installed";
	if ([files count] > 1) return @"Error In Wrapper Folder";
	NSString *currentVersion = [files objectAtIndex:0];
	currentVersion = [currentVersion stringByReplacingOccurrencesOfString:@".app" withString:@""];
	return currentVersion;
}

- (void)setEnginesAvailablePrompt
{
	NSMutableArray *availableEngines = [self getAvailableEngines];
	NSArray *ignoredEngines = [self getEnginesToIgnore];
	NSMutableArray *testList = [NSMutableArray arrayWithCapacity:[availableEngines count]];
	for (NSString *itemAE in availableEngines)
	{
		BOOL matchFound=NO;
		for (NSString *itemIE in installedEnginesList)
		{
			if ([itemAE isEqualToString:itemIE])
			{
				matchFound=YES;
				break;
			}
		}
		if (!matchFound)
		{
			for (NSString *itemIE in ignoredEngines)
			{
				if ([itemAE isEqualToString:itemIE])
				{
					matchFound=YES;
					break;
				}
			}
		}
		if (!matchFound) [testList addObject:itemAE];
	}
	if ([testList count] > 0) [engineAvailableLabel setHidden:NO];
	else [engineAvailableLabel setHidden:YES];
}

- (void)setWrapperAvailablePrompt
{
	//get latest available version number
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://wineskin.doh123.com/WineskinWrapper/NewestVersion.txt?%@",[[NSNumber numberWithLong:rand()] stringValue]]];
	NSString *newVersion = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
	newVersion = [newVersion stringByReplacingOccurrencesOfString:@"\n" withString:@""]; //remove \n
	if (newVersion == nil || ![[newVersion substringToIndex:8] isEqualToString:@"Wineskin"]) return;
	//if different, prompt update available
	if ([[wrapperVersion stringValue] isEqualToString:newVersion])
	{
		[updateButton setEnabled:NO];
		[updateAvailableLabel setHidden:YES];
		return;
	}
	[updateButton setEnabled:YES];
	[updateAvailableLabel setHidden:NO];
}

- (void)displayString:(NSString *)input
{
	if (input == nil) input=@"nil";
	NSAlert *TESTER = [[NSAlert alloc] init];
	[TESTER addButtonWithTitle:@"close"];
	[TESTER setMessageText:@"Contents of string"];
	[TESTER setInformativeText:input];
	[TESTER setAlertStyle:NSInformationalAlertStyle];
	[TESTER runModal];
	[TESTER release];
}
//******************* engine build window *****************************
- (IBAction)engineBuildChooseButtonPressed:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setTitle:@"Choose Wine Source Folder"];
	[panel setPrompt:@"Choose"];
	[panel setCanChooseDirectories:YES];
	[panel setCanChooseFiles:NO];
	[panel setAllowsMultipleSelection:NO];
	int error = [panel runModal];
	if (error == 0) return;
	[engineBuildWineSource setStringValue:[[panel filenames] objectAtIndex:0]];
}
- (IBAction)engineBuildBuildButtonPressed:(id)sender
{
	if ([[engineBuildWineSource stringValue] isEqualToString:@""] || [[engineBuildEngineName stringValue] isEqualToString:@""])
	{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"Oops!"];
		[alert setInformativeText:@"You must select a folder with the Wine source code and a valid engine name"];
		[alert setAlertStyle:NSInformationalAlertStyle];
		[alert runModal];
		[alert release];
		return;
	}
	if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/Library/Application Support/Wineskin/Engines/%@.tar.7z",NSHomeDirectory(),[engineBuildEngineName stringValue]]])
	{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"Oops!"];
		[alert setInformativeText:@"That engine name is already in use!"];
		[alert setAlertStyle:NSInformationalAlertStyle];
		[alert runModal];
		[alert release];
		return;
	}
	
	//write out the config file
	NSString *configFileContents = [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@\n",[engineBuildWineSource stringValue],[engineBuildEngineName stringValue],[engineBuildConfigurationOptions stringValue],[engineBuildCurrentEngineBase stringValue],[NSString stringWithFormat:@"%@/Library/Application Support/Wineskin/7za", NSHomeDirectory()]];
	[configFileContents writeToFile:[NSString stringWithFormat:@"%@/Library/Application Support/Wineskin/EngineBase/%@/config.txt",NSHomeDirectory(),[engineBuildCurrentEngineBase stringValue]] atomically:NO encoding:NSUTF8StringEncoding error:nil];
	//launch terminal with the script
	system([[NSString stringWithFormat:@"open -a Terminal.app \"%@/Library/Application Support/Wineskin/EngineBase/%@/WineskinEngineBuild\"", NSHomeDirectory(),[engineBuildCurrentEngineBase stringValue]] UTF8String]);
	//prompt user warning
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:@"WARNING!"];
	[alert setInformativeText:@"This build will fail if you use Wineskin Winery, Wineskin, or any Wineskin wrapper while it is running!!!"];
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert runModal];
	[alert release];
	//exit program
	[NSApp terminate:sender];
}
- (IBAction)engineBuildUpdateButtonPressed:(id)sender
{
	//get latest available version number
	NSString *newVersion = [self availableEngineBuildVersion];
	//download new wrapper to /tmp
	[urlInput setStringValue:[NSString stringWithFormat:@"http://wineskin.doh123.com/WineskinEngineBase/%@.tar.7z?%@",newVersion,[[NSNumber numberWithLong:rand()] stringValue]]];
	[urlOutput setStringValue:[NSString stringWithFormat:@"file:///tmp/%@.tar.7z",newVersion]];
	[fileName setStringValue:newVersion];
	[fileNameDestination setStringValue:@"EngineBase"];
	[wineskinEngineBuilderWindow orderOut:self];
	[downloadingWindow makeKeyAndOrderFront:self];
}
- (IBAction)engineBuildCancelButtonPressed:(id)sender
{
	[wineskinEngineBuilderWindow orderOut:self];
	[window makeKeyAndOrderFront:self];
}
- (NSString *)currentEngineBuildVersion
{
	NSString *folder = [NSString stringWithFormat:@"%@/Library/Application Support/Wineskin/EngineBase",NSHomeDirectory()];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray *filesArray = [fm contentsOfDirectoryAtPath:folder error:nil];
	NSMutableArray *files = [NSMutableArray arrayWithCapacity:2];
	for(NSString *file in filesArray)
		if (!([file isEqualToString:@".DS_Store"])) [files addObject:file];
	if ([files count] < 1)
	{
		[engineBuildBuildButton setEnabled:NO];
		return @"No Engine Base Installed";
	}
	if ([files count] > 1)
	{
		[engineBuildBuildButton setEnabled:NO];
		return @"Error In Engine Base Folder";
	}
	[engineBuildBuildButton setEnabled:YES];
	NSString *currentVersion = [files objectAtIndex:0];
	return currentVersion;
}
- (NSString *)availableEngineBuildVersion
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://wineskin.doh123.com/WineskinEngineBase/NewestVersion.txt?%@",[[NSNumber numberWithLong:rand()] stringValue]]];
	NSString *newVersion = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
	newVersion = [newVersion stringByReplacingOccurrencesOfString:@"\n" withString:@""]; //remove \n
	if (newVersion == nil || ![[newVersion substringToIndex:2] isEqualToString:@"WS"]) return @"ERROR";
	return newVersion;
}

//************ Engine Window (+ button) methods *******************
- (IBAction)engineWindowDownloadAndInstallButtonPressed:(id)sender
{
	[urlInput setStringValue:[NSString stringWithFormat:@"http://wineskin.doh123.com/WineskinEngines/%@.tar.7z?%@",[[engineWindowEngineList selectedItem] title],[[NSNumber numberWithLong:rand()] stringValue]]];
	[urlOutput setStringValue:[NSString stringWithFormat:@"file:///tmp/%@.tar.7z",[[engineWindowEngineList selectedItem] title]]];
	[fileName setStringValue:[[engineWindowEngineList selectedItem] title]];
	[fileNameDestination setStringValue:@"Engines"];
	[addEngineWindow orderOut:self];
	[downloadingWindow makeKeyAndOrderFront:self];
}
- (IBAction)engineWindowViewWineReleaseNotesButtonPressed:(id)sender
{
	NSArray *tempArray = [[[engineWindowEngineList selectedItem] title] componentsSeparatedByString:@"Wine"];
	NSString *wineVersion = [tempArray objectAtIndex:1];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.winehq.org/announce/%@",wineVersion]]];
}
- (IBAction)engineWindowEngineListChanged:(id)sender
{
	NSArray *ignoredEngines = [self getEnginesToIgnore];
	BOOL matchFound=NO;
	for (NSString *item in ignoredEngines)
		if ([item isEqualToString:[[engineWindowEngineList selectedItem] title]]) matchFound=YES;
	if (matchFound) [engineWindowDontPromptAsNewButton setEnabled:NO];
	else [engineWindowDontPromptAsNewButton setEnabled:YES];
	NSArray *tempArray = [[[engineWindowEngineList selectedItem] title] componentsSeparatedByString:@"Wine"];
	NSString *wineVersion = [tempArray objectAtIndex:1];
	if ([wineVersion hasPrefix:@"C"]) [engineWindowViewWineReleaseNotesButton setEnabled:NO];
	else [engineWindowViewWineReleaseNotesButton setEnabled:YES];
}
- (IBAction)engineWindowDontPromptAsNewButtonPressed:(id)sender
{
	//read current ignore list into string
	NSArray *ignoredEngines = [self getEnginesToIgnore];
	NSString *ignoredEnginesString = @"";
	for (NSString *item in ignoredEngines)
		ignoredEnginesString = [ignoredEnginesString stringByAppendingString:[item stringByAppendingString:@"\n"]];
	ignoredEnginesString = [NSString stringWithFormat:@"%@\n%@",ignoredEnginesString,[[engineWindowEngineList selectedItem] title]];
	//write engine to ignored engines text file
	[ignoredEnginesString writeToFile:[NSHomeDirectory() stringByAppendingString:@"/Library/Application Support/Wineskin/IgnoredEngines.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
	//disable prompt button
	[engineWindowDontPromptAsNewButton setEnabled:NO];
	
}
- (IBAction)engineWindowDontPromptAllEnginesAsNewButtonPressed:(id)sender
{
	NSArray *ignoredEngines = [self getEnginesToIgnore];
	NSMutableArray *availableEngines = [NSMutableArray arrayWithCapacity:[ignoredEngines count]];
	int length = [engineWindowEngineList numberOfItems];
	for (int i=0;i<length;i++)
		[availableEngines addObject:[engineWindowEngineList itemTitleAtIndex:i]];
	NSMutableArray *fixedIgnoredEnginesList = [NSMutableArray arrayWithCapacity:[ignoredEngines count]];
	for (NSString *item in ignoredEngines)
	{
		if (!([availableEngines containsObject:item]))
			[fixedIgnoredEnginesList addObject:item];
	}
	NSString *ignoredEnginesString = @"";
	//add all fixed ignored list if any... new ones already removed.
	for (NSString *item in fixedIgnoredEnginesList)
		ignoredEnginesString = [NSString stringWithFormat:@"%@\n%@",ignoredEnginesString,item];
	//add all the engines available to the string
	for (NSString *item in availableEngines)
		ignoredEnginesString = [NSString stringWithFormat:@"%@\n%@",ignoredEnginesString,item];
	//remove any \n off the front of the string
	if ([ignoredEnginesString hasPrefix:@"\n"])
	{
		ignoredEnginesString = [ignoredEnginesString stringByReplacingCharactersInRange:[ignoredEnginesString rangeOfString:@"\n"] withString:@""];
	}
	//write engine to ignored engines text file
	[ignoredEnginesString writeToFile:[NSHomeDirectory() stringByAppendingString:@"/Library/Application Support/Wineskin/IgnoredEngines.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
	//disable prompt button
	[engineWindowDontPromptAsNewButton setEnabled:NO];
}
- (IBAction)engineWindowCustomBuildAnEngineButtonPressed:(id)sender
{
	[self refreshButtonPressed:self];
	[self makeFoldersAndFiles];
	[addEngineWindow orderOut:self];
	[wineskinEngineBuilderWindow makeKeyAndOrderFront:self];
	NSString *currentEngineBuild = [self currentEngineBuildVersion];
	[engineBuildCurrentEngineBase setStringValue:currentEngineBuild];
	NSString *availableEngineBase = [self availableEngineBuildVersion];
	//set default engine name
	[engineBuildEngineName setStringValue:[NSString stringWithFormat:@"%@-MyCustomEngine",[currentEngineBuild stringByReplacingOccurrencesOfString:@"EngineBase" withString:@""]]];
	//set update button and label
	if ([availableEngineBase isEqualToString:currentEngineBuild])
	{
		[engineBuildUpdateButton setEnabled:NO];
		[engineBuildUpdateAvailable setHidden:YES];
	}
	else
	{
		[engineBuildUpdateButton setEnabled:YES];
		[engineBuildUpdateAvailable setHidden:NO];
	}
}
- (IBAction)engineWindowCancelButtonPressed:(id)sender
{
	[addEngineWindow orderOut:self];
	[window makeKeyAndOrderFront:self];
	[self refreshButtonPressed:self];
}
//***************************** Downloader ************************
- (IBAction) startDownload:(NSButton *)sender;
{
	[self downloadToggle:YES];
	NSString *input = [urlInput stringValue];
	NSURL *url = [NSURL URLWithString:input];
	
	request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	if (connection)
	{
		payload = [[NSMutableData data] retain];
		//NSLog(@"Connection starting: %@", connection);
	}
	else
	{
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"Download Failed!"];
		[alert setInformativeText:@"unable to download!"];
		[alert setAlertStyle:NSCriticalAlertStyle];
		[alert beginSheetModalForWindow:[cancelButton window] modalDelegate:self didEndSelector:nil contextInfo:nil];
		
		[self downloadToggle:NO];
	}
}

- (IBAction) stopDownloading:(NSButton *)sender;
{
	if (connection) [connection cancel];
	[self downloadToggle:NO];
	if (([[fileNameDestination stringValue] isEqualToString:@"EngineBase"]))
	{
		[downloadingWindow orderOut:self];
		[wineskinEngineBuilderWindow makeKeyAndOrderFront:self];
	}
	else if (([[fileNameDestination stringValue] isEqualToString:@"Engines"]))
	{
		[downloadingWindow orderOut:self];
		[addEngineWindow makeKeyAndOrderFront:self];
	}
	else if ([[fileName stringValue] isEqualToString:@"Wineskin Winery Update"])
	{
		//display warning about not updating.
		NSAlert *warning = [[NSAlert alloc] init];
		[warning addButtonWithTitle:@"OK"];
		[warning setMessageText:@"Warning!"];
		[warning setInformativeText:@"Some things may not function properly with new Wrappers or Engines until you update!"];
		[warning runModal];
		[warning release];
		[downloadingWindow orderOut:self];
		[window makeKeyAndOrderFront:self];
	}
	else
	{
		[downloadingWindow orderOut:self];
		[window makeKeyAndOrderFront:self];
	}
}

- (void) downloadToggle:(BOOL)toggle
{
	[progressBar setMaxValue:100.0];
	[progressBar setDoubleValue:1.0];
	if (toggle == YES)
	{
		[downloadButton setEnabled:NO];
		[progressBar setHidden:NO];
	}
	else
	{
		[downloadButton setEnabled:YES];
		[progressBar setHidden:YES];
	}
}

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response
{
	//NSLog(@"Recieved response with expected length: %i", [response expectedContentLength]);
	
	[payload setLength:0];
	[progressBar setMaxValue:[response expectedContentLength]];
}
- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data
{
	//NSLog(@"Recieving data. Incoming Size: %i  Total Size: %i", [data length], [payload length]);
	
	[payload appendData:data];
	[progressBar setDoubleValue:[payload length]];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
	[self downloadToggle:NO];
	//delete any files that might exist in /tmp first
	[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@.app.tar.7z",[fileName stringValue]] error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@.app.tar",[fileName stringValue]] error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@.app",[fileName stringValue]] error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@.tar.7z",[fileName stringValue]] error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@.tar",[fileName stringValue]] error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@",[fileName stringValue]] error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:@"/tmp/WineskinWinery.app.tar.7z" error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:@"/tmp/WineskinWinery.app.tar" error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:@"/tmp/WineskinWinery.app" error:nil];
	//NSString *output = [urlOutput stringValue];
	[payload writeToURL:[NSURL URLWithString:[urlOutput stringValue]] atomically:YES];
	[conn release];
	[downloadingWindow orderOut:self];
	[busyWindow makeKeyAndOrderFront:self];
	if (([[fileNameDestination stringValue] isEqualToString:@"Wrapper"]))
	{
		//uncompress download
		[self makeFoldersAndFiles];
		system([[NSString stringWithFormat:@"\"%@/Library/Application Support/Wineskin/7za\" x \"/tmp/%@.app.tar.7z\" -o/tmp", NSHomeDirectory(),[fileName stringValue]] UTF8String]);
		system([[NSString stringWithFormat:@"/usr/bin/tar -C /tmp -xf /tmp/%@.app.tar",[fileName stringValue]] UTF8String]);
		//remove 7z and tar
		[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@.app.tar.7z",[fileName stringValue]] error:nil];
		[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@.app.tar",[fileName stringValue]] error:nil];
		//remove old one
		[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/Library/Application Support/Wineskin/Wrapper",NSHomeDirectory()] error:nil];
		[self makeFoldersAndFiles];
		//move download into place
		[[NSFileManager defaultManager] moveItemAtPath:[NSString stringWithFormat:@"/tmp/%@.app",[fileName stringValue]] toPath:[NSString stringWithFormat:@"%@/Library/Application Support/Wineskin/%@/%@.app",NSHomeDirectory(),[fileNameDestination stringValue],[fileName stringValue]] error:nil];
		[busyWindow orderOut:self];
		[window makeKeyAndOrderFront:self];
	}
	else if (([[fileNameDestination stringValue] isEqualToString:@"Engines"]))
	{
		//move download into place
		[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/Library/Application Support/Wineskin/%@/%@.tar.7z",NSHomeDirectory(),[fileNameDestination stringValue],[fileName stringValue]] error:nil];
		[[NSFileManager defaultManager] moveItemAtPath:[NSString stringWithFormat:@"/tmp/%@.tar.7z",[fileName stringValue]] toPath:[NSString stringWithFormat:@"%@/Library/Application Support/Wineskin/%@/%@.tar.7z",NSHomeDirectory(),[fileNameDestination stringValue],[fileName stringValue]] error:nil];
		//remove engine from ignored list
		NSString *ignoreList = [NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@/Library/Application Support/Wineskin/IgnoredEngines.txt",NSHomeDirectory()] encoding:NSUTF8StringEncoding error:nil];
		ignoreList = [ignoreList stringByReplacingOccurrencesOfString:[fileName stringValue] withString:@""];
		[ignoreList writeToFile:[NSHomeDirectory() stringByAppendingString:@"/Library/Application Support/Wineskin/IgnoredEngines.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
		[busyWindow orderOut:self];
		[window makeKeyAndOrderFront:self];
	}
	else if (([[fileNameDestination stringValue] isEqualToString:@"EngineBase"]))
	{
		//uncompress download
		[self makeFoldersAndFiles];
		system([[NSString stringWithFormat:@"\"%@/Library/Application Support/Wineskin/7za\" x \"/tmp/%@.tar.7z\" -o/tmp", NSHomeDirectory(),[fileName stringValue]] UTF8String]);
		system([[NSString stringWithFormat:@"/usr/bin/tar -C /tmp -xf /tmp/%@.tar",[fileName stringValue]] UTF8String]);
		//remove 7z and tar
		[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@.tar.7z",[fileName stringValue]] error:nil];
		[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@.tar",[fileName stringValue]] error:nil];
		//remove old one
		[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/Library/Application Support/Wineskin/EngineBase",NSHomeDirectory()] error:nil];
		[self makeFoldersAndFiles];
		//move download into place
		[[NSFileManager defaultManager] moveItemAtPath:[NSString stringWithFormat:@"/tmp/%@",[fileName stringValue]] toPath:[NSString stringWithFormat:@"%@/Library/Application Support/Wineskin/%@/%@",NSHomeDirectory(),[fileNameDestination stringValue],[fileName stringValue]] error:nil];		
		NSString *currentEngineBuild = [self currentEngineBuildVersion];
		[engineBuildCurrentEngineBase setStringValue:currentEngineBuild];
		NSString *availableEngineBase = [self availableEngineBuildVersion];
		//set default engine name
		[engineBuildEngineName setStringValue:[NSString stringWithFormat:@"%@-MyCustomEngine",[currentEngineBuild stringByReplacingOccurrencesOfString:@"EngineBase" withString:@""]]];
		//set update button and label
		if ([availableEngineBase isEqualToString:currentEngineBuild])
		{
			[engineBuildUpdateButton setEnabled:NO];
			[engineBuildUpdateAvailable setHidden:YES];
		}
		else
		{
			[engineBuildUpdateButton setEnabled:YES];
			[engineBuildUpdateAvailable setHidden:NO];
		}
		[busyWindow orderOut:self];
		[wineskinEngineBuilderWindow makeKeyAndOrderFront:self];
	}
	if ([[fileName stringValue] isEqualToString:@"Wineskin Winery Update"])
	{
		//take care of update
		[self makeFoldersAndFiles];
		[[NSFileManager defaultManager] removeItemAtPath:@"/tmp/WineskinWineryUpdater" error:nil];
		system([[NSString stringWithFormat:@"\"%@/Library/Application Support/Wineskin/7za\" x \"/tmp/WineskinWinery.app.tar.7z\" -o/tmp", NSHomeDirectory()] UTF8String]);
		system([[NSString stringWithFormat:@"/usr/bin/tar -C /tmp -xf /tmp/WineskinWinery.app.tar"] UTF8String]);
		[[NSFileManager defaultManager] copyItemAtPath:@"/tmp/WineskinWinery.app/Contents/Resources/WineskinWineryUpdater" toPath:@"/tmp/WineskinWineryUpdater" error:nil];
		//run updater program
		system([[NSString stringWithFormat:@"/tmp/WineskinWineryUpdater \"%@\" &",[[NSBundle mainBundle] bundlePath]] UTF8String]);
		//kill this app, Updater will restart it after changing out contents.
		[NSApp terminate:self];
	}
	[self refreshButtonPressed:self];
}
- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
	[self downloadToggle:NO];
	
	[payload setLength:0];
	
	// Create and display an alert sheet
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:[error localizedDescription]];
	[alert setAlertStyle:NSCriticalAlertStyle];
	
	[alert beginSheetModalForWindow:[cancelButton window] modalDelegate:self didEndSelector:nil contextInfo:nil];
	[downloadingWindow orderOut:self];
	[window makeKeyAndOrderFront:self];
}
//*********************** wrapper creation **********************
- (IBAction)createWrapperOkButtonPressed:(id)sender
{
	//make sure wrapper name is unique
	if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/Applications/Wineskin/%@.app",NSHomeDirectory(),[createWrapperName stringValue]]])
	{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"Oops! File already exists!"];
		[alert setInformativeText:[NSString stringWithFormat:@"A wrapper at \"%@/Applications/Wineskin\" with the name \"%@\" already exists!  Please choose a different name.",NSHomeDirectory(),[createWrapperName stringValue]]];
		[alert setAlertStyle:NSInformationalAlertStyle];
		[alert runModal];
		[alert release];
		return;
	}
	//replace common symbols...
	[createWrapperName setStringValue:[[createWrapperName stringValue] stringByReplacingOccurrencesOfString:@"&" withString:@"and"]];
	[createWrapperName setStringValue:[[createWrapperName stringValue] stringByReplacingOccurrencesOfString:@"!" withString:@""]];
	[createWrapperName setStringValue:[[createWrapperName stringValue] stringByReplacingOccurrencesOfString:@"#" withString:@""]];
	[createWrapperName setStringValue:[[createWrapperName stringValue] stringByReplacingOccurrencesOfString:@"$" withString:@""]];
	[createWrapperName setStringValue:[[createWrapperName stringValue] stringByReplacingOccurrencesOfString:@"%" withString:@""]];
	[createWrapperName setStringValue:[[createWrapperName stringValue] stringByReplacingOccurrencesOfString:@"^" withString:@""]];
	[createWrapperName setStringValue:[[createWrapperName stringValue] stringByReplacingOccurrencesOfString:@"*" withString:@""]];
	[createWrapperName setStringValue:[[createWrapperName stringValue] stringByReplacingOccurrencesOfString:@"(" withString:@""]];
	[createWrapperName setStringValue:[[createWrapperName stringValue] stringByReplacingOccurrencesOfString:@")" withString:@""]];
	[createWrapperName setStringValue:[[createWrapperName stringValue] stringByReplacingOccurrencesOfString:@"+" withString:@""]];
	[createWrapperName setStringValue:[[createWrapperName stringValue] stringByReplacingOccurrencesOfString:@"=" withString:@""]];
	[createWrapperName setStringValue:[[createWrapperName stringValue] stringByReplacingOccurrencesOfString:@"|" withString:@""]];
	[createWrapperName setStringValue:[[createWrapperName stringValue] stringByReplacingOccurrencesOfString:@"\\" withString:@""]];
	[createWrapperName setStringValue:[[createWrapperName stringValue] stringByReplacingOccurrencesOfString:@"?" withString:@""]];
	[createWrapperName setStringValue:[[createWrapperName stringValue] stringByReplacingOccurrencesOfString:@">" withString:@""]];
	[createWrapperName setStringValue:[[createWrapperName stringValue] stringByReplacingOccurrencesOfString:@"<" withString:@""]];
	[createWrapperName setStringValue:[[createWrapperName stringValue] stringByReplacingOccurrencesOfString:@";" withString:@""]];
	[createWrapperName setStringValue:[[createWrapperName stringValue] stringByReplacingOccurrencesOfString:@":" withString:@""]];
	[createWrapperName setStringValue:[[createWrapperName stringValue] stringByReplacingOccurrencesOfString:@"@" withString:@""]];
	//get rid of window
	[createWrapperWindow orderOut:self];
	[busyWindow makeKeyAndOrderFront:self];
	[self makeFoldersAndFiles];
	//delete files that might already exist
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@.app",[createWrapperName stringValue]] error:nil];
	[fm removeItemAtPath:[NSString stringWithFormat:@"%@/Library/Application Support/Wineskin/Engines/%@.tar",NSHomeDirectory(),[createWrapperEngine stringValue]] error:nil];
	[fm removeItemAtPath:[NSString stringWithFormat:@"%@/Library/Application Support/Wineskin/Engines/WineskinEngine.bundle",NSHomeDirectory()] error:nil];
	//copy master wrapper to /tmp with correct name
	//NSError *error = nil;
	[fm copyItemAtPath:[NSString stringWithFormat:@"%@/Library/Application Support/Wineskin/Wrapper/%@.app",NSHomeDirectory(),[wrapperVersion stringValue]] toPath:[NSString stringWithFormat:@"/tmp/%@.app",[createWrapperName stringValue]] error:nil];
	//[self displayString:[error localizedDescription]];
	//decompress engine
	system([[NSString stringWithFormat:@"\"%@/Library/Application Support/Wineskin/7za\" x \"%@/Library/Application Support/Wineskin/Engines/%@.tar.7z\" \"-o/%@/Library/Application Support/Wineskin/Engines\"", NSHomeDirectory(),NSHomeDirectory(),[createWrapperEngine stringValue],NSHomeDirectory()] UTF8String]);
	system([[NSString stringWithFormat:@"/usr/bin/tar -C \"%@/Library/Application Support/Wineskin/Engines\" -xf \"%@/Library/Application Support/Wineskin/Engines/%@.tar\"",NSHomeDirectory(),NSHomeDirectory(),[createWrapperEngine stringValue]] UTF8String]);
	//remove tar
	[fm removeItemAtPath:[NSString stringWithFormat:@"%@/Library/Application Support/Wineskin/Engines/%@.tar",NSHomeDirectory(),[createWrapperEngine stringValue]] error:nil];
	//put engine in wrapper
	[fm moveItemAtPath:[NSString stringWithFormat:@"%@/Library/Application Support/Wineskin/Engines/WineskinEngine.bundle",NSHomeDirectory()] toPath:[NSString stringWithFormat:@"/tmp/%@.app/Contents/Resources/WineskinEngine.bundle",[createWrapperName stringValue]] error:nil];
	//refresh wrapper
	system([[NSString stringWithFormat:@"\"/tmp/%@.app/Contents/MacOS/Wineskin\" WSS-wineprefixcreate",[createWrapperName stringValue]] UTF8String]);
	//move wrapper to ~/Applications/Wineskin
	[fm moveItemAtPath:[NSString stringWithFormat:@"/tmp/%@.app",[createWrapperName stringValue]] toPath:[NSString stringWithFormat:@"%@/Applications/Wineskin/%@.app",NSHomeDirectory(),[createWrapperName stringValue]] error:nil];
	//put ending message
	[busyWindow orderOut:self];
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"View wrapper in Finder"];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:@"Wrapper Creation Finished"];
	[alert setInformativeText:[NSString stringWithFormat:@"Created File: %@.app\n\nCreated In:%@/Applications/Wineskin\n",[createWrapperName stringValue],NSHomeDirectory()]];
	[alert setAlertStyle:NSInformationalAlertStyle];
	if ([alert runModal] == NSAlertFirstButtonReturn)
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"file://%@/Applications/Wineskin/",NSHomeDirectory()]]];
	// bring main window back
	[window makeKeyAndOrderFront:self];
}
- (IBAction)createWrapperCancelButtonPressed:(id)sender
{
	[createWrapperWindow orderOut:self];
	[window makeKeyAndOrderFront:self];
}
//***************************** OVERRIDES *************************
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [installedEnginesList count];
}
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return [installedEnginesList objectAtIndex:rowIndex];
}
- (id)init
{
	self = [super init];
	if (self)
	{
		installedEnginesList = [[NSMutableArray alloc] initWithObjects:@"Please Wait...",nil];
	}
	return self;
}
- (void)dealloc
{
	[installedEnginesList release];
	[super dealloc];
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

@end
