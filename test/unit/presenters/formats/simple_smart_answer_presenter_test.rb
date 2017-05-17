require 'test_helper'

class SimpleSmartAnswerPresenterTest < ActiveSupport::TestCase
  include GovukContentSchemaTestHelpers::TestUnit

  def subject
    Formats::SimpleSmartAnswerPresenter.new(edition)
  end

  def edition
    @_edition ||= begin
      @edition = FactoryGirl.create(
        :simple_smart_answer_edition,
        start_button_text: "Start now",
        title: "Party time",
        body: "Are you ready to party?",
        state: "draft",
        slug: "ready-to-party",
        panopticon_id: artefact.id
      )

      @edition.nodes.build(
        kind: "question",
        slug: "question-1",
        title: "Are you really though?",
        body: "It's going to be a big night",
        options_attributes: [
          {
            label: "Yes please",
            slug: "yes-please",
            next_node: "outcome-1",
          },
          {
            label: "Not tonight",
            slug: "not-tonight",
            next_node: "outcome-2",
          }
        ]
      )
      @edition.nodes.build(
        kind: "outcome",
        slug: "outcome-1",
        title: "Let's party!",
        body: "Good choice"
      )
      @edition.nodes.build(
        kind: "outcome",
        slug: "outcome-2",
        title: "Maybe next time...",
        body: "What a shame"
      )
      @edition.save!
      @edition
    end
  end

  def artefact
    @_artefact ||= FactoryGirl.create(:artefact, kind: "simple_smart_answer")
  end

  def result
    subject.render_for_publishing_api
  end

  should "be valid against schema" do
    assert_valid_against_schema(result, 'simple_smart_answer')
  end

  should "[:schema_name]" do
    assert_equal 'simple_smart_answer', result[:schema_name]
  end

  context "[:details]" do
    context "required details" do
      should "[:start_button_text]" do
        expected = "Start now"
        assert_equal expected, result[:details][:start_button_text]
      end
    end

    context "optional details" do
      context "[:body]" do
        should "present the data" do
          expected = [
            {
              content_type: "text/govspeak",
              content: "Are you ready to party?"
            }
          ]
          assert_equal expected, result[:details][:body]
        end

        should "not present the data if nil" do
          edition.update(body: nil)
          refute_includes result[:details].keys, :body
        end
      end

      context "[:nodes]" do
        should "present the data" do
          expected = [
            {
              kind: "question",
              slug: "question-1",
              title: "Are you really though?",
              body: [
                {
                  content_type: 'text/govspeak',
                  content: "It's going to be a big night",
                }
              ],
              options: [
                {
                  label: "Yes please",
                  slug: "yes-please",
                  next_node: "outcome-1"
                },
                {
                  label: "Not tonight",
                  slug: "not-tonight",
                  next_node: "outcome-2"
                }
              ]
            },
            {
              kind: "outcome",
              slug: "outcome-1",
              title: "Let's party!",
              body: [
                {
                  content_type: 'text/govspeak',
                  content: "Good choice",
                }
              ],
              options: [],
            },
            {
              kind: "outcome",
              slug: "outcome-2",
              title: "Maybe next time...",
              body: [
                {
                  content_type: 'text/govspeak',
                  content: "What a shame",
                }
              ],
              options: [],
            },
          ]
          assert_equal expected, result[:details][:nodes]
        end
      end
    end

    should "[:external_related_links]" do
      link = { 'url' => 'www.foo.com', 'title' => 'foo' }
      artefact.update_attribute(:external_links, [link])
      expected = [
        {
          url: link['url'],
          title: link['title']
        }
      ]

      assert_equal expected, result[:details][:external_related_links]
    end

    should "[:routes]" do
      edition.update_attribute(:slug, 'foo')
      expected = [
        { path: '/foo', type: 'prefix' },
      ]
      assert_equal expected, result[:routes]
    end
  end
end
