require 'test_helper'
require 'rake'

class LocalTransactionsRakeTest < ActiveSupport::TestCase

  setup do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require("lib/tasks/local_transactions", [Rails.root.to_s], [])
    Rake::Task.define_task(:environment)
  end

  context "local_transactions:fetch" do
    setup do
      @task_name = "local_transactions:fetch"

      @saved_file = Rails.root.join('data', 'test_local_interactions.csv')

      LocalServiceImporter.stubs(:new).returns(stub(:run))
      LocalInteractionImporter.stubs(:new).returns(stub(:run))
    end

    should "download the service details CSV file and write it to disk" do
      stub_request(:get, "http://local.direct.gov.uk/Data/local_authority_service_details.csv").
        to_return(:status => 200, :body => "Example CSV Content")

      ENV['FILENAME'] = @saved_file.to_s

      silence_stream(STDERR) do
        @rake[@task_name].invoke
      end

      assert File.exists?(@saved_file)
      assert_equal "Example CSV Content", File.open(@saved_file).read
      assert_equal @saved_file.to_s, ENV["SOURCE"]
    end

    teardown do
      @saved_file.delete if @saved_file.exist?
    end
  end

  context "local_transactions:import" do
    setup do
      @task_name = "local_transactions:import"
      @source_filename = 'test.csv'
    end

    should "call LocalServiceImporter and LocalInteractionImporter with the correct filehandles" do
      ENV['SOURCE'] = @source_filename

      services_filehandle = stub()
      interactions_filehandle = stub()

      File.expects(:open).with('data/local_services.csv', 'r:Windows-1252:UTF-8').returns(services_filehandle)
      File.expects(:open).with(@source_filename, 'r:Windows-1252:UTF-8').returns(interactions_filehandle)

      LocalServiceImporter.expects(:new).with(services_filehandle, anything()).returns(stub(:run))
      LocalInteractionImporter.expects(:new).with(interactions_filehandle, anything()).returns(stub(:run))

      silence_stream(STDERR) do
        @rake[@task_name].invoke
      end
    end

    should "exit when no source is provided" do
      ENV['SOURCE'] = nil

      assert_raise SystemExit do
        silence_stream(STDOUT) do
          @rake[@task_name].invoke
        end
      end
    end
  end

end
