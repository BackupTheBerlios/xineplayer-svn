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

#ifndef _YUV_OUTPUT_H
#define _YUV_OUTPUT_H

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>

#include "xine.h"
#include "xine/video_out.h"

struct yuv_display_s {
	NSQuickDrawView			*qdView;
	
	NSSize					 movieSize;
	NSRect					 yuv_frame;
	
	ImageDescriptionHandle	 idh;
	MatrixRecordPtr			 matrix;
	DecompressorComponent	 codec;
	ImageSequence			 seq;
	BOOL					 sequence_started;
	
	NSLock					*lock;
};

typedef struct yuv_display_s yuv_display_t;

yuv_display_t* createYUVDisplayOnView(NSQuickDrawView *targetView, NSSize size);
void disposeYUVDisplay(yuv_display_t *display);
void resizeYUVDisplay(yuv_display_t *display, NSSize newSize);
void displayYUVPixmapOnView(yuv_display_t *display, PlanarPixmapInfoYUV420* pixmap);

#endif /* _YUV_OUTPUT_H */
