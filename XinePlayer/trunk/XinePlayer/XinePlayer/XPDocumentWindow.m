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


#import "XPDocumentWindow.h"
#import "XPDocument.h"

@implementation XPDocumentWindow

- (void) awakeFromNib
{
	_displayingAdvancedPanel = YES;
	[self disclosureChanged: nil];
}

- (IBAction) disclosureChanged: (id) sender
{
	NSPoint origin = [[self contentView] bounds].origin;
	NSRect hideViewFrame = [_advancedPanel frame];
	NSRect growViewFrame = [_growView frame];
	NSRect windowFrame = [self frame];
	
	if([_advancedHideShowButton state] == NSOnState)
	{
		// Show advanced panel
		if(!_displayingAdvancedPanel)
		{
			growViewFrame.size.height -= hideViewFrame.size.height;
			origin.y -= hideViewFrame.size.height;
			windowFrame.size.height += hideViewFrame.size.height;
			windowFrame.origin.y -= hideViewFrame.size.height;
			
			[[self contentView] setBoundsOrigin:origin];
			[_growView setFrame: growViewFrame];
			[self setFrame:windowFrame display:YES animate: NO];
			
			_displayingAdvancedPanel = YES;
		}
	} else {
		// Hide advanced panel
		if(_displayingAdvancedPanel)
		{
			growViewFrame.size.height += hideViewFrame.size.height;
			origin.y += hideViewFrame.size.height;
			windowFrame.size.height -= hideViewFrame.size.height;
			windowFrame.origin.y += hideViewFrame.size.height;
			
			[[self contentView] setBoundsOrigin:origin];
			[_growView setFrame: growViewFrame];
			[self setFrame:windowFrame display:YES animate: NO];
			
			_displayingAdvancedPanel = NO;
		}
	}
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	// Make sure that we hace an XPDocument managing us.
	if(![[[self windowController] document] isKindOfClass: [XPDocument class]])
		return NSDragOperationNone;
	
	if([[sender draggingPasteboard] availableTypeFromArray: [NSArray arrayWithObjects: NSFilenamesPboardType, NSURLPboardType, nil]])
		return NSDragOperationCopy;
	
	return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	return [self draggingEntered: sender];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	if([self draggingEntered:sender] != NSDragOperationNone)
		return YES;

	return NO;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pBoard = [sender draggingPasteboard];
	if(![[[self windowController] document] isKindOfClass: [XPDocument class]])
		return NO;
	XPDocument *document = [[self windowController] document];
			
	if([self draggingEntered:sender] == NSDragOperationNone)
		return NO;
	
	if([pBoard availableTypeFromArray: [NSArray arrayWithObject: NSFilenamesPboardType]])
	{
		//NSLog(@"Filenames:");
		NSEnumerator *fnEnum = [[pBoard propertyListForType: NSFilenamesPboardType] objectEnumerator];
		NSString* file;
		while(file = [fnEnum nextObject])
		{
			[document addFileToPlaylist: file];
		}
		
		return YES;
	} else if([pBoard availableTypeFromArray: [NSArray arrayWithObject: NSURLPboardType]])
	{
		NSURL *url = [NSURL URLFromPasteboard: pBoard];
		[document addURLToPlaylist: url];
		
		return YES;
	}
	
	return NO;
}

- (void) keyDown: (NSEvent*) event
{
	if([[event characters] isEqualToString: @" "]) {
		[(XPDocument*)[[self windowController] document] togglePlayAndPause: self];
		return;
	}
	
	[super keyDown: event];
}

@end
