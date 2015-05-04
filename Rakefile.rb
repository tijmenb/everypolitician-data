require 'tmpdir'

@COUNTRIES = FileList['*/Rakefile.rb'].pathmap('%d')

@COUNTRIES.each do |country|
  desc "Regenerate #{country}"
  task country.to_sym do 
    Rake::Task[:regenerate].execute(country: country) 
  end
end

task :regenerate, :country do |t, args|
  country = args[:country] or abort "Need a country"
  abort "Don't know how to build #{country}" unless @COUNTRIES.include? country
  chdir country
  sh 'rake rebuild'
  chdir '..'
end

desc "Regenarate all countries"
task :regenerate_all do
  @COUNTRIES.each do |country| 
    Rake::Task[country.to_sym].execute
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
      cp "#{cwd}/#{country}/final.json", "data/#{country}.json"
    end
    %x[ hub add data ]
    %x[ hub commit -m "Refresh with new data from #{last_commit}" ]
    %x[ hub push -u origin #{branch_name} ]
    %x[ hub pull-request -m "Refresh with new data from #{last_commit}" ]
  end
end

