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


#import "XPController.h"
#import "XPDocument.h"
#import "XPDVDDocument.h"

#include <assert.h>
#include <string.h>
#include <paths.h>

#include <IOKit/IOKitLib.h>
#include <IOKit/IOBSD.h>
#include <IOKit/storage/IOMedia.h>
#include <IOKit/storage/IOCDMedia.h>
#include <IOKit/storage/IODVDMedia.h>

static NSArray *GetEjectableMediaOfClass( const char *psz_class );
static XPController *_sharedController = nil;

@implementation XPController

+ (XPController*) sharedController
{
	if(_sharedController)
		return _sharedController;
	
	XPController *newController = [[[XPController alloc] init] autorelease];
	[newController awakeFromNib];
	
	return newController;
}

- (id) init
{
	id mySelf = [super init];
	if(mySelf)
	{
		_sharedController = mySelf;
		
		/* Create the default xine engine */
		_defaultEngine = [[XineEngine defaultEngine] retain];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(terminate:) name:NSApplicationWillTerminateNotification object:nil];
	}
	return mySelf;
}

- (void) terminate: (NSNotification*) notification;
{
	[_defaultEngine release];
}

- (void) openURL: (id) sender
{
	if(![_openURLDialogue isVisible])
	{
		[_openURLDialogue center];
		[_openURLDialogue makeKeyAndOrderFront:nil];
	}
}

- (IBAction) openURLClicked: (id) sender
{
	NSURL *url = [NSURL URLWithString:[_openURLComboBox stringValue]];
	/* NSLog(@"URL: %@", url); */
	if(!url)
	{
		NSAlert *errorAlert = [[[NSAlert alloc] init] autorelease];
		[errorAlert addButtonWithTitle: NSLocalizedString(@"OK", @"Canonical dialogue box button.")];
		[errorAlert setMessageText: [NSString stringWithFormat:NSLocalizedString(@"'%@' is not a valid URL.", @"Error shown when user attempts to open an invalid URL."), [_openURLComboBox stringValue]]];
		[errorAlert beginSheetModalForWindow:_openURLDialogue modalDelegate:nil didEndSelector:nil contextInfo:nil];
	} else {
		[_openURLDialogue orderOut:nil];
		NSDocument *newDocument = [[NSDocumentController sharedDocumentController] makeDocumentWithContentsOfURL:url ofType:@"Movie"];
		
		if(newDocument)
		{
			[[NSDocumentController sharedDocumentController] addDocument: newDocument];
			[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:url];
			[newDocument makeWindowControllers];
			[newDocument showWindows];
		} else {
			NSLog(@"Error creating document.");
		}
	}
}

- (IBAction) cancelOpenURLClicked: (id) sender
{
	[_openURLDialogue orderOut:nil];
}

- (NSString *)comboBox:(NSComboBox *)aComboBox completedString:(NSString *)uncompletedString
{
	if(aComboBox != _openURLComboBox)
		return nil;
	NSArray *recentURLs = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
	NSEnumerator *recentEnum = [recentURLs objectEnumerator];
	NSURL *urlStr;
	while(urlStr = [recentEnum nextObject]) 
	{
		if([[urlStr absoluteString] hasPrefix:uncompletedString])
			return [urlStr absoluteString];
	}
}

- (unsigned int)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)aString
{
	if(aComboBox != _openURLComboBox)
		return nil;
	NSArray *recentURLs = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
	NSEnumerator *recentEnum = [recentURLs objectEnumerator];
	NSURL *urlStr; unsigned int i = 0;
	while(urlStr = [recentEnum nextObject]) 
	{
		if([urlStr isEqualTo: [NSURL URLWithString:aString]])
			return i;
		i++;
	}
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)index
{
	if(aComboBox != _openURLComboBox)
		return nil;
	
	return [[[NSDocumentController sharedDocumentController] recentDocumentURLs] objectAtIndex: index];
}

- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
	if(aComboBox != _openURLComboBox)
		return 0;
	
	return [[[NSDocumentController sharedDocumentController] recentDocumentURLs] count];
}

- (void) openDisc: (NSString*) devicePath
{
	NSLog(@"openDisc: %@", devicePath);
	
	// Check that we don't have any DVD players already.
	NSEnumerator *documentEnumerator = [[[NSDocumentController sharedDocumentController] documents] objectEnumerator];
	XPDocument *tempDoc = nil;
	while(tempDoc = [documentEnumerator nextObject])
	{
		if([tempDoc respondsToSelector: @selector(isDVDPlayer)] && [tempDoc isDVDPlayer])
			return;
	}
		
	NSArray *dvdDrives = GetEjectableMediaOfClass(kIODVDMediaClass);
	
	// Horrible hack, we assume that the device now mounted is the first DVD drive.
	if([dvdDrives count] > 0)
	{
		// The mounted media is a DVD drive.
		NSURL *url = [NSURL URLWithString: [dvdDrives objectAtIndex: 0] relativeToURL: [NSURL URLWithString:@"dvd:/"]]; 
		
		NSLog(@"Attempting to open %@", url);
		
		NSDocument *newDocument = [[[XPDVDDocument alloc] initWithContentsOfURL:url ofType:@"DVD"] autorelease];
		
		if(newDocument)
		{
			[[NSDocumentController sharedDocumentController] addDocument: newDocument];
			[newDocument makeWindowControllers];
			[newDocument showWindows];
		} else {
			NSLog(@"Error creating document.");
		}
	}
}

