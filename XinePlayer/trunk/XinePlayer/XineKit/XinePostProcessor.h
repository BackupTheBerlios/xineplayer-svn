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
#import "xine.h"

@class XinePostParameter;

typedef enum {
	XinePostVideoPort = XINE_POST_DATA_VIDEO,
	XinePostAudioPort = XINE_POST_DATA_AUDIO,
	XinePostIntPort = XINE_POST_DATA_INT,
	XinePostDoublePort = XINE_POST_DATA_DOUBLE,
	XinePostParametersPort = XINE_POST_DATA_PARAMETERS,
} XinePostPortType;

@protocol XinePostPort 
- (NSString*) name;
- (XinePostPortType) type;
@end

@interface XinePostInputPort : NSObject <XinePostPort> {
	xine_post_in_t *_input;
	xine_post_t *_post;
}
- (id) initWithInput: (xine_post_in_t*) input post: (xine_post_t*) post;
- (NSArray*) parameters;
- (XinePostParameter*) parameterNamed: (NSString*) name;
- (xine_post_in_t*) handle;
@end

@interface XinePostOutputPort : NSObject <XinePostPort> {
	xine_post_out_t *_output;
	xine_post_t *_post;
}
- (id) initWithOutput: (xine_post_out_t*) output post: (xine_post_t*) post;
- (xine_post_out_t*) handle;
@end

typedef enum {
	XinePostLastParameter = POST_PARAM_TYPE_LAST,
	XinePostIntParameter = POST_PARAM_TYPE_INT,
	XinePostDoubleParameter = POST_PARAM_TYPE_DOUBLE,
	XinePostCharParameter = POST_PARAM_TYPE_CHAR,
	XinePostStringParameter = POST_PARAM_TYPE_STRING,
	XinePostStringListParameter = POST_PARAM_TYPE_STRINGLIST,
	XinePostBoolParameter = POST_PARAM_TYPE_BOOL,
} XinePostParameterType;

@interface XinePostParameter : NSObject {
	xine_post_api_parameter_t *_parameter;
}

- (id) initWithParameter: (xine_post_api_parameter_t*) parameter;

- (XinePostParameterType) type;
- (NSString*) name;
- (NSArray*) enumValues;
- (double) minimumValue;
- (double) maximumValue;
- (BOOL) isReadOnly;
- (NSString*) description;

- (void) setBytes: (void*) data length: (size_t) length;
- (NSData*) dataValue;

- (void) setIntValue: (uint32_t) value;
- (uint32_t) intValue;
- (void) setDoubleValue: (double) value;
- (double) doubleValue;
- (void) setCharValue: (unsigned char) value;
- (unsigned char) charValue;
- (void) setStringValue: (NSString*) string;
- (NSString*) stringValue;
- (void) setStringListValue: (NSArray*) list;
- (NSArray*) stringListValue;
- (void) setBooleanValue: (BOOL) value;
- (BOOL) booleanValue;

@end

@interface XinePostProcessor : NSObject {
	xine_post_t *_post_plugin;
	XineEngine *_engine;
}

+ (XinePostProcessor*) postProcessorNamed: (NSString*) name forEngine: (XineEngine*) engine inputs: (int)inputs audioPorts: (NSArray*) audioPorts videoPorts: (NSArray*) videoPorts;
- (id) initWithName: (NSString*) name forEngine: (XineEngine*) engine inputs: (int)inputs audioPorts: (NSArray*) audioPorts videoPorts: (NSArray*) videoPorts;
- (NSArray*) inputAudioPorts;
- (NSArray*) inputVideoPorts;
- (NSArray*) inputNames;
- (NSArray*) outputNames;
- (XinePostInputPort*) inputPortNamed: (NSString*) name;
- (XinePostOutputPort*) outputPortNamed: (NSString*) name;
- (xine_post_t*) handle;
+ (BOOL) wireOutput: (XinePostOutputPort*) output toInput: (XinePostInputPort*) input;

@end
