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

#include "QuartzYUVOutput.h"
#include "xine/xineutils.h"

yuv_display_t* createYUVDisplayOnView(NSQuickDrawView *targetView, NSSize size)
{
	OSStatus err;
	UInt32 codec;
	
	int width = size.width;
	int height = size.height;
	
	/* NSLog(@"createYUVDisplay: %i,%i", width, height); */
	
	yuv_display_t *display = (yuv_display_t*) malloc(sizeof(yuv_display_t));
	
	if(!display) {
		NSLog(@"Error creating display.");
		return NULL;
	}
	
	codec = kYUV420CodecType;
	display->idh = (ImageDescriptionHandle) NewHandleClear(sizeof(ImageDescription));
	display->matrix = (MatrixRecordPtr) malloc(sizeof(MatrixRecord));
	
	if(EnterMovies() != noErr) {
		NSLog(@"Bugger... QuickTime wouldn't init.");
		free(display);
		return NULL;
	}
	
	err = FindCodec(codec, bestSpeedCodec, nil, &(display->codec));
	if(err != noErr) {
		NSLog(@"Could not find a suitable YUV codec!");
		free(display);
		return NULL;
	}
	
	SetIdentityMatrix(display->matrix);
	
	display->movieSize = NSMakeSize(width, height);
	
	display->yuv_frame = NSMakeRect(0,0,width,height);
	HLock((Handle)display->idh);
	
	(**(display->idh)).idSize = sizeof(ImageDescription);
	(**(display->idh)).cType = codec;
	(**(display->idh)).version = 1;
	(**(display->idh)).revisionLevel = 0;
	(**(display->idh)).width = width;
	(**(display->idh)).height = height;
	(**(display->idh)).hRes = Long2Fix(72);
	(**(display->idh)).vRes = Long2Fix(72);
	(**(display->idh)).spatialQuality = codecLosslessQuality;
	(**(display->idh)).frameCount = 1;
	(**(display->idh)).clutID = -1;
	(**(display->idh)).dataSize = 0;
	(**(display->idh)).depth = 24;
	
	HUnlock((Handle)display->idh);
	
	display->sequence_started = NO;
	
	display->qdView = [targetView retain];
	
	display->lock = [[NSLock alloc] init];
	
	return display;
}

void resizeYUVDisplay(yuv_display_t *display, NSSize newSize)
{
	if(!display)
		return;
	
	HLock((Handle)display->idh);
	
	(**(display->idh)).width = newSize.width;
	(**(display->idh)).height = newSize.height;

	display->movieSize = newSize;
	
	HUnlock((Handle)display->idh);
}

void disposeYUVDisplay(yuv_display_t *display)
{
	/* NSLog(@"dispose display"); */
	
	if(!display)
		return;
	
	if(display->lock)
		[display->lock release];
	
	CDSequenceEnd(display->seq);
	ExitMovies();
	
	free(display->matrix);
	DisposeHandle((Handle) display->idh);
	
	if(display->qdView)
		[display->qdView release];
	
	free(display);
}

void displayYUVPixmapOnView(yuv_display_t *display, PlanarPixmapInfoYUV420 *pixmap)
{
	if(!display)
		return;
	
	if(!pixmap) {
		NSLog(@"Passed a NULL pixmap.");
		return;
	}
	
	[display->lock lock];
	
	if(![display->qdView qdPort])
		return;
	
	OSErr err;
	CodecFlags flags = 0;
	
	if(!display->sequence_started) 
	{
		if(![display->qdView qdPort])
			return;
		
		/* NSLog(@"qdPort: %i", [display->qdView qdPort]); */
		err = DecompressSequenceBeginS(&(display->seq), display->idh, NULL, 0, [display->qdView qdPort], NULL, NULL, display->matrix, 0, NULL, codecFlagUseImageBuffer, codecLosslessQuality, display->codec);
	
		if(err != noErr) {
			NSLog(@"Error trying to start the YUV codec.");
			return;
		}
		display->sequence_started = YES;
	}
	
	NSRect contentFrame = [display->qdView bounds];
	
	if(!NSEqualRects(display->yuv_frame, contentFrame))
	{
		Fixed scale_x, scale_y;
		
		scale_x = FixDiv( FloatToFixed(contentFrame.size.width), Long2Fix(display->movieSize.width) );
		scale_y = FixDiv( FloatToFixed(contentFrame.size.height), Long2Fix(display->movieSize.height) );
		SetIdentityMatrix(display->matrix);
		ScaleMatrix(display->matrix, scale_x, scale_y, Long2Fix(0), Long2Fix(0));
		TranslateMatrix(display->matrix, FloatToFixed(contentFrame.origin.x), FloatToFixed(contentFrame.origin.y));
		SetDSequenceMatrix(display->seq, display->matrix);
		
		display->yuv_frame = contentFrame;
	}
	
	if([display->qdView lockFocusIfCanDraw]) {
		if( ( err = DecompressSequenceFrameS(display->seq, (void*)pixmap, sizeof(PlanarPixmapInfoYUV420), codecFlagUseImageBuffer, &flags, nil) != noErr ) )
		{
			NSLog(@"DecompressSequenceFrameS failed.");
		}
		QDFlushPortBuffer([display->qdView qdPort], NULL);
		[display->qdView unlockFocus];
	}
	
	[display->lock unlock];
}