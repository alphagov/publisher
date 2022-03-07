module FormHelper
  def form_errors(errors)
    tag.ul(class: %w[help-block error-block]) do
      safe_join(errors.map { |e| tag.li(e) })
    end
  end

  def form_group(form, field_name, label: nil, help: nil, attributes: {}, &block)
    raise "No input field given" unless block_given?

    errors = form.object.errors[field_name]
    attributes[:class] = Array(attributes[:class]) << "form-group"
    attributes[:class] << "has-error" if errors.any?

    tag.div(**attributes) do
      wrapped_label = tag.div(class: "form-label") { form_label_element(form, field_name, label) }
      wrapped_field = tag.div(class: "form-wrapper", &block)
      errors = form_errors(errors)
      help = tag.div(class: "help-block") { help } if help

      safe_join([wrapped_label, help, errors, wrapped_field])
    end
  end

private

  def form_label_element(form, field_name, label)
    return label if label&.match?(/\A<label/) # already a label element

    form.label(field_name, label)
  end
end
