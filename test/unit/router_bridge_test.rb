require 'test_helper'

class RouterBridgeTest < ActiveSupport::TestCase
  def setup
    routes = stub("routes")
    @router_client = stub("router", routes: routes)
  end

  def create_answer_edition
    answer = AnswerEdition.create(:slug => "childcare", :title => "Something", :body => 'Lots of info', :state => 'ready', :panopticon_id => 123)
    answer.publish
    answer.save
    answer
  end

  def expect_update(incoming_path)
    @router_client.routes.expects(:update).with(
      application_id: "frontend",
      route_type: :full,
      incoming_path: incoming_path
    )
  end

  test "RouterBridge.register_all will register homepage" do
    expect_update("/")

    router_bridge = RouterBridge.new(router: @router_client, logger: NullLogger.instance)
    router_bridge.register_all
  end

  test "RouterBridge.register_all will register all publications" do
    a_publication = stub("a publication", 
      slug: "a-publication", 
      title: "A publication", 
      is_a?: false)
    Edition.stubs(:published).returns([a_publication])
    @router_client.routes.stubs(:update)

    expect_update("/a-publication")
    expect_update("/a-publication.json")
    expect_update("/a-publication.xml")

    router_bridge = RouterBridge.new(router: @router_client, logger: NullLogger.instance)
    router_bridge.register_all
  end

  test "RouterBridge.register_all will register .kml for PlaceEdition" do
    a_places_edition = stub("a places edition",
      slug: "a-places-edition",
      title: "A places edition"
    )
    a_places_edition.expects(:is_a?).with(GuideEdition).returns(false)
    a_places_edition.expects(:is_a?).with(ProgrammeEdition).returns(false)
    a_places_edition.expects(:is_a?).with(LocalTransactionEdition).returns(false)
    a_places_edition.expects(:is_a?).with(PlaceEdition).returns(true)
    Edition.stubs(:published).returns([a_places_edition])
    @router_client.routes.stubs(:update)

    expect_update("/a-places-edition")
    expect_update("/a-places-edition.json")
    expect_update("/a-places-edition.xml")
    expect_update("/a-places-edition.kml")

    router_bridge = RouterBridge.new(router: @router_client, logger: NullLogger.instance)
    router_bridge.register_all
  end
end
