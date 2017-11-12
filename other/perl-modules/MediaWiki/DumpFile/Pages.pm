package MediaWiki::DumpFile::Pages;

our $VERSION = '0.2.2';
our $TESTED_SCHEMA_VERSION = 0.5;

use strict;
use warnings;
use Scalar::Util qw(reftype);
use Carp qw(croak);
use Data::Dumper;

use XML::TreePuller;
use XML::LibXML::Reader;
use IO::Uncompress::AnyUncompress qw($AnyUncompressError);

sub new {
	my ($class, @args) = @_;
	my $self = {};
	my $reftype; 
	my $xml;
	my $input;
	my %conf;
	my $io;
	
	bless($self, $class);
	
	$self->{siteinfo} = undef;
	$self->{version} = undef;
	$self->{fast_mode} = undef;
	$self->{version_ignore} = 1;
		
	if (scalar(@args) == 0) {
		croak "must specify a file path or open file handle object or a hash of options";
	} elsif (scalar(@args) == 1) {
		$input = $args[0];
	} elsif (! scalar(@args) % 2) {
		croak "must specify a hash as an argument";
	} else {
		%conf = @args;
		
		if (! defined($input = $conf{input})) {
			croak "input is a required option";
		}
		
		if (defined($conf{fast_mode})) {
			$self->{fast_mode} = $conf{fast_mode};
		}
		
		if (defined($conf{strict})) {
			$self->{version_ignore} = $conf{version_ignore};
		}
	}
	
	$reftype = reftype($input);
	
	if (! defined($reftype)) {
		if (! -e $input) {
			croak("$input is not a file");
		}
		
	} elsif ($reftype ne 'GLOB') {
		croak('must provide a GLOB reference');
	} 
	
	$self->{input} = $input;
	$io = IO::Uncompress::AnyUncompress->new($input);		
	$xml = $self->_new_puller(IO => $io);
	
	if (exists($ENV{MEDIAWIKI_DUMPFILE_VERSION_IGNORE})) {
		$self->{version_ignore} = $ENV{MEDIAWIKI_DUMPFILE_VERSION_IGNORE};
	}
	
	if (exists($ENV{MEDIAWIKI_DUMPFILE_FAST_MODE})) {
		$self->{fast_mode} = $ENV{MEDIAWIKI_DUMPFILE_FAST_MODE};
	}
	
	$self->{xml} = $xml;
	$self->{reader} = $xml->reader;
	$self->{input} = $input;
	$self->{io} = $io;

	$self->_init_xml;
	
	return $self;
}

sub next {
	my ($self, $fast) = @_;
	my $version;
	my $new;
	
	if ($fast || $self->{fast_mode}) {
		my ($title, $text);
		
		if ($self->{finished}) {
			return ();
		}
		
		eval { ($title, $text) = $self->_fast_next; };
		
		if ($@) {
			chomp($_);
			croak("E_XML_PARSE_FAILED \"$@\" see the ERRORS section of the MediaWiki::DumpFile::Pages Perl module documentation for what to do");
		}
		
		unless (defined($title)) {
			$self->{finished} = 1;
			return ();
		}
		
		return MediaWiki::DumpFile::Pages::FastPage->new($title, $text);
	}

	if ($self->{finished}) {
		return undef;
	}
	
	$version = $self->{version};
	eval { $new  = $self->{xml}->next; };
	
	if ($@) {
		chomp($_);
		croak("E_XML_PARSE_FAILED \"$@\" see the ERRORS section of the MediaWiki::DumpFile::Pages Perl module documentation for what to do");
	}
			
	unless (defined($new)) {
		$self->{finished} = 1;
		return undef;
	}
	
	return MediaWiki::DumpFile::Pages::Page->new($new, $version);
}

sub size {
	my $source = $_[0]->{input};
	
	unless(defined($source) && ref($source) eq '') {
		return undef;
	}
	
	#if we are decompressing a file on the fly then don't report the size
	#of the file because we don't actually know the uncompressed size,
	#only the compressed size
	if (defined($_[0]->{io}->getHeaderInfo)) {
		return undef;
	}
	
	my @stat = stat($source);
	return $stat[7];
}

sub current_byte {
	return $_[0]->{xml}->reader->byteConsumed;	
}

