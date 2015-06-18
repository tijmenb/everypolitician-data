require_relative '../../../rakefile_morph.rb'

@MORPH = 'tmtmtmtm/new-zealand-parliament'
@LEGISLATURE = {
  name: 'New Zealand Parliament',
  seats: 120,
}

# http://www.parliament.nz/en-nz/pb/debates/debates?Criteria.Parliament=51&Criteria.PageNumber=16
@TERMS = [{
  id: 51,
  name: "51st Parliament",
  start_date: '2014-10-20',
}]
