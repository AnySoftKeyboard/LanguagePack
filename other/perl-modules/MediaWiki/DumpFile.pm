package MediaWiki::DumpFile;

our $VERSION = '0.2.2';

use warnings;
use strict;
use Carp qw(croak);

sub new {
	my ($class, %files) = @_;
	my $self = {};
	
	bless($self, $class);
	
	return $self;
}

sub sql {
	if (! defined($_[1])) {
		croak "must specify a filename or open filehandle";
	}
	
	require MediaWiki::DumpFile::SQL;
	
	return MediaWiki::DumpFile::SQL->new($_[1]);
}

sub pages {
	my ($class, @args) = @_;
	require MediaWiki::DumpFile::Pages;
	
	return MediaWiki::DumpFile::Pages->new(@args);
}

sub fastpages {
	if (! defined($_[1])) {
		croak "must specify a filename or open filehandle";
	}
	
	require MediaWiki::DumpFile::FastPages;
	
	return MediaWiki::DumpFile::FastPages->new($_[1]);
}

1;

__END__

=head1 NAME

MediaWiki::DumpFile - Process various dump files from a MediaWiki instance

=head1 SYNOPSIS

  use MediaWiki::DumpFile;

  $mw = MediaWiki::DumpFile->new;
  
  $sql = $mw->sql($filename);
  $sql = $mw->sql(\*FH);
  
  $pages = $mw->pages($filename);
  $pages = $mw->pages(\*FH);
  
  $fastpages = $mw->fastpages($filename);
  $fastpages = $mw->fastpages(\*FH);
  
  use MediaWiki::DumpFile::Compat;
  
  $pmwd = Parse::MediaWikiDump->new;
  
=head1 ABOUT

This module is used to parse various dump files from a MediaWiki instance. The most
likely case is that you will want to be parsing content at http://download.wikimedia.org/backup-index.html 
provided by WikiMedia which includes the English and all other language Wikipedias. 

This module is the successor to Parse::MediaWikiDump acting as a near full replacement in feature set
and providing an independent 100% backwards compatible API that is faster than Parse::MediaWikiDump is 
(see the MediaWiki::DumpFile::Compat and MediaWiki::DumpFile::Benchmarks documentation for details). 

=head1 STATUS

This software is maturing into a stable and tested state with known users; the API is
stable and will not be changed. The software is actively being maintained and improved; 
please submit bug reports, feature requests, and other feedback to the author using the
bug reporting features described below. 

=head1 FUNCTIONS

=head2 sql

Return an instance of MediaWiki::DumpFile::SQL. This object can be used to parse
any arbitrary SQL dump file used to recreate a single table in the MediaWiki instance. 

=head2 pages

Return an instance of MediaWiki::DumpFile::Pages. This object parses the contents of the
page dump file and supports both single and multiple revisions per article as well as
associated metadata. The page can be parsed in either normal or fast mode where
fast mode is only capable of parsing the article titles and text contents, with
restrictions. 

=head2 fastpages

Return an instance of MediaWiki::DumpFile::FastPages. This class is a subclass of
MediaWiki::DumpFile::Pages that configures it to fast mode by default and uses 
a tuned iterator interface with slightly less overhead. 

=head1 SPEED

MediaWiki::DumpFile now runs in a slower configuration when installed with out
the recommended Perl modules; this was done so that the package can be installed
with out a C compiler and still have some utility. As well there is a fast mode
available when parsing the XML document that can give significant speed boosts 
while giving up support for anything except for the article titles and text
contents. If you want to decrease the processing overhead of this system follow
this guide:

=over 4

=item Install XML::CompactTree::XS

Having this module on your system will cause XML::TreePuller to use it
automatically - this will net you a dramatic speed boost if it is not
already installed. This can give you a 3-4 times speed increase when
not using fast mode. 

=item Use fast mode if possible

Details of fast mode and the restrictions it imposes are in the MediaWiki::DumpFile::Pages
documentation. Fast mode is also available in the compatibility library as a new available
option. Fast mode can give you a further 3-4 times speed increase over parsing with
XML::CompatTree::XS installed but it does not require that module to function; fast mode
is nearly the same speed with or with out XML::CompactTree::XS installed. 

=item Stop using compatibility mode

If you are using the compatibility API you lose performance; the compatibility API
is a set of wrappers around the MediaWiki::DumpFile API and while it is faster than
the original Parse::MediaWikiDump::Pages it is still slower than MediaWiki::DumpFile::Pages
by a few percent. 

=item Use MediaWiki::DumpFile::FastPages

This is a subclass of MediaWiki::DumpFile::Pages that configures it by default to run
in fast mode and uses a tuned iterator that decreases overhead another few percent. This
is generally the absolute fastest fully supported and tested way to parse the XML dump files. 

=item Start hacking

I've put some considerable effort into finding the fastest ways to parse the XML dump files. 
Probably the most important part of this research has been an XML benchmarking suite I
created for specifically measuring the performance of parsing the Mediawiki page dump
files. The benchmark suite is present in the module tarball in the speed_test/ directory.
It contains a comprehensive set of test cases to measure the performance of a good
number of XML parsers and parsing schemes from CPAN. You can use this suite as a starting
point to see how various parsers work and how fast they go; as well you can use it to
reliably verify the performance impacts of experiments in parsing performance. 

The result of my research into XML parsers was to create XML::TreePuller which is the heart
XML processing system of MediaWiki::DumpFile::Pages - it's fast but I'm positive there
is room for improvement. Increaseing the speed of that module will increase the speed
of MediaWiki::DumpFile::Pages as well. 

Please consider sharing the results of your hacking with me by opening a ticket in the
bug reporting system as documented below.

The following test cases are notable and could be used by anyone who just needs to extract
article titles and text:

=over 4

=item XML-Bare

Wow is it fast! And wrong! Just so very wrong... but it does pass the tests *shrug*

=back

=back

=head2 Benchmarks

See MediWiki::DumpFile::Benchmarks for a comprehensive report on dump file processing
speeds. 

=head1 AUTHOR

Tyler Riddle, C<< <triddle at gmail.com> >>

=head1 LIMITATIONS

=over 4

=item English Wikipedia comprehensive dump files not supported

There are two types of Mediawiki dump files sharing one schema: ones with
one revision of page per entry and one with multiple revisions of a page per entry.
This software is designed to parse either case and provide a consistent API however
it comes with the restriction that an entire entry must fit in memory. The normal
English Wikipedia dump file is around 20 gigabytes and each entry easily fits into 
RAM on most machines. 

In the case of the comprehensive English Wikipedia dump files the file itself is measured
in the terabytes and a single entry can be 20 gigabytes or more. It is technically possible 
for the original Parse::MediaWikiDump::Revisions (not the compatibility version provided 
in this module) to parse that dump file however Parse::MediaWikiDump runs at a few megabytes per
second under the best of conditions. 

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-mediawiki-dumpfile at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MediaWiki-DumpFile>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=over 4

=item 56843 ::Pages->current_byte() wraps at 2 gigs+

If you have a large XML file, where the file size is greater than a signed 32bit integer,
the returned value from this method can go negative. 

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MediaWiki::DumpFile


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MediaWiki-DumpFile>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MediaWiki-DumpFile>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MediaWiki-DumpFile>

=item * Search CPAN

L<http://search.cpan.org/dist/MediaWiki-DumpFile/>

=back


=head1 ACKNOWLEDGEMENTS

All of the people who reported bugs or feature requests for Parse::MediaWikiDump. 

=head1 COPYRIGHT & LICENSE

Copyright 2009 "Tyler Riddle".

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
