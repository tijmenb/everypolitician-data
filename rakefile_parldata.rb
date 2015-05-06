
require_relative 'rakefile_common.rb'

file 'parldata.json' do
  venv_path = ENV['PARLDATA_VENV'] or raise "PARLDATA_VENV must be set to a virtualenv"
  venv_python = venv_path + "/bin/python"
  File.exist? venv_python or raise "No `python` binary found at #{venv_python}"

  [@PARLDATA].flatten.each_with_index do |house, i|
    fetcher = File.expand_path("../bin/parldataeu.py", __FILE__)
    cmd = [venv_python, fetcher, house].join ' '

    outfile = 'parldata'
    outfile << "-#{house.split('/').last}" unless i.zero?

    data = %x[ #{cmd} ]
    File.write("#{outfile}.json", data)
  end
end
CLOBBER.include('parldata.json')
  
file 'clean.json' => 'parldata.json' do
  json = JSON.load(File.read('parldata.json'), lambda { |h|
    if h.class == Hash 
      h.reject! { |_, v| v.nil? or v.empty? }
      h.reject! { |k, v| [:created_at, :updated_at, :_links].include? k }
    end
  }, { symbolize_names: true })

  json[:persons] = json.delete :people
  json[:organizations].delete_if { |o| o[:classification] == 'committee' }
  File.write('clean.json', JSON.pretty_generate(json))
end
CLEAN.include('clean.json')


# Migrate Chambers to Terms before adding a default one
task :ensure_legislative_period => :migrate_to_terms

task :migrate_to_terms => :ensure_legislature_exists do
  # require 'pry'
  # binding.pry
  leg = @json[:organizations].find { |h| h[:classification] == 'legislature' }
  @json[:organizations].find_all { |h| h[:classification] == 'chamber' }.each do |c|
    (leg[:legislative_periods] ||= []) << c.merge({ 
      classification: "legislative period",
      start_date: c.delete(:founding_date),
      end_date: c.delete(:dissolution_date),
    }.reject { |_,v| v.nil? or v.empty? })

    @json[:memberships].find_all { |m| m[:organization_id] == c[:id] }.each do |m|
      m[:organization_id] = leg[:id]
      m[:legislative_period_id] = c[:id]
      # TODO m[:on_behalf_of] = '' 
      m[:role] = 'member'
    end
  end
  @json[:organizations].delete_if { |h| h[:classification] == 'chamber' }

end