sub completed {
	my ($self) = @_;
	my $size = $self->size;
	my $current = $self->current_byte;
	
	return -1 unless (defined($size) && defined($current));
	
	return int($current / $size * 100);
}

sub version {
	return $_[0]->{version};
}

#private methods

sub _init_xml {
	my ($self) = @_;
	my $xml = $self->{xml};
	my $version;
	
	$xml->iterate_at('/mediawiki', 'short');
	$xml->iterate_at('/mediawiki/siteinfo', 'subtree');
	$xml->iterate_at('/mediawiki/page', 'subtree');
	
	$version = $self->{version} = $xml->next->attribute('version');

	unless ($self->{version_ignore}) {
		$self->_version_enforce($version);
	}
	
	if ($version > 0.2) {
		$self->{siteinfo} = $xml->next;
		
		bless($self, 'MediaWiki::DumpFile::PagesSiteinfo');
	} 
			
	return undef;
}

sub _version_enforce {
	my ($self, $version) = @_;

	if ($version > $TESTED_SCHEMA_VERSION) {
		my $filename;
		my $msg;
		
		if (ref($self->{input}) eq '') {
			$filename = $self->{input};
		} else {
			$filename = ref($self->{input});
		}
				
		$msg = "E_UNTESTED_DUMP_VERSION Version $version dump file \"$filename\" has not been tested with ";
		$msg .= __PACKAGE__ . " version $VERSION; see the ERRORS section of the MediaWiki::DumpFile::Pages Perl module documentation for what to do";

		die $msg;		
	}

}

sub _new_puller {
	my ($self, @args) = @_;
	my $ret;
	
	eval { $ret = XML::TreePuller->new(@args) };
	
	if ($@) {
		chomp($@);
		croak("E_XML_CREATE_FAILED \"$@\" see the ERRORS section of the MediaWiki::DumpFile::Pages Perl module documentation for what to do")
	}
	
	return $ret;
}

sub _get_text {
	my ($self) = @_;
	my $r = $self->{reader};
	my @buffer;
	my $type;

	while($r->nodeType != XML_READER_TYPE_TEXT && $r->nodeType != XML_READER_TYPE_END_ELEMENT) {
		$r->read or die "could not read";
	}

	while($r->nodeType != XML_READER_TYPE_END_ELEMENT) {
		if ($r->nodeType == XML_READER_TYPE_TEXT) {
			push(@buffer, $r->value);
		}
		
		$r->read or die "could not read";
	}

	return join('', @buffer);	
}

sub _fast_next {
	my ($self) = @_;
	my $reader = $self->{reader};
	my ($title, $text);
	
	if ($self->{finished}) {
		return ();
	}
	
	while(1) {
		my $type = $reader->nodeType;
		 
		if ($type == XML_READER_TYPE_ELEMENT) {
			if ($reader->name eq 'title') {
				$title = $self->_get_text();
				last unless $reader->nextElement('text') == 1;
				next;
			} elsif ($reader->name eq 'text') {
				$text = $self->_get_text();
				$reader->nextElement('page');
				last;
			}		
		} 
		
		last unless $reader->nextElement == 1;
	}
	
	if (! defined($title) || ! defined($text)) {
		$self->{finished} = 1;
		return ();
	}

	return($title, $text);
}

package MediaWiki::DumpFile::PagesSiteinfo;

use base qw(MediaWiki::DumpFile::Pages);

use Data::Dumper;

use MediaWiki::DumpFile::Pages::Lib qw(_safe_text); 

sub _site_info {
	my ($self, $name) = @_;
	my $siteinfo = $self->{siteinfo};
	
	return _safe_text($siteinfo, $name);
}

sub sitename {
	return $_[0]->_site_info('sitename');
}

sub base {
	return $_[0]->_site_info('base');
}

sub generator {
	return $_[0]->_site_info('generator');
}

sub case {
	return $_[0]->_site_info('case');
}

sub namespaces {
	my ($self) = @_;
	my @e = $self->{siteinfo}->get_elements('namespaces/namespace');
	my %ns;
	
	map({ $ns{ $_->attribute('key') } = $_->text } @e);

	return %ns;
}

package MediaWiki::DumpFile::Pages::Page;

use strict;
use warnings;
use Data::Dumper;

