use strict;
use warnings;

use lib 't';

use Test::More;

use TestApp;

use Dancer::Test;

plan tests => 14;

response_status_is [ 'GET', '/set/foo/bar' ], 200, '/set/foo/bar';

response_content_is [ 'GET', '/get/foo' ], 'bar', '/get/foo';

response_content_is [ 'GET', '/cached' ], 1, '/cached';

response_content_is [ 'GET', '/cached' ], 2, '/cached (not cached yet)';

response_status_is [ 'GET', '/check_page_cache' ], 200, '/check_page_cache';

response_content_is [ 'GET', '/cached' ], 2, '/cached (cached!)';

response_status_is [ 'GET', '/clear' ], 200, '/clear';

response_content_is [ 'GET', '/cached' ], 3, '/cached (cleared)';

my $secret = 'flamingo';
my $resp = dancer_response PUT => '/stash', { body => $secret };

is $resp->status => 200, 'secret stashed';

response_content_is [ GET => '/stash' ], $secret, 'secret retrieved';

response_content_is [ GET => '/compute' ], 'aab', '/compute, first';
response_content_is [ GET => '/compute' ], 'aab', '/compute, cached';
response_status_is [ GET => '/clear' ], 200, '/clear cache';
response_content_is [ GET => '/compute' ], 'aac', '/compute, again';

