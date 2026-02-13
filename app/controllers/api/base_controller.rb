module Api
  class BaseController < ApplicationController
    skip_forgery_protection
  end
end
