/* DesktopManager -- A virtual desktop provider for OS X
 * Adapted for XinePlayer -- A OS X multimedia player
 * 
 * Copyright (C) 2003, 2004, 2005 Richard J Wareham <richwareham@users.sourceforge.net>
 * This program is free software; you can redistribute it and/or modify it 
 * under the terms of the GNU General Public License as published by the Free 
 * Software Foundation; either version 2 of the License, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but 
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
 * for more details.
 *
 * You should have received a copy of the GNU General Public License along 
 * with this program; if not, write to the Free Software Foundation, Inc., 675 
 * Mass Ave, Cambridge, MA 02139, USA.
 */
 
#import "XPPreferencesController.h"
#import <PreferencePanes/NSPreferencePane.h>
#import "../XineKit/XineKit.h"

#define XP_PREF_AUDIO_VISUALISATION @"AudioVisualisation"

static XPPreferencesController *_defaultController = nil;

@implementation XPPreferencesController

- (NSArray*) audioVisualisationNames
{	
	NSMutableArray *array = [NSMutableArray arrayWithObject: @"none"];
	[array addObjectsFromArray: [[XineEngine defaultEngine] postProcessorNamesForType: XinePostAudioVisualization]];
	return array;
}

- (NSString*) audioVisualisation
{
	id retVal = [[NSUserDefaults standardUserDefaults] objectForKey: XP_PREF_AUDIO_VISUALISATION];
	if(retVal && [[self audioVisualisationNames] containsObject: retVal])
		return retVal;
	
	return [[self audioVisualisationNames] objectAtIndex: 0];
}

- (void) setAudioVisualisation: (NSString*) value {
	if(![[self audioVisualisationNames] containsObject: value])
		return;
	
	[[NSUserDefaults standardUserDefaults] setObject:value forKey: XP_PREF_AUDIO_VISUALISATION];
}

+ (XPPreferencesController*) defaultController
{
	if(_defaultController)
		return _defaultController;
	return nil;
	// return [[[XPPreferencesController alloc] init] autorelease];
}

- (id) init 
{
	id mySelf = [super init];
	if(mySelf) {
		if(!_defaultController)
			_defaultController = self;
	}
	return mySelf;
}

- (void) awakeFromNib {
	panesArray = nil;
	toolbar = nil;
	toolbarItems = nil;
	selectableIdentifiers = nil;
	defaultIdentifiers = nil;
}

- (void) freeResources: (id) sender
{
	if(panesArray) { 
		[panesArray release]; 
		panesArray = nil;
	}
	if(toolbar) { 
		[prefsWindow setToolbar: nil];
		[toolbar release]; 
		toolbar = nil;
	}
	if(toolbarItems) {
		[toolbarItems release]; 
		toolbarItems = nil;
	}
	if(selectableIdentifiers) { 
		[selectableIdentifiers release]; 
		selectableIdentifiers = nil;
	}
	if(defaultIdentifiers) { 
		[defaultIdentifiers release];
		defaultIdentifiers = nil;
	}
}

- (void) dealloc 
{
	[self freeResources: nil];
	if(_defaultController == self)
		_defaultController = nil;
	
	[super dealloc];
}

- (void) prefsChanged {
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction) showPreferences: (id) sender {
	if(!panesArray)
		[self buildPreferencesToolbar: nil];
	
    [prefsWindow orderOut: self];      
    [prefsWindow center];
    [prefsWindow makeKeyAndOrderFront: self];
}

- (void) showPane: (NSPreferencePane*) pane animate: (BOOL) animate {
	NSView *mainView = [pane mainView];
	NSView *contentView = [prefsWindow contentView];
	NSView *oldView = nil;
	
	if([[contentView subviews] count]) {
		oldView = [[contentView subviews] objectAtIndex: 0];
	}
	
	if(oldView == mainView) { return; /* Nothing to do here */ }
	
	if(!mainView) { NSLog(@"Error getting main view."); return; }
	
	NSRect newFrame = [prefsWindow frame];
	float newHeight = [prefsWindow frameRectForContentRect: [mainView frame]].size.height;
	newFrame.origin.y += newFrame.size.height - newHeight;
	newFrame.size.height = newHeight;

	if(oldView) { [oldView removeFromSuperview]; }
	[prefsWindow setFrame: newFrame display: YES animate: animate];
	[pane willSelect];
	[contentView addSubview: mainView];
	[pane didSelect];
}

- (void) showPane: (NSPreferencePane*) pane
{
	[self showPane: pane animate: YES];
}