use MediaWiki::DumpFile::Pages::Lib qw(_safe_text); 

sub new {
	my ($class, $element, $version) = @_;
	my $self = { tree => $element };
	
	bless($self, $class);
	
	if ($version >= 0.4) {
		bless ($self, 'MediaWiki::DumpFile::Pages::Page000004000');
	}
	
	return $self;
}

sub title {
	return _safe_text($_[0]->{tree}, 'title');
}

sub id {
	return _safe_text($_[0]->{tree}, 'id');
}

sub revision {
	my ($self) = @_;
	my @revisions;
	
	foreach ($self->{tree}->get_elements('revision')) {
		push(@revisions, MediaWiki::DumpFile::Pages::Page::Revision->new($_));
	}
	
	if (wantarray()) {
		return (@revisions);
	}
	
	return pop(@revisions);
}

package MediaWiki::DumpFile::Pages::Page000004000;

use base qw(MediaWiki::DumpFile::Pages::Page);

use strict;
use warnings;

sub redirect {
	return 1 if defined $_[0]->{tree}->get_elements('redirect');
	return 0;
}


package MediaWiki::DumpFile::Pages::Page::Revision;

use strict;
use warnings;

use MediaWiki::DumpFile::Pages::Lib qw(_safe_text); 

sub new {
	my ($class, $tree) = @_;
	my $self = { tree => $tree };
	
	return bless($self, $class);
}

sub text {
	return _safe_text($_[0]->{tree}, 'text');
}

sub id {
	return _safe_text($_[0]->{tree}, 'id');
}

sub timestamp {
	return _safe_text($_[0]->{tree}, 'timestamp');
}

sub comment {
	return _safe_text($_[0]->{tree}, 'comment');
} 

sub minor {
	return 1 if defined $_[0]->{tree}->get_elements('minor');
	return 0;
}

sub contributor {
	return MediaWiki::DumpFile::Pages::Page::Revision::Contributor->new(
		$_[0]->{tree}->get_elements('contributor') );
}

package MediaWiki::DumpFile::Pages::Page::Revision::Contributor;

use strict;
use warnings;

use Carp qw(croak);

use overload 
	'""' => 'astext',
	fallback => 'TRUE';

sub new {
	my ($class, $tree) = @_;
	my $self = { tree => $tree };
	
	return bless($self, $class);
}

sub astext {
	my ($self) = @_;
	
	if (defined($self->ip)) {
		return $self->ip;
	} 	
	
	return $self->username;
}

sub username {
	my $user = $_[0]->{tree}->get_elements('username');
	
	return undef unless defined $user;
	
	return $user->text;
}

sub id {
	my $id = $_[0]->{tree}->get_elements('id');
	
	return undef unless defined $id;
	
	return $id->text;
}

sub ip {
	my $ip = $_[0]->{tree}->get_elements('ip');
	
	return undef unless defined $ip;
	
	return $ip->text;
}

package MediaWiki::DumpFile::Pages::FastPage;

sub new {
	my ($class, $title, $text) = @_;
	my $self = { title => $title, text => $text };
	
	bless($self, $class);
	
	return $self;
}

sub title {
	return $_[0]->{title};
}

sub text {
	return $_[0]->{text};
}

sub revision {
	return $_[0];
}

1;

__END__

=head1 NAME

MediaWiki::DumpFile::Pages - Process an XML dump file of pages from a MediaWiki instance

