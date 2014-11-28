require 'csv'

namespace :topic_changes do

  desc "Given a source and destination tag, writes a CSV of slugs requiring retagging"
  task :prepare, [:source_topic_id, :destination_topic_id, :output_path] => :environment do |t, args|
    source_topic_id = args[:source_topic_id]
    destination_topic_id = args[:destination_topic_id]
    output_path = args[:output_path]

    unless source_topic_id.present? && destination_topic_id.present? && output_path.present?
      raise "Missing arguments.  This task requires 'source_topic_id', 'destination_topic_id' and 'output_path'."
    end

    if File.exists?(output_path)
      raise "A file already exists at '#{output_path}'.  Please remove it, or use a different name."
    end

    puts "Initializing preparer for source topic '#{source_topic_id}' and destination topic '#{destination_topic_id}'."
    preparer = TopicChanges::Preparer.new(source_topic_id, destination_topic_id)

    output_file = File.open(output_path, 'w') do |file|
      file.write(preparer.build_csv)
    end

    puts "Task complete."
  end

  task :process, [:path_to_csv] => :environment do |t, args|
    path_to_csv = args[:path_to_csv]

    unless path_to_csv.present?
      raise "Missing arguments. Specify the CSV file to use with the 'path_to_csv' argument."
    end

    puts "Reading from: #{path_to_csv}"
    csv = CSV.read(path_to_csv, headers: true)

    logger = Logger.new($stdout)
    processor = TopicChanges::Processor.new(csv, logger)
    processor.run

    puts "Task complete"
  end

end
