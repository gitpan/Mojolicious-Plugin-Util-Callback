package Mojolicious::Plugin::Util::Callback;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.02';

my %callback;

# Register the plugin
sub register {
  my ($plugin, $mojo) = @_;

  # Add 'callback' helper
  $mojo->helper(
    callback => sub {
      my $c = shift;
      my $name = shift;

      # Establish callbacks by array reference
      if (ref $name && ref $name eq 'ARRAY') {

	# Param hash reference
	my $param = shift;

	# -once flag
	my $flag  = shift;

	# For each given callback name
	foreach (@$name) {

	  # Get callback
	  if (my $cb = delete $param->{$_}) {

	    # Establish callback
	    if (ref $cb && ref $cb eq 'CODE') {
	      $mojo->callback($_, $cb, $flag);
	    };
	  };
	};

	# Everything went fine
	return 1;
      };

      # Establish callback
      if (ref $_[0] && ref $_[0] eq 'CODE') {
	my $cb = shift;
	my $once = $_[0] && $_[0] eq '-once' ? 1 : 0;


	# Callback exists
	if (exists $callback{$name} && $callback{$name}->[1]) {
	  $mojo->log->debug(
	    qq{No allowance to redefine callback "$name"}
	  );

	  # Return nothing
	  return;
	};

	# Establish callback
	$callback{$name} = [$cb, $once];
      }

      # Release callback
      else {

	# Release existing callback
	return $callback{$name}->[0]->($c, @_) if exists $callback{$name};

	# Return nothing
	return;
      };
    }
  );
};


1;


__END__

=pod

=head1 NAME

Mojolicious::Plugin::Util::Callback - Reverse helpers for Mojolicious


=head1 SYNOPSIS

  # Mojolicious
  $app->plugin('Util::Callback');

  # Mojolicious::Lite
  plugin 'Util::Callback';

  # In app or plugin
  $self->callback(get_cached_profile => sub {
    my ($c, $name) = @_;
    return $c->cache->get( $name );
  });

  # In plugin or controller
  my $profile = $self->callback(
    get_cached_profile => 'Akron'
  );


=head1 DESCRIPTION

Callbacks are similar to helpers, with slightly
different semantics.
While helpers are usually established by plugins
and called by controllers, callbacks are
usually called by plugins and established
by other plugins or inside the main application.

A typical usecase for callbacks is the database
agnostic access to data via plugins.


=head1 HELPERS

=head2 callback

  # Call a callback
  my $profile = $self->callback(
    get_cached_profile => 'Akron'
  );

  # Establish a single callback
  $self->callback(get_cached_profile => sub {
    my ($c, $name) = @_;
    return $c->cache->get( $name );
  });

Establish or release a callback.
To release a callback, just pass the unique name of the
callback and all necessary parameters to the helper.
To establish a callback, pass the unique name of the
callback and a code reference to the helper.
This code reference will be invoked each time the
callback is released, and all parameters will be passed,
prepended by the controller object.

An additional C<-once> flag when establishing single or
multiple callbacks (see the example below) indicates,
that the callbacks are not allowed to be redefined later.

If there is no callback defined for a certain name,
C<undef> is returned on releasing.

To establish multiple callbacks, e.g. at the start of the
registration routine of a plugin, pass an array reference
of callback names followed by a hash reference containing
the callbacks to the helper. All callback references will
be deleted from the hash, while the rest will stay intact.

  # Inside 'MyUserPlugin'
  sub register {
    my ($self, $app, $param) = @_;

    # Establish Util::Callback plugin
    $app->plugin('Util::Callback');

    # Accept callbacks defined by parameter
    $app->callback(
      ['get_cached_profile','get_db_profile'] => $param, -once
    );

    # Establish database agnostic 'fetch_profile' helper
    $app->helper(
      fetch_profile => sub {
        my $c = shift;
        my $user_name = shift;

        # Return profile from cache or from db, if cache fails,
        #   either because no cache callback is established or
        #   the user is not in cache.
        return
          $c->callback(get_cache_profile => $user_name) ||
          $c->callback(get_db_profile => $user_name);
      }
    );
  };

  # In a Mojolicious::Lite app
  plugin MyUserPlugin => {
    get_db_profile => sub {
      my ($c, $name) = @_;
      return $c->db->load( $name );
    }
  };

  # In another plugin (e.g. for caching) or later in the application
  $app->callback(
    get_cached_profile => sub {
      my ($c, $name) = @_;
      return $c->cache->get( $name );
    }
  );

  # In controller, app or template
  my $profile = $c->fetch_profile('Akron');


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-Util-Callback


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
