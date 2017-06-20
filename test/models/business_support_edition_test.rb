# encoding: utf-8
require_relative "../test_helper"

class BusinessSupportEditionTest < ActiveSupport::TestCase
  def setup
    @artefact = FactoryGirl.create(:artefact)
  end

  should "have custom fields" do
    support = FactoryGirl.create(
      :business_support_edition,
      panopticon_id: @artefact.id,
      short_description: "The short description",
      body: "The body",
      eligibility: "The eligibility",
      evaluation: "The evaluation",
      additional_information: "The additional information",
      min_value: 1000,
      max_value: 3000,
      max_employees: 2000,
      organiser: "The business support people",
      continuation_link: "http://www.gov.uk",
      will_continue_on: "The GOVUK website",
      contact_details: "123 The Street, Townsville, UK. 07324 123456",
      priority: 2,
      area_gss_codes: %w(G123 G345 G45 G9),
      locations: %w(scotland england),
      sectors: %w(education manufacturing),
      support_types: %w(grant loan),
      start_date: Date.parse("1 Jan 2000"),
      end_date: Date.parse("1 Jan 2020"),
    )

    support.business_sizes << "up-to-249"
    support.business_types << "charity"
    support.purposes << "making-the-most-of-the-internet"
    support.stages << "start-up"

    assert_equal "The short description", support.short_description
    assert_equal "The body", support.body
    assert_equal "The eligibility", support.eligibility
    assert_equal "The evaluation", support.evaluation
    assert_equal "The additional information", support.additional_information
    assert_equal 1000, support.min_value
    assert_equal 3000, support.max_value
    assert_equal 2000, support.max_employees
    assert_equal "The business support people", support.organiser
    assert_equal "http://www.gov.uk", support.continuation_link
    assert_equal "The GOVUK website", support.will_continue_on
    assert_equal "123 The Street, Townsville, UK. 07324 123456", support.contact_details

    assert_equal 2, support.priority

    assert_equal %w(G123 G345 G45 G9), support.area_gss_codes
    assert_equal ["up-to-249"], support.business_sizes
    assert_equal ["charity"], support.business_types
    assert_equal %w(scotland england), support.locations
    assert_equal ["making-the-most-of-the-internet"], support.purposes
    assert_equal %w(education manufacturing), support.sectors
    assert_equal ["start-up"], support.stages
    assert_equal %w(grant loan), support.support_types
    assert_equal Date.parse("1 Jan 2000"), support.start_date
    assert_equal Date.parse("1 Jan 2020"), support.end_date
  end

  should "not allow max_value to be less than min_value" do
    support = FactoryGirl.create(
      :business_support_edition,
      panopticon_id: @artefact.id,
    )
    support.min_value = 100
    support.max_value = 50

    refute support.valid?
  end

  context "numeric field validations" do
    # https://github.com/mongoid/mongoid/issues/1735 Really Mongoid‽
    [
      :min_value,
      :max_value,
      :max_employees,
    ].each do |field|
      should "require an integer #{field}" do
        @support = FactoryGirl.build(:business_support_edition)
        [
          'sadfsadf',
          '100,000',
          1.23,
        ].each do |value|
          @support.send("#{field}=", value)
          refute @support.valid?
          assert_equal 1, @support.errors[field].count
        end

        @support.send("#{field}=", "100")
        @support.save!
        s = BusinessSupportEdition.find(@support.id)
        assert_equal 100, s.send(field)

        @support.send("#{field}=", "")
        @support.save!
        s = BusinessSupportEdition.find(@support.id)
        assert_nil s.send(field)
      end
    end
  end

  context "continuation_link validation" do
    setup do
      @bs = FactoryGirl.create(
        :business_support_edition,
        panopticon_id: @artefact.id,
      )
    end

    should "not validate the continuation link when blank" do
      @bs.continuation_link = ""
      assert @bs.valid?, "continuation link validation should not be triggered when the field is blank"
    end
    should "fail validation when the continuation link has an invalid url" do
      @bs.continuation_link = "not&a+valid_url"
      assert !@bs.valid?, "continuation link validation should fail with a invalid url"
    end
    should "pass validation with a valid continuation link url" do
      @bs.continuation_link = "http://www.hmrc.gov.uk"
      assert @bs.valid?, "continuation_link validation should pass with a valid url"
    end
  end

  context "for facets" do
    setup do
      @e1 = FactoryGirl.create(
        :business_support_edition,
        area_gss_codes: %w(G2345 G1234),
        business_sizes: ['1', 'up-to-1000000'],
        locations: ['narnia'],
        purposes: ['world-domination'],
        sectors: %w(agriculture healthcare),
        stages: ['pivoting'],
        support_types: %w(award grant loan),
      )
      @e2 = FactoryGirl.create(
        :business_support_edition,
        area_gss_codes: %w(G1212 G1234 G999),
        business_sizes: ['1', 'up-to-1000000'],
        locations: %w(hades narnia),
        purposes: ['business-growth-and-expansion'],
        sectors: %w(education healthcare),
        stages: ['start-up', 'pivoting'],
        support_types: %w(grant loan equity),
      )
      @e3 = FactoryGirl.create(
        :business_support_edition,
        area_gss_codes: ['G1234'],
        business_sizes: ['up-to-249', 'up-to-1000000'],
        locations: ['hades', 'chicken-town'],
        purposes: ['making-the-most-of-the-internet'],
        sectors: ['utilities'],
        stages: ['start-up'],
        support_types: ['grant'],
      )
    end

    should "only return editions matching the facet values provided" do
      editions = BusinessSupportEdition.for_facets(purposes: 'business-growth-and-expansion',
        support_types: 'equity')
      assert_equal [@e2], editions
      editions = BusinessSupportEdition.for_facets(business_sizes: '1,up-to-1000000',
        locations: 'narnia')
      assert_equal [@e1, @e2], editions
    end
    should "support searching with all the facet values" do
      editions = BusinessSupportEdition.for_facets(area_gss_codes: 'G1234',
        business_sizes: 'up-to-1000000',
        locations: 'narnia,hades,chicken-town',
        purposes: 'business-growth-and-expansion,making-the-most-of-the-internet,world-domination',
        sectors: 'agriculture,healthcare,utilities',
        stages: 'pivoting,start-up',
        support_types: 'award,grant,loan')
      assert_equal [@e1, @e2, @e3], editions
    end
    should "return nothing where no facet values match" do
      editions = BusinessSupportEdition.for_facets(business_sizes: 'up-to-a-bizillion',
        locations: 'ecclefechan')
      assert_empty editions
    end
  end

  context "scheme dates" do
    should "should have year with 4 digits length" do
      invalid_edition = FactoryGirl.build(
        :business_support_edition,
        start_date: Date.new(99, 12, 31),
        end_date: Date.new(99, 12, 31),
      )

      refute invalid_edition.valid?

      edition_errors = invalid_edition.errors.full_messages
      assert_includes edition_errors, "Start date year must be 4 digits"
      assert_includes edition_errors, "End date year must be 4 digits"
    end

    should "have start date earlier than end date" do
      invalid_edition = FactoryGirl.build(
        :business_support_edition,
        start_date: 1.week.ago,
        end_date: 2.weeks.ago,
      )

      refute invalid_edition.valid?
      assert_includes invalid_edition.errors.full_messages, "Start date can't be later than end date"
    end
  end
end
