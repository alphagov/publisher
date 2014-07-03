class DateInput
  include Formtastic::Inputs::Base

  def to_html
    html = field_title
    html += hint_tag unless options[:hide_hint]
    html << date_fields
  end

  def date_fields
    day, month, year = extract_date_field_prefill_values

    day_field_html(day) <<
    month_field_html(month) <<
    year_field_html(year)
  end

private

  def day_field_html(value)
    template.content_tag(:div, class: 'form-group-day') do
      template.label_tag(method_s + '_day', 'Day') +
      template.text_field_tag(method_s + '_day', value,
        { maxlength: 2, name: format_tag_name(builder, '3i'), class: 'form-control', disabled: options[:disabled] })
    end
  end

  def month_field_html(value)
    template.content_tag(:div, class: 'form-group-month') do
      template.label_tag(method_s + '_month', "Month") +
      template.text_field_tag(method_s + '_month', value,
        { maxlength: 2, name: format_tag_name(builder, '2i'), class: 'form-control', disabled: options[:disabled] })
    end
  end

  def year_field_html(value)
    template.content_tag(:div, class: 'form-group-year') do
      template.label_tag(method_s + '_year', "Year") +
      template.text_field_tag(method_s + '_year', value,
        { maxlength: 4, name: format_tag_name(builder, '1i'), class: 'form-control', disabled: options[:disabled] })
    end
  end

  def format_tag_name(builder, suffix=nil)
    "#{@object_name}[#{sanitized_method_name}#{"(#{suffix})" if suffix}]"
  end

  def method_s
    method.to_s
  end

  def extract_date_field_prefill_values
    [prefill_value.day.to_s.rjust(2, '0'),
      prefill_value.month.to_s.rjust(2, '0'),
      prefill_value.year] if prefill_value
  end

  def prefill_value
    @value ||= (builder.object && builder.object.send(method)) || options[:default]
  end

  def field_title
    template.content_tag(:legend, label_text, class: 'date-input-legend')
  end

  def hint_tag
    template.content_tag(:p, hint_text, class: "form-hint")
  end

  def hint_text
    "For example, 16 08 2014"
  end

end
