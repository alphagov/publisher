class SlugValidator < ActiveModel::EachValidator
  # implement the method called during validation
  def validate_each(record, attribute, value)
    validators = [
      DonePageValidator,
      ForeignTravelAdvicePageValidator,
      HelpPageValidator,
      FinderEmailSignupValidator,
      ManualPageValidator,
      DefaultValidator
    ].map { |klass| klass.new(record, attribute, value) }

    validators.find(&:applicable?).validate!
  end

  InstanceValidator = Struct.new(:record, :attribute, :value) do
    def starts_with?(expected_prefix)
      value.to_s.start_with?(expected_prefix)
    end

    def ends_with?(expected_suffix)
      value.to_s.end_with?(expected_suffix)
    end

    def of_kind?(expected_kind)
      record.respond_to?(:kind) && [*expected_kind].include?(record.kind)
    end

    def url_after_first_slash
      value.to_s.split('/', 2)[1]
    end

    def url_after_first_slash_is_valid_slug!
      if !valid_slug?(url_after_first_slash)
        record.errors[attribute] << "must be usable in a url"
      end
    end

    def url_parts
      value.to_s.split("/")
    end

    def valid_slug?(url_part)
      # Regex taken from ActiveSupport::Inflector.parameterize
      # We don't want to use this method because it also does a number of cosmetic tidy-ups
      # which lead to false-positives (eg merging consecutive '-'s)
      ! url_part.to_s.match(/[^a-z0-9\-_]/)
    end
  end

  class DonePageValidator < InstanceValidator
    def applicable?
      of_kind?("completed_transaction")
    end

    def validate!
      record.errors[attribute] << "Done page slugs must have a done/ prefix" unless starts_with?("done/")
      url_after_first_slash_is_valid_slug!
    end
  end

  class ForeignTravelAdvicePageValidator < InstanceValidator
    def applicable?
      starts_with?("foreign-travel-advice/") && of_kind?('travel-advice')
    end

    def validate!
      url_after_first_slash_is_valid_slug!
    end
  end

  class FinderEmailSignupValidator < InstanceValidator
    def applicable?
      of_kind?("finder_email_signup")
    end

    def validate!
      url_after_first_slash_is_valid_slug!
    end
  end

  class HelpPageValidator < InstanceValidator
    def applicable?
      of_kind?('help_page')
    end

    def validate!
      record.errors[attribute] << "Help page slugs must have a help/ prefix" unless starts_with?("help/")
      url_after_first_slash_is_valid_slug!
    end
  end

  class ManualPageValidator < InstanceValidator
    def applicable?
      of_kind?('manual')
    end

    def validate!
      validate_number_of_parts!
      validate_guidance_prefix!
      validate_parts_as_slugs!
    end

  private

    def validate_number_of_parts!
      unless [2, 3].include?(url_parts.size)
        record.errors[attribute] << 'must contains two or three path parts'
      end
    end

    def validate_guidance_prefix!
      unless starts_with?('guidance/')
        record.errors[attribute] << 'must have a guidance/ prefix'
      end
    end

    def validate_parts_as_slugs!
      unless url_parts.all? { |url_part| valid_slug?(url_part) }
        record.errors[attribute] << 'must be usable in a URL'
      end
    end
  end

  class DefaultValidator < InstanceValidator
    def applicable?
      true
    end

    def validate!
      record.errors[attribute] << "must be usable in a url" unless valid_slug?(value)
    end
  end
end
