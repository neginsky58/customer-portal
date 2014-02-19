jQuery.fn.rdy = function(func){
	this.length && func.apply(this);
	return this;
};
jQuery(document).ready(function($){
	$('.hasBigShadow').append('<div class="bigShadow"/>');
	$('.hasSmallShadow, .shortcutsBoxes .box').append('<div class="smallShadow"/>');
	
	$('#productSlider').rdy(function(){
		var slider = $('#productSlider');
		slider.find('ul').width(slider.find('li').length*280);
		$('<ul class="productSliderPages"/>').appendTo(slider);
		for(var i=0, len = slider.find('li').length; i<len; i++){
			$('.productSliderPages').append('<li><a href="#"/></li>');
		}
		$('.productSliderPages').delegate('li', 'click', function(e){
			var t=$(this);
			t.addClass('s').siblings().removeClass('s');
			slider.find('ul:first').animate({
				marginLeft:-t.index()*280
			})
			return false;
		});
		$('.productSliderPages li:first').click();
	});
});