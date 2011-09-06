require 'test_helper'
require 'capybara/rails'

class MockImminence

  def initialize(app)
    @app = app
  end

  def call(env)
    if env['PATH_INFO'] == '/places/registry-offices.json'
      return [ 200, {}, "[]" ]
    else
      @app.call(env)
    end
  end
end

Capybara.default_driver = :selenium
Capybara.server_port = 3000
Capybara.app = Rack::Builder.new do 
  map "/" do
    use MockImminence
    run Capybara.app
  end
end

class PreviewsTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
  
  def teardown
    DatabaseCleaner.clean
  end

  def setup_users
    @author ||= User.create(:name=>"Author",:email=>"test@example.com") 
    @reviewer ||= User.create(:name=>"Reviewer",:email=>"test@example.com")
  end
  
  def setup_place_thing(random_name)
    setup_users
    
    without_panopticon_validation do
      @place = @author.create_place(:name => random_name, :slug => 'test-place')
      @place.editions.first.title = random_name
      @place.editions.first.introduction = 'Body text'
      @place.editions.first.more_information = 'More body text'
      @place.editions.first.place_type = 'registry-offices'
      
      @place.save
    end
    
    return @place
  end
    
  def publish_answer(random_name)
    setup_users
    
    without_panopticon_validation do
      @answer = @author.create_answer(:name => random_name, :slug => 'test-answer')
      @answer.editions.first.title = random_name
      @answer.editions.first.body = 'Body text'
      @answer.save
    
      @author.request_review(@answer.editions.first, '')
      @reviewer.okay(@answer.editions.first, '')
      @author.publish(@answer.editions.first, 'Done')
      @answer.calculate_statuses
      @answer.save
    end
    
    return @answer
  end

  def random_string(length,suffix="")
    random_name = (0...length).map{65.+(rand(25)).chr}.join + suffix
  end

  # test "Creating and previewing a place thing" do
  #   random_name = random_string(8," GUIDE") 
  #   thing = setup_place_thing(random_name)
  #   
  #   visit "/admin"
  #   click_on 'Edit this publication'
  #   within(:css, '#guide-controls') { 
  #     click_on 'Preview'
  #   }
  # 
  #   assert page.has_content? random_name
  #       
  #   visit "/preview/#{thing.editions.first.version_number}/#{thing.slug}?postcode=EC2A+4AA"
  #   assert page.has_content? random_name
  #   sleep(30)
  # end
    
  test "Creating and previewing an answer second edition" do
    random_name = random_string(8," GUIDE") 
    answer = publish_answer(random_name)
    
    @author.new_version(answer.editions.first)
    answer.save
    
    visit "/admin"
    click_on 'Edit this publication'
    within(:css, '#guide-controls') { 
      click_on 'Preview'
    }
    assert page.has_content? random_name
  end
end