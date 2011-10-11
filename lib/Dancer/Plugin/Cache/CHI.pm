package Dancer::Plugin::Cache::CHI;
BEGIN {
  $Dancer::Plugin::Cache::CHI::AUTHORITY = 'cpan:yanick';
}
BEGIN {
  $Dancer::Plugin::Cache::CHI::VERSION = '1.1.0';
}
# ABSTRACT: Dancer plugin to cache response content (and anything else)

use strict;
use warnings;

no warnings qw/ uninitialized /;

use Dancer 1.1904 ':syntax';
use Dancer::Plugin;
use Dancer::Response;
use Dancer::SharedData;

use CHI;


my $cache;
my $cache_page; # actually hold the ref to the args

my $after_cb = sub {
    return unless $cache_page;

    my $resp = shift;
    cache()->set( request->{path_info},
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
    return $cache ||= CHI->new(%{ plugin_setting() });
};


register check_page_cache => sub {
    before sub {
        # Instead halt() now we use a more correct method - setting of a
        # response to Dancer::Response object for a more correct returning of
        # some HTTP headers (X-Powered-By, Server)
        if ( my $cached =  cache()->get(request->{path_info})) {
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
        }
    };
};


register cache_page => sub {
    my ( $content, @args ) = @_;
    $cache_page = \@args;

    if ($after_cb) {
        after $after_cb;
        $after_cb = undef;
    }

    return $content;
};


for my $method ( qw/ set get remove clear compute / ) {
    register 'cache_'.$method => sub {
        return cache()->$method( @_ );
    }
}

register_plugin;



=pod

=head1 NAME

Dancer::Plugin::Cache::CHI - Dancer plugin to cache response content (and anything else)

=head1 VERSION

version 1.1.0

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

The plugin's configuration is passed directly to the L<CHI> object's
constructor. For example, the configuration given in the L</SYNOPSIS>
will create a cache object equivalent to

    $cache = CHI->new( driver => 'Memory', global => 1, );

=head1 KEYWORDS

=head2 cache

Returns the L<CHI> cache object.

=head2 check_page_cache

If invoked, returns the cached response of a route, if available.

The C<path_info> attribute of the request is used as the key for the route,
so the same route requested with different parameters will yield the same
cached content. Caveat emptor.

=head2 cache_page($content, $expiration)

Caches the I<$content> to be served to subsequent requests. The I<$expiration>
parameter is optional.

=head2 cache_set, cache_get, cache_remove, cache_clear, cache_compute

Shortcut to the cache's object methods.

    get '/cache/:attr/:value' => sub {
        # equivalent to cache->set( ... );
        cache_set $params->{attr} => $params->{value};
    };

See the L<CHI> documentation for further info on these methods.

=head1 SEE ALSO

Dancer Web Framework - L<Dancer>

L<CHI>

L<Dancer::Plugin::Memcached> - plugin that heavily inspired this one.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
