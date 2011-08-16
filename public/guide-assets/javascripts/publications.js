// Javascript that may be used on every publication show/edit page

(function($) {
  $.fn.hasSlugField = function(opts) {

    var update_slug_notice = function(slug_field, available) {
      var container = slug_field.parent();
      var elem = container.find('.slug-status');
      if (elem.length == 0) {
        elem = $('<p class="inline-hints slug-status"></p>');
        container.append(elem)
      }

      if (available) {
        elem.css('color', 'green').text('That slug is currently available');
      } else {
        elem.css('color', 'red').text('That slug is already taken');
      }
    }
    
    return this.each(function() {
      var title_field = $(this);
      var slug_field = opts.field;
      
      $(this).change(function () {  
        if (slug_field.text() == '') {
          slug_field.val(GovUKGuideUtils.convertToSlug(title_field.val()));
          slug_field.trigger('change');
        }
      });
      
      $(slug_field).change(function () {
        $.ajax({
          url: panoption_host + "/slugs/" + $(this).val() + "?jsoncallback=panopticon",
          dataType: "jsonp",
          jsonpCallback: "panopticon",
          cache: false,
          method: "get",
          success: function(data) { update_slug_notice(slug_field, false); },
          error: function(jqXHR, textStatus, errorThrown) { update_slug_notice(slug_field, true); }
        });
      })
    });
  };
  
  $.fn.hasBasicSlugs = function() {
    $(this).live('change', function () {
      var title_field = $(this);
      var slug_field = title_field.closest('.part').find('.slug');
      if (slug_field.text() == '') {
        slug_field.val(GovUKGuideUtils.convertToSlug(title_field.val()));
      }
    });
  }
  
})(jQuery);

$(function () {
  $('.publication-nav').tabs();
  
  var submit_form = function(form,success) {
     var jq = $.post(
         form.attr('action')+".json",
         form.serialize(),
         success
     ).error( function(data) {
         var errors = $.parseJSON(data.responseText);
         var messages = "There were problems saving this edition: ";
         errors = $.map(errors, function(v,k) {
             return k + " " + v.join(", ");
         });
         messages = messages + errors.join("; ") + ".";
         $("<p class=\"flash-alert\">"+messages+"</p>").insertBefore("#wrapper:first");
     });
   }
  
  var saved = false;
  
  $('#save-edition').submit(function () {
      var edition_form = $('form.edition');
      var publication_form = $('form.publication');
      if (! saved) {
          submit_form(publication_form,function() {
              saved = true;
              edition_form.trigger('submit');
          });
      }
      
      return saved;
  });
  
  $('<a style="padding-left: 5px">[gi]</a>').appendTo('label[for=edition_title]').click(function () {
        var search_term = $('#edition_title').val();
        $('body').append('<iframe id="popup" src="/admin/google_insight?search_term='+encodeURIComponent(search_term)+'" height="410" scrolling="NO" width="400" style="position:absolute; z-index: 5; top: 50%; margin-top: -205px; left: 50%; margin-left: -200px; box-shadow: 0 0 15px rgba(0,0,0,0.4)"></iframe>');
  });
  
  if (! 'autofocus' in document.createElement('input')) {
    $('*[autofocus]').focus();
  }
  
  var submitted_forms = false;
  
  $('form.edition,form.publication').change(function () {
  	submitted_forms = false;
  });
  
  $('.also_save_edition').submit(function () {
    var edition_form = $('form.edition');
    var publication_form = $('form.publication');
    
    var this_form = $(this);

    if (! submitted_forms) {
        submit_form(edition_form,function(data) {
            submit_form(publication_form,function(data) {
                submitted_forms = true;
                this_form.trigger("submit");
            })
        });
    }
    
    return submitted_forms;
  });
});

function close_popups() {
   var iframe = document.getElementById('popup');
   iframe.parentNode.removeChild(iframe);
}
