require_relative '../rakefile_kvapi.rb'

@DEST = 'albania'
@KVAPI = 'al/kuvendi'

@current_term = { 
  id: 'term/44',
  name: '44th Parliament',
  start_date: '2013-09-07',
}

task :ensure_legislative_period => :cleanup 

task :cleanup => :ensure_legislature_exists do
  committees, orgs = @json[:organizations].partition { |o| o[:classification] == 'committee' }
  terms,      orgs =                  orgs.partition { |o| o[:classification] == 'chamber' }

  committee_ids = committees.map { |c| c[:id] }.to_set

  @json[:memberships].delete_if { |m| committee_ids.include? m[:organization_id] }

  @json[:organizations] = orgs
  leg = @json[:organizations].find { |h| h[:classification] == 'legislature' } or raise "No legislature"
  leg[:legislative_periods] = terms.map do |t|
    t[:classification] == 'legislative_period_id'
    t[:start_date] = t.delete :founding_date if t.has_key? :founding_date
    t[:end_date] = t.delete :dissolution_date if t.has_key? :dissolution_date
    t
  end

end

__END__

# Switch membership of 'chamber' to legislative session
      "label": "Deputet",
      "organization_id": "chamber_I",
      "person_id": "mp_BlushiBen",
      "id": "chamber_I-mp_BlushiBen"

    {
      "id": "chamber_XIX-mp_BushatiHelidon",
      "label": "Deputet",
      "organization_id": "chamber_XIX",
      "person_id": "mp_BushatiHelidon",
      "start_date": "2013"
    },
      
------

    {
      "label": "MP",
      "organization_id": "committee_2006NëVazhdimBotuesDheBashkautorNëArtikujTëNdryshëmShkencorNdërkombëtar",
      "sources": [
        {
          "url": "http://www.parlament.al/web/KOSOVA_Halim_16286_1.php"
        }
      ],
      "person_id": "mp_KosovaHalim",
      "id": "committee_2006NëVazhdimBotuesDheBashkautorNëArtikujTëNdryshëmShkencorNdërkombëtar-mp_KosovaHalim"
    },
    

