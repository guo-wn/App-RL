use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::RL;

my $result = test_app( 'App::RL' => [qw(help cover)] );
like( $result->stdout, qr{cover}, 'descriptions' );

$result = test_app( 'App::RL' => [qw(cover t/S288c.txt -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 3, 'line count' );
unlike( $result->stdout, qr{S288c},  'species names' );
unlike( $result->stdout, qr{1\-100}, 'covered' );
like( $result->stdout, qr{1\-150}, 'covered' );

done_testing(5);
