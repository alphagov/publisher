PANOPTICON_HOST = case Rails.env.to_s
when 'development' then 'http://local.alphagov.co.uk:3001'
when 'staging' then 'http://panopticon.staging.alphagov.co.uk:8080'
end