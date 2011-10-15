package TestApp;

use strict;
use warnings;
no warnings qw/ uninitialized /;

use lib 't';

use Dancer qw/:syntax :tests/;
use Dancer::Plugin::Cache::CHI;

use Dancer::Test;
use Test::More;

set plugins => {
    'Cache::CHI' => { 
        driver => 'Memory', 
        global => 1, 
        expires_in => '1 min',
        'honor_no_cache' => 1,
    },
};

check_page_cache;

my $i;
get '/cached' => sub {
    return cache_page ++$i;
};

plan tests => 6;

response_content_is '/cached' => 1, 'initial hit';
response_content_is '/cached' => 1, 'cached';

my $resp = dancer_response 'GET' => '/cached', {
    headers => [ qw/ Cache-Control no-cache / ],
};

response_content_is $resp => 2, 'Cache-Control: no-cache';
response_content_is '/cached' => 2, 'cached again';

$resp = dancer_response 'GET' => '/cached', {
    headers => [ qw/ Pragma no-cache / ],
};

response_content_is $resp => 3, 'Pragma: no-cache';
response_content_is '/cached' => 3, 'cached again';
