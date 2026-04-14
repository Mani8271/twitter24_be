//= require active_admin/base

document.addEventListener('DOMContentLoaded', function () {
  var textarea = document.getElementById('html_content_editor');
  if (!textarea) return;

  // Load CodeMirror CSS
  ['https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.css',
   'https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/theme/dracula.min.css'
  ].forEach(function (href) {
    var link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = href;
    document.head.appendChild(link);
  });

  // Chain-load CodeMirror scripts then initialize
  function loadScript(src, cb) {
    var s = document.createElement('script');
    s.src = src;
    s.onload = cb;
    document.head.appendChild(s);
  }

  loadScript(
    'https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.js',
    function () {
      loadScript(
        'https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/mode/xml/xml.min.js',
        function () {
          loadScript(
            'https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/mode/javascript/javascript.min.js',
            function () {
              loadScript(
                'https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/mode/css/css.min.js',
                function () {
                  loadScript(
                    'https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/mode/htmlmixed/htmlmixed.min.js',
                    function () {
                      var editor = CodeMirror.fromTextArea(textarea, {
                        mode: 'htmlmixed',
                        theme: 'dracula',
                        lineNumbers: true,
                        lineWrapping: true,
                        indentWithTabs: false,
                        indentUnit: 2,
                        viewportMargin: Infinity
                      });
                      editor.setSize('100%', 560);

                      // Sync back to textarea on form submit
                      var form = textarea.closest('form');
                      if (form) {
                        form.addEventListener('submit', function () {
                          editor.save();
                        });
                      }
                    }
                  );
                }
              );
            }
          );
        }
      );
    }
  );
});
