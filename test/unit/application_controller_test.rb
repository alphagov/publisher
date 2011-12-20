require 'test_helper'

class ApplicationControllerTest < Test::Unit::TestCase

  class AbstractTestClass < ApplicationController
    public :local_request?
    attr_accessor :request
  end

  def concrete_test_class
    Class.new(AbstractTestClass)
  end

  def test_request_should_be_local_when_ip_address_is_127_0_0_1
    controller = concrete_test_class.new
    controller.request = mock(ip: "127.0.0.1")
    assert controller.local_request?
  end

  def test_request_should_be_local_when_ip_address_is_1
    controller = concrete_test_class.new
    controller.request = mock(ip: "::1")
    assert controller.local_request?
  end

  def test_request_should_be_local_when_ip_address_is_same_as_socket_address
    Socket.stubs(:ip_address_list).returns([Addrinfo.ip("9.8.7.6")])
    controller = concrete_test_class.new
    controller.request = mock(ip: "9.8.7.6")
    assert controller.local_request?
  end

  def test_request_should_not_be_local_for_other_ip_addresses
    controller = concrete_test_class.new
    controller.request = mock(ip: "9.8.7.6")
    assert !controller.local_request?
  end
end
