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

#import "XineKit.h"
#import "xine.h"

@implementation XinePostProcessor

+ (XinePostProcessor*) postProcessorNamed: (NSString*) name fromEngine: (XineEngine*) engine inputs: (int) inputs audioPorts: (NSArray*) audioPorts videoPorts: (NSArray*) videoPorts
{
	return [[[XinePostProcessor alloc] autorelease] initWithName: name fromEngine: engine inputs: inputs audioPorts: audioPorts videoPorts: videoPorts];
}

- (id) initWithName:  (NSString*) name fromEngine: (XineEngine*) engine inputs: (int) inputs audioPorts: (NSArray*) audioPorts videoPorts: (NSArray*) videoPorts
{
	id mySelf = [self init];
	if(mySelf) {
		_engine = [engine retain];
		xine_audio_port_t **audio_targets = malloc(([audioPorts count] + 1) * sizeof(xine_audio_port_t*));
		xine_video_port_t **video_targets = malloc(([videoPorts count] + 1) * sizeof(xine_video_port_t*));
		
		int i; NSEnumerator *objEnum;
		i = 0; objEnum = [audioPorts objectEnumerator];
		XineAudioPort *aport;
		while(aport = [objEnum nextObject]) {
			audio_targets[i++] = [aport handle];
		}
		audio_targets[i] = NULL;
		i = 0; objEnum = [videoPorts objectEnumerator];
		XineVideoPort *vport;
		while(vport = [objEnum nextObject]) {
			video_targets[i++] = [vport handle];
		}
		video_targets[i] = NULL;
		
		_post = xine_post_init([_engine handle], [name cString], inputs, audio_targets, video_targets);
		
		free(audio_targets);
		free(video_targets);
		
		if(!_post) {
			[_engine release];
			_engine = nil;
			return nil;
		}
	}
	return mySelf;
}

- (void) dealloc
{
	if(_post)
		xine_post_dispose([_engine handle], _post);
	if(_engine)
		[_engine release];
	[super dealloc];
}

- (void*) handle
{
	return _post;
}

- (XinePostProcessorType) type
{
	return ((xine_post_t*)_post)->type;
}

- (NSArray*) audioInputs
{
	NSMutableArray *array = [NSMutableArray array];
	xine_audio_port_t **audio_input = ((xine_post_t*)_post)->audio_input;
	while(*audio_input) {
		[array addObject: [(XineAudioPort*) [[XineAudioPort alloc] autorelease] initWithHandle: *audio_input fromEngine: _engine]];
		audio_input++;
	}
	return array;
}

- (NSArray*) videoInputs
{
	NSMutableArray *array = [NSMutableArray array];
	xine_video_port_t **video_input = ((xine_post_t*)_post)->video_input;
	while(*video_input) {
		[array addObject: [(XineVideoPort*) [[XineVideoPort alloc] autorelease] initWithHandle: *video_input fromEngine: _engine]];
		video_input++;
	}
	return array;
}

@end

