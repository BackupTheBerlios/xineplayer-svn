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
		_defaultEngine = [[[XineEngine alloc] init] autorelease];
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
		
		NSLog(@"Plugin path: %@", pluginPath);
		setenv("XINE_PLUGIN_PATH", [pluginPath cString], 1);
		setenv("DYLD_LIBRARY_PATH", [pluginPath cString], 1);
		
		xine = xine_new();
		[self loadConfiguration];
		xine_init(xine);
		
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
	
	return mySelf;
}

- (void) dealloc
{
	NSLog(@"Engine shutdown");
	
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

@end