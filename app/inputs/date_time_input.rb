class DateTimeInput < DateInput
  def to_html
    field_title << time_fields << date_fields
  end

  def time_fields
    hour, min = extract_time_field_prefill_values
    hour_field_html(hour) << min_field_html(min)
  end

private

  def hour_field_html(value)
    template.content_tag(:div, class: 'form-group-hour') do
      template.label_tag(method_s + '_hour', 'Hour') +
      template.text_field_tag(method_s + '_hour', value,
        { placeholder: 'HH', maxlength: 2, name: format_tag_name(builder, '4i'), class: 'form-control', disabled: options[:disabled] })
    end
  end

  def min_field_html(value)
    template.content_tag(:div, class: 'form-group-min') do
      template.label_tag(method_s + '_min', 'Minute') +
      template.text_field_tag(method_s + '_min', value,
        { placeholder: 'MM', maxlength: 2, name: format_tag_name(builder, '5i'), class: 'form-control', disabled: options[:disabled] })
    end
  end

  def extract_time_field_prefill_values
    return if builder.object.nil?

    prefill_value = builder.object.send(method)
    [prefill_value.hour.to_s.rjust(2, '0'),
      prefill_value.min.to_s.rjust(2, '0')] if prefill_value
  end

end
