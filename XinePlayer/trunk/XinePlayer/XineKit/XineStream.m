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
#import <xine.h>

NSString *XineStreamFrameFormatDidChangeNotification = @"XineStreamFrameFormatDidChangeNotification";
NSString *XineStreamPlaybackDidFinishNotification = @"XineStreamPlaybackDidFinishNotification";
NSString *XineStreamChannelsChangedNotification = @"XineStreamChannelsChangedNotification";

void event_listener_cb(void *user_data, const xine_event_t* event);

@implementation XineStream

- (bool) openMRL: (NSString*) mrl
{
	return xine_open(_stream,[mrl cString]);
}

- (void) play
{
	xine_play(_stream,0,0);
}

- (void) playFromPosition: (int) pos
{
	xine_play(_stream,pos,0);
}

- (void) playFromTime: (int) time
{
	xine_play(_stream,0,time);
}

- (void) stop
{
	xine_stop(_stream);
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
	xine_close(_stream);
}

- (bool) eject
{
	return xine_eject(_stream);
}

- (void) wireAudioToPort: (XineAudioPort*) port
{
	xine_post_wire_audio_port(xine_get_audio_source(_stream),[port handle]);
}

- (void) wireVideoToPort: (XineVideoPort*) port
{
	xine_post_wire_video_port(xine_get_video_source(_stream),[port handle]);
}

- (void) setValue: (int) value ofParameter: (int) param
{
	xine_set_param(_stream,param,value);
}

- (int) valueOfParameter: (int) param
{
	return xine_get_param(_stream,param);
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
	xine_trick_mode(_stream,XINE_TRICK_MODE_SEEK_TO_POSITION,position);
}

- (BOOL) hasPositionInformation
{
	int a,b,c;
	return xine_get_pos_length(_stream,&a,&b,&c);
}

- (int) getStreamInformationForKey: (int) key
{
	return xine_get_stream_info(_stream, key);
}

- (void) getPosition: (int*) position time: (int*) time length: (int*) length
{
	xine_get_pos_length(_stream,position,time,length);
}

+ (XineStream*) streamWithEngine: (XineEngine*) engine audioPort: (XineAudioPort*) ao videoPort: (XineVideoPort*) vo
{
	return [[[XineStream alloc] autorelease] initWithEngine:engine audioPort:ao videoPort:vo];
}	

- (id) initWithEngine: (XineEngine*) engine audioPort: (XineAudioPort*) ao videoPort: (XineVideoPort*) vo
{
	id mySelf = [super init];
	if(mySelf) 
	{
		_engine = [engine retain];
		_stream = xine_stream_new([_engine handle],[ao handle],[vo handle]);
		if(!_stream) { return nil; }
		_videoView = [[vo videoView] retain];
		[_videoView didAssociateWithStream: _stream];
		
		_eventLock = [[NSLock alloc] init];
		
		_queue = xine_event_new_queue(_stream);
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
		[_videoView didDisassociateWithStream: _stream];
		[_videoView release];
	}
	if(_stream) { xine_dispose(_stream); }
	if(_engine) 
		[_engine release];
	[super dealloc];
}

- (NSString*) getMetaInfoForKey: (int) key
{
	const char *cStr = xine_get_meta_info(_stream,key);
	
	if(!cStr) { return [NSString stringWithString:@""]; }
	
	return [NSString stringWithUTF8String: cStr];
}

- (void*) handle { return _stream; }
- (XineEngine*) engine { return _engine; }

/*
- (XinePostOutputPort*) videoSourceForPostProcessor: (XinePostProcessor*) post
{
	return [[[XinePostOutputPort alloc] initWithOutput: xine_get_video_source(_stream) post:[post handle]] autorelease];
}

- (XinePostOutputPort*) audioSourceForPostProcessor: (XinePostProcessor*) post
{
	return [[[XinePostOutputPort alloc] initWithOutput: xine_get_audio_source(_stream) post:[post handle]] autorelease];
}
*/

- (void) sendInputButtonEvent: (int) buttonEventType
{
	xine_event_t event;
	event.type = buttonEventType;
	event.data = 0;
	event.data_length = 0;
	event.stream = _stream;
	xine_event_send(_stream,&event);
}

- (BOOL) isPlaying
{
	if(!_stream)
		return NO;
	
	return (xine_get_status(_stream) == XINE_STATUS_PLAY);
}

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

