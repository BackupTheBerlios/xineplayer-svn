<?php include "page.php"; startPage("about"); ?>

<!-- begin main content -->
<div id="mainPage">
  <div id="rightBox">
  <div class="box" id="news">
    <h1>Latest News</h1>
<?php
  include "newsItems.php";

  $i = 0;
  echo "<ul>\n";
  while(($i < 5) && ($i < count($newsItems))) {
    $item = $newsItems[$i];
    ?> <li><span class="date"><?php echo $item['date'];?></span>
	    <a href="news.php#item<?php echo $item['date']; 
	    ?>"><?php echo $item['title']; ?></a></li><?php
    $i++;
  }
  echo "</ul>\n";
?>
  </div>
  <div class="box" id="donate">
  <h1>Donate to XinePlayer</h1>
  <p>Any donations you can make to show your appreciation or to help
  continue the development of XinePlayer are most welcome.</p>
    <form action="https://www.paypal.com/cgi-bin/webscr" method="post">
  <div style="text-align: center;">
      <input type="hidden" name="cmd" value="_xclick" />
      <input type="hidden" name="business" value="richwareham@users.sourceforge.net" />
      <input type="hidden" name="item_name" value="XinePlayer" />
      <input type="hidden" name="no_note" value="1" />
      <input type="hidden" name="currency_code" value="GBP" />
      <input type="hidden" name="tax" value="0" />
      <input type="hidden" name="lc" value="GB" />
      <input type="image" src="https://www.paypal.com/en_US/i/btn/x-click-but21.gif" style="border: none;" name="submit" alt="Make payments with PayPal - it's fast, free and secure!" />
  </div>
    </form>
  </div>
  <div class="box" id="license">
    <h1>Licensing</h1>
    <p>This software is released under the terms of the 
    <a href="http://www.gnu.org/copyleft/gpl.html">GNU General Public
    License</a>, see the file COPYING distributed with the app for details.</p>
  </div>
  </div>
  <div class="box" id="about">
    <h1>About XinePlayer</h1>
    <p>XinePlayer is a multimedia player for Mac OS X. It is based upon
    the stable and mature <a href="http://xinehq.de/">xine</a> multimedia
    playback engine. It is designed to be a free replacement for QuickTime
    Player and DVD Player.</p>
    <h2>Features</h2>
    <ul>
    <li>Support for many popular formats including MPEG 1/2, QuickTime (MOV),
    DivX (AVI) and some Windows Media formats (WMV).</li>
    <li>DVD playback (using the VideoLan
        <a href="http://videolan.org/libdvdcss">libdvdcss</a> 
        decoding library).</li>
    <li>DVD menu support for advanced navigation features.</li>
    <li>Playlists.</li>
    <li>Fullscreen playback.</li>
    <li>Software deinterlacing.</li>
    </ul>
    <h2>Reporting Bugs/Requesting Features</h2>
    <p>You can either <a href="mailto:richwareham -at- users -dot- sourceforge -dot- net">e-mail me</a>
    or use the <a href="http://developer.berlios.de/bugs/?group_id=3329">bug 
    reporting system</a> and <a href="http://developer.berlios.de/feature/?group_id=3329">feature
    request system</a>. Using the bug/feature tracker makes it a lot easier for you to check
    the progress of your report.</p>
    <h2>Acknowledgements</h2>
    <p>XinePlayer is hosted by the <a href="http://berlios.de/">BerliOS project</a>.</p>
    <p>
    <a href="http://developer.berlios.de" title="BerliOS Developer"> <img src="http://developer.berlios.de/bslogo.php?group_id=3329" width="124px" height="32px" border="0" alt="BerliOS Developer Logo"></a></p>
    <p><a href="http://macupdate.com/info.php/id/17492">MacUpdate</a> for their speedy listing.</p>
    </p>
  </div>
  <!--
  <div class="box" id="warning">
    <h1>Important note</h1>
    <div class="warning">
      This software is alpha quality. It has been tested on the author's
      system as his main media player. Use at your own risk. It has only been
      tested with OS X version 10.3 (Panther). On other versions os OS X your
      mileage may vary.
    </div>
  </div>
  -->
</div>
<!-- end main content -->


<?php endPage(); ?>

