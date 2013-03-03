package Mojolicious::Plugin::Util::Callback;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.01';

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

      # Call callback
      else {

	# Call existing callback
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

Callbacks are similar to helpers, with a slightly
different semantic.
While helpers are usually established by plugins
and called by controllers, callbacks are
usually called by plugins and established
by other plugins or on registration of other plugins
in the application.

A typical usecase is the database agnostic
access to data via plugins.


=head1 HELPERS

=head2 callback

  # Call a callback
  my $profile = $self->callback(
    get_cached_profile => 'Akron'
  );

  # Establish callback
  $self->callback(get_cached_profile => sub {
    my ($c, $name) = @_;
    return $c->cache->get( $name );
  });

  # Define multiple callbacks ...
  my $param = {
    my_callback_1 => sub { 'Yeah!' },
    my_callback_2 => sub { 'Fine!' }
  };

  # ... and establish them, e.g. when registering a plugin
  $self->callback(
    [qw/my_callback_1 my_callback_2/] => $param, -once
  );

Establish or call a callback.
To call a callback, just pass the name and all parameters
to the helper.
To establish a callback, pass the name and a code reference
to release to the helper. The arguments of the callback
function will be the controller object followed by all
passed parameters from the call.
To establish multiple callbacks, e.g. at the start of the
registration routine of a plugin, pass an array reference
of callback names followed by a hash reference containing
the callbacks to the helper. All callback references will
be deleted from the hash, while the rest will stay intact.

An additional C<-once> flag when establishing indicates,
that the callbacks are not allowed to be redefined later.

If there is no callback defined for a certain name,
C<undef> is returned on calling.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-Util-Callback


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
