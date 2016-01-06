require([
    'base/js/namespace',
    'base/js/events',
], function (IPython, events) {

    function to(mode) {
        function to_mode(c) {
            c.code_mirror.setOption('keyMap', mode);
        };
        IPython.notebook.get_cells().map(to_mode);
        require("notebook/js/cell").Cell.options_default.cm_config.keyMap = mode;
    };

    events.on('notebook_loaded.Notebook', function () {
        require(["codemirror/keymap/emacs"], function () {
            to('emacs');
            console.log('emacs.js loaded');
        });

        // Also remove Ctrl-Shift-- as Emacs uses this for undo
        IPython.keyboard_manager.edit_shortcuts.remove_shortcut('ctrl-shift--');
        IPython.keyboard_manager.edit_shortcuts.remove_shortcut('ctrl-shift-subtract');
    });
});

require([
    'base/js/namespace',
    'base/js/events',
], function (IPython, events) {
    events.on('notebook_loaded.Notebook', function () {
        if($(IPython.toolbar.selector.concat(' > #kill-run-first')).length == 0){
            IPython.toolbar.add_buttons_group([
                {
                    'label'   : 'kill and run-first',
                    'icon'    : 'fa fa-angle-double-down',
                    'callback': function(){
                        IPython.notebook.kernel.restart();
                        $(IPython.events).one('kernel_ready.Kernel', function(){
                            var idx = IPython.notebook.get_selected_index();
                            IPython.notebook.select(0);
                            IPython.notebook.execute_cell();
                            IPython.notebook.select(idx);
                        });
                    }
                }
            ], 'kill-run-first');
        }
    });
});
