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

#import "xine.h"
#import <XineKit.h>

@implementation XinePort

- (XineEngine*) engine
{
	return _engine;
}

- (void*) handle
{
	return _port;
}

- (id) initWithHandle: (void*) handle fromEngine: (XineEngine*) engine shouldClose: (BOOL) shouldClose
{
	id mySelf = [self init];
	if(mySelf) 
	{
		_engine = [engine retain];
		_port = handle;
		_needsClosing = shouldClose;
	}
	
	return mySelf;	
}

- (id) initWithHandle: (void*) handle fromEngine: (XineEngine*) engine
{
	return [self initWithHandle:handle fromEngine:engine shouldClose: NO];
}

- (void) dealloc
{
	if(_engine)
		[_engine release];
	[super dealloc];
}

@end

@implementation XineAudioPort

+ (XineAudioPort*) audioPortForDriver: (NSString*) driver fromEngine: (XineEngine*) engine userData: (void*) data 
{
	xine_audio_port_t *port = xine_open_audio_driver([engine handle],[driver cString],data);
	
	if(!port) 
		return nil;
	
	return [[[XineAudioPort alloc] initWithHandle:port fromEngine:engine shouldClose: YES] autorelease];
}

- (void) dealloc
{
	if(_needsClosing && _port) {
		xine_close_audio_driver([_engine handle],_port);
	}
	[super dealloc];
}

@end

@implementation XineVideoPort

+ (XineVideoPort*) videoPortForDriver: (NSString*) driver fromEngine: (XineEngine*) engine forView: (XineVideoView*) view
{
	xine_video_port_t *port = xine_open_video_driver([engine handle], [driver cString], XINE_VISUAL_TYPE_MACOSX, view);
	if(!port)
		return nil;
	return [[[XineVideoPort alloc] initWithHandle: port fromEngine: engine shouldClose: YES forView: view] autorelease];
}

- (id) init
{
	id mySelf = [super init];
	if(mySelf) {
		_view = nil;
	}
	return mySelf;
}

- (id) initWithHandle: (void*) handle fromEngine: (XineEngine*) engine shouldClose: (BOOL) shouldClose forView: (XineVideoView*) view
{
	id mySelf = [self initWithHandle: handle fromEngine: engine shouldClose: shouldClose];
	if(mySelf) {
		_view = [view retain];
	}
	return mySelf;
}

- (void) dealloc
{
	if(_needsClosing && _port) {
		xine_close_video_driver([_engine handle],_port);
	}
	if(_view)
		[_view release];
	[super dealloc];
}

- (XineVideoView*) videoView
{
	return _view;
}

@end

