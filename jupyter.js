require([
    'base/js/namespace',
    'base/js/events',
], function (IPython, events) {

    function to(mode) {
        function to_mode(c) {
            return c.code_mirror.setOption('keyMap', mode);
        };
        IPython.notebook.get_cells().map(to_mode);
        require("notebook/js/cell").Cell.options_default.cm_config.keyMap = mode;
    };

    events.on('notebook_loaded.Notebook', function () {
        require(["codemirror/keymap/emacs"], function () {
            to('emacs')
            console.log('emacs.js loaded')
        });
    });
});
