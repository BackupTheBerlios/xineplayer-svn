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
    <p>Yes but by default XinePlayer can only play non-copy protected
    DVDs due to licensing constraints and bully-boy tactics by the
    DVD Copyright Control Agency. A plugin is available separately which
    will allow you to play copy-protected DVDs.</p>
    <h2>Does XinePlayer support DVD menus?</h2>
    <p>XinePlayer uses the <a href="http://dvd.sf.net/">libdvdnav</a> library
    to provide full support for DVD menus and advanced features such as
    multiple angles, audio tracks or subtitles.</p>
    <h2>Why doesn't XinePlayer play this particular file?</h2>
    <p>XinePlayer supports all the codecs that the xine library supports. If
    a particular file won't play it is likely that xine itself doesn't
    support that codec. Try filing a bug on <a href="http://xinehq.de/">the
    xine website</a>.
  </div>
</div>
<!-- end main content -->


<?php endPage(); ?>

