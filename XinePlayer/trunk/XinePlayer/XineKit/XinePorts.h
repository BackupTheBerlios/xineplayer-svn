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

@class XineEngine;
@class XineVideoView;

@interface XinePort : NSObject {
	void *_port;
	XineEngine *_engine;
	BOOL _needsClosing;
}

- (id) initWithHandle: (void*) handle fromEngine: (XineEngine*) engine shouldClose: (BOOL) shouldClose;
- (id) initWithHandle: (void*) handle fromEngine: (XineEngine*) engine;
- (XineEngine*) engine;
- (void*) handle;
@end

@interface XineAudioPort : XinePort {
}
+ (XineAudioPort*) audioPortForDriver: (NSString*) driver fromEngine: (XineEngine*) engine userData: (void*) data;
@end

@interface XineVideoPort : XinePort {
	XineVideoView *_view;
}
+ (XineVideoPort*) videoPortForDriver: (NSString*) driver fromEngine: (XineEngine*) engine forView: (XineVideoView*) view;
- (id) initWithHandle: (void*) handle fromEngine: (XineEngine*) engine shouldClose: (BOOL) shouldClose forView: (XineVideoView*) view;
- (XineVideoView*) videoView;
@end
