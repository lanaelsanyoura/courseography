/**
 * Requests an image from the server. The server automatically generates this
 * image.
 */
function getGraphImage() {
    'use strict';

    $.ajax({
        url: 'image',
        success: function (data) {
            var contentDiv = $('<div></div>');
            var topContentDiv = $('<div></div>');
            var calendarOption = $('<a href="calendar" target="_blank">Download ICS</a>');
            calendarOption.attr('target', '_blank');
            var pdfOption = $('<a href="timetable-pdf" target="_blank">Download PDF</a>');
            topContentDiv.html('<img id="post-image" src="data:image/png;base64,' + data + '" />');
            contentDiv.attr('id', 'modal-content-container')
                      .append(calendarOption)
                      .append(pdfOption)
                      .append(topContentDiv);

            openModal('Export', contentDiv);
            
        },
        error: function () {
            throw 'No image generated';
        }
    });

}
