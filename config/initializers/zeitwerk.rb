Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "csv_presenter" => "CSVPresenter",
    "csv_parser" => "CSVParser",
  )
end
