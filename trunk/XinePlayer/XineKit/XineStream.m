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

NSString *XineStreamFrameFormatDidChangeNotification = @"XineStreamFrameFormatDidChangeNotification";
NSString *XineStreamPlaybackDidFinishNotification = @"XineStreamPlaybackDidFinishNotification";
NSString *XineStreamChannelsChangedNotification = @"XineStreamChannelsChangedNotification";

void event_listener_cb(void *user_data, const xine_event_t* event);

@implementation XineStream

- (bool) openMRL: (NSString*) mrl
{
	return xine_open(stream,[mrl cString]);
}

- (void) play
{
	xine_play(stream,0,0);
}

- (void) playFromPosition: (int) pos
{
	xine_play(stream,pos,0);
}

- (void) playFromTime: (int) time
{
	xine_play(stream,0,time);
}

- (void) stop
{
	xine_stop(stream);
}

- (void) stop: (BOOL) waitUntilDone
{
	[self stop];
	if(!waitUntilDone) 
		return;
	while([self isPlaying]) {
		xine_usec_sleep(50000);
	}
}

- (void) close
{
	xine_close(stream);
}

- (bool) eject
{
	return xine_eject(stream);
}

- (void) setValue: (int) value ofParameter: (int) param
{
	xine_set_param(stream,param,value);
}

- (int) valueOfParameter: (int) param
{
	return xine_get_param(stream,param);
}

- (XineSpeed) speed
{
	return [self valueOfParameter: XINE_PARAM_SPEED];
}

- (void) setSpeed: (XineSpeed) speed
{
	[self setValue: speed ofParameter: XINE_PARAM_SPEED];
}

- (void) seekToPosition: (int) position
{
	xine_trick_mode(stream,XINE_TRICK_MODE_SEEK_TO_POSITION,position);
}

- (BOOL) hasPositionInformation
{
	int a,b,c;
	return xine_get_pos_length(stream,&a,&b,&c);
}

- (int) getStreamInformationForKey: (int) key
{
	return xine_get_stream_info(stream, key);
}

- (void) getPosition: (int*) position time: (int*) time length: (int*) length
{
	xine_get_pos_length(stream,position,time,length);
}

- (id) initWithEngine: (xine_t*) engine audioPort: (XineAudioPort*) ao videoPort: (XineVideoPort*) vo
{
	id mySelf = [super init];
	if(mySelf) 
	{
		xine = engine;
		stream = xine_stream_new(xine,[ao port],[vo port]);
		if(!stream) { return nil; }
		_videoView = [[vo videoView] retain];
		// [[_videoView openGLView] setDelegate: self];
		[_videoView didAssociateWithStream: stream];
		
		_eventLock = [[NSLock alloc] init];
		
		_queue = xine_event_new_queue(stream);
		xine_event_create_listener_thread(_queue,event_listener_cb,self);
	}
	return mySelf;
}

- (void) dealloc
{
	if(_queue)
		xine_event_dispose_queue(_queue);
	if(_eventLock)
		[_eventLock release];
	if(_videoView)
	{
		// [[_videoView openGLView] setDelegate: nil];
		[_videoView didDisassociateWithStream: stream];
		[_videoView release];
	}
	if(stream) { xine_dispose(stream); }
	[super dealloc];
}

- (NSString*) getMetaInfoForKey: (int) key
{
	const char *cStr = xine_get_meta_info(stream,key);
	
	if(!cStr) { return [NSString stringWithString:@""]; }
	
	return [NSString stringWithUTF8String: cStr];
}

- (xine_stream_t*) stream { return stream; }
- (xine_t*) engine { return xine; }

- (void) sendInputButtonEvent: (int) buttonEventType
{
	xine_event_t event;
	event.type = buttonEventType;
	event.data = 0;
	event.data_length = 0;
	event.stream = stream;
	xine_event_send(stream,&event);
}

- (BOOL) isPlaying
{
	if(!stream)
		return NO;
	
	return (xine_get_status(stream) == XINE_STATUS_PLAY);
}

@end

@implementation XineStream (XineOpenGLViewDelegate)
/*
- (NSPoint) convertPoint: (NSPoint) point fromOpenGLView: (XineOpenGLView*) oglView
{
	NSSize videoSize = [oglView videoSize];
	NSSize rectSize = [oglView bounds].size;
	NSPoint location = [oglView convertPoint: point fromView: nil];
	
	return NSMakePoint((location.x * videoSize.width) / rectSize.width, videoSize.height - ((location.y * videoSize.height) / rectSize.height));
}
*/

- (void) processEvent: (id) sender;
{
	if(!_currentEvent)
		return;
	
	xine_event_t *event = _currentEvent;
	// NSLog(@"Event: %i", event->type);
	
	switch(event->type) 
	{
		case XINE_EVENT_FRAME_FORMAT_CHANGE:
		{
			xine_format_change_data_t *format_data = event->data;

			[[NSNotificationCenter defaultCenter] postNotificationName:XineStreamFrameFormatDidChangeNotification object:self];
		}
			break;
		case XINE_EVENT_UI_PLAYBACK_FINISHED:
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:XineStreamPlaybackDidFinishNotification object:self];		
			break;
		}
	}
}

- (void) setCurrentEvent: (const xine_event_t*) event
{
	[_eventLock lock];
	_currentEvent = (xine_event_t*) event;
}

- (void) unsetCurrentEvent
{
	_currentEvent = nil;
	[_eventLock unlock];
}

void event_listener_cb(void *user_data, const xine_event_t* event)
{
	XineStream *stream = (XineStream*) user_data;
	
	// Only respond to certain events so that we don't waste time synchronising.
	if(event->type != XINE_EVENT_QUIT)
	{
		[stream setCurrentEvent: event];
		[stream performSelectorOnMainThread:@selector(processEvent:) withObject:nil waitUntilDone:YES];
		[stream unsetCurrentEvent];
	}
}

@end

