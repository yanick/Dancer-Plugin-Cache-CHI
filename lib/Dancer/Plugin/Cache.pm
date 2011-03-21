package Dancer::Plugin::Cache;
BEGIN {
  $Dancer::Plugin::Cache::AUTHORITY = 'cpan:yanick';
}
BEGIN {
  $Dancer::Plugin::Cache::VERSION = '0.2.1';
}
# ABSTRACT: Dancer plugin to cache response content (and anything else)

use strict;
use warnings;

use Dancer 1.1904 ':syntax';
use Dancer::Plugin;

use CHI;


my $cache;
register cache => sub {
    return $cache ||= CHI->new(%{ plugin_setting() });
};


register check_page_cache => sub {
    before sub {
        halt cache()->get(request->{path_info});
    };  
};


register cache_page => sub {
    return cache()->set( request->{path_info}, @_ );
};


for my $method ( qw/ set get clear compute / ) {
    register 'cache_'.$method => sub {
        return cache()->$method( @_ );
    }
}

register_plugin;

1;



=pod

=head1 NAME

Dancer::Plugin::Cache - Dancer plugin to cache response content (and anything else)

=head1 VERSION

version 0.2.1

=head1 SYNOPSIS

In your configuration:

    plugins:
        Cache:
            driver: Memory
            global: 1

In your application:

    use Dancer ':syntax';
    use Dancer::Plugin::Cache;

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

=head2 cache_set, cache_get, cache_clear, cache_compute

Shortcut to the cache's object methods.

    get '/cache/:attr/:value' => sub {
        # equivalent to cache->set( ... );
        cache_set $params->{attr} => $params->{value};
    };

=head1 SEE ALSO

Dancer Web Framework - L<Dancer>

L<Dancer::Plugin::Memcached> - plugin that heavily inspired this one.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

