module FactCheck
  class PublicationsController < ApplicationController
    def index
      @edition = Edition.find_by(id: "bbec7a91-88aa-4f15-b286-22f9b6b8a436")
    end
  end
end
