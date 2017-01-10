class RemoveFromSearch
  attr_reader :base_path

  def self.call(slug)
    new(slug).call
  end

  def initialize(slug)
    @base_path = "/#{slug}"
  end

  def call
    with_error_handling do
      Services.rummager.delete_content!(base_path)
    end
  end

  def with_error_handling(&_block)
    begin
      tries ||= 2
      yield
    rescue => exception
      if (tries -= 1).zero?
        Airbrake.notify_or_ignore(
          exception,
          parameters: { failed_base_path: base_path }
        )
      else
        retry
      end
    end
  end
end
