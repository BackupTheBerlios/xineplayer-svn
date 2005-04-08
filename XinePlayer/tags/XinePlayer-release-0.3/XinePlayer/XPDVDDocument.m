/* XinePlayer - Cocoa-based GUI frontend to Xine.
*
* Copyright (C) 2005 Richard J Wareham <richwareham@users.sourceforge.net>
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

#import "XPDVDDocument.h"
#import "XPController.h"

#import <xine.h>

@implementation XPDVDDocument

- (BOOL) isDVDPlayer
{
	return YES;
}

- (IBAction) gotoDVDTitleMenu: (id) sender
{
	[_stream sendInputButtonEvent: XINE_EVENT_INPUT_MENU1];
	[[self documentWindow] makeKeyWindow];
}

- (IBAction) gotoDVDMenu: (id) sender
{
	[_stream sendInputButtonEvent: XINE_EVENT_INPUT_MENU2];
	[[self documentWindow] makeKeyWindow];
}

- (IBAction) upArrowPressed: (id) sender
{
	[videoView moveUp: sender];
	[[self documentWindow] makeKeyWindow];
}

- (IBAction) downArrowPressed: (id) sender
{
	[videoView moveDown: sender];
	[[self documentWindow] makeKeyWindow];
}

- (IBAction) leftArrowPressed: (id) sender
{
	[videoView moveLeft: sender];
	[[self documentWindow] makeKeyWindow];
}

- (IBAction) rightArrowPressed: (id) sender
{
	[videoView moveRight: sender];
	[[self documentWindow] makeKeyWindow];
}

- (IBAction) selectButtonPressed: (id) sender
{
	[_stream sendInputButtonEvent: XINE_EVENT_INPUT_SELECT];
	[[self documentWindow] makeKeyWindow];
}

- (IBAction) toggleDVDControls: (id) sender
{
	XPController *controller = [XPController sharedController];
	
	if([controller isDVDPanelOpen]) {
		[controller closeDVDPanel: sender];
	} else {
		[controller openDVDPanel: sender];
	}
}

- (BOOL)validateMenuItem: (NSMenuItem*) item
{
	NSString *itemSelector = NSStringFromSelector([item action]);
	BOOL superVal = [super validateMenuItem: item];
	
	if([itemSelector isEqualToString: @"toggleDVDControls:"]) 
	{
		// Work out which we want it to be.
		if([[XPController sharedController] isDVDPanelOpen]) 
		{
			[item setTitle: [[NSBundle mainBundle] localizedStringForKey:@"HideDVDControls" value:@"Hide DVD" table:nil]];
		} else {
			[item setTitle: [[NSBundle mainBundle] localizedStringForKey:@"ShowDVDControls" value:@"Show DVD" table:nil]];
		}
	} else if([itemSelector isEqualToString: @"togglePlaylist:"]) 
	{
		return NO;
	}

	return superVal;
}

- (NSString*) displayName
{
	return [[NSBundle mainBundle] localizedStringForKey:@"DVDPlayerName" value:@"DVD Player" table:nil];
}

@end
