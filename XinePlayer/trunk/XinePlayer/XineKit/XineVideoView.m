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

#import <XineKit.h>
#import <QuickTime/QuickTime.h>
#import "QuartzYUVOutput.h"
#import <ApplicationServices/ApplicationServices.h>

#define CURSOR_DELAY 5

NSString *XineVideoViewFrameSizeDidChangeNotification = @"XineVideoViewFrameSizeDidChangeNotification";

@interface XineVideoView (Private)
- (BOOL) ensureDisplay;
@end

@implementation XineVideoView

- (NSRect) contentFrame
{
	NSSize contentSize = [self bounds].size;
	
	if([self isFullScreen])
		contentSize = [_fullScreenWindow contentRectForFrameRect: [_fullScreenWindow frame]].size;
	
	NSSize finalSize;		
	
	float videoAspect = _aspectRatio;
	
	if(videoAspect * contentSize.height > contentSize.width)
	{
		// Proceed by setting width.
		finalSize.width = contentSize.width;
		finalSize.height = finalSize.width / videoAspect;
	} else {
		// Proceed by setting height.
		finalSize.height = contentSize.height;
		finalSize.width = finalSize.height * videoAspect;
	}
	
	NSRect contentFrame;
	
	contentFrame.origin.x = 0.5 * (contentSize.width - finalSize.width) ;
	contentFrame.origin.y = 0.5 * (contentSize.height - finalSize.height);
	contentFrame.size = finalSize;
	
	contentFrame = NSInsetRect(NSIntegralRect(contentFrame),2,2);
	
	return contentFrame;
}

- (NSRect) idealParentWindowFrame: (float) ratio
{
	NSWindow *parentWindow = [self window];
	if(!parentWindow)
		return NSMakeRect(0,0,640,480);
	
	NSRect windowFrame = [parentWindow frame];
	NSRect oldFrame = windowFrame;
	
	NSSize delta = NSMakeSize(windowFrame.size.width - [self frame].size.width,windowFrame.size.height - [self frame].size.height);
	
	windowFrame.size.width = _aspectRatio * (ratio*_videoSize.height) + delta.width + 2;
	windowFrame.size.height = (ratio*_videoSize.height) + delta.height + 2;
	
	windowFrame.origin.x += 0.5*(oldFrame.size.width - windowFrame.size.width);
	windowFrame.origin.y += 0.5*(oldFrame.size.height - windowFrame.size.height);
	
	// Some magic to ensure that the new window doesn't go outside the visible screen.
	
	NSRect visFrame = [[parentWindow screen] visibleFrame];
	if(windowFrame.origin.x < visFrame.origin.x)
		windowFrame.origin.x = visFrame.origin.x;
	if(windowFrame.origin.y < visFrame.origin.y)
		windowFrame.origin.y = visFrame.origin.y;
	
	if(windowFrame.origin.x + windowFrame.size.width > visFrame.origin.x + visFrame.size.width)
		windowFrame.origin.x = visFrame.origin.x + visFrame.size.width - windowFrame.size.width;
	if(windowFrame.origin.y + windowFrame.size.height > visFrame.origin.y + visFrame.size.height)
		windowFrame.origin.y = visFrame.origin.y + visFrame.size.height - windowFrame.size.height;
	
	if(windowFrame.size.width > visFrame.size.width)
	{
		windowFrame.size.width = visFrame.size.width;
		windowFrame.origin.x = visFrame.origin.x;
	}
	if(windowFrame.size.height > visFrame.size.height)
	{
		windowFrame.size.height = visFrame.size.height;
		windowFrame.origin.y = visFrame.origin.y;
	}
	
	return NSIntegralRect(windowFrame);
}

- (void) resizeParentWindowToFit: (float) ratio
{
	NSWindow *parentWindow = [self window];
	if(!parentWindow || ![parentWindow isVisible])
		return;
	
	[parentWindow setFrame: [self idealParentWindowFrame: ratio] display:YES animate:YES];
}

