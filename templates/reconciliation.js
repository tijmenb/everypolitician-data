jQuery(function($) {
  var table = $('table');
  $.each(matches, function(i, match) {
    var row = $('<tr>');
    var existing = $('<td>').addClass('existing').text(match[3]).data({uuid: match[2], text: match[3]});
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
    var incoming = $('<td>').addClass('incoming').text(match[1]).data({id: match[0], text: match[1]});
    incoming.draggable({revert: 'invalid'});
    row.append(incoming);
    table.append(row);

    var span = $('<span/>').text('x').appendTo(incoming);
    span.click(function(e) {
      e.preventDefault();
      var newRow = $('<tr>');
      $('<td>').appendTo(newRow);
      span.closest('td').appendTo(newRow);
      newRow.appendTo(table);
    });
  });

  $('#generate-csv').click(function(e) {
    e.preventDefault();
    var csv = [];
    csv.push(headers.join(','));
    $('table tr').each(function(i, row) {
      // Skip header rows
      if ($('th', row).length > 0) {
        return;
      }
      var existing = $('.existing', row).data('text');
      var incoming = $('.incoming', row).data('text');
      var uuid = $('.existing', row).data('uuid');
      var id = $('.incoming', row).data('id');
      csv.push([id, incoming, uuid, existing, null].join(','));
    });
    $('#csv-output').val(csv.join('\n'));
  });
});
