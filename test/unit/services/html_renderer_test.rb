require "test_helper"

class HtmlRendererTest < ActiveSupport::TestCase
  context ".render_hash" do
    should "call render_html once for a single-item hash" do
      expected_output = { content: { 'body': "<p>foo</p>" } }

      output = HtmlRenderer.render_hash({ content: { 'body': "foo" } })

      assert_equal expected_output, output
    end

    should "call render_html for each item in a multi-item hash" do
      expected_output = { '0': { 'body': "<p>foo</p>" }, '1': { 'body': "<p>foo 2</p>" }, '2': { 'body': "<p>foo 3</p>" } }

      output = HtmlRenderer.render_hash({ '0': { 'body': "foo" }, '1': { 'body': "foo 2" }, '2': { 'body': "foo 3" } })

      assert_equal expected_output, output
    end
  end

  context ".render_html" do
    should "correctly process simple govspeak into html" do
      input = "Hello World!"

      assert_equal "<p>Hello World!</p>", HtmlRenderer.render_html(input)
    end

    should "correctly process complex govspeak into html" do
      input = <<~GOV_SPEAK
        %warning callout%

        ^useful information^

        paragraph

        - [link text](href)
        - li
      GOV_SPEAK

      expected_output = <<~HTML.strip
        <div role="note" aria-label="Warning" class="application-notice help-notice">
        <p>warning callout</p>
        </div>

        <div role="note" aria-label="Information" class="application-notice info-notice">
          <p>useful information</p>
        </div>

        <p>paragraph</p>

        <ul>
          <li><a href="href\">link text</a></li>
          <li>li</li>
        </ul>
      HTML

      assert_equal expected_output, HtmlRenderer.render_html(input)
    end

    should "call ContentBlockTools::ContentBlock.from_embed_code when a content block embed code is present" do
      input = "Before block, {{embed:content_block_contact:content-item}}, after block"

      # ContentBlockTools has some internal logic and an API call that need stubbing out here
      mock_content_block = Minitest::Mock.new
      mock_content_block.expect(:render, "block content")
      ContentBlockTools::ContentBlock.expects(:from_embed_code).with("{{embed:content_block_contact:content-item}}").returns(mock_content_block)

      assert_equal "<p>Before block, block content, after block</p>", HtmlRenderer.render_html(input)
    end

    should "return an empty string when given an empty document" do
      assert_equal "", HtmlRenderer.render_html("")
    end
  end
end