- (void) dealloc
{
	if([self isFullScreen])
		[self exitFullScreen: nil];
	/*
	if(_eventQueue) {
		xine_event_dispose_queue(_eventQueue);
		_eventQueue = nil;
	}
	 */
	if(_yuvDisplay) {
		disposeYUVDisplay(_yuvDisplay);
		_yuvDisplay = nil;
	}
	if(_videoView)
		[_videoView release];
	if(_displayLock)
		[_displayLock release];
	[super dealloc];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		_associatedStream = nil;
		_aspectRatio = 4.0 / 3.0;
		_videoSize = NSMakeSize(0,0);
		_lastFrame = NULL;
		_lastFormat = XINE_IMGFMT_YV12;
		_yuvDisplay = NULL;
		_cursorHideTimer = nil;
		/* _eventQueue = nil; */
		
		_videoView = [[[NSQuickDrawView alloc] initWithFrame: [self contentFrame]] autorelease];
		[_videoView retain];
		[self addSubview: _videoView];
		
		_displayLock = [[NSLock alloc] init];
		
		[self setAutoresizesSubviews: YES];
		
		_fullScreenWindow = nil;
	}
    return self;
}

- (void)drawRect:(NSRect)rect {
	NSRectEdge mySides[] = {NSMinYEdge, NSMinXEdge, NSMaxYEdge, NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge, NSMaxXEdge};
	float myGrays[] = {NSBlack, NSBlack, NSWhite, NSWhite, NSDarkGray, NSDarkGray, NSWhite, NSWhite};
	
	if(_lastFrame && ![self isFullScreen]) {
		if([self ensureDisplay]) {
			displayImageOnView(_yuvDisplay, _lastFrame);
		}
	}
	
	NSDrawTiledRects(NSInsetRect([self contentFrame], -2, -2), rect, mySides, myGrays, 8);
	[[NSColor blackColor] set];
	NSRectFill([self contentFrame]);
	[super drawRect: rect];
}

- (NSSize) videoSize
{
	return _videoSize;
}

- (float) aspectRatio
{
	return _aspectRatio;
}

- (void) didDisassociateWithStream: (void*) stream
{
	_associatedStream = nil;
	/*
	if(_eventQueue) {
		xine_event_dispose_queue(_eventQueue);
		_eventQueue = nil;
	}
	 */
}

/*
- (void) processXineEvent: (const xine_event_t*) event
{
	switch(event->type) {
		case XINE_EVENT_FRAME_FORMAT_CHANGE:
			[_displayLock lock];
			xine_format_change_data_t *change = (xine_format_change_data_t*) event->data;
			NSLog(@"Old size: %f,%f", _videoSize.width, _videoSize.height);
			_videoSize = NSMakeSize(change->width, change->height);
			NSLog(@"New size: %f,%f", _videoSize.width, _videoSize.height);
			[self setNeedsDisplay: YES];
			[_displayLock unlock];
			break;
	}
}

void _event_listener_cb(void *user_data, const xine_event_t *event) {
	XineVideoView *recipient = (XineVideoView*) user_data;
	if(![recipient isKindOfClass: [XineVideoView class]]) 
		return;
	
	[recipient processXineEvent: event];
}
*/

- (void) didAssociateWithStream: (void*) stream
{
	_associatedStream = stream;
	/*
	if(_eventQueue) {
		xine_event_dispose_queue(_eventQueue);
		_eventQueue = nil;
	}
	_eventQueue = xine_event_new_queue(_associatedStream);
	xine_event_create_listener_thread(_eventQueue,_event_listener_cb,self);
	 */
}

- (NSPoint) convertLocationFromEvent: (NSEvent*) theEvent
{
	NSPoint location = [_videoView convertPoint: [theEvent locationInWindow] fromView: nil];
	
	if([self isFullScreen]) {
		location = [_videoView convertPoint: [_fullScreenWindow convertScreenToBase: [NSEvent mouseLocation]] fromView: nil];
	}
	
	location.x /= [_videoView bounds].size.width;
	location.y /= [_videoView bounds].size.height;
	location.x *= _videoSize.width;
	location.y *= _videoSize.height;
	
	return location;
}

- (void) mouseDown:(NSEvent *)theEvent
{
	if(!_associatedStream)
		return;
	
	xine_input_data_t buttonData;
	xine_event_t event;
	
	NSPoint location = [self convertLocationFromEvent: theEvent];
	if(!NSPointInRect(location, NSMakeRect(0,0,_videoSize.width,_videoSize.height)))
	   return;
	
	buttonData.button = 1;
	buttonData.x = location.x;
	buttonData.y = location.y;
	event.type = XINE_EVENT_INPUT_MOUSE_BUTTON;
	event.data = &buttonData;
	event.data_length = sizeof(buttonData);
	event.stream = _associatedStream;
	
	xine_event_send(_associatedStream, &event);
}

