require_relative '../rakefile_morph.rb'

@DEST = 'australia'
@MORPH = 'tmtmtmtm/popit-australia'

@current_term = { 
  id: 'term/44',
  name: '44th Parliament',
  start_date: '2013-09-07',
}

task :connect_chambers => :ensure_legislature_exists do
  better_name = { 
    'senate' => 'Senate',
    'representatives' => 'House of Representatives',
  }
  @json[:organizations].find_all { |h| h[:classification] == 'chamber' }.each do |c|
    c[:name] = better_name[c[:name]] || c[:name]
    c[:parent_id] ||= 'legislature'
  end
end

file 'final.json' => :connect_chambers

