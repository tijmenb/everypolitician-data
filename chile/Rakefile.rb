require_relative '../rakefile_morph.rb'

@MORPH = 'tmtmtmtm/chile-opendata'
@DEST = 'chile'

namespace :whittle do

  task :write => :clean_zero_districts

  task :clean_zero_districts => :load do
    @json[:memberships].each do |m|
      m.delete(:area) if m.has_key?(:area) and m[:area][:name] == '0'
    end
  end
end


namespace :transform do

  task :write => :add_all_terms

  # From http://opendata.congreso.cl/wscamaradiputados.asmx/getPeriodosLegislativos
  task :add_all_terms => :ensure_legislature do
    leg = @json[:organizations].find { |h| h[:classification] == 'legislature' } or raise "No legislature"
    leg[:legislative_periods] = [
      {
        id: 'term/1',
        start_date: '1990-03-11',
        end_date: '1994-03-10',
        name: 'Legislativo 1990-1994',
        classification: 'legislative period',
      }, {
        id: 'term/2',
        start_date: '1994-03-11',
        end_date: '1998-03-10',
        name: 'Legislativo 1994-1998',
        classification: 'legislative period',
      }, {
        id: 'term/3',
        start_date: '1998-03-11',
        end_date: '2002-03-10',
        name: 'Legislativo 1998-2002',
        classification: 'legislative period',
      }, {
        id: 'term/4',
        start_date: '2002-03-11',
        end_date: '2006-03-10',
        name: 'Legislativo 2002-2006',
        classification: 'legislative period',
      }, {
        id: 'term/5',
        start_date: '2006-03-11',
        end_date: '2010-03-10',
        name: 'Legislativo 2006-2010',
        classification: 'legislative period',
      }, {
        id: 'term/6',
        start_date: '2010-03-11',
        end_date: '2014-03-10',
        name: 'Legislativo 2010-2014',
        classification: 'legislative period',
      }, {
        id: 'term/8',
        start_date: '2014-03-11',
        end_date: '2018-03-10',
        name: 'Legislativo 2014-2018',
        classification: 'legislative period',
      }
    ]
  end

end

