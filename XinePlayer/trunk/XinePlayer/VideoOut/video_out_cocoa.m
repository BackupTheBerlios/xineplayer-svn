/*
 * Copyright (C) 2000-2003 the xine project
 *
 * This file is part of xine, a free video player.
 *
 * xine is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * xine is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA
 *
 * This driver is based upon the macosx video driver in the main xine
 * source. It was modified by Rich Wareham <richwareham@users.sourceforge.net>.
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include <AppKit/AppKit.h>

#define LOG_MODULE "video_out_cocoa"
#define LOG_VERBOSE
/*
#define LOG
*/

#include "alphablend.h"
#include "xine/video_out.h"
#include "xine/vo_scale.h"
#include "xine.h"
#include "xine/xine_internal.h"
#include "xine/xineutils.h"

#import <QuickTime/QuickTime.h>

PlanarPixmapInfoYUV420* createPixmapAndUpdateFrame(vo_frame_t *frame);
void freePixmap(PlanarPixmapInfoYUV420* pixmap);

typedef struct {
  vo_frame_t            vo_frame;
  int                   width;
  int                   height;
  double                ratio;
  int                   format;
  xine_t               *xine;
  PlanarPixmapInfoYUV420 *yuv_pixmap;
} cocoa_frame_t;

@protocol VideoDriver
- (void) displayYUVFrame: (PlanarPixmapInfoYUV420*) frame size: (NSSize) frameSize aspectRatio: (float) ratio;
- (void) freedYUVFrame: (PlanarPixmapInfoYUV420*) frame;
@end

typedef struct {
  vo_driver_t           vo_driver;
  config_values_t      *config;
  int                   ratio;
  xine_t               *xine;
  NSView<VideoDriver>  *videoView;
  alphablend_t          alphablend_extra_data;
  int					deinterlace;
} cocoa_driver_t;

typedef struct {
  video_driver_class_t  driver_class;
  config_values_t      *config;
  xine_t               *xine;
} cocoa_class_t;

/* This is borrowed from xine */

/* Linear Blend filter - C version contributed by Rogerio Brito.
This algorithm has the same interface as the other functions.

The destination "screen" (pdst) is constructed from the source
screen (psrc[0]) line by line.

The i-th line of the destination screen is the average of 3 lines
from the source screen: the (i-1)-th, i-th and (i+1)-th lines, with
the i-th line having weight 2 in the computation.

Remarks:
* each line on pdst doesn't depend on previous lines;
* due to the way the algorithm is defined, the first & last lines of the
screen aren't deinterlaced.

*/
static void deinterlace_linearblend_yuv( uint8_t *pdst, uint8_t *psrc[],
                                         int width, int height )
{
	register int x, y;
	register uint8_t *l0, *l1, *l2, *l3;
	
	l0 = pdst;		/* target line */
	l1 = psrc[0];		/* 1st source line */
	l2 = l1 + width;	/* 2nd source line = line that follows l1 */
	l3 = l2 + width;	/* 3rd source line = line that follows l2 */
	
	/* Copy the first line */
	xine_fast_memcpy(l0, l1, width);
	l0 += width;
	
	for (y = 1; y < height-1; ++y) { 
		/* computes avg of: l1 + 2*l2 + l3 */
		
		for (x = 0; x < width; ++x) {
			l0[x] = (l1[x] + (l2[x]<<1) + l3[x]) >> 2;
		}
		
		/* updates the line pointers */
		l1 = l2; l2 = l3; l3 += width;
		l0 += width;
	}
	
	/* Copy the last line */
	xine_fast_memcpy(l0, l1, width);
}

static void free_framedata(cocoa_frame_t* frame) {
	if(frame->yuv_pixmap && [((cocoa_driver_t*)frame->vo_frame.driver)->videoView respondsToSelector: @selector(freedYUVFrame:)]) {
	  [((cocoa_driver_t*)frame->vo_frame.driver)->videoView freedYUVFrame: frame->yuv_pixmap];
    freePixmap(frame->yuv_pixmap);
	frame->yuv_pixmap = NULL;
  } else if(frame->vo_frame.base[0]) {
	free(frame->vo_frame.base[0]);
  }
	
  frame->vo_frame.base[0] = NULL;
  frame->vo_frame.base[1] = NULL;
  frame->vo_frame.base[2] = NULL;
}

