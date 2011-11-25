require 'test_helper'

require 'stomp'

class MarplesTestDouble
  def initialize
    @listeners = []
  end
  
  def when(application, object_type, action, &block)
    @listeners << [application, object_type, action, block]
  end
  
  def publish(application, object_type, action, object)
    @listeners
      .select { |listener| listener_matches?(listener, [application, object_type, action]) }
      .each { |listener| listener[3].call(object) }
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
    @routes = stub("routes")
    @applications = stub("applications")
    @applications.stubs(:create)
    @router_client = stub("router", routes: @routes, applications: @applications)
    @marples_client = MarplesTestDouble.new
    @platform = "__TEST_PLATFORM__"
    @env = { 'FACTER_govuk_platform' => @platform }
  end
  
  test "when starting to listen, registers publisher application to the router" do
    @router_client.applications.expects(:create).with(
      application_id: "frontend",
      backend_url: "frontend.#{@platform}.alphagov.co.uk/"
    )
    RouterBridge.new(@router_client, env: @env).listen(@marples_client)
  end

  test "when marples receives a published message, create a route" do
    publication = {
      slug: 'my-test-slug'
    }
    @router_client.routes.expects(:create).with(
      application_id: "frontend",
      incoming_path: "/#{publication[:slug]}",
      route_type: :full
    )
    RouterBridge.new(@router_client, env: @env).listen(@marples_client)
    @marples_client.publish("publisher", "guide", "published", publication)
  end
  
  test "register_publications will register routes for all published publications" do
    publications = (1..3).map do |i|
      stub("p#{i}", attributes: {slug: "p#{i}"})
    end
    Publication.stubs(:published).returns(publications)
    registration = sequence('registration')
    publications.each do |p|
      @router_client.routes.expects(:create).with(
        application_id: "frontend",
        incoming_path: "/#{p.attributes[:slug]}",
        route_type: :full
      ).in_sequence(registration)
    end
    router_bridge = RouterBridge.new(@router_client, env: @env)
    router_bridge.register_publications
  end
end
