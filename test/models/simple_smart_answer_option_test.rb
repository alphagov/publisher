require "test_helper"

class SimpleSmartAnswerOptionTest < ActiveSupport::TestCase
  context "given a smart answer exists with a node" do
    setup do
      @node = SimpleSmartAnswerEdition::Node.new(slug: "question1", title: "Question One?", kind: "question")
      @edition = FactoryGirl.create(:simple_smart_answer_edition, nodes: [
        @node,
        SimpleSmartAnswerEdition::Node.new(slug: "outcome1", title: "Outcome One", kind: "outcome")
      ])

      @atts = {
        label: "Yes",
        next_node: "yes"
      }
    end

    should "be able to create a valid option" do
      @option = @node.options.build(@atts)

      assert @option.save!
      @node.reload

      assert_equal "Yes", @node.options.first.label
      assert_equal "yes", @node.options.first.next_node
    end

    should "not be valid without a label" do
      @option = @node.options.build(@atts.merge(label: nil))

      assert !@option.valid?
      assert @option.errors.keys.include?(:label)
    end

    should "not be valid without the next node" do
      @option = @node.options.build(@atts.merge(next_node: nil))

      assert !@option.valid?
      assert @option.errors.keys.include?(:next_node)
    end

    should "expose the node" do
      @option = @node.options.create(@atts)
      @option.reload

      assert_equal @node, @option.node
    end

    should "return in order" do
      @options = [
        @node.options.create(@atts.merge(label: "Third", next_node: "baz", order: 3)),
        @node.options.create(@atts.merge(label: "First", next_node: "foo", order: 1)),
        @node.options.create(@atts.merge(label: "Second", next_node: "bar", order: 2)),
      ]

      assert_equal %w(First Second Third), @node.options.all.map(&:label)
      assert_equal %w(foo bar baz), @node.options.all.map(&:next_node)
    end

    context "slug" do
      should "generate a slug from the label if blank" do
        @option = @node.options.build(@atts)

        assert @option.valid?
        assert_equal "yes", @option.slug
      end

      should "keep the slug up to date if the label changes" do
        @option = @node.options.create(@atts.merge(slug: "most-likely"))
        @option.label = "Most of the times"
        assert @option.valid?
        assert_equal "most-of-the-times", @option.slug
      end

      should "not overwrite a given slug" do
        @option = @node.options.build(@atts.merge(slug: "fooey"))

        assert @option.valid?
        assert_equal "fooey", @option.slug
      end

      should "not be valid with an invalid slug" do
        @option = @node.options.build(@atts)

        [
          'under_score',
          'space space',
          'punct.u&ation',
        ].each do |slug|
          @option.slug = slug
          refute @option.valid?
        end
      end
    end
  end
end
