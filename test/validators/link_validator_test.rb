require "test_helper"

class LinkValidatorTest < ActiveSupport::TestCase
  context "links" do
    should "not be verified for blank govspeak fields" do
      edition = FactoryBot.create(:answer_edition)

      assert_nothing_raised do
        edition.update!(body: nil)
      end
      assert_empty edition.errors
    end

    should "not contain any errors when valid" do
      edition = FactoryBot.create(:answer_edition)
      edition.update!(body: "Nothing is invalid")

      assert edition.valid?
      assert_empty edition.errors[:body]
    end

    should "start with http[s]://, mailto: or /" do
      edition = FactoryBot.create(:answer_edition)

      assert_not edition.update(body: "abc [external](external.com)")
      assert edition.invalid?
      assert_includes edition.errors.attribute_names, :body

      edition.update!(body: "abc [external](http://external.com)")
      assert edition.valid?

      edition.update!(body: "abc [internal](/internal)")
      assert edition.valid?
    end

    should "not contain hover text" do
      edition = FactoryBot.create(:answer_edition)
      assert_not edition.update(body: 'abc [foobar](http://foobar.com "hover")')

      assert edition.invalid?
      assert_includes edition.errors.attribute_names, :body
    end

    should "validate smart quotes as normal quotes" do
      edition = FactoryBot.create(:answer_edition)
      assert_not edition.update(body: "abc [foobar](http://foobar.com “hover”)")

      assert edition.invalid?
      assert_includes edition.errors.attribute_names, :body
    end

    should "not set rel=external" do
      edition = FactoryBot.create(:answer_edition)
      assert_not edition.update(body: 'abc [foobar](http://foobar.com){:rel="external"}')

      assert edition.invalid?
      assert_includes edition.errors.attribute_names, :body
    end

    should "show multiple errors" do
      edition = FactoryBot.create(:answer_edition)
      assert_not edition.update(body: 'abc [foobar](foobar.com "bar"){:rel="external"}')

      assert edition.invalid?
      assert_equal 3, edition.errors.count
    end

    should "only show each error once" do
      edition = FactoryBot.create(:answer_edition)
      assert_not edition.update(body: "abc [link1](foobar.com), ghi [link2](bazquux.com)")

      assert edition.invalid?
      assert_equal 1, edition.errors.count
    end
  end
end
