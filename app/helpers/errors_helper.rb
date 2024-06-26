module ErrorsHelper
  def errors_for(errors, attribute, use_full_message: true)
    return nil if errors.blank?

    errors.filter_map { |error|
      if error.attribute == attribute
        {
          text: use_full_message ? error.full_message : error.message,
        }
      end
    }
          .presence
  end
end
