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

#import "DVDPreferencePane.h"
#import "XineKit/XineKit.h"
#import "Preferences/XPPreferencesController.h"

#define XPPreferencesController NSClassFromString(@"XPPreferencesController")

@implementation DVDPreferencePane

- (BOOL) validateDVDRegion:(id*) ioValue error: (NSError**) outError
{
	if(*ioValue == nil)
		return YES;
	
	if(([*ioValue intValue] < 1) || ([*ioValue intValue] > 8))
	{
		NSString *errorString = NSLocalizedString(@"DVD region must be between 1 and 8", @"validation: invalid dvd region");
		NSError *error = [[[NSError alloc] initWithDomain:@"DVDPreferences" code:0 userInfo:[NSDictionary dictionaryWithObject:errorString forKey:NSLocalizedDescriptionKey]] autorelease];
		*outError = error;
		return NO;
	}
	
	return YES;
}

- (id) DVDRegion
{
	return [NSNumber numberWithInt: [[XPPreferencesController defaultController] DVDRegion]];
}

- (void) setDVDRegion: (id) region
{
	[[XPPreferencesController defaultController] setDVDRegion: [region intValue]];
}

@end
