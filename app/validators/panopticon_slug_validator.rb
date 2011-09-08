require 'net/http'

class PanopticonSlugValidator < ActiveModel::EachValidator
  def claim_slug(endpoint_url, attributes_to_send)
    uri = URI.parse(endpoint_url)
    res = Net::HTTP.post_form(uri, attributes_to_send)

    case res
    when Net::HTTPCreated
      return true
    when Net::HTTPNotAcceptable
      return false
    else
      Rails.logger.warn "Panopticon communications error: #{res.inspect}"
      return false
    end
  end

  # implement the method called during validation
  def validate_each(record, attribute, value)
    the_slug = record.send(attribute)

    if the_slug.length < 4 or the_slug.length > 60
      record.errors[attribute] << "must be between 4 and 60 characters"
      return
    end

    endpoint_url = "#{PANOPTICON_HOST}/slugs"
    attributes_to_send = {
      'slug[kind]' => record.class.to_s,
      'slug[owning_app]' => 'publisher',
      'slug[name]' => the_slug
    }

    record.errors[attribute] << 'must be unique across Gov.UK' unless claim_slug(endpoint_url, attributes_to_send)
  rescue Errno::ECONNREFUSED
    record.errors[attribute] << 'panopticon seems to be unavailable'
  end
end
