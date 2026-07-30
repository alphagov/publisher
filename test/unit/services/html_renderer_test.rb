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

    should "return an empty string when given an empty document" do
      assert_equal "", HtmlRenderer.render_html("")
    end

    context "when the document contains content blocks" do
      setup do
        stub_publishing_api_responses_for_content_blocks

        @mock_render = '<span class="content-block" data-embed-code="{{embed:content_block_contact:content-item}}">block content</span>'

        @mock_render_two = '<span class="content-block" data-embed-code="{{embed:content_block_contact:content-item-two}}">different block content</span>'

        stub_built_content_blocks
      end

      context "rendering" do
        context "when a single embed code is present" do
          setup do
            @document_contents = "First block: {{embed:content_block_contact:content-item}} done."
          end

          should "render the block in the expected position" do
            expected_html = "<p>First block: #{@mock_render} done.</p>"

            assert_equal(
              expected_html,
              HtmlRenderer.render_html(@document_contents),
            )
          end
        end

        context "when embed codes from two blocks are present" do
          setup do
            @document_contents = <<~MARKUP.squish
              First block: {{embed:content_block_contact:content-item}} done.
              Second block: {{embed:content_block_contact:content-item-two}} done.
            MARKUP
          end

          should "render both blocks in the expected positions" do
            expected_html = <<~HTML.squish
              <p>First block: #{@mock_render} done.
              Second block: #{@mock_render_two} done.</p>
            HTML

            assert_equal(
              expected_html,
              HtmlRenderer.render_html(@document_contents),
            )
          end
        end

        context "when a particular embed code appears more than once" do
          setup do
            @document_contents = <<~MARKUP.squish
              First block: {{embed:content_block_contact:content-item}} done.
              Second block: {{embed:content_block_contact:content-item-two}} done.
              Second block again: {{embed:content_block_contact:content-item-two}} done.
            MARKUP
          end

          should "render the repeated block in all expected positions" do
            expected_html = <<~HTML.squish
              <p>First block: #{@mock_render} done.
              Second block: #{@mock_render_two} done.
              Second block again: #{@mock_render_two} done.</p>
            HTML

            assert_equal(
              expected_html,
              HtmlRenderer.render_html(@document_contents),
            )
          end
        end
      end
    end
  end

  def stub_publishing_api_responses_for_content_blocks
    stubbed_api_results_1 = {
      "results" => [
        {
          "details" => { title: "Contact 1" },
          "document_type" => "content_block_contact",
          "title" => "Contact title",
          "content_id" => "1234",
        },
      ],
    }
    stubbed_api_results_2 = {
      "results" => [
        {
          "details" => { title: "Contact 2" },
          "document_type" => "content_block_contact",
          "title" => "Contact 2 title",
          "content_id" => "4567",
        },
      ],
    }

    stubbed_api_response_1 = stub("stubbed_api_response_1", parsed_content: stubbed_api_results_1)
    stubbed_api_response_2 = stub("stubbed_api_response_2", parsed_content: stubbed_api_results_2)

    Services.publishing_api.stubs(:get_content_items).with(
      content_id_aliases: %w[content-item],
      document_type: "content_block_contact",
    ).returns(stubbed_api_response_1)

    Services.publishing_api.stubs(:get_content_items).with(
      content_id_aliases: %w[content-item-two],
      document_type: "content_block_contact",
    ).returns(stubbed_api_response_2)
  end

  def stub_built_content_blocks
    stubbed_content_block = stub(render: @mock_render)
    stubbed_content_block_two = stub(render: @mock_render_two)

    ContentBlockTools::ContentBlock.stubs(:new).with(
      content_id: "1234",
      title: "Contact title",
      document_type: "content_block_contact",
      details: { title: "Contact 1" },
      embed_code: "{{embed:content_block_contact:content-item}}",
    ).returns(stubbed_content_block)

    ContentBlockTools::ContentBlock.stubs(:new).with(
      content_id: "4567",
      title: "Contact 2 title",
      document_type: "content_block_contact",
      details: { title: "Contact 2" },
      embed_code: "{{embed:content_block_contact:content-item-two}}",
    ).returns(stubbed_content_block_two)
  end
end
