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

#import "XPDocument.h"
#import "XPDocumentWindow.h"
#import "XPController.h"
#import "../Preferences/XPPreferencesController.h"

#import <xine.h>

@interface XPDocument (Private)

// Make the document window reflect the current status.
- (void) synchroniseGUIAndStream: (id) sender;
- (void) setNotificationMessage: (NSString*) message;

@end

@implementation XPDocument

- (id)init
{
    self = [super init];
    if (self) {
		_stream = nil;
		_videoPort = nil;
		_audioPort = nil;
		_playlist = [[NSMutableArray array] retain];
		_playlistIndex = -1; // Not played anything yet.
		_isSynchingGUI = NO;
		_guiTimer = nil;
		_isPlaying = NO;
		_audioVisualisationFilter = nil;
		_deinterlaceFilter = nil;
		_deinterlace = NO;
		_resizeOnFrameChange = NO;
    }
    return self;
}

- (void) close
{
	if([_stream isPlaying]) {
		[_stream wireAudioToPort: _audioPort];
		[_stream wireVideoToPort: _videoPort];
	}

	if(_guiTimer)
		[_guiTimer invalidate];
	_guiTimer = nil;
	
	if(_stream)
		[_stream release];
	_stream = nil;

	if(_audioVisualisationFilter) 
		[_audioVisualisationFilter release];
	_audioVisualisationFilter = nil;
	if(_deinterlaceFilter) 
		[_deinterlaceFilter release];
	_deinterlaceFilter = nil;
	
	if(_videoPort)
		[_videoPort release];
	_videoPort = nil;
	
	if(_audioPort)
		[_audioPort release];
	_audioPort = nil;
	
	if(_engine)
		[_engine release];
	_engine = nil;
	
	if(_playlist)
		[_playlist release];
	_playlist = nil;

	[super close];
}

- (void) dealloc
{
	[super dealloc];
}

- (NSString *)windowNibName
{
	return @"XPDocument";
}

- (void) prefsChanged: (NSNotification*) notification
{
	XPPreferencesController *prefController = [XPPreferencesController defaultController];
	
	_resizeOnFrameChange = [prefController resizeWindowOnFrameChange];
	
	if(_deinterlaceFilter) {
		[_deinterlaceFilter setValue: [prefController deinterlaceAlgorithm] forProperty: @"method"];
		[_deinterlaceFilter setValue: [NSNumber numberWithBool: YES] forProperty: @"cheap_mode"];
		[_deinterlaceFilter setValue: [NSNumber numberWithBool: NO] forProperty: @"pulldown"];
		[_deinterlaceFilter setValue: [NSNumber numberWithBool: YES] forProperty: @"use_progressive_frame_flag"];
		
#if 0
		NSArray *properties = [_deinterlaceFilter propertyNames];
		NSEnumerator *objEnum = [properties objectEnumerator];
		NSString *name;
		while(name = [objEnum nextObject]) {
			NSLog(@"Property: %@ (%@)", name, [_deinterlaceFilter valueForProperty: name]);
			NSLog(@"  - %@", [_deinterlaceFilter descriptionForProperty: name]);
			if([_deinterlaceFilter isEnumeratedParameter: name]) {
				NSEnumerator *enumEnum = [[_deinterlaceFilter enumeratedValuesForProperty: name] objectEnumerator];
				NSString *value;
				while(value = [enumEnum nextObject]) 
				{
					NSLog(@"    + %@", value);
				}
			}
		}
#endif
	}
	
	/* This isn't very stable yet */
#if 0
	if(_audioVisualisationFilter && [[_audioVisualisationFilter name] isNotEqualTo: [prefController audioVisualisation]]) 
	{
		[_stream wireAudioToPort: _audioPort];
		[_audioVisualisationFilter release];
		_audioVisualisationFilter = nil;
	}
#endif
	
	if(!_audioVisualisationFilter && [[prefController audioVisualisation] isNotEqualTo: @"none"]) 
	{
		_audioVisualisationFilter = [XinePostProcessor postProcessorNamed: [[XPPreferencesController defaultController] audioVisualisation] fromEngine: _engine inputs:0 audioPorts: [NSArray arrayWithObject: _audioPort] videoPorts: [NSArray arrayWithObject: _videoPort]];
		if(_audioVisualisationFilter) 
			[_audioVisualisationFilter retain];
	}

	if(![_stream getStreamInformationForKey: XINE_STREAM_INFO_HAS_VIDEO] && _audioVisualisationFilter)
	{
		[_stream wireAudioToPort: _audioPort];
		[_stream wireAudioToPort: [[_audioVisualisationFilter audioInputs] objectAtIndex: 0]];
	} else {
		[_stream wireAudioToPort: _audioPort];
	}
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
	
	[[aController window] center];
	[[aController window] setAcceptsMouseMovedEvents: YES];
	
	_engine = [[XineEngine defaultEngine] retain];
		
	// Create the default stream and video/audio ports.
	_videoPort = [[_engine createVideoPortFromVideoView: videoView] retain];
	_audioPort = [[_engine createAudioPort] retain];
	
	[videoView setNotficationView: notificationView];
	[self setNotificationMessage: @"piiiiiiing..."];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameChanged:) name:XineVideoViewFrameSizeDidChangeNotification object:videoView];
	_stream = [[_engine createStreamWithAudioPort:_audioPort videoPort:_videoPort] retain];
	 	
	_deinterlaceFilter = [XinePostProcessor postProcessorNamed: @"tvtime" fromEngine: _engine inputs:0 audioPorts: [NSArray arrayWithObject: _audioPort] videoPorts: [NSArray arrayWithObject: _videoPort]];
	if(_deinterlaceFilter) 
		[_deinterlaceFilter retain];
		
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
	[self prefsChanged: nil];
	
	[[self documentWindow] makeFirstResponder: videoView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:XineStreamPlaybackDidFinishNotification object:_stream];
	
	_guiTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(synchroniseGUIAndStream:) userInfo:nil repeats:YES];
	
	[[self documentWindow] registerForDraggedTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, NSURLPboardType, nil]];
	
	if([_playlist count]) {
		[self openPlaylistItemAtIndex: 0];
	}
	
	[self performSelectorOnMainThread:@selector(windowsShown:) withObject:nil waitUntilDone:NO];
}

