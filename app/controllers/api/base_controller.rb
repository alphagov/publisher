module Api
  class BaseController < ApplicationController
    skip_forgery_protection

    before_action { authorise_user!("internal_app") }
  end
end
