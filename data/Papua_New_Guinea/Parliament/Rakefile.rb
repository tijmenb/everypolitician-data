require_relative '../../../rakefile_morph.rb'

@MORPH = 'duncanparkes/papuanewguinea'
@MORPH_TERMS = true
@MORPH_QUERY = "SELECT *, area AS constituency FROM data"
@LEGISLATURE = {
  name: 'National Parliament',
  seats: 109
}
