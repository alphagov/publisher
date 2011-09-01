module FrontEndEnvironment

  def environment
    ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'
  end

  def api_host
    case environment 
    when 'development','test'
      "local.alphagov.co.uk:3000"
    when 'production'
       "api.alpha.gov.uk"
    else
       "guides.#{environment}.alphagov.co.uk:8080"
    end
  end

  def asset_host
    case environment
    when 'development','test'
      ""
    when 'production'
      "http://alpha.gov.uk"
    else
      "http://#{environment}.alphagov.co.uk:8080"
    end
  end

  def imminence_api_host
    case environment
    when 'development','test'
      "local.alphagov.co.uk:3002"
    when 'production'
      "imminence.alpha.gov.uk"
    else
      "imminence.#{environment}.alphagov.co.uk:8080"
    end
  end

  extend self
end


