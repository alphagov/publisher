# TODO: Pull this out into Plek
module ExternalServices

  def local_environment
    ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'
  end

  def api_host
    case local_environment
    when 'development','test'
      "publisher.dev.gov.uk"
    when 'production'
       "api.alpha.gov.uk"
    else
       "guides.#{local_environment}.alphagov.co.uk:8080"
    end
  end

  def front_end_host
    case local_environment
    when 'development','test'
      "http://www.dev.gov.uk"
    when 'production'
      "http://frontend.alpha.gov.uk"
    when 'staging'
      "http://demo.alphagov.co.uk"
    else
      "http://frontend.#{local_environment}.alphagov.co.uk:8080"
    end
  end

  def asset_host
    case local_environment
    when 'development','test'
      ""
    when 'production'
      "http://alpha.gov.uk"
    else
      "http://#{local_environment}.alphagov.co.uk:8080"
    end
  end

  def imminence_api_host
    case local_environment
    when 'development','test'
      "imminence.dev.gov.uk"
    when 'production'
      "imminence.alpha.gov.uk"
    else
      "imminence.#{local_environment}.alphagov.co.uk:8080"
    end
  end

  extend self
end


