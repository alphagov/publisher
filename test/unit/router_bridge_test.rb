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
    RouterBridge.new(@router_client, env: @env).run(@marples_client)
    @marples_client.publish("publisher", "guide", "published", publication)
  end
end
