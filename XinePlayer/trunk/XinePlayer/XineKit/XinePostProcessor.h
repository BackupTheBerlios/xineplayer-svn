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
#import "XineEngine.h"

@interface XinePostProcessor : NSObject {
	void *_post;
	void *_api;
	void *_descr;
	void *_param;
	
	void *_param_data;
	char **_properties_names;
	
	NSString *_name;
	XineEngine *_engine;
}

+ (XinePostProcessor*) postProcessorNamed: (NSString*) name fromEngine: (XineEngine*) engine inputs: (int) inputs audioPorts: (NSArray*) audioPorts videoPorts: (NSArray*) videoPorts;
- (id) initWithName:  (NSString*) name fromEngine: (XineEngine*) engine inputs: (int) inputs audioPorts: (NSArray*) audioPorts videoPorts: (NSArray*) videoPorts;
- (void*) handle;
- (XinePostProcessorType) type;
- (NSArray*) audioInputs;
- (NSArray*) videoInputs;
- (NSString*) name;

- (NSArray*) propertyNames;
- (void) setValue: (id) value forProperty: (NSString*) name;
- (NSString*) descriptionForProperty: (NSString*) name;
- (NSArray*) enumeratedValuesForProperty: (NSString*) name;
- (BOOL) isEnumeratedParameter: (NSString*) name;
- (BOOL) isReadOnlyParameter: (NSString*) name;
- (id) valueForProperty: (NSString*) name;

@end
