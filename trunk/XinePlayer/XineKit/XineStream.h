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

extern NSString *XineStreamFrameFormatDidChangeNotification;
extern NSString *XineStreamPlaybackDidFinishNotification;
extern NSString *XineStreamChannelsChangedNotification;

typedef enum {
	XinePause = 0,
	XineQuarterSpeed = 1,
	XineHalfSpeed = 2,
	XineNormalSpeed = 4,
	XineDoubleSpeed = 8,
	XineQuadrupleSpeed = 16
} XineSpeed;

@interface XineStream : NSObject {
	xine_stream_t *stream;
	xine_t *xine;
	XineVideoView *_videoView;
	
	xine_event_queue_t *_queue;
	xine_event_t *_currentEvent;	
	NSLock *_eventLock;
}

- (id) initWithEngine: (xine_t*) engine audioPort: (XineAudioPort*) ao videoPort: (XineVideoPort*) vo;
- (xine_stream_t*) stream;
- (xine_t*) engine;

- (bool) openMRL: (NSString*) mrl;
- (void) play;
- (void) playFromPosition: (int) pos;
- (void) playFromTime: (int) time;
- (void) stop;
- (void) stop: (BOOL) waitUntilDone;
- (void) close;
- (bool) eject;

- (void) seekToPosition: (int) position;

- (void) setValue: (int) value ofParameter: (int) param;
- (int) valueOfParameter: (int) param;

- (int) getStreamInformationForKey: (int) key;

- (void) sendInputButtonEvent: (int) buttonEventType;

- (XineSpeed) speed;
- (void) setSpeed: (XineSpeed) speed;

- (BOOL) hasPositionInformation;
- (void) getPosition: (int*) position time: (int*) time length: (int*) length;

- (NSString*) getMetaInfoForKey: (int) key;

- (BOOL) isPlaying;

@end
