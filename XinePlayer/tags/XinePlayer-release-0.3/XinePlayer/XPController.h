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


#import <Cocoa/Cocoa.h>

@class XineEngine;

@interface XPController : NSObject {
	IBOutlet NSPanel *dvdControlsPanel;
	IBOutlet NSWindow *_openURLDialogue;
	IBOutlet NSComboBox *_openURLComboBox;
	XineEngine *_defaultEngine;
}

+ (XPController*) sharedController;

- (void) openDisc: (NSString*) devicePath;

- (BOOL) isDVDPanelOpen;

- (IBAction) openFirstDisc: (id) sender;
- (IBAction) openURL: (id) sender;
- (IBAction) openDVDPanel: (id) sender;
- (IBAction) closeDVDPanel: (id) sender;

- (IBAction) openURLClicked: (id) sender;
- (IBAction) cancelOpenURLClicked: (id) sender;

@end
