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

@implementation XinePostProcessor

+ (XinePostProcessor*) postProcessorNamed: (NSString*) name forEngine: (XineEngine*) engine inputs: (int)inputs audioPorts: (NSArray*) audioPorts videoPorts: (NSArray*) videoPorts
{
	XinePostProcessor *post = [[XinePostProcessor alloc] autorelease];
	return [post initWithName: name forEngine: engine inputs:inputs audioPorts: audioPorts videoPorts: videoPorts];
}

- (id) initWithName: (NSString*) name forEngine: (XineEngine*) engine inputs: (int)inputs audioPorts: (NSArray*) audioPorts videoPorts: (NSArray*) videoPorts
{
	id mySelf = [self init];
	if(mySelf) {
		xine_audio_port_t **audio_ports = malloc(([audioPorts count]+1) * sizeof(xine_audio_port_t*));
		xine_video_port_t **video_ports = malloc(([videoPorts count]+1) * sizeof(xine_video_port_t*));
		NSEnumerator *objEnum;
		
		objEnum = [audioPorts objectEnumerator];
		XineAudioPort *aport;
		int i = 0;
		while(aport = [objEnum nextObject]) {
			audio_ports[i++] = [aport handle];
		}
		audio_ports[i] = NULL;
		objEnum = [videoPorts objectEnumerator];
		XineVideoPort *vport;
		i = 0;
		while(vport = [objEnum nextObject]) {
			video_ports[i++] = [vport handle];
		}
		video_ports[i] = NULL;
		
		_engine = [engine retain];
		_post_plugin = xine_post_init([_engine handle],[name cString],inputs,audio_ports,video_ports);
		NSLog(@"Post: %@, %x", name, _post_plugin);
		free(audio_ports);
		free(video_ports);
		
		if(!_post_plugin) { return nil; }
	}
	return mySelf;
}

- (void) dealloc
{
	xine_post_dispose([_engine handle],_post_plugin);
	if(_engine) 
		[_engine release];
	[super dealloc];
}

- (NSArray*) inputAudioPorts
{
	NSMutableArray *array = [NSMutableArray array];
	xine_audio_port_t **audio_input = _post_plugin->audio_input;
	while(*audio_input) {
		[array addObject: [[(XineAudioPort*)[XineAudioPort alloc] initWithHandle:*audio_input fromEngine:_engine] autorelease]];
		audio_input ++;
	}
	return array;
}

- (NSArray*) inputVideoPorts
{
	NSMutableArray *array = [NSMutableArray array];
	xine_video_port_t **video_input = _post_plugin->video_input;
	while(*video_input) {
		[array addObject: [[(XineVideoPort*)[XineVideoPort alloc] initWithHandle:*video_input fromEngine:_engine] autorelease]];
		video_input ++;
	}
	return array;
}

- (NSArray*) inputNames
{
	NSMutableArray *array = [NSMutableArray array];
	const char *const * inputs = xine_post_list_inputs(_post_plugin);
	while(*inputs) {
		[array addObject: [NSString stringWithCString:*inputs]];
		inputs++;
	}
	return array;
}

- (NSArray*) outputNames
{
	NSMutableArray *array = [NSMutableArray array];
	const char *const * outputs = xine_post_list_outputs(_post_plugin);
	while(*outputs) {
		[array addObject: [NSString stringWithCString:*outputs]];
		outputs++;
	}
	return array;
}

- (XinePostInputPort*) inputPortNamed: (NSString*) name
{
	xine_post_in_t *input = xine_post_input(_post_plugin, [name cString]);
	if(!input)
		return;
	
	return [[[XinePostInputPort alloc] initWithInput: input post:_post_plugin] autorelease];
}

- (XinePostOutputPort*) outputPortNamed: (NSString*) name
{
	xine_post_out_t *output = xine_post_output(_post_plugin, [name cString]);
	if(!output)
		return;
	
	return [[[XinePostOutputPort alloc] initWithOutput: output post:_post_plugin] autorelease];
}

+ (BOOL) wireOutput: (XinePostOutputPort*) output toInput: (XinePostInputPort*) input
{
	return xine_post_wire([output handle],[input handle]);
}

- (xine_post_t*) handle
{
	return _post_plugin;
}

@end

@implementation XinePostParameter

- (id) initWithParameter: (xine_post_api_parameter_t*) parameter
{
	id mySelf = [self init];
	if(mySelf) {
		_parameter = parameter;
	}
	return mySelf;
}

- (XinePostParameterType) type 
    { return _parameter->type; }
- (NSString*) name 
    { return [NSString stringWithCString: _parameter->name]; }

- (NSArray*) enumValues
{
	NSMutableArray *array = [NSMutableArray array];
	
	char **enum_values = _parameter->enum_values;
	while(*enum_values) {
		[array addObject: [NSString stringWithCString: *enum_values]];
		enum_values ++;
	}
	
	return array;
}

