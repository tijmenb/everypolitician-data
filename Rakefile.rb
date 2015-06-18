require 'json'
require 'iso_country_codes'
require 'tmpdir'

ISO = IsoCountryCodes.for_select

@HOUSES = FileList['data/**/Rakefile.rb'].map { |f| f.pathmap '%d' }.reject { |p| File.exist? "#{p}/WIP" }


def name_to_iso_code(name)
  if code = ISO.find { |iname, _| iname == name }
    return code.last
  elsif code = ISO.find { |iname, _| iname.start_with? name }
    return code.last
  else
    fail "Can't find country code for #{name}"
  end
end

def terms_from(json_file, h)
  json = JSON.parse(File.read(json_file), symbolize_names: true)
  json[:events].find_all { |o| o[:classification] == 'legislative period' }.map { |t|
    t.delete :classification
    t.delete :organization_id
    t[:csv] = h + "/term-#{t[:id].split('/').last}.csv"
    t
  }.select { |t| File.exist? t[:csv] }
end

desc 'Install country-list locally'
task 'countries.json' do
  countries = @HOUSES.group_by { |h| h.split('/')[1] }
  
  data = countries.map do |c, hs|
    meta_file = hs.first + '/../meta.json'
    meta = File.exist?(meta_file) ? JSON.load(File.open meta_file) : {}
    name = c.tr('_', ' ')
    {
      country: name,
      code: meta['iso_code'] || name_to_iso_code(name),
      legislatures: hs.map { |h|
        json_file = h + '/final.json'
        cmd = "git log -p --format='%h|%at' --no-notes -s -1 #{h}"
        (sha, lastmod) = `#{cmd}`.chomp.split('|')
        {
          name: h.split('/').last.tr('_', ' '),
          sources_directory: "#{h}/sources",
          popolo: json_file,
          lastmod: lastmod,
          sha: sha,
          legislative_periods: terms_from(json_file, h),
        }
      }
    }
  end
  File.write('countries.json', JSON.pretty_generate(data.to_a))
end

