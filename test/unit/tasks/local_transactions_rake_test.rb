require 'test_helper'
require 'rake'

class LocalTransactionsRakeTest < ActiveSupport::TestCase

  def task_path
    "lib/tasks/local_transactions"
  end

  setup do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require(task_path, [Rails.root.to_s], loaded_files_excluding_current_rake_file)
    Rake::Task.define_task(:environment)
  end

  def loaded_files_excluding_current_rake_file
    $".reject {|file| file == Rails.root.join("#{task_path}.rake").to_s }
  end

  context "local_transactions:fetch" do
    setup do
      @task_name = "local_transactions:fetch"
      @rake["local_transactions:import"].clear
    end

    should "download the CSV file and write to disk" do
      stub_request(:get, "http://local.direct.gov.uk/Data/local_authority_service_details.csv").
        to_return(:status => 200, :body => "Example CSV Content")
      saved_file = Rails.root.join("tmp","local_services","local_services.csv")

      Rake::Task[@task_name].execute

      assert File.exists?(saved_file)
      assert_equal "Example CSV Content", File.open(saved_file).read
      assert_equal saved_file.to_s, ENV["SOURCE"]
    end
  end

  context "local_transactions:import" do
    setup do
      @task_name = "local_transactions:import"
      @source_filename = 'test.csv'
    end

    should "call LocalServiceImporter and LocalInteractionImporter with the correct filenames" do
      ENV['SOURCE'] = @source_filename

      LocalServiceImporter.expects(:new).returns(stub(:run))
      LocalInteractionImporter.expects(:new).returns(stub(:run))

      File.expects(:open).with('data/local_services.csv', 'r:Windows-1252:UTF-8').returns(stub())
      File.expects(:open).with(@source_filename, 'r:Windows-1252:UTF-8').returns(stub())

      Rake::Task[@task_name].execute
    end

    should "exit when no source is provided" do
      ENV['SOURCE'] = nil

      assert_raise SystemExit do
        Rake::Task[@task_name].execute
      end
    end

  end


end