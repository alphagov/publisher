require 'test_helper'

class FactCheckMailTest < ActiveSupport::TestCase
  def email
    Mail.new do
      from    'foo@example.com'
      to      'fact-check@gov.uk'
      subject 'This is a fact check response'
      body    'I like it. Good work!'
    end
  end

  def email_with_header(key, value)
    e = email
    e[key] = value
    FactCheckMail.new(e)
  end

  [
    ['Auto-Submitted', 'auto-replied'],
    ['Auto-Submitted', 'auto-generated'],
    ['Precedence', 'bulk'],
    ['Precedence', 'auto_reply'],
    ['Precedence', 'junk'],
    ['Return-Path', nil],
    ['Subject', 'Out of Office'],
    ['X-Precedence', 'bulk'],
    ['X-Precedence', 'auto_reply'],
    ['X-Precedence', 'junk'],
    ['X-Autoreply', 'yes'],
    ['X-Autorespond', nil],
    ['X-Auto-Response-Suppress', nil]
  ].each do |key, value|
    should "return true when email is out of office with #{key} header set to #{value}" do
      assert email_with_header(key, value).out_of_office?
    end
  end

  [
    ['Auto-Submitted', 'no'],
    ['Precedence', 'foo'],
    ['Subject', 'On holiday'],
    ['X-Precedence', 'bar'],
    ['X-Autoreply', 'no'],
  ].each do |key, value|
    should "return false when the #{key} header isn't an auto-reply value" do
      refute email_with_header(key, value).out_of_office?
    end
  end

  should "Return Mail::Field class if the header is present" do
    assert_equal Mail::Field, email['From'].class
  end

  should "Return NilClass class if the header is not present" do
    assert_equal NilClass, email['X-Some-Radom-Header'].class
  end
end