static void cocoa_frame_dispose(vo_frame_t *vo_frame) {
  cocoa_frame_t *frame = (cocoa_frame_t *)vo_frame;
  free_framedata(frame);  
  free (frame);
}

static void cocoa_frame_field(vo_frame_t *vo_frame, int which_field) {
  /* do nothing */
}

static uint32_t cocoa_get_capabilities(vo_driver_t *vo_driver) {
  /* both styles, country and western */
  return VO_CAP_YV12 | VO_CAP_YUY2 | VO_CAP_UNSCALED_OVERLAY;
}

static vo_frame_t *cocoa_alloc_frame(vo_driver_t *vo_driver) {
  /* cocoa_driver_t *this = (cocoa_driver_t *) vo_driver; */
  cocoa_frame_t  *frame;
  
  frame = (cocoa_frame_t *) xine_xmalloc(sizeof(cocoa_frame_t));
  if(!frame)
    return NULL;

  frame->vo_frame.base[0] = NULL;
  frame->vo_frame.base[1] = NULL;
  frame->vo_frame.base[2] = NULL;
  
  frame->vo_frame.proc_slice = NULL;
  frame->vo_frame.proc_frame = NULL;
  frame->vo_frame.field      = cocoa_frame_field;
  frame->vo_frame.dispose    = cocoa_frame_dispose;
  frame->vo_frame.driver     = vo_driver;
  
  frame->yuv_pixmap	= NULL;
    
  return (vo_frame_t *)frame;
}

static void cocoa_update_frame_format(vo_driver_t *vo_driver, vo_frame_t *vo_frame,
                                     uint32_t width, uint32_t height, 
                                     double ratio, int format, int flags) {
  cocoa_driver_t *this = (cocoa_driver_t *) vo_driver;
  cocoa_frame_t  *frame = (cocoa_frame_t *) vo_frame;

  if((frame->width != width) || (frame->height != height) ||
     (frame->format != format)) {
    
    free_framedata(frame);
    
    frame->width  = width;
    frame->height = height;
    frame->format = format;

    lprintf ("frame change, new height:%d width:%d (ratio:%lf) format:%d\n",
             height, width, ratio, format);

    switch(format) {

    case XINE_IMGFMT_YV12: 
      {
		frame->yuv_pixmap = createPixmapAndUpdateFrame(vo_frame);
      }
      break;

		/*
    case XINE_IMGFMT_YUY2:
      frame->vo_frame.pitches[0] = 8*((width + 3) / 4);
      frame->vo_frame.base[0] = malloc(frame->vo_frame.pitches[0] * height);
      frame->vo_frame.base[1] = NULL;
      frame->vo_frame.base[2] = NULL;
      break;
*/
		
    default:
      xprintf (this->xine, XINE_VERBOSITY_DEBUG, "video_out_cocoa: unknown frame format %04x)\n", format);
      break;

    }
  }

  frame->ratio = ratio;
}

static void cocoa_display_frame(vo_driver_t *vo_driver, vo_frame_t *vo_frame) {
  cocoa_driver_t  *driver = (cocoa_driver_t *)vo_driver;
  cocoa_frame_t   *frame = (cocoa_frame_t *)vo_frame;
  
  if([driver->videoView respondsToSelector: @selector(displayYUVFrame:size:aspectRatio:)] && frame->yuv_pixmap) {
	  /* We have a YUV pixmap ready for display. */
	  
	  /* Attempt to auto de-interlace if we're not progressive. */
	  if(driver->deinterlace) {
		  deinterlace_linearblend_yuv(vo_frame->base[0], &(vo_frame->base[0]), vo_frame->width, vo_frame->height);
	  }
	  
	  [driver->videoView displayYUVFrame: frame->yuv_pixmap size: NSMakeSize(frame->width, frame->height) aspectRatio: frame->ratio];
  }
  
  frame->vo_frame.free(&frame->vo_frame);
}

