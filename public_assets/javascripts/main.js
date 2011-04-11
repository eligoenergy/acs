require(['modernizr-1.6.min.js', 'jquery-ui-1.8.2.js', 'placeholder.jquery.js', 'rails.js'], function() {
 	if (!Modernizr.placeholder) {
		// alert('no placeholder support!')
		// FIXME This doesn't work with firefox for some reason
		$('textarea').placeholder();
		$('input[autofocus=true]').focus();
	}
	// if (!Modernizr.csscolumns) {
	  // $('.columnize').columnize();
	// }
	
	$('.collapsable > ul').addClass('dont_look');
	$('.collapsable > h6, .collapsable > h5').addClass('right_arrow');
	$('.collapsable > h6, .collapsable > h5').click(function() {
	  $(this).toggleClass('down_arrow').toggleClass('right_arrow');
      $(this).parent().children('ul').slideToggle().toggleClass('dont_look');
	});
});