- (void) frameChanged: (NSNotification*) notification
{
	/* NSLog(@"Frame change!"); */
	if(_resizeOnFrameChange && ![videoView isFullScreen])
	{
		[self performSelectorOnMainThread:@selector(normalSize:) withObject:nil waitUntilDone:NO];
	}
}

- (void) windowsShown: (void*) data
{	
	if([_playlist count] == 0)
	{
		// Load the logo and play it.
		[self openMRL: [[NSBundle mainBundle] pathForResource:@"logo" ofType:@"mpv"]];
	}
}

- (void) playbackFinished: (NSNotification*) notification
{
	_isPlaying = NO;
	NSLog(@"Finished playback");
	[self openNextMRL: self];
}

- (BOOL)validateMenuItem: (NSMenuItem*) item
{
	NSString *itemSelector = NSStringFromSelector([item action]);
		
	if([itemSelector isEqualToString: @"toggleStreamInfo:"]) {
		int sidState = [streamInfoDrawer state];
		// Work out which we want it to be.
		if((sidState == NSDrawerOpeningState) || (sidState == NSDrawerOpenState)) 
		{
			[item setTitle: [[NSBundle mainBundle] localizedStringForKey:@"HideMovieInformation" value:@"Hide Movie Info" table:nil]];
		} else {
			[item setTitle: [[NSBundle mainBundle] localizedStringForKey:@"ShowMovieInformation" value:@"Show Movie Info" table:nil]];
		}
	} else if([itemSelector isEqualToString: @"togglePlaylist:"]) {
		int plistState = [playlistDrawer state];
		// Work out which we want it to be.
		if((plistState == NSDrawerOpeningState) || (plistState == NSDrawerOpenState)) 
		{
			[item setTitle: [[NSBundle mainBundle] localizedStringForKey:@"HidePlaylist" value:@"Hide Playlist" table:nil]];
		} else {
			[item setTitle: [[NSBundle mainBundle] localizedStringForKey:@"ShowPlaylist" value:@"Show Playlist" table:nil]];
		}
	} else if([itemSelector isEqualToString: @"toggleDeinterlace:"]) {
		[item setEnabled: (_deinterlaceFilter != nil)];
		[item setState: [self isDeinterlacing] ? NSOnState : NSOffState];
	}

	return [super validateMenuItem: item];
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType
{
	[self addFileToPlaylist: fileName];
	return YES;
}

- (BOOL)readFromURL:(NSURL *)aURL ofType:(NSString *)docType
{
	[self addURLToPlaylist: aURL];
	return YES;
}

- (BOOL) openMRL: (NSString*) mrl
{
	_isPlaying = NO;
	
	/* Actually stop the stream and wait until it has taken effect. */
	if([_stream isPlaying]) {
		[_stream stop: YES];
	}
	
	if([_stream openMRL: mrl])
	{		
		if(![_stream getStreamInformationForKey: XINE_STREAM_INFO_HAS_VIDEO] && _audioVisualisationFilter)
		{
			[_stream wireAudioToPort: _audioPort];
			[_stream wireAudioToPort: [[_audioVisualisationFilter audioInputs] objectAtIndex: 0]];
		} else {
			[_stream wireAudioToPort: _audioPort];
		}
		
		[_stream play];
		[(NSWindowController*) [[self windowControllers] objectAtIndex: 0] synchronizeWindowTitleWithDocumentName];
		
		_isPlaying = YES;
	}
	
	[self synchroniseGUIAndStream: nil];
	[[self documentWindow] makeFirstResponder: [[self documentWindow] initialFirstResponder]];
	
	return _isPlaying;
}

- (NSString*) displayName
{
	if([_playlist count] > 0) 
	{
		if([[_playlist objectAtIndex: _playlistIndex] isKindOfClass: [NSString class]])
		{
			NSArray *pathComponents = [[self currentMRL] pathComponents];
			return [pathComponents lastObject];
		} else if([[_playlist objectAtIndex: _playlistIndex] isKindOfClass: [NSURL class]])
		{
			return [(NSURL*) [_playlist objectAtIndex: _playlistIndex] absoluteString];
		}
	}
	
	return [[NSBundle mainBundle] localizedStringForKey:@"MoviePlayerName" value:@"Movie Player" table:nil];
}

// Somehow a lot easier than I'd expect...
- (NSWindow*) documentWindow { return [videoView window]; }

// We let XPDVDDocument handle DVD stuff
- (BOOL) isDVDPlayer { return NO; }

- (BOOL) isDeinterlacing { 
	return _deinterlace; 
}

- (void) setDeinterlace: (BOOL) interlace
{
	_deinterlace = interlace;
	if(_deinterlace && _deinterlaceFilter) 
	{
		[_stream wireVideoToPort: [[_deinterlaceFilter videoInputs] objectAtIndex: 0]];
	} else {
		[_stream wireVideoToPort: _videoPort];
	}
}

@end

@implementation XPDocument (Playlist)

- (BOOL) openPlaylistItemAtIndex: (int) index
{
	if((index < 0) || (index >= [_playlist count]))
		return NO;
	
	_playlistIndex = index;
	NSString *MRL = [self currentMRL];
	NSLog(@"Opening: %@", MRL);
	return [self openMRL: MRL];
}

- (void) addURLToPlaylist: (NSURL*) url
{
	[_playlist addObject: url];
	
	if(_stream && ![self isPlaying])
	{
		[self openPlaylistItemAtIndex: [_playlist count] - 1];
	}
}

- (void) addFileToPlaylist: (NSString*) filename
{
	[_playlist addObject: filename];
	
	if(_stream && ![self isPlaying])
	{
		[self openPlaylistItemAtIndex: [_playlist count] - 1];
	}	
}

- (BOOL) isPlaying { return _isPlaying; }

- (NSString*) currentMRL
{
	if([[_playlist objectAtIndex: _playlistIndex] isKindOfClass: [NSString class]])
	{
		return [_playlist objectAtIndex: _playlistIndex];
		
	} else if([[_playlist objectAtIndex: _playlistIndex] isKindOfClass: [NSURL class]])
	{
		return [(NSURL*) [_playlist objectAtIndex: _playlistIndex] absoluteString];
	}
	
	return @"???";
}

@end

@implementation XPDocument (Actions)

- (IBAction) toggleDeinterlace: (id) sender
{
	[self setDeinterlace: ![self isDeinterlacing]];
	[self setNotificationMessage: [self isDeinterlacing] ? NSLocalizedString(@"Deinterlace On", @"Message displayed to user") : NSLocalizedString(@"Deinterlace Off", @"Message displayed to user")];
	[videoView displayNotification];
}

- (IBAction) openNextMRL: (id) sender
{
	_playlistIndex ++;
	while(_playlistIndex < [_playlist count]) 
	{
		if([self openPlaylistItemAtIndex: _playlistIndex]) { return; }
		_playlistIndex ++;
	}
	
	return;
}

- (IBAction) openPreviousMRL: (id) sender
{
	_playlistIndex --;
	while(_playlistIndex >= 0) 
	{
		if([self openPlaylistItemAtIndex: _playlistIndex]) { return; }
		_playlistIndex --;
	}
	
	return;
}

- (IBAction) normalSize: (id) sender
{
	if([videoView isFullScreen])
		return;
	[[self documentWindow] setFrame: [videoView idealParentWindowFrame: 1.0] display: YES animate: YES];
}

- (IBAction) halfSize: (id) sender
{
	if([videoView isFullScreen])
		return;
	[[self documentWindow] setFrame: [videoView idealParentWindowFrame: 0.5] display: YES animate: YES];
}

- (IBAction) doubleSize: (id) sender
{
	if([videoView isFullScreen])
		return;
	[[self documentWindow] setFrame: [videoView idealParentWindowFrame: 2.0] display: YES animate: YES];
}

- (IBAction) toggleStreamInfo: (id) sender
{
	[playlistDrawer close];
	[streamInfoDrawer toggle: sender];
}

- (IBAction) togglePlaylist: (id) sender
{
	[streamInfoDrawer close];
	[playlistDrawer toggle: sender];
}

- (IBAction) toggleFullScreen: (id) sender
{
	if([videoView isFullScreen])
		[videoView exitFullScreen: sender];
	else
		[videoView goFullScreen: sender];
}

- (IBAction) toggleMute: (id) sender
{
	if(!_stream)
		return;
	if(_isSynchingGUI)
		return;
	
	if([muteButton state] == NSOnState)
	{
		[_stream setValue: 1 ofParameter:XINE_PARAM_AUDIO_MUTE];
	} else {
		[_stream setValue: 0 ofParameter:XINE_PARAM_AUDIO_MUTE];
	}
	
	[self synchroniseGUIAndStream: nil];
}

- (IBAction) volumeChanged: (id) sender
{
	if(_isSynchingGUI)
		return;
	
	// [_stream setValue: [volumeSlider intValue] ofParameter:XINE_PARAM_AUDIO_VOLUME];
	[self synchroniseGUIAndStream: nil];
}

- (IBAction) togglePlayAndPause: (id) sender
{
	if(!_stream)
		return;
	if(_isSynchingGUI)
		return;
	
	if([_stream speed] != XineNormalSpeed) 
	{
		[_stream setSpeed: XineNormalSpeed];
	} else {
		[_stream setSpeed: XinePause];
	}
	
	[self synchroniseGUIAndStream: nil];
}

- (IBAction) timeChanged: (id) sender
{
	if(!_stream)
		return;
	if(_isSynchingGUI)
		return;
	
	[_stream playFromPosition: [timeSlider intValue]];
	[self synchroniseGUIAndStream: nil];
}

@end

@implementation XPDocument (TableViewDataSource)

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if(aTableView == streamInfoTable)
	{
		return 8;
	} else if(aTableView == playlistTable)
	{
		return [_playlist count];
	}
	
	return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if(aTableView == streamInfoTable)
	{
		// NSLog(@"row: %i id: %@", rowIndex, [aTableColumn identifier]);
		if([[aTableColumn identifier] isEqualToString: @"field"])
		{
			switch(rowIndex)
			{
				case 0:
					return @"Video Codec";
					break;
				case 1:
					return @"Video Size";
					break;
				case 2:
					return @"Input Plugin";
					break;
				case 3: 
					return @"Audio Codec";
					break;
				case 4: 
					return @"Sample Rate";
					break;
				case 5: 
					return @"Channels";
					break;
				case 6: 
					return @"Audio Bitrate";
					break;
				case 7: 
					return @"Aspect Ratio";
					break;
			}
		}
		if([[aTableColumn identifier] isEqualToString: @"value"])
		{
			switch(rowIndex)
			{
				case 0:
					return [_stream getMetaInfoForKey: XINE_META_INFO_VIDEOCODEC];
					break;
				case 1:
				{   
					NSSize videoSize = [[_videoPort videoView] videoSize];
					return [NSString stringWithFormat: @"%i x %i", (int) videoSize.width, (int) videoSize.height];
				}
					break;
				case 2:
					return [_stream getMetaInfoForKey: XINE_META_INFO_INPUT_PLUGIN];
					break;
				case 3: 
					return [_stream getMetaInfoForKey: XINE_META_INFO_AUDIOCODEC];
					break;
				case 4:
					return [NSString stringWithFormat: @"%iHz", [_stream getStreamInformationForKey: XINE_STREAM_INFO_AUDIO_SAMPLERATE]];
					break;
				case 5:
					return [NSNumber numberWithInt:[_stream getStreamInformationForKey: XINE_STREAM_INFO_AUDIO_CHANNELS]];
					break;
				case 6:
					return [NSNumber numberWithInt:[_stream getStreamInformationForKey: XINE_STREAM_INFO_AUDIO_BITRATE]];
					break;
				case 7:
					return [NSNumber numberWithFloat:(float)[_stream getStreamInformationForKey: XINE_STREAM_INFO_VIDEO_RATIO] / 10000.0];
					break;
			}			
		}
	} else if(aTableView == playlistTable)
	{
		if([[aTableColumn identifier] isEqualToString: @"playing"])
		{
			if(rowIndex == _playlistIndex)
				return [NSImage imageNamed: @"volume"];
		} else if([[aTableColumn identifier] isEqualToString: @"mrl"])
		{
			return [[_playlist objectAtIndex: rowIndex] description];
		}
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	return;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	// Never edit but resister double-click to chenge MRL.
	// NSLog(@"Edit row %i, column %@", rowIndex, [aTableColumn identifier]);
	
	if((aTableView == playlistTable) && ([[aTableColumn identifier] isEqualToString:@"mrl"]))
	{
		[self openPlaylistItemAtIndex: rowIndex];
	}
	
	return NO;
}

@end

@implementation XPDocument (Private)

- (void) setNotificationMessage: (NSString*) message
{
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowOffset:NSMakeSize(0,0)];
	[shadow setShadowBlurRadius: 3.0];
	[shadow setShadowColor: [NSColor colorWithCalibratedWhite:0.0 alpha:0.8]];
	NSAttributedString *aString = [[[NSAttributedString alloc] autorelease] initWithString:message attributes:[NSDictionary dictionaryWithObjectsAndKeys: 
		[NSFont boldSystemFontOfSize: 20], NSFontAttributeName,
		[NSColor greenColor], NSForegroundColorAttributeName,
		shadow, NSShadowAttributeName,
		nil]];
	[notificationLabel setAttributedStringValue: aString];
	[notificationLabel sizeToFit];
	[notificationLabel setFrameOrigin:NSMakePoint(0,[notificationView bounds].size.height - [notificationLabel frame].size.height)];
}

