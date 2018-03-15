require "test_helper"

class SimpleSmartAnswerEditionTest < ActiveSupport::TestCase
  setup do
    @artefact = FactoryBot.create(:artefact)
  end

  should "be created with valid nodes" do
    edition = FactoryBot.build(:simple_smart_answer_edition, panopticon_id: @artefact.id)
    edition.body = "This is a simple smart answer."

    edition.nodes.build(slug: "question1", title: "You approach two locked doors. Which do you choose?", kind: "question", order: 1)
    edition.nodes.build(slug: "left", title: "As you open the door, a lion bursts out and mauls you to death.", order: 2, kind: "outcome")
    edition.nodes.build(slug: "right", title: "As you open the door, a tiger bursts out and mauls you to death.", order: 3, kind: "outcome")
    edition.save!

    edition = SimpleSmartAnswerEdition.first

    assert_equal "This is a simple smart answer.", edition.body
    assert_equal 3, edition.nodes.count
    assert_equal %w(question1 left right), edition.nodes.all.map(&:slug)
  end

  should "copy the body and nodes when cloning an edition" do
    edition = FactoryBot.create(:simple_smart_answer_edition,
      panopticon_id: @artefact.id,
      body: "This smart answer is somewhat unique and calls for a different kind of introduction",
      state: "published")
    edition.nodes.build(slug: "question1", title: "You approach two open doors. Which do you choose?", kind: "question", order: 1)
    edition.nodes.build(slug: "left", title: "As you wander through the door, it slams shut behind you, as a lion starts pacing towards you...", order: 2, kind: "outcome")
    edition.nodes.build(slug: "right", title: "As you wander through the door, it slams shut behind you, as a tiger starts pacing towards you...", order: 3, kind: "outcome")
    edition.save!

    cloned_edition = edition.build_clone
    cloned_edition.save!

    old_edition = SimpleSmartAnswerEdition.find(edition.id)
    assert_equal %w(question outcome outcome), old_edition.nodes.all.map(&:kind)
    assert_equal %w(question1 left right), old_edition.nodes.all.map(&:slug)

    new_edition = SimpleSmartAnswerEdition.find(cloned_edition.id)
    assert_equal edition.body, new_edition.body
    assert_equal %w(question outcome outcome), new_edition.nodes.all.map(&:kind)
    assert_equal %w(question1 left right), new_edition.nodes.all.map(&:slug)
  end

  should "not copy nodes when new edition is not a smart answer" do
    edition = FactoryBot.create(:simple_smart_answer_edition,
      panopticon_id: @artefact.id,
      body: "This smart answer is somewhat unique and calls for a different kind of introduction",
      state: "published")
    edition.nodes.build(slug: "question1", title: "You approach two open doors. Which do you choose?", kind: "question", order: 1)
    edition.save!

    new_edition = edition.build_clone(AnswerEdition)

    assert_equal "This smart answer is somewhat unique and calls for a different kind of introduction\n\n\nquestion: You approach two open doors. Which do you choose? \n\n ", new_edition.body

    assert new_edition.is_a?(AnswerEdition)
    assert ! new_edition.respond_to?(:nodes)
  end

  should "select the first node as the starting node" do
    edition = FactoryBot.create(:simple_smart_answer_edition)
    edition.nodes.build(slug: "question1", title: "Question 1", kind: "question", order: 1)
    edition.nodes.build(slug: "question2", title: "Question 2", kind: "question", order: 2)
    edition.nodes.build(slug: "foo", title: "Outcome 1.", order: 3, kind: "outcome")
    edition.nodes.build(slug: "bar", title: "Outcome 2", order: 4, kind: "outcome")

    assert_equal "question1", edition.initial_node.slug
  end

  should "create nodes with nested attributes" do
    edition = FactoryBot.create(:simple_smart_answer_edition, nodes_attributes: [
      { slug: "question1", title: "Question 1", kind: "question", order: 1 },
      { slug: "foo", title: "Outcome 1", kind: "outcome", order: 2 },
    ])

    assert_equal 2, edition.nodes.size
    assert_equal %w(question1 foo), edition.nodes.all.map(&:slug)
  end

  should "destroy nodes using nested attributes" do
    edition = FactoryBot.create(:simple_smart_answer_edition)
    edition.nodes.build(slug: "question1", title: "Question 1", kind: "question", order: 1)
    edition.nodes.build(slug: "question2", title: "Question 2", kind: "question", order: 1)
    edition.save!

    assert_equal 2, edition.nodes.size

    edition.update_attributes(nodes_attributes: {
        "1" => { "id" => edition.nodes.first.id, "_destroy" => "1" }
      })
    edition.reload

    assert_equal 1, edition.nodes.size
  end

  context "SimpleSmartAnswerEdition: Start Button" do
    setup do
      @edition_attributes = {
        panopticon_id: @artefact.id,
        body: "This is a simple smart answer with a default text for start button."
      }
    end
    context "with default text" do
      setup do
        edition = FactoryBot.build(:simple_smart_answer_edition, @edition_attributes)
        edition.save!
      end

      should "be created with the default text for start button" do
        edition = SimpleSmartAnswerEdition.first

        assert_equal "Start now", edition.start_button_text
        assert_equal "This is a simple smart answer with a default text for start button.", edition.body
        assert_equal @artefact.id.to_s, edition.panopticon_id
      end
    end

    context "when button text changes" do
      setup do
        edition = FactoryBot.build(
          :simple_smart_answer_edition,
          @edition_attributes.merge(start_button_text: "Click to start")
        )
        edition.save!
      end

      should "be created with the text given by the content creator" do
        edition = SimpleSmartAnswerEdition.first

        refute_equal "Start Now", edition.start_button_text
        assert_equal "Click to start", edition.start_button_text
        assert_equal "This is a simple smart answer with a default text for start button.", edition.body
        assert_equal @artefact.id.to_s, edition.panopticon_id
      end
    end
  end

  context "update_attributes method" do
    setup do
      @edition = FactoryBot.create(:simple_smart_answer_edition)
      @edition.nodes.build(slug: "question1", title: "Question 1", kind: "question", order: 1)
      @edition.nodes.build(slug: "question2", title: "Question 2", kind: "question", order: 1)
      @edition.nodes.first.options.build(
        label: "Option 1", next_node: "question2", order: 1
)
      @edition.save!
    end

    should "update edition and nested node and option attributes" do
      @edition.update_attributes(title: "Smarter than the average answer",
        body: "No developers were involved in the changing of this copy",
        nodes_attributes: {
          "0" => { "id" => @edition.nodes.first.id, "title" => "Question the first", "options_attributes" => {
            "0" => { "id" => @edition.nodes.first.options.first.id, "label" => "Option the first" }
          } }
      })

      @edition.reload

      assert_equal "Smarter than the average answer", @edition.title
      assert_equal "No developers were involved in the changing of this copy", @edition.body
      assert_equal "Question the first", @edition.nodes.first.title
      assert_equal "Option the first", @edition.nodes.first.options.first.label
    end

    should "create and destroy nodes and options using nested attributes" do
      @edition.update_attributes(nodes_attributes: {
          "0" => { "id" => @edition.nodes.first.id, "options_attributes" => {
              "0" => { "id" => @edition.nodes.first.options.first.id, "_destroy" => "1" }
            } },
          "1" => { "id" => @edition.nodes.second.id, "_destroy" => "1" },
          "2" => { "kind" => "question", "title" => "Question 3", "slug" => "question3", "options_attributes" => {
            "0" => { "label" => "Goes to outcome 1", "next_node" => "outcome1" }
          } },
          "3" => { "kind" => "outcome", "title" => "Outcome 1", "slug" => "outcome1" }
        })

      @edition.reload

      assert_equal 3, @edition.nodes.size
      assert_equal 0, @edition.nodes.first.options.size
      assert_equal "Question 3", @edition.nodes.second.title
      assert_equal 1, @edition.nodes.second.options.size
      assert_equal "outcome1", @edition.nodes.second.options.first.next_node
      assert_equal "Outcome 1", @edition.nodes.third.title
    end

    should "ignore new nodes if they are to be destroyed" do
      @edition.update_attributes(nodes_attributes: {
          "0" => { "id" => @edition.nodes.first.id, "title" => "Question the first" },
          "1" => { "title" => "", "slug" => "", "kind" => "outcome", "_destroy" => "1" }
        })
      @edition.reload

      assert_equal "Question the first", @edition.nodes.first.title
      assert_equal 2, @edition.nodes.size
    end
  end
end
