require 'test_helper'

class PublicationListenerTest < ActiveSupport::TestCase

  def test_should_find_matching_publication_and_post_to_rummager
    stub_request(:get, %r{^http://panopticon\.test\.gov\.uk/.*}).
      to_return(:status => 200, :body => "{}", :headers => {})

    guide = FactoryGirl.create(:guide) 
    message = stub(
      body: {"_id" => guide.id}.to_xml,
      headers: {"message-id" => "123"}
    )
    stomp_client = stub(join: nil, close: nil, acknowledge: nil)
    stomp_client.expects(:subscribe).yields(message)

    Rummageable.expects(:index).with(guide.search_index)

    PublicationListener.new(stomp_client).listen
  end

end
