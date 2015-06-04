require 'tmpdir'

@COUNTRIES = FileList['data/*/Rakefile.rb'].map { |c| {
  path: c.pathmap('%d'),
  name: c.pathmap('%d').split('/').last,
}}

@COUNTRIES.each do |country|
  desc "Regenerate #{country[:name]}"
  task country[:name].to_sym do 
    warn "Regenerating #{country[:name]}"
    Rake::Task[:regenerate].execute(country: country) 
  end
end

task :regenerate, :country do |t, args|
  country = args[:country] or abort "Need a country"
  Dir.chdir country[:path] do
    sh 'rake rebuild'
  end
end

desc "Regenarate all countries"
task :regenerate_all do
  @COUNTRIES.each do |country| 
    Rake::Task[country[:name].to_sym].execute
  end
end