- (void) mouseMoved:(NSEvent *)theEvent
{
	if(!_associatedStream)
		return;

	if([self isFullScreen]) {
		[NSCursor setHiddenUntilMouseMoves: NO];
		[_cursorHideTimer invalidate];
		_cursorHideTimer = [NSTimer scheduledTimerWithTimeInterval:CURSOR_DELAY target:self selector:@selector(cursorHideTick:) userInfo:nil repeats:NO];
	}
	
	xine_input_data_t buttonData;
	xine_event_t event;
	
	NSPoint location = [self convertLocationFromEvent: theEvent];
	if(!NSPointInRect(location, NSMakeRect(0,0,_videoSize.width,_videoSize.height)))
	   return;
	
	buttonData.button = 0;
	buttonData.x = location.x;
	buttonData.y = location.y;
	event.type = XINE_EVENT_INPUT_MOUSE_MOVE;
	event.data = &buttonData;
	event.data_length = sizeof(buttonData);
	event.stream = _associatedStream;
	
	xine_event_send(_associatedStream, &event);
}

- (void)moveDown:(id)sender
{
	if(!_associatedStream)
		return;
	
	xine_event_t event;
	
	event.type = XINE_EVENT_INPUT_DOWN;
	event.stream = _associatedStream;
	event.data = nil;
	event.data_length = 0;
	xine_event_send(_associatedStream,&event);
}

- (void)moveUp:(id)sender
{
	if(!_associatedStream)
		return;
	
	xine_event_t event;
	
	event.type = XINE_EVENT_INPUT_UP;
	event.stream = _associatedStream;
	event.data = nil;
	event.data_length = 0;
	xine_event_send(_associatedStream,&event);
}

- (void)moveLeft:(id)sender
{
	if(!_associatedStream)
		return;
	
	xine_event_t event;
	
	event.type = XINE_EVENT_INPUT_LEFT;
	event.stream = _associatedStream;
	event.data = nil;
	event.data_length = 0;
	xine_event_send(_associatedStream,&event);
}

- (void)moveRight:(id)sender
{
	if(!_associatedStream)
		return;
	
	xine_event_t event;
	
	event.type = XINE_EVENT_INPUT_RIGHT;
	event.stream = _associatedStream;
	event.data = nil;
	event.data_length = 0;
	xine_event_send(_associatedStream,&event);
}

- (void) goFullScreen: (id) sender
{
	if([self isFullScreen])
		return;
	
	if(CGDisplayCapture( kCGDirectMainDisplay ) != kCGErrorSuccess) {
		/* Failed to capture the screen */
		return;
	}
	
	_fullScreenWindow = [[NSWindow alloc] initWithContentRect: [[[self window] screen] frame] styleMask: NSBorderlessWindowMask backing: NSBackingStoreBuffered defer: NO screen: [[self window] screen]];
	[_fullScreenWindow setLevel: CGShieldingWindowLevel()];
	[_fullScreenWindow setBackgroundColor: [NSColor blackColor]];
	[_fullScreenWindow setAcceptsMouseMovedEvents: YES];
	NSView *tempView = [[[NSView alloc] initWithFrame: [_fullScreenWindow contentRectForFrameRect: [_fullScreenWindow frame]]] autorelease];
	[_fullScreenWindow setContentView: tempView];
	[_fullScreenWindow makeKeyAndOrderFront: nil];
	[_displayLock lock];
	[tempView addSubview: _videoView];
	[_videoView setFrame: [self contentFrame]];
	[_videoView setNextResponder: self];
	[_displayLock unlock];
	
	if(_lastFrame) {
		if([self ensureDisplay]) {
			displayImageOnView(_yuvDisplay, _lastFrame);
		}
	}
	
	_cursorHideTimer = [NSTimer scheduledTimerWithTimeInterval:CURSOR_DELAY target:self selector:@selector(cursorHideTick:) userInfo:nil repeats:NO];
}

