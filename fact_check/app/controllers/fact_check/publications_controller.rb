module FactCheck
  class PublicationsController < ApplicationController
    def index
      @edition = Edition.last
    end
  end
end
