require 'test_helper'
require 'mail_fetcher_config'
require 'mail'

class MailFetcherConfigTest < ActiveSupport::TestCase
  # Because the `defaults` method on `Mail` calls `instance_eval` with a block,
  # we need to have a stub class to test what that block does without relying
  # too heavily on the internals of `Mail` in our tests.
  class StubMail
    def defaults(&block)
      instance_eval(&block)
    end
  end

  setup do
    @env_run_fact_check_fetcher = ENV["RUN_FACT_CHECK_FETCHER"]
    ENV["RUN_FACT_CHECK_FETCHER"] = "1"
  end

  teardown do
    ENV["RUN_FACT_CHECK_FETCHER"] = @env_run_fact_check_fetcher
  end

  should "raise an error if given strings as keys" do
    assert_raises ArgumentError do
      MailFetcherConfig.new("user_name" => "bob@example.com")
    end
  end

  should "configure email settings when activated" do
    mail = StubMail.new
    mail.expects(:retriever_method).with(:imap, user_name: "bob@example.com")
    MailFetcherConfig.new(user_name: "bob@example.com").configure(mail)
  end

  should "configure the Mail module if not given an explicit argument" do
    Mail.expects(:defaults).once
    MailFetcherConfig.new(user_name: "bob@example.com").configure
  end

  should "not configure email settings if given an empty hash" do
    mail = StubMail.new
    mail.expects(:defaults).never
    MailFetcherConfig.new({}).configure(mail)
  end

  should "not configure email settings if RUN_FACT_CHECKER_FETCHER is not set" do
    mail = StubMail.new
    mail.expects(:defaults).never
    ENV.delete("RUN_FACT_CHECK_FETCHER")
    MailFetcherConfig.new(user_name: "bob@example.com").configure(mail)
  end
end
