/* XinePlayer - Cocoa-based GUI frontend to Xine.
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
#import <XineKit.h>

@interface XPDocument : NSDocument
{
	IBOutlet XineVideoView *videoView;
	IBOutlet NSSlider *volumeSlider;
	IBOutlet NSButton *muteButton;
	IBOutlet NSButton *playPauseButton;
	IBOutlet NSButton *nextButton;
	IBOutlet NSButton *previousButton;
	IBOutlet NSSlider *timeSlider;
	IBOutlet NSDrawer *streamInfoDrawer;
	IBOutlet NSDrawer *playlistDrawer;
	IBOutlet NSTableView *streamInfoTable;
	IBOutlet NSTableView *playlistTable;
	
	NSMutableArray *_playlist;
	int _playlistIndex;
	BOOL _isPlaying;
	
	BOOL _isSynchingGUI;
	
	XineVideoPort *_videoPort;
	XineAudioPort *_audioPort;
	XinePostProcessor *_deinterlaceFilter;
	XinePostProcessor *_audioVisualisationFilter;
	XineStream *_stream;
	XineEngine *_engine;
	
	BOOL _deinterlace;
	BOOL _resizeOnFrameChange;
	
	NSTimer *_guiTimer;
}

- (BOOL) isDVDPlayer;
- (NSWindow*) documentWindow;
- (BOOL) openMRL: (NSString*) mrl;

- (BOOL) isDeinterlacing;
- (void) setDeinterlace: (BOOL) interlace;

@end

@interface XPDocument (Playlist)

- (void) addURLToPlaylist: (NSURL*) url;
- (void) addFileToPlaylist: (NSString*) filename;
- (BOOL) openPlaylistItemAtIndex: (int) index;
- (NSString*) currentMRL;
- (BOOL) isPlaying;

@end

@interface XPDocument (Actions)

- (IBAction) normalSize: (id) sender;
- (IBAction) halfSize: (id) sender;
- (IBAction) doubleSize: (id) sender;

- (IBAction) togglePlayAndPause: (id) sender;
- (IBAction) toggleMute: (id) sender;
- (IBAction) volumeChanged: (id) sender;
- (IBAction) timeChanged: (id) sender;
- (IBAction) openNextMRL: (id) sender;
- (IBAction) openPreviousMRL: (id) sender;

- (IBAction) toggleFullScreen: (id) sender;

- (IBAction) toggleStreamInfo: (id) sender;
- (IBAction) togglePlaylist: (id) sender;

- (IBAction) toggleDeinterlace: (id) sender;

@end
