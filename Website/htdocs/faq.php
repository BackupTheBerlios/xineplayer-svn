<?php include "page.php"; startPage("faq"); ?>

<!-- begin main content -->
<div id="mainPage">
  <div class="box">
  <h1>Frequenly Asked Questions</h1>
    <p>If you think there is a particular question missing from this
    FAQ, <a href="mailto:richwareham -at- users.sourceforge.net">mail me</a>.</p>
    <h2>Why are you not maintinaing this as part of the xine project?</h2>
    <p>Many xine frontends (e.g. 
       <a href="http://www.hadess.net/totem.php3">totem</a> or
       <a href="http://kaffeine.sourceforge.net/">kaffeine</a>) are
       maintained separately. It is a testament to the good design of the
       xine engine that such frontends may be developed like this.</p>
    <h2>Can I play DVDs with XinePlayer?</h2>
    <p>Yes. XinePlayer uses the VideoLan
   <a href="http://videolan.org/libdvdcss/">libdvdcss</a> library to access
  all DVDs.</p>
    <h2>Does XinePlayer support DVD menus?</h2>
    <p>XinePlayer uses the <a href="http://dvd.sf.net/">libdvdnav</a> library
    to provide full support for DVD menus and advanced features such as
    multiple angles, audio tracks or subtitles.</p>
    <h2>XinePlayer crashes when I try to open a file or open a new window!</h2>
    <p>Make sure you have downloaded the correct version of XinePlayer for
    your processor. There are different G3 (without Altivec) and
    G4/G5 (with Altivec) builds.</p>
    <h2>Why doesn't XinePlayer play this particular file?</h2>
    <p>XinePlayer supports all the codecs that the xine library supports. If
    a particular file won't play it is likely that xine itself doesn't
    support that codec. Try filing a bug on <a href="http://xinehq.de/">the
    xine website</a>.
    <h2>I want the source code!</h2>
    <p>You can <a href="http://svn.berlios.de/viewcvs/xineplayer/">browse the source-code</a> or
    <a href="http://developer.berlios.de/svn/?group_id=3329">check it out of the Subversion
    repository</a>. The source code to xine is available from the
    <a href="http://sourceforge.net/cvs/?group_id=9655">xine CVS repository</a> and the
    source code to libdvdcss can be checked out of the 
    <a href="http://developers.videolan.org/svn.html">VideoLan subversion repository</a>.
    The Subversion repository should be considered definitive but from time-to-time
    releases might be accompanied with snapshot source tarballs.</p>
    <h2>Your source won't build!</h2>
    <p>The XCode project assumes that xine has already been downloaded and built. See the
    <a href="http://svn.berlios.de/viewcvs/xineplayer/XinePlayer/trunk/XinePlayer/BUILDING_README?view=markup">BUILDING_README</a> 
    file  for more details.</p>
  </div>
</div>
<!-- end main content -->


<?php endPage(); ?>

