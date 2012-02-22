// JavaScript Document

jQuery(document).ready(function() {
    
  $('#login').find('#sectionBreak').hide().end().find('h1').click( function(){
    $(this).next().slideToggle();
  });
});