static void cocoa_overlay_blend (vo_driver_t *this_gen, vo_frame_t *frame_gen,
                                  vo_overlay_t *overlay) {
  cocoa_driver_t *this = (cocoa_driver_t *) this_gen;
  cocoa_frame_t *frame = (cocoa_frame_t *) frame_gen;

  /* TODO: should check here whether the overlay has changed or not: use a
   * ovl_changed boolean variable similarly to video_out_xv */
  if (overlay->rle) {
    if (frame->format == XINE_IMGFMT_YV12)
      /* TODO: It may be possible to accelerate the blending via Quartz
       * Extreme ... */
      blend_yuv(frame->vo_frame.base, overlay,
          frame->width, frame->height, frame->vo_frame.pitches,
          &this->alphablend_extra_data);
    else
      blend_yuy2(frame->vo_frame.base[0], overlay,
          frame->width, frame->height, frame->vo_frame.pitches[0],
          &this->alphablend_extra_data);
  }
}

static int cocoa_get_property(vo_driver_t *vo_driver, int property) {
  cocoa_driver_t  *driver = (cocoa_driver_t *)vo_driver;
  
  switch(property) {

  case VO_PROP_ASPECT_RATIO:
    return driver->ratio;
    break;
	  
  case VO_PROP_INTERLACED:
	return driver->deinterlace;
	break;
	  
  default:
    break;
  }

  return 0;
}

static int cocoa_set_property(vo_driver_t *vo_driver, int property, int value) {
  cocoa_driver_t  *driver = (cocoa_driver_t *)vo_driver;
  
  switch(property) {

  case VO_PROP_ASPECT_RATIO:
    if(value >= XINE_VO_ASPECT_NUM_RATIOS)
      value = XINE_VO_ASPECT_AUTO;

    driver->ratio = value;
    break;
	  
  case VO_PROP_INTERLACED:
	driver->deinterlace = value;
	break;
	  
  default:
    break;
  }
  return value;
}

static void cocoa_get_property_min_max(vo_driver_t *vo_driver,
                                        int property, int *min, int *max) {
  *min = 0;
  *max = 0;
}

static int cocoa_gui_data_exchange(vo_driver_t *vo_driver, int data_type, void *data) {
/*   cocoa_driver_t     *this = (cocoa_driver_t *) vo_driver; */

  switch (data_type) {
  case XINE_GUI_SEND_COMPLETION_EVENT:
  case XINE_GUI_SEND_DRAWABLE_CHANGED:
  case XINE_GUI_SEND_EXPOSE_EVENT:
  case XINE_GUI_SEND_TRANSLATE_GUI_TO_VIDEO:
  case XINE_GUI_SEND_VIDEOWIN_VISIBLE:
  case XINE_GUI_SEND_SELECT_VISUAL:
  default:
    lprintf("unknown GUI data type %d\n", data_type);
    break;
  }

  return 0;
}
static void cocoa_dispose(vo_driver_t *vo_driver) {
  cocoa_driver_t *this = (cocoa_driver_t *) vo_driver;

  _x_alphablend_free(&this->alphablend_extra_data);
  
  free(this);
}

static int cocoa_redraw_needed(vo_driver_t *vo_driver) {
  return 0;
}

PlanarPixmapInfoYUV420* createPixmapAndUpdateFrame(vo_frame_t *frame)
{
	PlanarPixmapInfoYUV420 *pixmap = NULL;
	int width = frame->width;
	int height = frame->height;
	
	/* NSLog(@"createPixmap: %i,%i", width, height); */
	
	/* Create the pixmap */
	switch(frame->format)
	{
		case XINE_IMGFMT_YV12:
		{
			int y_size, uv_size;
			
			frame->pitches[0] = 8*((width + 7) / 8);
			frame->pitches[1] = 8*((width + 15) / 16);
			frame->pitches[2] = 8*((width + 15) / 16);
			
			y_size  = frame->pitches[0] * height;
			uv_size = frame->pitches[1] * ((height+1)/2);
			
			int offset = sizeof(PlanarPixmapInfoYUV420);
			offset = (offset + 0xf) & ~0xf;
			UInt8 *data = (UInt8*) xine_xmalloc_aligned(16, offset + (y_size + 2*uv_size), (void**) &pixmap);
			
			frame->base[0] = data + offset;
			pixmap->componentInfoY.offset = frame->base[0] - (UInt8*)pixmap;
			pixmap->componentInfoY.rowBytes = frame->pitches[0];
			
			offset += y_size;
			frame->base[1] = data + offset;
			pixmap->componentInfoCb.offset = frame->base[1] - (UInt8*)pixmap;
			pixmap->componentInfoCb.rowBytes = frame->pitches[1];
			
			offset += uv_size;
			frame->base[2] = data + offset;
			pixmap->componentInfoCr.offset = frame->base[2] - (UInt8*)pixmap;
			pixmap->componentInfoCr.rowBytes = frame->pitches[2];;
		}
			break;
		default:
			NSLog(@"Unsupported YUV format.");
			return NULL;
			break;
	}
	
	/* NSLog(@"Return: %x", pixmap); */
	
	return pixmap;
}