=head1 SYNOPSIS

  use MediaWiki::DumpFile::Pages;
  
  #dump files up to version 0.5 are tested 
  $input = 'file-name.xml';
  #many supported compression formats
  $input = 'file-name.xml.bz2';
  $input = 'file-name.xml.gz';
  $input = \*FH;
  
  $pages = MediaWiki::DumpFile::Pages->new($input);
  
  #default values
  %opts = (
    input => $input, 
    fast_mode => 0,
    version_ignore => 1
  );
  
  #override configuration options passed to constructor
  $ENV{MEDIAWIKI_DUMPFILE_VERSION_IGNORE} = 0;
  $ENV{MEDIAWIKI_DUMPFILE_FAST_MODE} = 1;
  
  $pages = MediaWiki::DumpFile::Pages->new(%opts);
  $version = $pages->version; 
  
  #version 0.3 and later dump files only
  $sitename = $pages->sitename; 
  $base = $pages->base;
  $generator = $pages->generator;
  $case = $pages->case;
  %namespaces = $pages->namespaces;
  
  #all versions
  while(defined($page = $pages->next) {
    print 'Title: ', $page->title, "\n";
  }
  
  $title = $page->title; 
  $id = $page->id; 
  $revision = $page->revision; 
  @revisions = $page->revision; 
  
  $text = $revision->text; 
  $id = $revision->id; 
  $timestamp = $revision->timestamp; 
  $comment = $revision->comment; 
  $contributor = $revision->contributor;
  #version 0.4 and later dump files only
  $bool = $revision->redirect;
  
  $username = $contributor->username;
  $id = $contributor->id;
  $ip = $contributor->ip;
  $username_or_ip = $contributor->astext;
  $username_or_ip = "$contributor";
  
=head1 METHODS

=head2 new

This is the constructor for this package. If it is called with a single parameter it must be
the input to use for parsing. The input is specified as either the location of
a MediaWiki pages dump file or a reference to an already open file handle. 

If more than one argument is passed to new it must be a hash of options. The keys are named

=over 4

=item input

This is the input to parse as documented earlier.

=item fast_mode

Have the iterator run in fast mode by default; defaults to false. See the section on fast mode below. 

=item version_ignore

Do not enforce parsing of only tested schemas in the XML document; defaults to true

=back

=head2 version

Returns the version of the dump file.

=head2 sitename

Returns the sitename from the MediaWiki instance. Requires a dump file of at least version 0.3.

=head2 base

Returns the URL used to access the MediaWiki instance. Requires a dump file of at least version 0.3.

=head2 generator

Returns the version of MediaWiki that generated the dump file. Requires a dump file of at least version 0.3.

=head2 case

Returns the case sensitivity configuration of the MediaWiki instance. Requires a dump file of at least version 0.3.

=head2 namespaces

Returns a hash where the key is the numerical namespace id and the value is
the plain text namespace name. The main namespace has an id of 0 and an empty 
string value. Requires a dump file of at least version 0.3.

=head2 next

Accepts an optional boolean argument to control fast mode. If the argument is specified
it forces fast mode on or off. Otherwise the mode is controlled by the fast_mode
configuration option. See the section below on fast mode for more information. 

It is safe to intermix calls between fast and normal mode in one parsing session.

In all modes undef is returned if there is no more data to parse. 

In normal mode an instance of MediaWiki::DumpFile::Pages::Page is returned
and the full API is available. 

In fast mode an instance of MediaWiki::DumpFile::Pages::FastPage is returned; the only
methods supported are title, text, and revision. This class can act as a stand-in for
MediaWiki::DumpFile::Pages::Page except it will throw an error if any attempt is made
to access any other part of the API. 

=head2 size

Returns the size of the input file in bytes or if the input specified is a reference
to a file handle it returns undef. 

=head2 current_byte

Returns the number of bytes of XML that have been successfully parsed. 

=head1 FAST MODE

Fast mode is a way to get increased parsing performance while dropping some of the features
available in the parser. If you only require the titles and text from a page then fast mode
will decrease the amount of time required just to parse the XML file; some times drastically. 

When fast mode is used on a dump file that has more than one revision of a single article in
it only the text of the first article in the dump file will be returned; the other revisions
of the article will be silently skipped over. 

=head1 MediaWiki::DumpFile::Pages::Page

This object represents a distinct Mediawiki page and is used to access the page data and metadata. The following
methods are available:

=over 4

=item title

Returns a string of the page title

=item id

Returns a numerical page identification

=item revision

In scalar context returns the last revision in the dump for this page; in array context returns a list of all
revisions made available for the page in the same order as the dump file. All returned data is an instance of
MediaWiki::DumpFile::Pages::Revision

=back

=head1 MediaWiki::DumpFile::Pages::Page::Revision

This object represents a distinct revision of a page from the Mediawiki dump file. The standard dump files contain only the most specific
revision of each page and the comprehensive dump files contain all revisions for each page. The following methods are available:

=over 4

=item text

Returns the page text for this specific revision of the page. 

=item id

Returns the numerical revision id for this specific revision - this is independent of the page id. 

=item timestamp 

Returns a string value representing the time the revision was created. The string is in the format of 
"2008-07-09T18:41:10Z".

=item comment

Returns the comment made about the revision when it was created. 

=item contributor

Returns an instance of MediaWiki::DumpFile::Pages::Page::Revision::Contributor

=item minor

Returns true if the edit was marked as being minor or false otherwise

=item redirect

Returns true if the page is a redirect to another page or false otherwise. Requires a dump file of at least version 0.4.

=back

=head1 MediaWiki::DumpFile::Pages::Page::Revision::Contributor

This object provides access to the contributor of a specific revision of a page. When used in a scalar
context it will return the username of the editor if the editor was logged in or the IP address of
the editor if the edit was anonymous.

=over 4

=item username

Returns the username of the editor if the editor was logged in when the edit was made or undef otherwise.

=item id

Returns the numerical id of the editor if the editor was logged in or undef otherwise.

=item ip

Returns the IP address of the editor if the editor was anonymous or undef otherwise. 

=item astext

Returns the username of the editor if they were logged in or the IP address if the editor
was anonymous. 

=back

=head1 ERRORS

=head2 E_XML_CREATE_FAILED Error creating XML parser object

While trying to build the XML::TreePuller object a fatal error
occured; the error message from the parser was included in the
generated error output you saw. At the time of writing this document
the error messages are not very helpful but for some reason the
XML parser rejected the document; here's a list of things to check:

=over 4

=item Make sure the file exists and is readable

=item Make sure the file is actually an XML file and is not compressed

=back

=head2 E_XML_PARSE_FAILED XML parser failed during parsing

Something went wrong with the XML parser - the error from the parser
was included in the generated error message. This happens when there is
a severe error parsing the document such as a syntax error.

=head2 E_UNTESTED_DUMP_VERSION Untested dump file versions

The dump files created by Mediawiki include a versioned XML schema. This software
is tested with the most recent known schema versions and can be configured to enforce
a specific tested schema. MediaWiki::DumpFile::Pages no longer enforces the versions
by default but the software author using this library has indicated that it should. 
When this happens it dies with an error like the following:

E_UNTESTED_DUMP_VERSION Version 0.4 dump file "t/simpleenglish-wikipedia.xml" 
has not been tested with MediaWiki::DumpFile::Pages version 0.1.9; see the ERRORS 
section of the MediaWiki::DumpFile::Pages Perl module documentation for what to do 
at lib/MediaWiki/DumpFile/Pages.pm line 148.

If you encounter this condition you can do the following:

=over 4

=item Check your module version

The error message should have the version number of this module in it. Check CPAN and 
see if there is a newer version with official support. The web page 

  http://search.cpan.org/dist/MediaWiki-DumpFile/lib/MediaWiki/DumpFile/Pages.pm

will show the highest supported version dump files near the top of the SYNOPSIS.

=item Check the bug database

It is possible the issue has been resolved already but the update has not made it 
onto CPAN yet. See this web page

  http://rt.cpan.org/Public/Dist/Display.html?Name=mediawiki-dumpfile

and check for an open bug report relating to the version number changing. 

=item Be adventurous 

If you just want to have the software run anyway and see what happens
you can set the environment variable MEDIAWIKI_DUMPFILE_VERSION_IGNORE to a true value 
which will cause the module to silently ignore the case and continue parsing the document.
You can set the environment and run your program at the same time with a command like
this:

  MEDIAWIKI_DUMPFILE_VERSION_IGNORE=1 ./wikiscript.pl 

This may work fine or it may fail in subtle ways silently - there is no way to know for sure
with out studying the schema to see if the changes are backwards compatible.  

=item Open a bug report

You can use the same URL for rt.cpan.org above to create a new ticket
in MediaWiki-DumpFile or just send an email to "bug-mediawiki-dumpfile
at rt.cpan.org". Be sure to use a title for the bug that others will
be able to use to find this case as well and to include the full text
from the error message. Please also specify if you were adventurous or
not and if it was successful for you. 

=back

=head1 AUTHOR

Tyler Riddle, C<< <triddle at gmail.com> >>

=head1 BUGS

Please see MediaWiki::DumpFile for information on how to report bugs in 
this software. 

=head1 COPYRIGHT & LICENSE

Copyright 2009 "Tyler Riddle".

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
