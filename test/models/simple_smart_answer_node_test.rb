require "test_helper"

class SimpleSmartAnswerNodeTest < ActiveSupport::TestCase

  context "given a smart answer exists" do
    setup do
      @edition = FactoryGirl.create(:simple_smart_answer_edition)

      @atts = {
        title: "How much wood could a woodchuck chuck if a woodchuck could chuck wood?",
        slug: "how-much-wood-could-a-woodchuck-chuck-if-a-woodchuck-could-chuck-wood",
        body: "This is a serious question.",
        kind: "question"
      }
    end

    should "be able to create a valid node" do
      @node = @edition.nodes.build(@atts)

      assert @node.save!

      @edition.reload

      assert_equal "how-much-wood-could-a-woodchuck-chuck-if-a-woodchuck-could-chuck-wood", @edition.nodes.first.slug
      assert_equal "How much wood could a woodchuck chuck if a woodchuck could chuck wood?", @edition.nodes.first.title
      assert_equal "This is a serious question.", @edition.nodes.first.body
    end

    should "not be valid without a slug" do
      @node = @edition.nodes.build( @atts.merge(slug: "") )

      assert ! @node.valid?
      assert_equal [:slug], @node.errors.keys
    end

    should "not be valid with an invalid slug" do
      @node = @edition.nodes.build(@atts)

      [
        'under_score',
        'space space',
        'punct.u&ation',
      ].each do |slug|
        @node.slug = slug
        refute @node.valid?
      end
    end

    should "not be valid without a title" do
      @node = @edition.nodes.build( @atts.merge(title: "") )

      assert ! @node.valid?
      assert_equal [:title], @node.errors.keys
    end

    should "not be valid without a kind" do
      @node = @edition.nodes.build(@atts.merge(:kind => nil))
      assert ! @node.valid?

      assert_equal [:kind], @node.errors.keys
    end

    should "not be valid with a kind other than 'question' or 'outcome'" do
      @node = @edition.nodes.build(@atts.merge(:kind => 'blah'))
      assert ! @node.valid?

      assert_equal [:kind], @node.errors.keys
    end

    should "create options using nested attributes" do
      @node = @edition.nodes.create!(@atts.merge(:options_attributes => [
        { :label => "Yes", :next_node => "yes" },
        { :label => "No", :next_node => "no" }
      ]))

      @node.reload
      assert_equal 2, @node.options.count
      assert_equal ["Yes", "No"], @node.options.all.map(&:label)
      assert_equal ["yes", "no"], @node.options.all.map(&:next_node)
    end

    should "destroy options using nested attributes" do
      @node = @edition.nodes.create!(@atts.merge(:options_attributes => [
        { :label => "Yes", :next_node => "yes" },
        { :label => "No", :next_node => "no" }
      ]))
      assert_equal 2, @node.options.count

      @node.update_attributes!(:options_attributes => {
        "1" => { "id" => @node.options.first.id, "_destroy" => "1" }
      })
      @node.reload

      assert_equal 1, @node.options.count
      assert_equal ["No"], @node.options.all.map(&:label)
      assert_equal ["no"], @node.options.all.map(&:next_node)
    end

    should "not be valid if an outcome has options" do
      @node = @edition.nodes.build(@atts.merge(:kind => 'outcome', options_attributes: [
        { :label => "Yes", :next_node => "yes" },
        { :label => "No", :next_node => "no" }
      ]))
      assert ! @node.valid?

      assert_equal [:options], @node.errors.keys
    end

    should "be able to create an outcome without options" do
      @node = @edition.nodes.build(@atts.merge(:kind => 'outcome', :options_attributes => [] ))

      assert @node.valid?
      assert @node.save!
    end

    should "be returned in order" do
      @nodes = [
        @edition.nodes.create(@atts.merge(:title => "Third", :order => 3)),
        @edition.nodes.create(@atts.merge(:title => "First", :order => 1)),
        @edition.nodes.create(@atts.merge(:title => "Second", :order => 2)),
      ]

      assert_equal ["First","Second","Third"], @edition.nodes.all.map(&:title)
    end

    should "expose the simple smart answer edition" do
      @node = @edition.nodes.build(@atts)

      assert_equal @node.edition, @edition
    end

  end

end
