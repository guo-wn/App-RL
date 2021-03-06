package App::RL::Command::some;
use strict;
use warnings;
use autodie;

use App::RL -command;
use App::RL::Common;

use constant abstract => 'extract some records';

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen." ],
    );
}

sub usage_desc {
    my $self = shift;
    my $desc = $self->SUPER::usage_desc;    # "%c COMMAND %o"
    $desc .= " <infile> <list.file>";
    return $desc;
}

sub description {
    my $desc;
    $desc .= "Extract some records from YAML file.\n";
    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} != 2 ) {
        $self->usage_error("This command need two input files.");
    }
    for ( @{$args} ) {
        next if lc $_ eq "stdin";
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".list.yml";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #----------------------------#
    # Loading
    #----------------------------#
    my $yml          = YAML::Syck::LoadFile( $args->[0] );
    my $all_name_set = Set::Scalar->new;
    for my $n ( @{ App::RL::Common::read_names( $args->[1] ) } ) {
        $all_name_set->insert($n);
    }

    my $out_ref = {};
    for my $key ( keys %{$yml} ) {
        if ( $all_name_set->has($key) ) {
            $out_ref->{$key} = $yml->{$key};
        }
    }

    #----------------------------#
    # Output
    #----------------------------#
    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = *STDOUT;
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    print {$out_fh} YAML::Syck::Dump($out_ref);

    close $out_fh;
}

1;
