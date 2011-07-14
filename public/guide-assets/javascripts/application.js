// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
var GovUKGuideUtils = {
  convertToSlug: function(title) {
      return title
      .toLowerCase()
      .replace(/[^\w ]+/g,'')
      .replace(/ +/g,'-');
  }
}