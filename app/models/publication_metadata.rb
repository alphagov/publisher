class PublicationMetadata
  module HTMLGenerator
    def html
      buffer = StringIO.new
      builder = Builder::XmlMarkup.new :target => buffer
      yield builder
      buffer.rewind
      buffer.string.html_safe
    end
    private :html
  end

  include HTMLGenerator

  initialize_with :publication

  def to_html
    html do |metadata|
      metadata.dl do |dl|
        attributes.each_pair do |name, value|
          next if value.to_s.blank?
          dl.dt { |term| term.text! name.humanize }
          dl.dd { |definition| definition.text! value.to_s }
        end
      end
    end
  end

  def attributes
    publication.attributes.select { |k,v| ['slug', 'section', 'department', 'kind'].include? k }
  end
end
