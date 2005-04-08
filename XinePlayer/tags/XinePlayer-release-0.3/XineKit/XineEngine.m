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
#import <stdlib.h>
#import <xine.h>

@interface XineEngine (Private)

- (NSString*) configFile;

@end

@implementation XineEngine (Streams)

- (XineStream*) createStreamWithAudioPort: (XineAudioPort*) ao videoPort: (XineVideoPort*) vo
{
	return [XineStream streamWithEngine:self audioPort:ao videoPort:vo];
}

@end

@implementation XineEngine (Ports)

- (XineVideoPort*) createVideoPortFromVideoView: (XineVideoView*) view
{
	return [XineVideoPort videoPortForDriver:@"cocoa" fromEngine:self forView:view];
}

- (XineAudioPort*) createAudioPort
{
	return [XineAudioPort audioPortForDriver:@"coreaudio" fromEngine:self userData:nil];
}

@end

static XineEngine *_defaultEngine = nil;

@implementation XineEngine 

+ (XineEngine*) defaultEngine
{
	if(!_defaultEngine) 
	{
		return [[[XineEngine alloc] init] autorelease];
	}
	
	return _defaultEngine;
}

- (void*) handle
{
	return xine;
}

- (id) init 
{
	id mySelf = [super init];
	
	if(mySelf)
	{
		// Locate the plugins directory
		NSBundle *bundle = [NSBundle bundleForClass: [self class]];
		NSString *pluginPath = [NSString stringWithFormat: @"%@:%@",
			[NSString pathWithComponents:
				[NSArray arrayWithObjects:
					[bundle builtInPlugInsPath], @"XinePlugins", nil]],
			[NSString pathWithComponents:
				[NSArray arrayWithObjects:
					NSHomeDirectory(), @"Library",
					@"XinePlugins", nil]]
		];
		
		/* NSLog(@"Plugin path: %@", pluginPath); */
		setenv("XINE_PLUGIN_PATH", [pluginPath cString], 1);
		setenv("DYLD_LIBRARY_PATH", [pluginPath cString], 1);
		
		xine = xine_new();
		[self loadConfiguration];
		xine_init(xine);
		
                if(getenv("XINEPLAYER_ENGINE_LOG")) 
                {
                  int section = xine_get_log_section_count(xine) - 1;
                  while(section >= 0) {
                    const char * const * message_list = xine_get_log(xine, section);
                    const char *section_name = xine_get_log_names(xine)[section];
                    
                    while(*message_list && strlen(*message_list)) {
                      NSLog(@"%s: %s", section_name, *message_list);
                      message_list ++;
                    }
                    
                    section --;
                  }
                }
	}

	if(!_defaultEngine)
		_defaultEngine = mySelf;
	
	return mySelf;
}

- (void) dealloc
{
	NSLog(@"Engine shutdown");
	
	[self saveConfiguration];
	
	if(xine)
	{
		xine_exit(xine);
	}
	
	if(self == _defaultEngine)
	{
		_defaultEngine = nil;
	}
	
	[super dealloc];
}

@end

@implementation XineEngine (Private)

- (NSString*) configFile
{
	NSBundle *appBundle = [NSBundle mainBundle];
	
	NSArray *prefsFile = [NSArray arrayWithObjects:
		NSHomeDirectory(),
		@"Library", @"Preferences",
		[NSString stringWithFormat: @"%@.xine.config",
			[appBundle bundleIdentifier]
			],
		nil
		];
	/* NSLog(@"Config file: %@", [NSString pathWithComponents: prefsFile]); */
	return [NSString pathWithComponents: prefsFile];
}

@end

@implementation XineEngine (PostProcessors)

- (NSArray*) postProcessorNames
{
	NSMutableArray *array = [NSMutableArray array];
	const char * const * plugin_list = xine_list_post_plugins([self handle]);
	while(*plugin_list) {
		[array addObject: [NSString stringWithCString: *plugin_list]];
		plugin_list ++;
	}
	
	return array;
}

- (NSArray*) postProcessorNamesForType: (XinePostProcessorType) type
{
	NSMutableArray *array = [NSMutableArray array];
	const char * const * plugin_list = xine_list_post_plugins_typed([self handle], type);
	while(*plugin_list) {
		[array addObject: [NSString stringWithCString: *plugin_list]];
		plugin_list ++;
	}
	
	return array;
}

@end

@implementation XineEngine (Configuration)

- (void) saveConfiguration
{
	xine_config_save(xine, [[self configFile] cString]);
}

- (void) loadConfiguration
{
	xine_config_load(xine, [[self configFile] cString]);
}

- (void) resetConfiguration
{
	xine_config_reset(xine);
}

- (id) configurationEntryForKey: (NSString*) key
{
	xine_cfg_entry_t entry;
	
	/* NSLog(@"Looking for '%@'", key); */
	
	if(!xine_config_lookup_entry(xine,[key cString],&entry))
		return nil;
	
	/* NSLog(@"Found '%@'", key); */
	
	switch(entry.type) {
		case XINE_CONFIG_TYPE_RANGE:
		case XINE_CONFIG_TYPE_NUM:
		case XINE_CONFIG_TYPE_BOOL:
			return [NSNumber numberWithInt:entry.num_value];
			break;
		case XINE_CONFIG_TYPE_ENUM:
			return [NSString stringWithCString:entry.enum_values[entry.num_value]];
		case XINE_CONFIG_TYPE_STRING:
			return [NSString stringWithCString:entry.str_value];
		default:
			NSLog(@"Unknown xine entry type: %i", entry.type);
			break;
	}
	
	return nil;
}

- (void) setConfigurationEntry: (id) value forKey: (NSString*) key
{
	xine_cfg_entry_t entry;
	if(!xine_config_lookup_entry(xine,[key cString],&entry))
	{
		NSLog(@"Attempt to set unknown confguration key %@", key);
		return;
	}
	
	switch(entry.type)
	{
		case XINE_CONFIG_TYPE_RANGE:
			if(([value intValue] > entry.range_max) || ([value intValue] < entry.range_min))
			{
				NSLog(@"Attempt to set %@ to out of range value %@.", key,value);
				return;
			}
		case XINE_CONFIG_TYPE_NUM:
			entry.num_value = [value intValue];
			break;
		case XINE_CONFIG_TYPE_BOOL:
			entry.num_value = [value boolValue];
		case XINE_CONFIG_TYPE_STRING:
			entry.str_value = (char*)[[value stringValue] cString];
			break;
		case XINE_CONFIG_TYPE_ENUM:
		{
			int i=0;
			BOOL managedIt = NO;
			char **enum_values = entry.enum_values;
			while(*enum_values)
			{
				if([[value stringValue] isEqualToString: [NSString stringWithCString:*enum_values]])
				{
					entry.num_value = i;
					managedIt = YES;
				}
				enum_values++; i++;
			}
			if(!managedIt)
			{
				NSLog(@"Attempted to set enum value '%@' to invalud value '%@'.", key, value);
			}
		}
			break;
		default:
			NSLog(@"Unknown xine entry type: %i", entry.type);
			break;
	}
	
	xine_config_update_entry(xine,&entry);
}

@end
