require 'net/http'

class PanopticonApi
  include ActiveModel::Validations
  cattr_accessor :endpoint
  attr_accessor :kind, :owning_app, :slug
  validates_presence_of :kind, :owning_app, :slug
  
  def initialize(attributes = {})
    attributes.each { |k, v| send("#{k}=", v) }
  end
  
  def save
    return false unless valid?
    
    attributes_to_send = {
      'slug[kind]' => self.kind,
      'slug[owning_app]' => self.owning_app,
      'slug[name]' => self.slug
    }
    uri = URI.parse("#{self.class.endpoint}/slugs")
    res = Net::HTTP.post_form(uri, attributes_to_send)

    case res
    when Net::HTTPCreated
      return true
    when Net::HTTPNotAcceptable
      errors['base'] << "must be unique across Gov.UK"
      return false
    else
      errors['base'] << "Panopticon communications error: #{res.inspect}"
      return false
    end
  rescue Errno::ECONNREFUSED
    errors['base'] << "Panopticon communications error"
    return false
  end
  
  def destroy
    uri = URI.parse("#{self.class.endpoint}/slugs/#{self.slug}")
    n = Net::HTTP.start(uri.host)
    res = n.delete(uri.path)
    return res.is_a?(Net::HTTPOK)
  end
  
  class <<self
    def find(slug)
      uri = URI.parse("#{endpoint}/slugs/#{slug}")
      res = Net::HTTP.get(uri)
      res.present? ? JSON.parse(res) : false
    end
  end
end