- (IBAction) openFirstDisc: (id) sender
{
	NSArray *dvdDrives = GetEjectableMediaOfClass(kIODVDMediaClass);
	if([dvdDrives count] == 0)
		return;
	
	[self openDisc: [dvdDrives objectAtIndex: 0]];
}

- (void) mediaMounted: (NSNotification*) notification
{
	NSDictionary *information = [notification userInfo];
	NSString *devicePath = [information objectForKey: @"NSDevicePath"];
	
	// Check to see if the mounted media is a DVD.
	BOOL isDir = NO;
	if(![[NSFileManager defaultManager] fileExistsAtPath: [NSString pathWithComponents: [NSArray arrayWithObjects:devicePath, @"VIDEO_TS", nil]] isDirectory:&isDir] || !isDir)
		return;
		
	[self openDisc: devicePath];
}

- (void) awakeFromNib
{
	[[NSDocumentController sharedDocumentController] setShouldCreateUI: YES];
	
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(mediaMounted:) name:NSWorkspaceDidMountNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedLaunching:) name:NSApplicationDidFinishLaunchingNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkDVDPanel:) name:NSWindowDidBecomeMainNotification object:nil];
}

- (void) checkDVDPanel: (NSNotification*) notification
{
	NSDocumentController *controller = [NSDocumentController sharedDocumentController];
	NSDocument *currentDocument = [controller currentDocument];
	
	/*
	if([currentDocument respondsToSelector: @selector(isDVDPlayer)] && [(XPDocument*) currentDocument isDVDPlayer])
	{
		// Enable the panel
	} else {
		// Disable the panel
	}
	 */
}

- (void) finishedLaunching: (NSNotification*) notification
{
	// Attempt to open a DVD if it is in the drive.
	// [self openFirstDisc: self];
	
	/* Not sure about this.
	if([[[NSDocumentController sharedDocumentController] documents] count] == 0)
	{
		[[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:@"Movie" display:YES];
	}
	 */
}

- (BOOL) isDVDPanelOpen
{
	return [dvdControlsPanel isVisible];
}

- (IBAction) openDVDPanel: (id) sender
{
	[dvdControlsPanel orderFront: sender];
}

- (IBAction) closeDVDPanel: (id) sender
{
	[dvdControlsPanel orderOut: self];
}

@end

// GetEjectableMediaOfClass function borrowed from the VLC media player:
// svn://svn.videolan.org/vlc/trunk/modules/gui/macosx/open.m
//
static NSArray *GetEjectableMediaOfClass( const char *psz_class )
{
    io_object_t next_media;
    mach_port_t master_port;
    kern_return_t kern_result;
    NSArray *o_devices = nil;
    NSMutableArray *p_list = nil;
    io_iterator_t media_iterator;
    CFMutableDictionaryRef classes_to_match;
    
    kern_result = IOMasterPort( MACH_PORT_NULL, &master_port );
    if( kern_result != KERN_SUCCESS )
    {
        return( nil );
    }
    
    classes_to_match = IOServiceMatching( psz_class );
    if( classes_to_match == NULL )
    {
        return( nil );
    }
    
    CFDictionarySetValue( classes_to_match, CFSTR( kIOMediaEjectableKey ), 
                          kCFBooleanTrue );
    
    kern_result = IOServiceGetMatchingServices( master_port, classes_to_match, 
                                                &media_iterator );
    if( kern_result != KERN_SUCCESS )
    {
        return( nil );
    }
    
    p_list = [NSMutableArray arrayWithCapacity: 1];
    
    next_media = IOIteratorNext( media_iterator );
    if( next_media != 0 )
    {
        char psz_buf[0x32];
        size_t dev_path_length;
        CFTypeRef str_bsd_path;
        
        do
        {
            str_bsd_path = IORegistryEntryCreateCFProperty( next_media,
                                                            CFSTR( kIOBSDNameKey ),
                                                            kCFAllocatorDefault,
                                                            0 );
            if( str_bsd_path == NULL )
            {
                IOObjectRelease( next_media );
                continue;
            }
            
            snprintf( psz_buf, sizeof(psz_buf), "%s%c", _PATH_DEV, 'r' );
            dev_path_length = strlen( psz_buf );
            
            if( CFStringGetCString( str_bsd_path,
                                    (char*)&psz_buf + dev_path_length,
                                    sizeof(psz_buf) - dev_path_length,
                                    kCFStringEncodingASCII ) )
            {
                [p_list addObject: [NSString stringWithCString: psz_buf]];
            }
            
            CFRelease( str_bsd_path );
            
            IOObjectRelease( next_media );
            
        } while( ( next_media = IOIteratorNext( media_iterator ) ) != 0 );
    }
    
    IOObjectRelease( media_iterator );
    
    o_devices = [NSArray arrayWithArray: p_list];
    
    return( o_devices );
}