- (void) cursorHideTick: (NSTimer*) timer
{
	[NSCursor setHiddenUntilMouseMoves: YES];	
	_cursorHideTimer = nil;
}

- (void) exitFullScreen: (id) sender
{
	if(![self isFullScreen])
		return;
	
	[_fullScreenWindow orderOut: nil];
	CGDisplayRelease(kCGDirectMainDisplay);

	[_displayLock lock];
	[_videoView removeFromSuperview]; 
	[self addSubview: _videoView];
	
	[_fullScreenWindow release];
	_fullScreenWindow = nil;

	[_videoView setFrame: [self contentFrame]];
	[_displayLock unlock];
	[self setNeedsDisplay: YES];

	[NSCursor setHiddenUntilMouseMoves: NO];
}

- (BOOL) isFullScreen
{
	return (_fullScreenWindow != nil);
}

- (void)keyDown: (NSEvent*) event
{
	// NSLog(@"Key: %i", [event keyCode]);
	if([event keyCode] == 36)
	{
		// Enter pressed
		xine_event_t event;
		
		event.type = XINE_EVENT_INPUT_SELECT;
		event.stream = _associatedStream;
		event.data = nil;
		event.data_length = 0;
		xine_event_send(_associatedStream,&event);
		
		return;
	} else if([event keyCode] == 53) {
		// Escape
		if([self isFullScreen]) {
			[self exitFullScreen: nil];
			return;
		}
	}
	
	[super keyDown: event];
}

- (BOOL) wantsDefaultClipping { return NO; }

- (BOOL) isFlipped { return YES; }

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize
{
	if(_videoView) {
		[_videoView setFrame: [self contentFrame]];
	}
	[super resizeSubviewsWithOldSize: oldBoundsSize];
}

- (void) setMenu: (NSMenu*) menu
{
	[_videoView setMenu: menu];
	[super setMenu: menu];
}

@end

@implementation XineVideoView (Internal)

-(void) resizeVideoView: (void*) data
{
	[_videoView setFrame: [self contentFrame]];
	[self setNeedsDisplay: YES];
}

- (void) displayFrame: (void*) pixmap size: (NSSize) frameSize aspectRatio: (float) ratio format: (int) format;
{
	_lastFrame = pixmap;
	
	if((format != _lastFormat) || (ratio != _aspectRatio) || (!NSEqualSizes(_videoSize, frameSize)))
	{
		if(!NSEqualSizes(_videoSize, frameSize)) 
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:XineVideoViewFrameSizeDidChangeNotification object:self];
		}
		
		_aspectRatio = ratio;
		_videoSize = frameSize;
		_lastFormat = format;
		
		[_displayLock lock];		
		if(_yuvDisplay && (!NSEqualSizes(_videoSize,((yuv_display_t*)_yuvDisplay)->movieSize) || (format != ((yuv_display_t*)_yuvDisplay)->format))) {
			/* Mostly because resizeYUVDisplay doesn't seem to work. */
			disposeYUVDisplay(_yuvDisplay);
			_yuvDisplay = NULL;
		}
		[_displayLock unlock];
		
		/* Do this on the main thread because we are resizing views. */
		[self performSelectorOnMainThread:@selector(resizeVideoView:) withObject:nil waitUntilDone:NO];
	} 
	
	if(_lastFrame) {
		if([self ensureDisplay] && [_videoView lockFocusIfCanDraw]) {
			displayImageOnView(_yuvDisplay, _lastFrame);
			[_videoView unlockFocus];
		}
	}
}

- (void) freedFrame: (void*) pixmap
{
	if(_lastFrame == pixmap)
		_lastFrame = NULL;
}

- (void*) videoPort
{
	if(!_videoView)
		return NULL;
	
	return [_videoView qdPort];
}

@end

@implementation XineVideoView (Private)

- (BOOL) ensureDisplay
{
	[_displayLock lock];
	
	if(!_videoView || ![_videoView qdPort]) {
		[_displayLock unlock];
		return NO;
	}
	
	if(!_yuvDisplay) {
		_yuvDisplay = createYUVDisplayOnView(_videoView, _videoSize, _lastFormat);
	}
	
	if(!_yuvDisplay) {
		[_displayLock unlock];
		return NO;
	}
	
	[_displayLock unlock];
	
	return YES;
}

@end
