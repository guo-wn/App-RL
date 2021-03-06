use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::RL;

my $result = test_app( 'App::RL' => [qw(help position)] );
like( $result->stdout, qr{position}, 'descriptions' );

$result
    = test_app( 'App::RL' => [qw(position --op overlap t/intergenic.yml t/S288c.txt -o stdout)] );

is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 2, 'line count' );
unlike( $result->stdout, qr{S288c}, 'species names' );
like( $result->stdout, qr{21294\-22075}, 'covered' );

$result = test_app(
    'App::RL' => [qw(position --op non-overlap t/intergenic.yml t/S288c.txt -o stdout)] );

is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 3, 'line count' );
like( $result->stdout, qr{S288c}, 'species names' );
unlike( $result->stdout, qr{21294\-22075}, 'covered' );

$result
    = test_app( 'App::RL' => [qw(position --op superset t/intergenic.yml t/S288c.txt -o stdout)] );

is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 2, 'line count' );
unlike( $result->stdout, qr{S288c}, 'species names' );
like( $result->stdout, qr{21294\-22075}, 'covered' );

done_testing(10);
