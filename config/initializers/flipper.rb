Flipper.configure do |config|
  config.adapter do
    Flipper::Adapters::Mongo.new(Mongoid.default_client['flipper'])
  end
end