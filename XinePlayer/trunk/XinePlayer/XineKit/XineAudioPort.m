/* XineKit - Objective C wrapper for xine-lib.
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

#import <XineKitIntl.h>

@implementation XineAudioPort

- (xine_t*) engine
{
	return xine;
}

- (xine_audio_port_t*) port
{
	return port;
}

- (id) initWithDriver: (NSString*) driver data: (id) data engine: (xine_t*) _xine
{
	id mySelf = [super init];
	if(mySelf) 
	{
		xine = _xine;
		port = xine_open_audio_driver(xine,[driver cString],data);
		
		if(!port) 
		{
			return nil;
		}
	}
	
	return mySelf;
}

- (void) dealloc
{
	if(port)
	{
		xine_close_audio_driver(xine,port);
	}
	[super dealloc];
}

@end
