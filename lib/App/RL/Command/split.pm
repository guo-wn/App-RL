package App::RL::Command::split;

use App::RL -command;
use App::RL::Common qw(:all);

use constant abstract => 'split runlist yaml files';

sub opt_spec {
    return (
        [   "outdir|o=s", "output location, [stdout] for screen, default is [.]", { default => '.' }
        ],
    );
}

sub usage_desc {
    my $self = shift;
    my $desc = $self->SUPER::usage_desc;    # "%c COMMAND %o"
    $desc .= " <infiles>";
    return $desc;
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    $self->usage_error("This command need one input files.") unless @{$args} == 1;
    for ( @{$args} ) {
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

    if ( !exists $opt->{outdir} ) {
        $opt->{outdir} = Path::Tiny::path( $args->[0] )->absolute . ".split";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $yml = YAML::Syck::LoadFile( $args->[0] );

    for my $key ( keys %{$yml} ) {
        if ( lc( $opt->{outdir} ) eq "stdout" ) {
            print YAML::Syck::Dump( $yml->{$key} );
        }
        else {
            YAML::Syck::DumpFile( Path::Tiny::path( $opt->{outdir}, $key . ".yml" ), $yml->{$key} );
        }
    }

    return;
}

1;
