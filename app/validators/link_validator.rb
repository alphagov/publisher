# encoding: UTF-8

class LinkValidator < ActiveModel::Validator
  def validate(record)
    record.class::GOVSPEAK_FIELDS.each do |govspeak_field_name|
      govspeak_field_value = record.read_attribute(govspeak_field_name)
      next if govspeak_field_value.blank?

      messages = errors(govspeak_field_value)
      record.errors[govspeak_field_name] << messages unless messages.blank?
    end
  end

  def errors(string)
    link_regex = %r{
      \[.*?\]           # link text in literal square brackets
      \(                # literal opening parenthesis
         (\S*?)           # containing URL
         (\s+"[^"]+")?    # and optional space followed by title text in quotes
      \)                # literal close paren
      (\{:rel=["']external["']\})?  # optional :rel=external in literal curly brackets.
    }x

    errors = Set.new

    string.gsub(/(“|”)+/, '"').scan(link_regex) do |match|
      if match[0] !~ %r{^(?:https?://|mailto:|/)}
        errors << 'Internal links must start with a forward slash eg [link text](/link-destination). External links must start with http://, https://, or mailto: eg [external link text](https://www.google.co.uk).'
      end
      if match[1]
        errors << %q-Don't include hover text in links. Delete the text in quotation marks eg "This appears when you hover over the link."-
      end
      if match[2]
        errors << 'Delete {:rel="external"} in links.'
      end
    end
    errors.to_a
  end
end
