use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::RL;

my $result = test_app( 'App::RL' => [qw(help split)] );
like( $result->stdout, qr{split}, 'descriptions' );

$result = test_app( 'App::RL' => [qw(split t/repeat.yml -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 16, 'line count' );
like( $result->stdout, qr{\-\-\- "\-"},           'runlist exists' );
like( $result->stdout, qr{\-\-\- 162831\-163399}, 'runlist exists' );

done_testing(4);
