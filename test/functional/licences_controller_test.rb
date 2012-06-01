require 'test_helper'

class LicencesControllerTest < ActionController::TestCase
  #def build_publication
    #GuideEdition.create!(slug: "childcare", title: 'Something distinctive', panopticon_id: 1)
  #end

  #def build_published_publication
    #build_publication.tap { |p|
      #p.state = 'ready'
      #p.publish
    #}
  #end

  context "index" do
    setup do
      @l1 = FactoryGirl.create(:licence_edition, :licence_identifier => "ab12", :state => 'published')
      @l2 = FactoryGirl.create(:licence_edition, :licence_identifier => "2345", :state => 'published')
      @l3 = FactoryGirl.create(:licence_edition, :licence_identifier => "2346", :state => 'published')
      
    end

    should "return id, slug, title, and short description for selected licences" do
      get :index, :format => :json, :ids => "ab12,2345,2346"
      results = ActiveSupport::JSON.decode(response.body)

      licences = [@l1, @l2, @l3]
      ids = results.map {|r| r['licence_identifier'] }
      slugs = results.map {|r| r['slug'] }
      titles = results.map {|r| r['title'] }
      short_descriptions = results.map {|r| r['short_description'] }

      assert_equal licences.map(&:licence_identifier).sort, ids.sort
      assert_equal licences.map(&:slug).sort, slugs.sort
      assert_equal licences.map(&:title).sort, titles.sort
      assert_equal licences.map(&:licence_short_description).sort, short_descriptions.sort
    end

    should "only return details for published licences" do
      @l2.state = 'draft'
      @l2.save!

      get :index, :format => :json, :ids => "ab12,2345,2346"
      results = ActiveSupport::JSON.decode(response.body)

      licences = [@l1, @l3]
      ids = results.map {|r| r['licence_identifier'] }

      assert_equal licences.map(&:licence_identifier).sort, ids.sort
    end

    should "return empty list if no query param" do
      get :index, :format => :json
      assert_equal [], ActiveSupport::JSON.decode(response.body)
    end
  end
end
