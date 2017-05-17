module DowntimesHelper
  def downtime_datetime(downtime)
    start_time = downtime.start_time
    end_time = downtime.end_time
    time_format = '%l:%M%P'
    date_format = 'on %e %B'
    datetime_format = "#{time_format} #{date_format}"

    strings = if start_time.to_date == (end_time - 1.second).to_date
                ["#{start_time.strftime(time_format).strip} to #{end_time.strftime(time_format).strip}"] << start_time.strftime(date_format)
              else
                ["#{start_time.strftime(datetime_format).strip} to #{end_time.strftime(datetime_format).strip}"]
              end

    strings.join(' ').gsub(':00', '').gsub('12pm', 'midday').gsub('12am', 'midnight')
  end
end
