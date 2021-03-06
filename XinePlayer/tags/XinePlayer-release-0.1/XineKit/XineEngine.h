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

@interface XineEngine : NSObject {
	xine_t *xine;
}

+ (XineEngine*) defaultEngine;
- (xine_t*) handle;

@end

@interface XineEngine (Streams)

- (XineStream*) createStreamWithAudioPort: (XineAudioPort*) ao videoPort: (XineVideoPort*) vo;

@end

@interface XineEngine (Ports)

- (XineVideoPort*) createVideoPortFromVideoView: (XineVideoView*) view;
- (XineAudioPort*) createAudioPort;

@end

@interface XineEngine (Configuration)

- (void) loadConfiguration;
- (void) saveConfiguration;
- (void) resetConfiguration;

@end
