require "test_helper"

class FormHelperTest < ActionView::TestCase
  context "form_errors" do
    should "return an unordered list with errors when there are errors present" do
      expected = '<div id="error-field-name"><ul class="help-block error-block no-bullets"><li>One</li><li>Two</li><li>Three</li></ul></div>'

      assert_equal expected, form_errors(%w[One Two Three], "field_name")
    end

    should "return an empty unordered list when there are no errors present" do
      expected = '<div id="error-field-name"><ul class="help-block error-block no-bullets"></ul></div>'

      assert_equal expected, form_errors([], "field_name")
    end
  end

  context "form_group" do
    setup do
      object = stub(field_name: "", errors: Hash.new([]))
      @form = FormBuilder.new("edition", object, self, {})
    end

    should "return the input wrapped within a form group" do
      output = form_group(@form, :field_name) { @form.text_field(:field_name) }
      label = '<div class="form-label"><label for="edition_field_name">Field name</label></div>'
      wrapped_field = '<div class="form-wrapper"><input type="text" value="" name="edition[field_name]" id="edition_field_name" /></div>'
      error_block = '<div id="error-field-name"><ul class="help-block error-block no-bullets"></ul></div>'

      assert_equal %(<div class="form-group">#{label}#{error_block}#{wrapped_field}</div>), output
    end

    should "include help text if that is provided" do
      output = form_group(@form, :field_name, help: "Help block text") { @form.text_field(:field_name) }
      help_block = '<div class="help-block">Help block text</div>'

      assert_match help_block, output
    end

    should "accept, and not wrap, a label element passed in" do
      output = form_group(@form, :field_name, label: "Custom label text") { @form.text_field(:field_name) }
      custom_label = '<div class="form-label"><label for="edition_field_name">Custom label text</label></div>'

      assert_match custom_label, output
    end

    should "return a form-group html structure with a custom attributes" do
      output = form_group(@form, :field_name, attributes: { id: :field_id, class: %i[one two] }) { @form.text_field(:field_name) }
      custom_attributes = '<div id="field_id" class="one two form-group">'

      assert_match custom_attributes, output
    end

    should "return a form-group html structure with a has-error class when any errors are present" do
      object = stub(field_name: "field_name", errors: Hash.new(["cannot be blank", "must be unique"]))
      form = FormBuilder.new("edition", object, self, {})
      output = form_group(form, :field_name) { form.text_field(:field_name) }
      form_group_with_errors = '<div class="form-group has-error">'

      assert_match form_group_with_errors, output
      assert_match "cannot be blank", output
    end

    should "raise an exception if there is no input field given as a block" do
      assert_raises(RuntimeError, "No input field given") do
        form_group(@form, :test_field)
      end
    end
  end
end
