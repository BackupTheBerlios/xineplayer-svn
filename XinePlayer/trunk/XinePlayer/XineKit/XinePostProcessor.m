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
		_name = [[NSString stringWithString:name] retain];
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
		
		_api = _descr = _param = NULL;
		_param_data = _properties_names = NULL;
		
		/*
		 * Now attempt to retrieve information on all the parameters.
		 * This is shamelessly 'borrowed' from xine-ui :) .
		 */
		xine_post_in_t *param_input = xine_post_input(_post, "parameters");
		if(param_input)
		{
			xine_post_api_t            *post_api;
			xine_post_api_descr_t      *api_descr;
			xine_post_api_parameter_t  *parm;
			int                         pnum = 0;
			
			post_api = (xine_post_api_t *) param_input->data;
			
			api_descr = post_api->get_param_descr();
			
			parm = api_descr->parameter;
			_param_data = malloc(api_descr->struct_size);
			post_api->get_parameters(_post, _param_data);
			
			while(parm->type != POST_PARAM_TYPE_LAST) {
				
				_properties_names = (char **) realloc(_properties_names, sizeof(char *) * (pnum + 2));
				
				_properties_names[pnum]     = strdup(parm->name);
				_properties_names[pnum + 1] = NULL;
				pnum++;
				parm++;
			}
			
			_api      = post_api;
			_descr    = api_descr;
			_param    = api_descr->parameter;
		}
	}
	return mySelf;
}

- (void) dealloc
{
	if(_name)
		[_name release];
	if(_param_data)
		free(_param_data);
	if(_properties_names)
		free(_properties_names);
	if(_post)
		xine_post_dispose([_engine handle], _post);
	if(_engine)
		[_engine release];
	[super dealloc];
}

- (NSString*) name
{
	return _name;
}

