# frozen_string_literal: true

class RootController < ApplicationController
  layout "design_system"

  def index
    @presenter = FilteredEditionsPresenter.new
  end
end
