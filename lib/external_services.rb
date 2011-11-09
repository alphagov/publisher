# TODO: Pull this out into Plek
module ExternalServices

  def local_environment
    ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'
  end

  def api_host
    Plek.current.find("publisher")
    #case local_environment
    #when 'development','test'
    #  "publisher.dev.gov.uk"
    #when 'production'
    #   "api.alpha.gov.uk"
    #else
    #   "guides.#{local_environment}.alphagov.co.uk:8080"
    #end
  end

  def front_end_host
    Plek.current.find("frontend")
    #case local_environment
    #when 'development','test'
    #  "http://www.dev.gov.uk"
    #when 'production'
    #  "http://www.production.alphagov.co.uk"
    #when 'staging'
    #  "http://demo.alphagov.co.uk"
    #else
    #  "http://www..#{local_environment}.alphagov.co.uk"
    #end
  end

  def asset_host
    Plek.current.find("static")
    #case local_environment
    #when 'development','test'
    #  ""
    #when 'production'
    #  "http://static.production.alphagov.co.uk"
    #else
    #  "http://#{local_environment}.alphagov.co.uk:8080"
    #end
  end

  def imminence_api_host
    Plek.current.find("data")
    #case local_environment
    #when 'development','test'
    #  "imminence.dev.gov.uk"
    #when 'production'
    #  "imminence.production.alpha.gov.uk"
    #else
    #  "imminence.#{local_environment}.alphagov.co.uk:8080"
    #end
  end

  extend self
end


