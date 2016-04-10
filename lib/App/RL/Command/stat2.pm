package App::RL::Command::stat2;

use App::RL -command;
use App::RL::Common qw(:all);

use constant abstract => 'coverage on another runlist for runlists';

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen." ],
        [   "op=s",
            "Operations: intersect, union, diff or xor. Default is [intersect]",
            { default => "intersect" }
        ],
        [ "size|s=s", "chr.sizes", { required => 1 } ],
        [ "base|b=s", "basename of infile2", ],
        [ "remove|r", "Remove 'chr0' from chromosome names." ],
        [ "mk",       "First YAML file contains multiple sets of runlists." ],
        [ "all",      "Only write whole genome stats" ],
    );
}

sub usage_desc {
    my $self = shift;
    my $desc = $self->SUPER::usage_desc;    # "%c COMMAND %o"
    $desc .= " <infile1> <infile2>";
    return $desc;
}

sub description {
    my $desc;
    $desc .= "Coverage statistics.\n";
    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    $self->usage_error("This command need two input files.") unless @$args == 2;
    $self->usage_error("The first input file [@{[$args->[0]]}] doesn't exist.")
        unless -e $args->[0];
    $self->usage_error("The second input file [@{[$args->[1]]}] doesn't exist.")
        unless -e $args->[1];

    if ( $opt->{op} =~ /^dif/i ) {
        $opt->{op} = 'diff';
    }
    elsif ( $opt->{op} =~ /^uni/i ) {
        $opt->{op} = 'union';
    }
    elsif ( $opt->{op} =~ /^int/i ) {
        $opt->{op} = 'intersect';
    }
    elsif ( $opt->{op} =~ /^xor/i ) {
        $opt->{op} = 'xor';
    }
    else {
        Carp::confess "[@{[$opt->{op}]}] invalid\n";
    }

    if ( !exists $opt->{base} ) {
        $opt->{base} = Path::Tiny::path( $args->[1] )->basename( ".yaml", ".yml" );
    }

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . $opt->{op} . ".csv";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #----------------------------#
    # Loading
    #----------------------------#
    my $length_of = read_sizes( $opt->{size}, $opt->{remove} );

    # file1
    my $s1_of = {};
    my @keys;
    if ( $opt->{mk} ) {
        my $yml = YAML::Syck::LoadFile( $args->[0] );
        @keys = sort keys %{$yml};

        for my $key (@keys) {
            $s1_of->{$key} = runlist2set( $yml->{$key}, $opt->{remove} );
        }
    }
    else {
        @keys = ("__single");
        $s1_of->{__single}
            = runlist2set( YAML::Syck::LoadFile( $args->[0] ), $opt->{remove} );
    }

    # file2
    my $s2 = runlist2set( YAML::Syck::LoadFile( $args->[1] ), $opt->{remove} );

    #----------------------------#
    # Operating
    #----------------------------#
    my $op_result_of = { map { $_ => {} } @keys };

    for my $key (@keys) {
        my $s1 = $s1_of->{$key};

        # give empty set to non-existing chrs
        for my $s ( $s1, $s2 ) {
            for my $chr ( sort keys %{$length_of} ) {
                if ( !exists $s->{$chr} ) {
                    $s->{$chr} = new_set();
                }
            }
        }

        # operate on each chr
        for my $chr ( sort keys %{$length_of} ) {
            my $op     = $opt->{op};
            my $op_set = $s1->{$chr}->$op( $s2->{$chr} );
            $op_result_of->{$key}{$chr} = $op_set;
        }
    }

    # warn YAML::Syck::Dump $s2;
    # warn YAML::Syck::Dump $op_result_of;

    #----------------------------#
    # Calcing
    #----------------------------#
    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = *STDOUT;
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    my $header = sprintf "key,chr,chr_length,size,%s_length,%s_size,c1,c2,ratio\n",
        $opt->{base}, $opt->{base};
    if ( $opt->{mk} ) {
        if ( $opt->{all} ) {
            $header =~ s/chr\,//;
        }
        my @lines = ($header);

        for my $key (@keys) {
            my @key_lines
                = csv_lines( $s1_of->{$key}, $length_of, $s2, $op_result_of->{$key}, $opt->{all} );
            $_ = "$key,$_" for @key_lines;
            push @lines, @key_lines;
        }

        print {$out_fh} $_ for @lines;
    }
    else {
        $header =~ s/key\,//;
        if ( $opt->{all} ) {
            $header =~ s/chr\,//;
        }
        my @lines = ($header);

        push @lines,
            csv_lines( $s1_of->{__single}, $length_of, $s2, $op_result_of->{__single},
            $opt->{all} );

        print {$out_fh} $_ for @lines;
    }

    close $out_fh;
    return;
}

sub csv_lines {
    my $set_of       = shift;
    my $length_of    = shift;
    my $s2           = shift;
    my $op_result_of = shift;
    my $all          = shift;

    my @lines;
    my ( $all_length, $all_size, $all_s2_length, $all_s2_size, );
    for my $chr ( sort keys %{$length_of} ) {
        my $length = $length_of->{$chr};
        my $size   = $set_of->{$chr}->size;

        my $s2_length = $s2->{$chr}->size;
        my $s2_size   = $op_result_of->{$chr}->size;

        $all_length    += $length;
        $all_size      += $size;
        $all_s2_length += $s2_length;
        $all_s2_size   += $s2_size;

        my $c1    = $size / $length;
        my $c2    = $s2_length == 0 ? 0 : $s2_size / $s2_length;
        my $ratio = $c2 == 0 ? 0 : $c2 / $c1;

        my $line = sprintf "%s,%d,%d,%d,%d,%.4f,%.4f,%.4f\n", $chr, $length, $size, $s2_length,
            $s2_size, $c1, $c2, $ratio;
        push @lines, $line;
    }

    my $all_c1    = $all_size / $all_length;
    my $all_c2    = $all_s2_length == 0 ? 0 : $all_s2_size / $all_s2_length;
    my $all_ratio = $all_c2 == 0 ? 0 : $all_c2 / $all_c1;

    # only keep whole genome
    my $all_line = sprintf "all,%d,%d,%d,%d,%.4f,%.4f,%.4f\n", $all_length, $all_size,
        $all_s2_length, $all_s2_size, $all_c1, $all_c2, $all_ratio;
    if ($all) {
        @lines = ();
        $all_line =~ s/all,//;
    }
    push @lines, $all_line;

    return @lines;
}

1;
