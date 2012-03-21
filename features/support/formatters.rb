def format_state(state)
  state.sub(' ', '_')
end

def format_value(value)
  value.blank? ? "" : value
end

def value_for_field_assertion(value)
  value.blank? ? { } : { :with => value }
end