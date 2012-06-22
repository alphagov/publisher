class ContentDiffFormatter
  include ActionView::Context
  include ActionView::Helpers::TagHelper

  def initialize(body)
    @body = body.split("\n")
    @line_no = 0
  end

  def line_for(type = :none, content)
    classes = [type, "alt"]
    @line_no += 1

    multiple_lines = content.split('\n')
    [ type, multiple_lines.map do |line|
      escaped_content = escape_once( line.sub("\\r","") ).html_safe
      content_tag :li, :class => classes.join(' ') do
        "<!--#{@line_no}-->".html_safe + "#{escaped_content}"
      end
    end.join("\n") ]
  end

  def lines
    output = @body.map {|ln|
      case ln
      when /{"(.*)" >> "(.*)"}/
        matches = ln.match /{"(.*)" >> "(.*)"}/
        [
          line_for( :removal, matches[1] ),
          line_for( :addition, matches[2] )
        ]
      when /{-"(.*)"}/
        matches = ln.match /{-"(.*)"}/
        [ line_for( :removal, matches[1] ) ]
      when /{\+"(.*)"}/
        matches = ln.match /{\+"(.*)"}/
        [ line_for( :addition, matches[1] ) ]
      else
        [ line_for( :none, ln ) ]
      end
    }.flatten(1).map {|x| x[1] }.join.html_safe
  end

  def to_html
    content_tag :ul, :class => 'diff' do
      lines
    end
  end
end