- (id) valueForKey: (NSString*) key
{
	NSLog(@"Hello %@", key);
	return [super valueForKey: key];
}

- (void) buildPreferencesToolbar: (id) controller 
{
	panesArray = [[NSMutableArray array] retain];
	toolbar = [[NSToolbar alloc] initWithIdentifier: @"PreferencesToolbar"];
	toolbarItems = [[NSMutableDictionary dictionary] retain];
	
	selectableIdentifiers = [[NSMutableArray array] retain];
	defaultIdentifiers = [[NSMutableArray array] retain];
	
	// Get list of plugins.
	NSMutableArray *prefBundles = [NSMutableArray array];
	
	// Load built-in plugins.
	NSArray *builtInBundles = [[NSBundle mainBundle] pathsForResourcesOfType: @"bundle"
		inDirectory: @"PreferencePanes"];
	if(builtInBundles && [builtInBundles count]) {
		NSString *bundlePath;
		NSEnumerator *bundleEnum = [builtInBundles objectEnumerator];
		while(bundlePath = [bundleEnum nextObject]) {
			NSBundle *prefBundle = [NSBundle bundleWithPath: bundlePath];
			
			if(![prefBundle isLoaded])
				[prefBundle load];
			
			NSString *iconLabel = [prefBundle objectForInfoDictionaryKey: @"NSPreferenceLabel"];
			NSString *iconPath = [prefBundle pathForImageResource: [prefBundle objectForInfoDictionaryKey: @"NSPreferenceIcon"]];
			NSPreferencePane *pane = [[[[prefBundle principalClass] alloc] initWithBundle: prefBundle] autorelease];
		
			[pane loadMainView];
			[panesArray addObject: pane];
			
			if(!iconPath) { 
				NSLog(@"Error loading icon: %@", iconPath);
			} else {
				NSImage *itemImage = [[[NSImage alloc] initByReferencingFile: iconPath] autorelease];
				
				if(!itemImage) { NSLog(@"Warning: Couldn't load image."); }
				
				NSToolbarItem *toolbarItem;
				toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: iconLabel] autorelease];
				
				if(!toolbarItem) 
					NSLog(@"Warning: Could not create toolbar item."); 
				
				[toolbarItem setImage: itemImage];
				[toolbarItem setLabel: iconLabel];
				[toolbarItem setTag: [panesArray count] - 1]; // The index of the appropriate pane.
				[toolbarItem setTarget: self];
				[toolbarItem setAction: @selector(toolbarButtonClicked:)];
				
				[toolbarItems setObject: toolbarItem forKey: iconLabel];
				[selectableIdentifiers insertObject: iconLabel atIndex: 0];
				[defaultIdentifiers insertObject: iconLabel atIndex: 0];
			}
		}
	}
	
	[toolbar setAutosavesConfiguration: NO];
	[toolbar setAllowsUserCustomization: NO];

	[toolbar setDelegate: self];
	[prefsWindow setToolbar: toolbar];
	
	if([selectableIdentifiers count]) {
		NSString *identifier = [selectableIdentifiers objectAtIndex: 0];
		NSToolbarItem *item = [toolbarItems objectForKey: identifier];
		NSPreferencePane *pane = [panesArray objectAtIndex: [item tag]];
		[toolbar setSelectedItemIdentifier: identifier];
		[self showPane: pane animate: NO];
	}
}

- (void) toolbarButtonClicked: (id) sender {
	NSPreferencePane *pane = [panesArray objectAtIndex: [(NSToolbarItem*) sender tag]];
	
	if(!pane) { NSLog(@"Error getting pane."); return; }

	[self showPane: pane];
}

// Toolbar delegate functions.
- (NSToolbarItem*) toolbar: (NSToolbar*) theToolbar
	itemForItemIdentifier: (NSString*) identifier willBeInsertedIntoToolbar: (BOOL) flag 
{
	NSToolbarItem *item = [toolbarItems objectForKey: identifier];
	if(!item) { return nil; }
	
	return item;
}

- (NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar*) theToolbar 
{
	//NSLog(@"Allowed Items: %i", [[toolbarItems allKeys] count]);
	return defaultIdentifiers;
}

- (NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar*) theToolbar 
{
	//NSLog(@"Default Items: %i", [[toolbarItems allKeys] count]);
	return defaultIdentifiers;
}

- (NSArray*) toolbarSelectableItemIdentifiers: (NSToolbar*) theToolbar 
{
	//NSLog(@"Default Items: %i", [[toolbarItems allKeys] count]);
	return selectableIdentifiers;
}

@end
