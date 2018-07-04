#!/usr/bin/env perl

package MediaWiki::DumpFile::FastPages;

our $VERSION = '0.2.0';

use base qw(MediaWiki::DumpFile::Pages);
use strict;
use warnings;
use Data::Dumper;

sub new {
	my ($class, $input) = @_;
	use Carp qw(croak);
	my $self;
	
	if (! defined($input)) {
		croak "you must provide either a filename or an already open file handle";
	}
	
	$self = $class->SUPER::new(input => $input, fast_mode => 1);
	bless($self, $class);
	
	return $self;
}

sub next {
	my ($self) = @_;

	return $self->_fast_next;	
}

1;

__END__

=head1 NAME

MediaWiki::DumpFile::FastPages - Fastest way to parse a page dump file

=head1 SYNOPSIS

  use MediaWiki::DumpFile::FastPages;
  
  $pages = MediaWiki::DumpFile::FastPages->new($file);
  $pages = MediaWiki::DumpFile::FastPages->new(\*FH);
  
  while(($title, $text) = $pages->next) {
    print "Title: $title\n";
    print "Text: $text\n";
  }
 
=head1 ABOUT

This is a subclass of MediaWiki::DumpFile::Pages that configures
it to run in fast mode and uses a custom iterator
that dispenses with the duck-typed MediaWiki::DumpFile::Pages::Page
object that fast mode uses giving a slight processing speed boost.

See the MediaWiki::DumpFile::Pages documentation for information about fast mode. 

=head1 METHODS

All of the methods of MediaWiki::DumpFile::Pages are also available on this
subclass.

=head2 new

This is the constructor for this package. It is called with a single parameter: the location of
a MediaWiki pages dump file or a reference to an already open file handle. 

=head2 next

Returns a two element list where the first element is the article title and the second element
is the article text. Returns an empty list when there are no more pages available.

=head1 AUTHOR

Tyler Riddle, C<< <triddle at gmail.com> >>

=head1 BUGS

Please see MediaWiki::DumpFile for information on how to report bugs in 
this software. 

=head1 HISTORY

This package originally started life as a very limited hack using only 
XML::LibXML::Reader and seeking to text and title nodes in the document.
Implementing a parser for the full document was a daunting task and
this package sat in the hopes that other people might find it useful. 

Because XML::TreePuller can expose the underlying XML::LibXML::Reader
object and sync itself back up after the cursor was moved out from
underneath it, I was able to integrate the logic from this package
into the main ::Pages parser. 

=head1 COPYRIGHT & LICENSE

Copyright 2009 "Tyler Riddle".

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
