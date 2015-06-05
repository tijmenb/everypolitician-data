require 'json'
require 'iso_country_codes'
require 'tmpdir'

@COUNTRIES = FileList['data/*/Rakefile.rb'].map do |c|
  {
    path: c.pathmap('%d'),
    name: c.pathmap('%d').split('/').last
  }
end

@COUNTRIES.each do |country|
  desc "Regenerate #{country[:name]}"
  task country[:name].to_sym do
    warn "Regenerating #{country[:name]}"
    Rake::Task[:regenerate].execute(country: country)
  end
end

task :regenerate, :country do |_t, args|
  country = args[:country] || abort('Need a country')
  Dir.chdir country[:path] do
    sh 'rake rebuild'
  end
end

desc 'Regenarate all countries'
task :regenerate_all do
  @COUNTRIES.each do |country|
    Rake::Task[country[:name].to_sym].execute
  end
end

ISO = IsoCountryCodes.for_select

def name_to_iso_code(name)
  if code = ISO.find { |iname, _| iname == name }
    return code.last
  elsif code = ISO.find { |iname, _| iname.start_with? name }
    return code.last
  else
    fail "Can't find country code for #{name}"
  end
end

desc 'Install country-list locally'
task 'countries.json' do
  data = @COUNTRIES.reject { |c| File.exist? c[:path] + '/WIP' }.map do |c|
    meta_file = c[:path] + '/meta.json'
    json_file = c[:path] + '/final.json'

    name = c[:name].tr('_', ' ')
    cmd = "git log -p --format='%h|%at' --no-notes -s -1 #{json_file}"
    (sha, lastmod) = `#{cmd}`.chomp.split('|')
    meta = File.exist?(meta_file) ? JSON.load(File.open meta_file) : {}

    {
      country: name,
      code: meta['iso_code'] || name_to_iso_code(name),
      sources_directory: "data/#{name}/sources",
      popolo: json_file,
      lastmod: lastmod,
      sha: sha
    }
  end
  File.write('countries.json', JSON.pretty_generate(data.to_a))
end
