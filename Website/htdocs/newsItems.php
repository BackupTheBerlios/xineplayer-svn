<?php
global $newsItems;

$newsItems = array(
  array( 'date' => '22-Mar-05', 'title' => 'Version 0.2 released',
  'contents' => '<p>Version 0.2 has been <a href="http://developer.berlios.de/project/showfiles.php?group_id=3329">released</a>. New features are below:</p>
<ul>
<li>\'Open URL...\' menu option.</li>
<li>Support for playlist-like files (e.g. RealAudio streams from websites).</li>
<li>Any errors opening a stream are reported.</li>
<li>Reports progress of network operations.</li>
<li>Uses less memory and CPU (hopefully) on lower-spec machines.</li>
<li>Ogg vorbis support.</li>
<li>If XinePlayer cannot open a movie it will tell you.</li>
<li>Can automatically resize window on movie size change.</li>
<li>Display a little notification in the video window when state changes (e.g. deinterlace is toggled, etc).</li>
<li>Attempt to open any type of file passed (i.e. no longer grey-out files in Open dialogue).</li>
<li>Deinterlacing is now done via xine\'s tvtime deinterlace plugin.</li>
<li>Implement preferences dialogue.</li>
<li>Audio visualisation support.</li>
<li>Support post-processing plugins.</li>
<li>Only use one xine engine instance per app.</li>
<li>Fix frame corruption bug whereby colours appeared \'streaky\' with certain movies.</li>
</ul>'),
  array( 'date' => '17-Mar-05', 'title' => 'First Public Builds',
          'contents' => '<p>I\'ve uploaded the first G3 and G4 builds to the <a href="http://developer.berlios.de/project/showfiles.php?group_id=3329">BerliOS file release system</a>. Please download the appropriate build for your processor. Also this is very, very alpha so I appologise for any bugs.</p>'),
  array( 'date' => '15-Mar-05', 'title' => 'First Public Release',
          'contents' => '<p>The first public release of XinePlayer has been made! Currently it is source only until I sort out some issues with my build system.</p>'),
/*
  array( 'date' => '4-Jul-04', 'title' => 'Rich Wareham Interview',
	  'contents' => '
'),
*/
);

?>
