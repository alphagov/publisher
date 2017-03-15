namespace :test do
  Rake::TestTask.new(:schemas => "test:prepare") do |t|
    t.libs << 'test'
    t.test_files = `grep -rlE "schema" test`.lines.map(&:chomp)
  end

  Rake::Task['test:schemas'].comment = "Test Publishing API presenters against schemas"
end
