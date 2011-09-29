require 'panopticon_api'

PanopticonApi.endpoint = case Rails.env.to_s
when 'development' then ENV['PANOPTICON_URI'] || 'http://panopticon.dev.gov.uk'
when 'test' then 'http://panopticon.dev.gov.uk'
when 'staging' then 'http://panopticon.staging.alphagov.co.uk:8080'
end