void freePixmap(PlanarPixmapInfoYUV420* pixmap)
{
	/* NSLog(@"Free pixmap"); */
	
	free(pixmap);
}

static vo_driver_t *open_plugin(video_driver_class_t *driver_class, const void *visual) {
  cocoa_class_t    *class = (cocoa_class_t *) driver_class;
  cocoa_driver_t   *driver;
  NSView  *view = (NSView*) visual;
  
  if(![view isKindOfClass: NSClassFromString(@"NSView")]) {
	  NSLog(@"This Quartz driver actually needs a NSView class...");
	  return NULL;
  }
  
  driver = (cocoa_driver_t *) xine_xmalloc(sizeof(cocoa_driver_t));

  driver->config = class->config;
  driver->xine   = class->xine;
  driver->ratio  = XINE_VO_ASPECT_AUTO;
  driver->videoView = view;
  driver->deinterlace = 0;
  
  driver->vo_driver.get_capabilities     = cocoa_get_capabilities;
  driver->vo_driver.alloc_frame          = cocoa_alloc_frame;
  driver->vo_driver.update_frame_format  = cocoa_update_frame_format;
  driver->vo_driver.overlay_begin        = NULL; /* not used */
  driver->vo_driver.overlay_blend        = cocoa_overlay_blend;
  driver->vo_driver.overlay_end          = NULL; /* not used */
  driver->vo_driver.display_frame        = cocoa_display_frame;
  driver->vo_driver.get_property         = cocoa_get_property;
  driver->vo_driver.set_property         = cocoa_set_property;
  driver->vo_driver.get_property_min_max = cocoa_get_property_min_max;
  driver->vo_driver.gui_data_exchange    = cocoa_gui_data_exchange;
  driver->vo_driver.dispose              = cocoa_dispose;
  driver->vo_driver.redraw_needed        = cocoa_redraw_needed;
 
  _x_alphablend_init(&driver->alphablend_extra_data, class->xine);

  return &driver->vo_driver;
}    

/*
 * Class related functions.
 */
static char* get_identifier (video_driver_class_t *driver_class) {
  return "cocoa";
}

static char* get_description (video_driver_class_t *driver_class) {
  return _("xine video output plugin for Mac OS X");
}

static void dispose_class (video_driver_class_t *driver_class) {
  cocoa_class_t    *this = (cocoa_class_t *) driver_class;
  
  free (this);
}

static void *init_class (xine_t *xine, void *visual) {
  cocoa_class_t        *this;
  
  this = (cocoa_class_t *) xine_xmalloc(sizeof(cocoa_class_t));
  
  this->driver_class.open_plugin     = open_plugin;
  this->driver_class.get_identifier  = get_identifier;
  this->driver_class.get_description = get_description;
  this->driver_class.dispose         = dispose_class;

  this->config                       = xine->config;
  this->xine                         = xine;

  return this;
}

static vo_info_t vo_info_cocoa = {
  1,                        /* Priority    */
  XINE_VISUAL_TYPE_MACOSX   /* Visual type */
};

plugin_info_t xine_plugin_info[] = {
  /* type, API, "name", version, special_info, init_function */  
  /* work around the problem that dlclose() is not allowed to
   * get rid of an image module which contains objective C code and simply
   * crashes with a Trace/BPT trap when we try to do so */
  { PLUGIN_VIDEO_OUT | PLUGIN_NO_UNLOAD, 20, "cocoa", XINE_VERSION_CODE, &vo_info_cocoa, init_class },
  { PLUGIN_NONE, 0, "", 0, NULL, NULL }
};
