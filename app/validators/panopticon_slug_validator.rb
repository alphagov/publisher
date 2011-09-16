require 'net/http'

class PanopticonSlugValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless record.errors.blank?
    
    the_slug = record.send(attribute)

    if the_slug.length < 4 or the_slug.length > 60
      record.errors[attribute] << "must be between 4 and 60 characters"
      return
    end

    adapter = PanopticonAdapter.new({:kind => record.class.to_s, :owning_app => 'publisher', :name => the_slug})
    record.errors[attribute] << 'must be unique across Gov.UK' unless adapter.save
  rescue Errno::ECONNREFUSED
    record.errors[attribute] << 'panopticon seems to be unavailable'
  end
end
