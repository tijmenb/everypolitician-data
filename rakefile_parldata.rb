
require_relative 'rakefile_common.rb'

namespace :raw do

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

end
    
namespace :whittle do

  task :load => 'parldata.json' do
    @json = JSON.load(File.read('parldata.json'), lambda { |h|
      if h.class == Hash 
        h.reject! { |_, v| v.nil? or v.empty? }
        h.reject! { |k, v| [:created_at, :updated_at, :_links].include? k }
      end
    }, { symbolize_names: true })
  end

  task :no_orphaned_memberships => [:delete_unwanted_orgs, :switch_people_to_persons]

  task :switch_people_to_persons => :load do
    @json[:persons] = @json.delete :people
  end

  task :delete_unwanted_orgs => :load do
    @json[:organizations].delete_if { |o| o[:classification] == 'committee' }
  end

end

