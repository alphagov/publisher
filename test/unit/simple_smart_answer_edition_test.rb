require 'test_helper'

class SimpleSmartAnswerEditionTest < ActiveSupport::TestCase

  setup do
    @artefact = FactoryGirl.create(:artefact)
  end

  context "handling nodes as json" do
    setup do
      @nodes = { "question1" => { "title" => "Hello, world!", "body" => "Some more information", "options" => [ ] } }
      @edition = FactoryGirl.create(:simple_smart_answer_edition, :panopticon_id => @artefact.id)
    end

    should "return the nodes attribute as json" do
      @edition.nodes = @nodes

      assert_equal @nodes.to_json, @edition.nodes_as_json
    end

    should "parse json into the nodes attribute" do
      @edition.nodes_as_json = @nodes.to_json

      assert_equal @nodes, @edition.nodes
    end
  end

end
