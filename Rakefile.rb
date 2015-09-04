require 'fileutils'
require 'iso_country_codes'
require 'pathname'
require 'pry'
require 'tmpdir'
require 'yajl/json_gem'

ISO = IsoCountryCodes.for_select

@HOUSES = FileList['data/*/*/Rakefile.rb'].map { |f| f.pathmap '%d' }.reject { |p| File.exist? "#{p}/WIP" }

def name_to_iso_code(name)
  if code = ISO.find { |iname, _| iname == name }
    return code.last
  elsif code = ISO.find { |iname, _| iname.start_with? name }
    return code.last
  else
    fail "Can't find country code for #{name}"
  end
end

def json_from(json_file)
  JSON.parse(File.read(json_file), symbolize_names: true)
end

def json_write(file, json)
  File.write(file, JSON.pretty_generate(json))
end

def terms_from(json, h)
  terms = json[:events].find_all { |o| o[:classification] == 'legislative period' }
  terms.sort_by { |t| t[:start_date].to_s }.reverse.map { |t|
    t.delete :classification
    t.delete :organization_id
    t[:slug] ||= t[:id].split('/').last
    t[:csv] = h + "/term-#{t[:slug]}.csv"
    t
  }.select { |t| File.exist? t[:csv] }
end

def name_from(json)
  orgs = json[:organizations].find_all { |o| o[:classification] == 'legislature' }
  raise "Wrong number of legislatures (#{orgs})" unless orgs.count == 1
  orgs.first[:name]
end

desc 'Make a new set of instructions'
task 'sources/instructions.json' do |t|
  basedir = Rake.original_dir
  root = File.expand_path("#{basedir}/../..")
  raise "Need to be in Legislature directory" unless Pathname.new(root).basename.to_s == 'data'
  puts "OK"

  Dir.chdir basedir
  FileUtils.mkpath 'sources'

  meta_file = Rake.original_dir + "/meta.json"
  meta = json_from meta_file
  morph_long  = meta.delete(:morph) or abort "no `morph` entry in meta.json" 
  morph_short = morph_long.split('/').last(2).join("/")

  sources = {
    sources: [
      {
        file: 'morph/data.csv',
        create: {
          type: 'morph',
          scraper: morph_short,
          query: 'SELECT * FROM data'
        },
        source: morph_long,
        type: 'membership'
      }
    ]
  }

  if terms = meta.delete(:terms)
    sources[:sources] << {
      file: 'morph/terms.csv',
      create: {
        type: 'morph',
        scraper: morph_short,
        query: 'SELECT * FROM terms'
      },
      type: 'term',
    }
  else
    warn "Now write a termfile"
  end

  puts "Writing #{t.name}"
  json_write(t.name, sources)

  puts "Writing sources/Rakefile.rb"
  File.write('sources/Rakefile.rb', "require_relative '../../../../rakefile_merged.rb'")

  puts "Writing Rakefile.rb"
  File.write('Rakefile.rb', "require_relative '../../../rakefile_local.rb'")

  puts "Writing #{meta_file}"
  json_write(meta_file, meta)
end

desc 'Install country-list locally'
task 'countries.json' do
  countries = @HOUSES.group_by { |h| h.split('/')[1] }
  
  data = countries.map do |c, hs|
    meta_file = hs.first + '/../meta.json'
    meta = File.exist?(meta_file) ? JSON.load(File.open meta_file) : {}
    name = meta['name'] || c.tr('_', ' ')
    slug = c.tr('_', '-')


    {
      name: name,
      # Deprecated — will be removed soon!
      country: name,
      code: meta['iso_code'] || name_to_iso_code(name),
      slug: slug,
      legislatures: hs.map { |h|
        json_file = h + '/ep-popolo-v1.0.json'
        popolo = json_from(json_file)

        cmd = "git log -p --format='%h|%at' --no-notes -s -1 #{h}"
        (sha, lastmod) = `#{cmd}`.chomp.split('|')
        lname = name_from(popolo)
        lslug = h.split('/').last.tr('_', '-')
        {
          name: lname,
          slug: lslug,
          sources_directory: "#{h}/sources",
          popolo: json_file,
          lastmod: lastmod,
          person_count: popolo[:persons].size,
          sha: sha,
          legislative_periods: terms_from(popolo, h),
        }
      }
    }
  end
  File.write('countries.json', JSON.pretty_generate(data.sort_by { |c| c[:name] }.to_a))
end