- (NSArray*) propertyNames;
{
	if(!_properties_names)
		return [NSArray array];
	
	NSMutableArray *array = [NSMutableArray array];
	char **names = _properties_names;
	while(*names) {
		[array addObject: [NSString stringWithCString:*names]];
		names++;
	}
	return array;
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

- (xine_post_api_parameter_t*) propertyNamed: (NSString*) name
{
	NSArray *propertyNames = [self propertyNames];
	if(![propertyNames containsObject: name])
		return NULL;
	
	int paramNum = [propertyNames indexOfObject: name];
	xine_post_api_parameter_t *param = ((xine_post_api_descr_t*)_descr)->parameter;
	param += paramNum;
	return param;
}

- (void) setValue: (id) value forProperty: (NSString*) name
{
	xine_post_api_parameter_t *param = [self propertyNamed: name];
	if(!param)
		return;
	void *data = _param_data + param->offset;
	
	if([self isReadOnlyParameter: name])
		return;
	
	// NSLog(@"Parameter %@ is type %i", name, param->type);
	
	switch(param->type) 
	{
		case POST_PARAM_TYPE_INT:
			if([self isEnumeratedParameter: name])
			{
				NSString *strVal = nil;
				if([value respondsToSelector: @selector(stringValue)]) 
				{
					strVal = [value stringValue];
				} else if([value isKindOfClass: [NSString class]])
				{
					strVal = value;
				}
				
				if(strVal)
				{
					int index = 0;
					BOOL managedIt = NO;
					NSArray *enumValues = [self enumeratedValuesForProperty: name];
					while(index < [enumValues count])
					{
						if([strVal isEqualToString: [enumValues objectAtIndex: index]])
						{
							*((int*)data) = index;
							managedIt = YES;
						}
						index++;
					}
				} else if([value respondsToSelector: @selector(intValue)])
				{
					*((int*)data) = [value intValue]; 
				} 
			} else if([value respondsToSelector: @selector(intValue)])
			{
				*((int*)data) = [value intValue]; 
			} else {
				NSLog(@"Attempt to set int parameter with invalid value.");
			}
			break;
		case POST_PARAM_TYPE_DOUBLE:
			if([value respondsToSelector: @selector(doubleValue)])
			{
				*((double*)data) = [value doubleValue]; 
			} else {
				NSLog(@"Attempt to set double parameter with invalid value.");
			}
			break;
		case POST_PARAM_TYPE_CHAR:
		{
			NSString *strVal = nil;
			if([value respondsToSelector: @selector(stringValue)])
			{
				strVal = [value stringValue];
			} else if([value isKindOfClass: [NSString string]])
			{
				strVal = value;
			}
			if(!strVal)
			{
				if([value respondsToSelector: @selector(charValue)]) {
					snprintf((char*)data, param->size / sizeof(char), "%c", [value charValue]);
				} else {
					NSLog(@"Attempt to set string/char parameter with invalid value.");
				}
			} else {
				snprintf((char*)data, param->size / sizeof(char), "%s", strVal);
			}
			break;
		}
		case POST_PARAM_TYPE_STRING:
			NSLog(@"Setting string value not yet supported.");
			break;
		case POST_PARAM_TYPE_STRINGLIST:
			NSLog(@"Setting string list values not yet supported.");
			break;
		case POST_PARAM_TYPE_BOOL:
			if([value respondsToSelector: @selector(boolValue)])
			{
				*((BOOL*)data) = [value boolValue]; 
			} else {
				NSLog(@"Attempt to set boolean parameter with invalid value.");
			}
			break;
		default:
			NSLog(@"Setting unknown type '%i' of param '%@'", param->type, name);
			break;
	}
	
	xine_post_api_t *api = (xine_post_api_t*) _api;
	api->set_parameters(_post, _param_data);
	api->get_parameters(_post, _param_data);
}

- (NSString*) descriptionForProperty: (NSString*) name
{
	xine_post_api_parameter_t *param = [self propertyNamed: name];
	if(!param)
		return nil;
	return [NSString stringWithCString: param->description];
}

- (NSArray*) enumeratedValuesForProperty: (NSString*) name
{
	xine_post_api_parameter_t *param = [self propertyNamed: name];
	if(!param)
		return nil;
	char **values = param->enum_values;
	NSMutableArray *array = [NSMutableArray array];
	while(*values) {
		[array addObject: [NSString stringWithCString: *values]];
		values ++;
	}
	return array;
}

- (BOOL) isEnumeratedParameter: (NSString*) name
{
	xine_post_api_parameter_t *param = [self propertyNamed: name];
	if(!param)
		return YES;
	return (param->enum_values != NULL);
}

- (BOOL) isReadOnlyParameter: (NSString*) name
{
	xine_post_api_parameter_t *param = [self propertyNamed: name];
	if(!param)
		return YES;
	return param->readonly;
}

- (id) valueForProperty: (NSString*) name
{
	xine_post_api_parameter_t *param = [self propertyNamed: name];
	if(!param)
		return nil;
	void *data = _param_data + param->offset;
	
	switch(param->type) 
	{
		case POST_PARAM_TYPE_INT:
			if([self isEnumeratedParameter: name])
				return [[self enumeratedValuesForProperty: name] objectAtIndex: *((int*)data)];
			return [NSNumber numberWithInt: *((int*)data)];
			break;
		case POST_PARAM_TYPE_DOUBLE:
			return [NSNumber numberWithDouble: *((double*)data)];
			break;
		case POST_PARAM_TYPE_CHAR:
			if(param->size > sizeof(char)) 
				return [NSString stringWithCString: data];
			return [NSNumber numberWithChar: *((char*)data)];
			break;
		case POST_PARAM_TYPE_STRING:
			return [NSString stringWithCString: data];
			break;
		case POST_PARAM_TYPE_STRINGLIST:
		{
			char **list = (char**)data;
			NSMutableArray *array = [NSMutableArray array];
			while(*list) 
			{
				[array addObject: [NSString stringWithCString:*list]];
				list++;
			}
			return array;
		}
			break;
		case POST_PARAM_TYPE_BOOL:
			return [NSNumber numberWithBool: *((BOOL*)data)];
			break;
		default:
			NSLog(@"Unknown type '%i' of param '%@'", param->type, name);
			break;
	}
	
	return nil;
}

@end

