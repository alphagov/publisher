require 'test_helper'

class MarplesTestDouble
  def initialize
    @listeners = []
  end

  def when(application, object_type, action, &block)
    @listeners << [application, object_type, action, block]
  end

  def publish(application, object_type, action, object)
    @listeners.select { |listener| listener_matches?(listener, [application, object_type, action]) }.each { |listener| listener[3].call(object) }
  end

  def listener_matches?(listener, message)
    message.each_index.all? do |i|
      listener[i] == '*' || listener[i] == message[i]
    end
  end

  def join
  end
end

class RouterBridgeTest < ActiveSupport::TestCase
  def setup
    routes = stub("routes")
    @router_client = stub("router", routes: routes)
    @marples_client = MarplesTestDouble.new
  end

  def create_answer_edition
    answer = AnswerEdition.create(:slug => "childcare", :title => "Something", :body => 'Lots of info', :state => 'ready', :panopticon_id => 123)
    answer.publish
    answer.save
    answer
  end

  test "when marples receives a published message, create a route" do
    edition = create_answer_edition()

    @router_client.routes.expects(:update).with(
        application_id: "frontend",
        incoming_path: "/#{edition['slug']}",
        route_type: :full
    )
    @router_client.routes.expects(:update).with(
        application_id: "frontend",
        incoming_path: "/#{edition['slug']}.json",
        route_type: :full
    )
    @router_client.routes.expects(:update).with(
        application_id: "frontend",
        incoming_path: "/#{edition['slug']}.xml",
        route_type: :full
    )
    RouterBridge.new(:router => @router_client, :marples_client => @marples_client, logger: NullLogger.instance).run
    @marples_client.publish("publisher", "guide_edition", "published", edition)
  end

  test "RouterBridge.register_all will register homepage" do
    @router_client.routes.expects(:update).with(
      application_id: "frontend",
      route_type: :full,
      incoming_path: "/"
    )
    router_bridge = RouterBridge.new(router: @router_client, marples_client: stub_everything(:marples_client), logger: NullLogger.instance)
    router_bridge.register_all
  end

  test "RouterBridge.register_all will register all publications" do
    a_publication = stub("a publication", 
      slug: "a-publication", 
      title: "A publication", 
      is_a?: false)
    Edition.stubs(:published).returns([a_publication])
    @router_client.routes.stubs(:update)
    @router_client.routes.expects(:update).with(
      application_id: "frontend",
      route_type: :full,
      incoming_path: "/a-publication"
    )
    @router_client.routes.expects(:update).with(
      application_id: "frontend",
      route_type: :full,
      incoming_path: "/a-publication.json"
    )
    @router_client.routes.expects(:update).with(
      application_id: "frontend",
      route_type: :full,
      incoming_path: "/a-publication.xml"
    )

    router_bridge = RouterBridge.new(router: @router_client, marples_client: stub_everything(:marples_client), logger: NullLogger.instance)
    router_bridge.register_all
  end
end
