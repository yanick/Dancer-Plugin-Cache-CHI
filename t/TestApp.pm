package
    TestApp;

use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin::Cache;

set plugins => {
    Cache => { driver => 'Memory', global => 1, expires_in => '1 min' },
};

get '/set/:attribute/:value' => sub {
    cache->set( params->{attribute}, params->{value} );
};

get '/get/:attribute' => sub {
    cache->get( params->{attribute} );
};

my $counter;
get '/cached' => sub {
    return cache_page ++$counter;
};

get '/check_page_cache' => sub {
    check_page_cache;
};

get '/clear' => sub {
    cache->clear;
};

1;
