package Dancer::Plugin::Cache::CHI;
# ABSTRACT: Dancer plugin to cache response content (and anything else)

use strict;
use warnings;
no warnings qw/ uninitialized /;

use Dancer 1.1904 ':syntax';
use Dancer::Plugin;
use Dancer::Hook;
use Dancer::Factory::Hook;
use Dancer::Response;
use Dancer::SharedData;

use CHI;

=head1 SYNOPSIS

In your configuration:

    plugins:
        'Cache::CHI':
            driver: Memory
            global: 1

In your application:

    use Dancer ':syntax';
    use Dancer::Plugin::Cache::CHI;

    # caching pages' response

    check_page_cache;

    get '/cache_me' => sub {
        cache_page template 'foo';
    };

    # using the helper functions

    get '/clear' => sub {
        cache_clear;
    };

    put '/stash' => sub {
        cache_set secret_stash => request->body;
    };

    get '/stash' => sub {
        return cache_get 'secret_stash';
    };

    del '/stash' => {
        return cache_remove 'secret_stash';
    };

    # using the cache directly

    get '/something' => sub {
        my $thingy = cache->compute( 'thingy', sub { compute_thingy() } );

        return template 'foo' => { thingy => $thingy };
    };

=head1 DESCRIPTION

This plugin provides Dancer with an interface to a L<CHI> cache. Also, it
includes a mechanism to easily cache the response of routes.

=head1 CONFIGURATION

Unrecognized configuration elements are passed directly to the L<CHI> object's
constructor. For example, the configuration given in the L</SYNOPSIS>
will create a cache object equivalent to

    $cache = CHI->new( driver => 'Memory', global => 1, );

=head2 honor_no_cache

If the parameter 'C<honor_no_cache>' is set to true, a request with the http
header 'C<Cache-Control>' or 'C<Pragma>' set to 'I<no-cache>' will ignore any
content cached via 'C<cache_page>' and will have the page regenerated anew.

=head1 KEYWORDS

=head2 cache

Returns the L<CHI> cache object.

=cut

my $cache;
my $cache_page; # actually hold the ref to the args
my $cache_page_key_generator = sub {
    return request()->{path_info};
};

hook after => sub {
    return unless $cache_page;

    my $resp = shift;
    cache()->set( $cache_page_key_generator->(),
        {
            status      => $resp->status,
            headers     => $resp->headers_to_array,
            content     => $resp->content
        },
        @$cache_page,
    );

    $cache_page = undef;
};

register cache => sub {
    return $cache ||= _create_cache();
};


my $honor_no_cache = 0;
sub _create_cache {
    Dancer::Factory::Hook->execute_hooks( 'before_create_cache' );

    my %setting = %{ plugin_setting() };

    if ( exists $setting{honor_no_cache} ) {
        $honor_no_cache = delete $setting{honor_no_cache};
    }

    return CHI->new(%setting);
}


=head2 check_page_cache

If invoked, returns the cached response of a route, if available.

The C<path_info> attribute of the request is used as the key for the route,
so the same route requested with different parameters will yield the same
cached content. Caveat emptor.

=cut

register check_page_cache => sub {
    before sub {
        # Instead halt() now we use a more correct method - setting of a
        # response to Dancer::Response object for a more correct returning of
        # some HTTP headers (X-Powered-By, Server)

        $DB::single = 1;
        my $cached = cache()->get( $cache_page_key_generator->() )
            or return;

        if ( $honor_no_cache ) {
            my $req =  Dancer::SharedData->request;

            return if $req->header('Cache-Control') eq 'no-cache'
                   or $req->header('Pragma')        eq 'no-cache';
        }

        Dancer::SharedData->response(
            Dancer::Response->new(
                ref $cached eq 'HASH'
                ?
                (
                    status       => $cached->{status},
                    headers      => $cached->{headers},
                    content      => $cached->{content}
                )
                :
                ( content => $cached )
            )
        );
    };
};

=head2 cache_page($content, $expiration)

Caches the I<$content> to be served to subsequent requests.
The headers and http status of the response are also cached.

The I<$expiration> parameter is optional.

=cut

register cache_page => sub {
    my ( $content, @args ) = @_;

    $cache_page = \@args;

    return $content;
};

=head2 cache_page_key

Returns the cache key used by 'C<cache_page>'. Defaults to
to the request's I<path_info>, but can be modified via
I<cache_page_key_generator>.

=cut


register cache_page_key => sub {
    return $cache_page_key_generator->();
};

=head2 cache_page_key_generator( \&sub )

Sets the function that generates the cache key for I<cache_page>.

For example, to have the key contains both information about the request's
hostname and path_info (useful to deal with multi-machine applications):

    cache_page_key_generator sub {
        return join ':', request()->host, request()->path_info;
    };

=cut

register cache_page_key_generator => sub {
    $cache_page_key_generator = shift;
};

=head2 cache_set, cache_get, cache_remove, cache_clear, cache_compute

Shortcut to the cache's object methods.

    get '/cache/:attr/:value' => sub {
        # equivalent to cache->set( ... );
        cache_set $params->{attr} => $params->{value};
    };

See the L<CHI> documentation for further info on these methods.

=cut

for my $method ( qw/ set get remove clear compute / ) {
    register 'cache_'.$method => sub {
        return cache()->$method( @_ );
    }
}

Dancer::Factory::Hook->instance->install_hooks(qw/ before_create_cache /);

=head1 HOOKS

=head2 before_create_cache

Called before the creation of the cache, which is lazily done upon
its first use.

Useful, for example, to change the cache's configuration at run time:


    use Sys::Hostname;

    # set the namespace to the current hostname
    hook before_create_cache => sub {
        config->{plugins}{'Cache::CHI'}{namespace} = hostname;
    };

=cut

register_plugin;

__END__

=head1 SEE ALSO

Dancer Web Framework - L<Dancer>

L<CHI>

L<Dancer::Plugin::Memcached> - plugin that heavily inspired this one.

=cut
