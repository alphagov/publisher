require "test_helper"
require_relative "prerendered_entity_tests"

class RenderedManualTest < ActiveSupport::TestCase
  include PrerenderedEntityTests

  def model_class
    RenderedManual
  end
end
