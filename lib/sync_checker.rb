require 'gds_api/content_store'

class SyncChecker
  class Success
    attr_reader :base_path

    def initialize(base_path:, content_store:)
      @base_path = base_path
      @content_store = content_store
    end

    def to_s
      "✅  #{@base_path} in #{@content_store}"
    end
  end

  class NotFoundFailure
    attr_reader :base_path, :content_store

    def initialize(base_path:, content_store:)
      @base_path = base_path
      @content_store = content_store
    end

    def to_s
      "❌  Failed path: #{base_path} in #{content_store}, failed expectations: Not found\n\n"
    end
  end

  class Failure
    attr_reader :edition, :content_item, :base_path, :failed_expectations, :content_store

    def initialize(edition:, content_item:, base_path:, failed_expectations:, content_store:)
      @edition = edition
      @content_item = content_item
      @base_path = base_path
      @failed_expectations = failed_expectations
      @content_store = content_store
    end

    def to_s
      str = "😡  Failed path: #{base_path} in #{content_store}, failed expectations: #{failed_expectations.join(', ')}"
      str << "\nExpected: #{filter_attributes(presented_edition)}"
      str << "\nActual: #{filter_attributes(content_item)}" if content_item
      str << "\n\n"
      str
    end

  private

    def filter_attributes(attrs)
      hash = attrs.symbolize_keys.select { |a| meaningful_attributes.include?(a) }
      Hash[hash.sort]
    end

    def meaningful_attributes
      %i(schema_name document_format title public_updated_at)
    end

    def presented_edition
      presenter = EditionPresenterFactory.get_presenter(edition)
      presenter.render_for_publishing_api
    end
  end


  def initialize(scope, store_string)
    @scope = scope
    @store_string = store_string
    @expectations = []
  end

  attr_reader :store_string, :expectations

  def add_expectation(description, &block)
    expectations << { description: description, block: block }
  end

  def call
    @scope.each do |edition|
      result = check(edition)
      puts result.to_s
    end
  end

private

  def check(edition)
    base_path = "/#{edition.slug}"
    response = content_store.content_item(base_path)

    content_item = response.to_h
    compare_content(content_item, edition, base_path)
  rescue GdsApi::HTTPErrorResponse
    NotFoundFailure.new(
      base_path: base_path,
      content_store: store_string
    )
  end

  def compare_content(content_item, edition, base_path)
    failed_expectations = expectations.reject do |expectation|
      expectation[:block].call(content_item, edition)
    end

    if failed_expectations.empty?
      Success.new(base_path: base_path, content_store: store_string)
    else
      failed_expectation_descriptions = failed_expectations.map { |expectation| expectation[:description] }
      Failure.new(
        edition: edition,
        content_item: content_item,
        base_path: base_path,
        failed_expectations: failed_expectation_descriptions,
        content_store: store_string
      )
    end
  end

  def content_store
    GdsApi::ContentStore.new(Plek.find(store_string))
  end
end
