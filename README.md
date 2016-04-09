[![Build Status](https://travis-ci.org/wang-q/App-RL.svg?branch=master)](https://travis-ci.org/wang-q/App-RL)

# NAME

App::RL - operating chromosome runlist files

# SYNOPSIS

    runlist <command> [-?h] [long options...]
        -? -h --help    show help

    Available commands:

      commands: list the application's commands
          help: display a command's help screen

       combine: combine multiple sets of runlists
       compare: compare 2 chromosome runlists
        covers: output covers on chromosomes
        genome: convert chr.size to runlists
         merge: merge runlist yaml files
          some: extract some records
          span: operating spans in runlists
         split: split runlist yaml files
          stat: coverage on chromosomes for runlists
         stat2: coverage on another runlist for runlists

See `runlist commands` for usage information.

# AUTHOR

Qiang Wang &lt;wang-q@outlook.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qiang Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
