(function($){
	$.fn.placeholder = function(){ 
		function valueIsPlaceholder(input){
			return ($(input).val() == $(input).attr("placeholder")); 
		}
		return this.each(function() {
			$(this).find(":input, :textarea").each(function(){
				if($(this).attr("type") == "password") {
					var	new_field = $("<input type='text'>" );
					new_field.attr("rel", $(this).attr("id"));
					new_field.attr("value", $(this).attr("placeholder"));
					$(this).parent().append(new_field);
					new_field.hide();
					function showPasswordPlaceHolder(input){
						if( $(input).val() == "" || valueIsPlaceholder(input) ) {
							$(input).hide();
							$('input[rel=' + $(input).attr("id") + ']').show();
						};
					};
					new_field.focus(function() {
						$(this).hide();
						$('input#' + $(this).attr("rel")).show().focus();
					});
					$(this).blur(function() { 
						showPasswordPlaceHolder(this, false);
					});	
					showPasswordPlaceHolder(this);
				} else {
					// Replace the value with the placeholder text.
					// optional reload parameter solves FF and IE caching values on fields.
					function showPlaceholder(input, reload){
						if( $(input).val() == "" || ( reload && valueIsPlaceholder(input) ) ){
							$(input).val($(input).attr("placeholder" ));
						}
					};
					$(this).focus(function(){
						if($(this).val() == $(this).attr("placeholder")) {
							$(this).val("");
						};
					});
					$(this).blur(function(){
						showPlaceholder($(this), false)
					});
					showPlaceholder(this, true);
				};
			});
			// Prevent forms from submitting default values
			$(this).submit(function(){
				$(this).find(":input").each(function(){
					if($(this).val() == $(this).attr("placeholder")){
						$(this).val("");
					}
				});
				$(this).find(":textarea").each(function(){
					if($(this).val() == $(this).attr("placeholder")){
						$(this).val("");
					}
				});
			});
		});
	};
})(jQuery);