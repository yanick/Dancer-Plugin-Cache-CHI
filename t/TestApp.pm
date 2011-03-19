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
    cache_set params->{attribute} => params->{value};
};

get '/get/:attribute' => sub {
    return cache_get params->{attribute};
};

my $counter;
get '/cached' => sub {
    return cache_page ++$counter;
};

get '/check_page_cache' => sub {
    check_page_cache;
};

get '/clear' => sub {
    cache_clear;
};

put '/stash' => sub {
    return cache_set secret_stash => request->body;
};

get '/stash' => sub {
    return cache_get 'secret_stash';
};

my $computed = 'aaa';
get '/compute' => sub {
    return cache_compute compute => sub { ++$computed };
};

1;