- (double) minimumValue
	{ return _parameter->range_min; }
- (double) maximumValue
	{ return _parameter->range_max; }
- (BOOL) isReadOnly
	{ return _parameter->readonly; }
- (NSString*) description
	{ return [NSString stringWithCString: _parameter->description]; }

- (void) setBytes: (void*) data length: (size_t) length
{
	if(length != _parameter->size) {
		NSLog(@"Size mis-match!");
		return;
	}
	
	void *dest = (void*)_parameter + _parameter->offset;
	xine_fast_memcpy(dest, data, length);
}

- (NSData*) dataValue
{
	return [NSData dataWithBytes: (void*)_parameter + _parameter->offset length: _parameter->size];
}

- (void) setIntValue: (uint32_t) value
{
	if([self type] != XinePostIntParameter) {
		NSLog(@"Parameter is not integer.");
		return;
	}
	[self setBytes:&value length:sizeof(uint32_t)];
}
- (uint32_t) intValue
{
	if([self type] != XinePostIntParameter) {
		NSLog(@"Parameter is not integer.");
		return 0;
	}	
	return *((uint32_t*)[[self dataValue] bytes]);
}
- (void) setDoubleValue: (double) value
{
	if([self type] != XinePostDoubleParameter) {
		NSLog(@"Parameter is not double.");
		return;
	}
	[self setBytes:&value length:sizeof(double)];
}
- (double) doubleValue
{
	if([self type] != XinePostDoubleParameter) {
		NSLog(@"Parameter is not double.");
		return 0.0;
	}	
	return *((double*)[[self dataValue] bytes]);
}
- (void) setCharValue: (unsigned char) value
{
	if([self type] != XinePostCharParameter) {
		NSLog(@"Parameter is not char.");
		return;
	}
	[self setBytes:&value length:sizeof(unsigned char)];
}
- (unsigned char) charValue
{
	if([self type] != XinePostCharParameter) {
		NSLog(@"Parameter is not char.");
		return 0;
	}	
	return *((unsigned char*)[[self dataValue] bytes]);
}
- (void) setStringValue: (NSString*) str
{
	if([self type] != XinePostStringParameter) {
		NSLog(@"Parameter is not string.");
		return;
	}
	[self setBytes:(void*)[str cString] length: [str length]+1];
}
- (NSString*) stringValue
{
	if([self type] != XinePostStringParameter) {
		NSLog(@"Parameter is not string.");
		return @"";
	}	
	return [NSString stringWithCString: (unsigned char*)[[self dataValue] bytes]];
}
- (void) setStringListValue: (NSArray*) list
{
}
- (NSArray*) stringListValue
{
}
- (void) setBooleanValue: (BOOL) value
{
	if([self type] != XinePostBoolParameter) {
		NSLog(@"Parameter is not bool.");
		return;
	}	
	[self setBytes:&value length:sizeof(uint32_t)];
}
- (BOOL) booleanValue
{
	if([self type] != XinePostBoolParameter) {
		NSLog(@"Parameter is not boot.");
		return NO;
	}	
	return *((uint32_t*)[[self dataValue] bytes]);
}

@end

@implementation XinePostOutputPort 
- (id) initWithOutput: (xine_post_out_t*) output post: (xine_post_t*) post
{
	id mySelf = [self init];
	if(mySelf) {
		_output = output;
		_post = post;
	}
	return mySelf;
}
- (NSString*) name 
	{ return [NSString stringWithCString: _output->name]; }
- (XinePostPortType) type
	{ return _output->type; }
- (xine_post_out_t*) handle
	{ return _output; }
@end

@implementation XinePostInputPort 
- (id) initWithInput: (xine_post_in_t*) input post: (xine_post_t*) post
{
	id mySelf = [self init];
	if(mySelf) {
		_input = input;
		_post = post;
	}
	return mySelf;
}
- (NSString*) name 
	{ return [NSString stringWithCString: _input->name]; }
- (XinePostPortType) type
	{ return _input->type; }
- (xine_post_in_t*) handle
	{ return _input; }
- (xine_post_api_t*) api
{
	if([self type] != XinePostParametersPort) {
		NSLog(@"Attempt to get parameters for non parameter input");
		return NULL;
	}
	
	return (xine_post_api_t*) _input->data;
}
- (NSArray*) parameters
{
	xine_post_api_t* api = [self api];
	if(!api)
		return nil;
	
	NSMutableArray *array = [NSMutableArray array];
	xine_post_api_descr_t *api_descr = api->get_param_descr();
	api->get_parameters(_post, api_descr);
	xine_post_api_parameter_t *params = api_descr->parameter;
	while(params->type != POST_PARAM_TYPE_LAST) {
		[array addObject: [[[[XinePostParameter alloc] autorelease] initWithParameter:params] autorelease]];
		params+=params->size;
	}
	return array;
}
- (XinePostParameter*) parameterNamed: (NSString*) name
{
}
@end