- (void) synchroniseGUIAndStream: (NSTimer*) timer
{
	if(!_stream)
		return;
	if(_isSynchingGUI)
		return;
	if(![self documentWindow])
		return;
	
	_isSynchingGUI = YES;
	
	BOOL isMuted = [_stream valueOfParameter:XINE_PARAM_AUDIO_MUTE];
	
	[muteButton setState: isMuted ? NSOnState : NSOffState];
	
	[volumeSlider setEnabled: ([_stream getStreamInformationForKey: XINE_STREAM_INFO_HAS_AUDIO] && !isMuted)];
	
	//NSLog(@"Has audio: %i", [_stream getStreamInformationForKey: XINE_STREAM_INFO_HAS_AUDIO]);
	//NSLog(@"Slider: %i", [volumeSlider intValue]);
	
	[_stream setValue: [volumeSlider intValue] ofParameter:XINE_PARAM_AUDIO_VOLUME];
	
	[timeSlider setEnabled: ([_stream isPlaying] && [_stream hasPositionInformation])];
	if([timeSlider isEnabled])
	{
		int pos, time, len;
		[_stream getPosition:&pos time:&time length:&len];
		[timeSlider setIntValue: pos];
	} else {
		[timeSlider setIntValue: 0];
	}
	
	if([_stream isPlaying] && ([_stream speed] == XineNormalSpeed))
	{
		[playPauseButton setImage: [NSImage imageNamed:@"pause"]];
		[playPauseButton setAlternateImage: [NSImage imageNamed:@"pause_blue"]];
	} else {
		[playPauseButton setImage: [NSImage imageNamed:@"play"]];
		[playPauseButton setAlternateImage: [NSImage imageNamed:@"play_blue"]];
	}
	
	[playPauseButton setEnabled: [_stream isPlaying]];
	
	[previousButton setEnabled: (_playlistIndex > 0)];
	[nextButton setEnabled: (_playlistIndex + 1 < [_playlist count])];
	
	[streamInfoTable reloadData];
	[playlistTable reloadData];
	
	_isSynchingGUI = NO;
}

@end
