require 'panopticon_api'

class PanopticonSlugValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless record.errors.blank?
    
    the_slug = record.send(attribute)

    if the_slug.length < 4 or the_slug.length > 60
      record.errors[attribute] << "must be between 4 and 60 characters"
      return
    end

    adapter = PanopticonApi.new({:kind => record.class.to_s, :owning_app => 'publisher', :slug => the_slug})
    if adapter.save
      return true
    else
      adapter.errors['base'].each { |msg| record.errors[attribute] << msg }
      return false
    end
  end
end
