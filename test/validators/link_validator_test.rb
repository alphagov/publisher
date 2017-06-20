# encoding: UTF-8

require 'test_helper'

class LinkValidatorTest < ActiveSupport::TestCase
  class Dummy
    include Mongoid::Document

    field "body", type: String
    field "assignee", type: String
    GOVSPEAK_FIELDS = [:body]

    validates_with LinkValidator
  end

  context "links" do
    should "not be verified for blank govspeak fields" do
      doc = Dummy.new(body: nil)

      assert_nothing_raised do
        doc.valid?
      end
      assert_empty doc.errors
    end

    should "not contain empty array for errors on fields" do
      doc = Dummy.new(body: "Nothing is invalid")

      assert doc.valid?
      assert_empty doc.errors[:body]
    end

    should "start with http[s]://, mailto: or /" do
      doc = Dummy.new(body: "abc [external](external.com)")
      assert doc.invalid?
      assert_includes doc.errors.keys, :body

      doc = Dummy.new(body: "abc [external](http://external.com)")
      assert doc.valid?

      doc = Dummy.new(body: "abc [internal](/internal)")
      assert doc.valid?
    end

    should "not contain hover text" do
      doc = Dummy.new(body: 'abc [foobar](http://foobar.com "hover")')
      assert doc.invalid?
      assert_includes doc.errors.keys, :body
    end

    should "validate smart quotes as normal quotes" do
      doc = Dummy.new(body: %q<abc [foobar](http://foobar.com “hover”)>)
      assert doc.invalid?
      assert_includes doc.errors.keys, :body
    end

    should "not set rel=external" do
      doc = Dummy.new(body: 'abc [foobar](http://foobar.com){:rel="external"}')
      assert doc.invalid?
      assert_includes doc.errors.keys, :body
    end

    should "show multiple errors" do
      doc = Dummy.new(body: 'abc [foobar](foobar.com "bar"){:rel="external"}')
      assert doc.invalid?
      assert_equal 3, doc.errors[:body].first.length
    end

    should "only show each error once" do
      doc = Dummy.new(body: 'abc [link1](foobar.com), ghi [link2](bazquux.com)')
      assert doc.invalid?
      assert_equal 1, doc.errors[:body].first.length
    end

    should "be validated when any attribute of the document changes" do
      # already published document having link validation errors
      doc = Dummy.new(body: 'abc [link1](foobar.com), ghi [link2](bazquux.com)')
      doc.save(validate: false)

      doc.assignee = "4fdef0000000000000000001"
      assert doc.invalid?

      assert_equal 1, doc.errors[:body].first.length
    end
  end
end
