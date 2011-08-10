class RootController < ApplicationController
  def index
    @items = Publication.published.all.collect(&:published_edition).sort_by(&:title)
  end
end
