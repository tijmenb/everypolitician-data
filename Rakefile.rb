require 'tmpdir'
require 'json'

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

desc "Install country-list locally"
task 'countries.json' do 
  data = @COUNTRIES.reject { |c| File.exist? "#{c[:path]}/WIP" }.map do |country| 
    popolo = country[:path] + '/final.json'
    cmd = "git log -p --format='%h|%at' --no-notes -s -1 #{popolo}"
    (sha, lastmod) = %x(#{cmd}).chomp.split('|')
    {
      country: country[:name],
      popolo: popolo,
      lastmod: lastmod,
      sha: sha,
    }
  end
  File.write('countries.json', JSON.pretty_generate(data.to_a))
end

