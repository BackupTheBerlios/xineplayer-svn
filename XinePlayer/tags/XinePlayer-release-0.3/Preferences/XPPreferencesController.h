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
 
#import <Foundation/Foundation.h>
#import <PreferencePanes/PreferencePanes.h>

@class XineEngine;

@interface XPPreferencesController : NSObject {
    IBOutlet NSWindow *prefsWindow;
  
	NSToolbar *toolbar;
    NSMutableArray *namesArray;
	NSMutableArray *panesArray;
	NSMutableDictionary *toolbarItems;
	NSMutableArray *selectableIdentifiers;
	NSMutableArray *defaultIdentifiers;
    int fromRow;
}

+ (XPPreferencesController*) defaultController;

- (IBAction) showPreferences: (id) sender;
- (void) buildPreferencesToolbar: (id) controller;

- (NSArray*) audioVisualisationNames;
- (NSString*) audioVisualisation;
- (void) setAudioVisualisation: (NSString*) visualisation;
- (NSArray*) deinterlaceAlgorithms;
- (NSString*) deinterlaceAlgorithm;
- (void) setDeinterlaceAlgorithm: (id) value;
- (BOOL) resizeWindowOnFrameChange;
- (void) setResizeWindowOnFrameChange: (BOOL) value;
- (int) DVDRegion;
- (void) setDVDRegion: (int) region;

@end

