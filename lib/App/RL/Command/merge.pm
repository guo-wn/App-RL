package App::RL::Command::merge;

use App::RL -command;
use App::RL::Common qw(:all);

use constant abstract => 'merge runlist yaml files';

sub opt_spec {
    return ( [ "outfile|o=s", "Output filename. [stdout] for screen." ], );
}

sub usage_desc {
    my $self = shift;
    my $desc = $self->SUPER::usage_desc;    # "%c COMMAND %o"
    $desc .= " <infiles>";
    return $desc;
}

sub description {
    my $desc;
    $desc .= "Merge files of runlist.\n";
    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    $self->usage_error("This command need one or more input files.") unless @$args;
    $self->usage_error("The input file [@{[$args->[0]]}] doesn't exist.")
        unless -e $args->[0];

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".merge.yml";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = *STDOUT;
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    for my $file ( @{$args} ) {
        my $basename = Path::Tiny::path($file)->basename( ".yaml", ".yml" );
        my $dir = Path::Tiny::path($file)->parent->stringify;
        my ($word) = split /[^\w]+/, $basename;

        my $content = YAML::Syck::LoadFile($file);
        $master->{$word} = $content;
    }
    print {$out_fh} YAML::Syck::Dump($master);

    close $out_fh;
    return;
}

1;
