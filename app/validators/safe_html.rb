require "govspeak"
require "plek"

class SafeHtml < ActiveModel::Validator
  ALLOWED_IMAGE_HOSTS = [
    # URLs for the local environment
    URI.parse(Plek.new.website_root).host, # eg www.preview.alphagov.co.uk
    URI.parse(Plek.new.asset_root).host,   # eg assets-origin.preview.alphagov.co.uk

    # Hardcode production URLs so that content copied from production is valid
    'www.gov.uk',
    'assets.digital.cabinet-office.gov.uk'
  ].freeze

  def validate(record)
    record.changes.each do |field_name, (_old_value, new_value)|
      next unless record.class::GOVSPEAK_FIELDS.include?(field_name.to_sym)
      check_struct(record, field_name, new_value)
    end
  end

  def check_struct(record, field_name, value)
    if value.respond_to?(:values) # e.g. Hash
      value.values.each { |entry| check_struct(record, field_name, entry) }
    elsif value.respond_to?(:each) # e.g. Array
      value.each { |entry| check_struct(record, field_name, entry) }
    elsif value.is_a?(String)
      check_string(record, field_name, value)
    end
  end

  def check_string(record, field_name, string)
    unless Govspeak::Document.new(string).valid?(allowed_image_hosts: ALLOWED_IMAGE_HOSTS)
      error = "cannot include invalid Govspeak, invalid HTML, any JavaScript or images hosted on sites except for #{ALLOWED_IMAGE_HOSTS.join(', ')}"
      record.errors.add(field_name, error)
    end
  end
end
