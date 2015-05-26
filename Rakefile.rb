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



desc "Publish data"
task :publish do
  Dir.mktmpdir do |dir|
    cwd = Dir.pwd
    last_commit = %x{ git rev-parse --short HEAD }.chomp
    branch_name = "epdata-#{Time.now.to_i}"

    %x[ hub clone mysociety/popolo-viewer-sinatra #{dir} ]
    cd dir
    %x[ hub fork ]
    %x[ hub checkout -b #{branch_name} ]
    @COUNTRIES.each do |country| 
      unless File.exist? "#{cwd}/#{country[:path]}/WIP"
        cp "#{cwd}/#{country[:path]}/final.json", "data/#{country[:name]}.json" 
      end
    end
    %x[ hub add data ]
    %x[ hub commit -m "Refresh with new data from #{last_commit}" ]
    %x[ hub push -u origin #{branch_name} ]
    %x[ hub pull-request ]
  end
end

desc "Install data locally"
task :install, :target_dir do |t, args|
  target_dir = args[:target_dir] || ENV['PVS_SOURCE_DIR'] || "../popolo-viewer-sinatra"
  raise "No /src in #{target_dir}" unless Dir.exist? "#{target_dir}/src/"
  @COUNTRIES.each do |country| 
    unless File.exist? "#{country[:path]}/WIP"
      cmd = "git log -p --format='%h|%at' --no-notes -s -1 #{country[:path]}/final.json > #{target_dir}/src/#{country[:name]}.src"
      warn cmd
      system(cmd)
    end
  end
end

