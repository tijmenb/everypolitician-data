_.templateSettings = {
  evaluate: /\{\%(.+?)\%\}/g,
  interpolate: /\{\{(.+?)\}\}/g,
  escape: /\{-(.+?)-\}/g
}

var renderTemplate = function renderTemplate(templateName, data){
  data = data || {};
  var source = $('#' + templateName);
  if(source.length){
    return _.template(source.html())(data);
  } else {
    throw 'renderTemplate Error: Could not find source template with matching #' + templateName;
  }
}

var vote = function vote($choice){
  var $pairing = $choice.parents('.pairing');
  var $existingPerson = $('.pairing__existing .person', $pairing);

  if($choice.is('.no-matches')){
    console.log('No match for', $existingPerson.attr('data-uuid'));
  } else if($choice.is('.skip-person')) {
    console.log('Skipped', $existingPerson.attr('data-uuid'));
  } else {
    console.log($existingPerson.attr('data-uuid'), 'matches', $choice.attr('data-id'));
  }

  $pairing.hide().next().show();

  var progress = ($pairing.index()+1) / $('.pairing').length * 100;
  $('.progress-bar div').css('width', '' + progress + '%')
}

var generateCSV = function generateCSV() {
  var csv = [];
  csv.push(['id', 'uuid']);
  $('table tr').each(function(i, row) {
    // Skip header rows
    if ($('th', row).length > 0) {
      return;
    }
    var id = $('.incoming', row).data('id');
    var $existing = $('.existing', row);
    var uuid;
    if ($('select', $existing).length >= 1) {
      uuid = $('select', $existing).val();
    } else {
      uuid = $existing.data('uuid');
    }
    csv.push([id, uuid]);
  });
  return Papa.unparse(csv);
}

jQuery(function($) {
  $.each(matches, function(i, match) {
    var incomingPerson = _.findWhere(incomingPeople, { id: match[0] });
    var existingPerson = _.findWhere(existingPeople, { uuid: match[1] });

    // Skip exact matches for now
    // TODO: This will get removed when we display everyone we know about
    if (incomingPerson[incomingField].toLowerCase() == existingPerson[existingField].toLowerCase()) {
      return;
    }

    var html = renderTemplate('pairing', {
      existingPersonHTML: renderTemplate('person', { person: existingPerson }),
      incomingPersonHTML: renderTemplate('person', { person: incomingPerson })
    });
    $('.pairings').append(html);
  });

  $('.pairing').eq(0).nextAll().hide();

  $(document).on('click', '.pairing__choices > div', function(){
    vote($(this));
  });

  $(document).on('keydown', function(e){
    if(e.which == 39){
      var $choice = $('.pairing:visible .skip-person');
      vote($choice);
    } else if(e.which == 48){
      var $choice = $('.pairing:visible .no-matches');
      vote($choice);
    } else if(e.which > 48 && e.which < 58){
      var $choice = $('.pairing:visible .pairing__choices .person').eq(e.which - 49);
      vote($choice);
    }
  })

  $('.export-csv').on('click', function(e){
    e.stopPropagation();
    var $csv = $('.csv');
    if($csv.is(':visible')){
      $csv.slideUp(100);
    } else {
      $csv.text(generateCSV());
      $csv.slideDown(100);
      $(document).on('click.dismiss-csv', function(){
          $csv.slideUp(100);
          $(document).off('click.dismiss-csv');
      });
    }
  });

  $('.csv').on('click', function(e){
    e.stopPropagation();
  });
});
