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

#import <Cocoa/Cocoa.h>

@interface XineVideoView : NSView {
	xine_stream_t *_associatedStream;
	NSSize _videoSize;
	float _aspectRatio;
	NSQuickDrawView *_videoView;

	void *_lastFrame;
	int _lastFormat;
	void *_yuvDisplay;
	
	NSLock *_displayLock;
	NSWindow *_fullScreenWindow;
	NSTimer *_cursorHideTimer;
}

- (NSRect) contentFrame;

- (void) didAssociateWithStream: (xine_stream_t*) stream;
- (void) didDisassociateWithStream: (xine_stream_t*) stream;
- (NSRect) idealParentWindowFrame: (float) ratio;
- (void) resizeParentWindowToFit: (float) ratio;

- (NSSize) videoSize;
- (float) aspectRatio;

- (void) goFullScreen: (id) sender;
- (void) exitFullScreen: (id) sender;
- (BOOL) isFullScreen;

@end

@interface XineVideoView (Internal)

- (void) displayFrame: (void*) pixmap size: (NSSize) frameSize aspectRatio: (float) ratio format: (int) format;
- (void) freedFrame: (void*) pixmap;
- (void*) videoPort;

@end
