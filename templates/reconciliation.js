jQuery(function($) {
  var table = $('table');
  $.each(matches, function(i, match) {
    var incomingPerson = incomingPeople.find(function(person) {
      return person.id === match[0];
    });
    var existingPerson = existingPeople.find(function(person) {
      return person.uuid === match[1];
    });

    // Skip exact matches for now
    // TODO: This will get removed when we display everyone we know about
    if (incomingPerson[incomingField].toLowerCase() == existingPerson[existingField].toLowerCase()) {
      return;
    }
    var row = $('<tr>');
    var existing = $('<td>').addClass('existing').text(existingPerson.name).data('uuid', existingPerson.uuid);
    existing.droppable({
      activate: function(e, ui) {
        // Add some styles or whatever to indicate where draggable should be dropped
        $(this).css({backgroundColor: 'beige'});
      },
      deactivate: function(e, ui) {
        // Add some styles or whatever to indicate where draggable should be dropped
        $(this).css({backgroundColor: 'white'});
      },
      over: function(e, ui) {
        // Add some styles or whatever when hovering over a drop target
        $(this).animate({backgroundColor: 'red'});
      },
      out: function(e, ui) {
        // Add some styles or whatever when user stops hovering on drop target
        $(this).animate({backgroundColor: 'white'});
      },
      drop: function(e, ui) {
        console.log("Dropped", ui.draggable.data());
        console.log("Target", $(this).data());
      }
    });
    row.append(existing);
    var incoming = $('<td>').addClass('incoming').text(incomingPerson.name).data('id', incomingPerson.id);
    incoming.draggable({revert: 'invalid'});
    row.append(incoming);
    table.append(row);

    var span = $('<span/>').addClass('remove').text('x').appendTo(incoming);
    span.click(function(e) {
      e.preventDefault();
      var newRow = $('<tr>');
      var manual = $('<td>').addClass('existing');
      var input = $('.js-merged-rows').clone().show().removeClass('js-merged-rows');
      input.change(function(e) {
        console.log("Changed input to ", $(this).val());
      });
      input.appendTo(manual).select2();
      manual.appendTo(newRow);
      span.closest('td').appendTo(newRow);
      newRow.appendTo(table);
    });
  });

  $('#generate-csv').click(function(e) {
    e.preventDefault();
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
    $('#csv-output').val(Papa.unparse(csv));
  });
});
