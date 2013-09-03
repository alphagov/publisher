require 'csv'
require 'exception_notifier'
require 'redis'
require 'redis-lock'

class LocalAuthorityDataImporter

  def self.update_all
    redis.lock("publisher:#{Rails.env}:local_authority_data_importer_lock", :life => 2.hours) do
      begin
        LocalServiceImporter.update
        LocalInteractionImporter.update
        LocalContactImporter.update
        nagios_check(true, "Import succeeded")
      rescue Exception => e
        nagios_check(false, e.to_s)

        # re-raise the exception so that it ends up in the logs
        # and we allow through SyntaxError, Interrupt and SignalException
        raise e
      end
    end
  rescue Redis::Lock::LockNotAcquired => e
    Rails.logger.debug("Failed to get lock for local directgov importing (#{e.message}). Another process probably got there first.")

    # Flag nagios that this servers instance succeeded to stop lingering failures
    nagios_check(true, "Importer not run on this instance")
  end

  def self.redis
    redis_config = YAML.load_file(Rails.root.join("config", "redis.yml"))
    Redis.new(redis_config.symbolize_keys)
  end

  def self.nagios_check(success, message)
    code = if success then 0 else 1 end
    `local_authority_import_check #{code} "#{message}"`
  end

  def self.update
    fh = fetch_data
    begin
      new(fh).run
    ensure
      fh.close
    end
  end

  def self.fetch_http_to_file(url)
    fh = Tempfile.new(['local_authority_data', 'csv'])
    fh.set_encoding('ascii-8bit')

    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)

    if response.code != "200"
      raise "HTTP Fetch failed [#{response.code}]: #{url}"
    end

    fh.write response.body

    fh.rewind
    fh.set_encoding('windows-1252', 'UTF-8')
    fh
  end

  def initialize(fh)
    @filehandle = fh
  end

  def run
    CSV.new(@filehandle, headers: true).each do |row|
      begin
        process_row(row)
      rescue => e
        Rails.logger.error "Error #{e.class} processing row in #{self.class}\n#{e.backtrace.join("\n")}"
        ExceptionNotifier::Notifier.background_exception_notification(e, :data => {:row => row})
      end
    end
  end
end
