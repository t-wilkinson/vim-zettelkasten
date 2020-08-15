with import <nixpkgs> {};
mkShell {
    name="mdnav-env";
    shellHook = ''
        cd ftplugin/markdown
        '';
    buildInputs = [
        (python38.withPackages(p: with p; [
            pynvim vim
            # more-itertools
            # packages
            # pluggypy
            # pyparsing
            # pytest
            # pytest-pythonpath
            # six
            # wcwidth
            # zipp
        ]))
    ];
}
