#!/usr/bin/env perl

#Parse::MediaWikiDump compatibility

package MediaWiki::DumpFile::Compat;

our $VERSION = '0.2.0';

package #go away indexer! 
	Parse::MediaWikiDump;

use strict;
use warnings;

sub new {
	my ($class) = @_;
	return bless({}, $class);
}

sub pages {
	shift(@_);
	return Parse::MediaWikiDump::Pages->new(@_);
}

sub revisions {
	shift(@_);
	return Parse::MediaWikiDump::Revisions->new(@_);
}

sub links {
	shift(@_);
	return Parse::MediaWikiDump::Links->new(@_);
}

package #go away indexer! 
	Parse::MediaWikiDump::Links;

use strict; 
use warnings;

use MediaWiki::DumpFile::SQL;

sub new {
	my ($class, $source) = @_;
	my $self = {};
	my $sql;
	
	$Carp::CarpLevel++;
	$sql = MediaWiki::DumpFile::SQL->new($source);
	$Carp::CarpLevel--;
	
	if (! defined($sql)) {
		die "could not create SQL parser";
	}
	
	$self->{sql} = $sql;
	
	return bless($self, $class);
}

sub next {
	my ($self) = @_;
	my $next = $self->{sql}->next;
	
	unless(defined($next)) {
		return undef;
	}
	
	return Parse::MediaWikiDump::link->new($next);
}

package #go away indexer! 
	Parse::MediaWikiDump::link;

use strict; 
use warnings;

use Data::Dumper;

sub new {
	my ($class, $self) = @_;
	
	bless($self, $class);
}

sub from {
	return $_[0]->{pl_from};
}

sub namespace {
	return $_[0]->{pl_namespace};
}

sub to {
	return $_[0]->{pl_title};
}

package #go away indexer! 
	Parse::MediaWikiDump::Revisions;

use strict;
use warnings;
use Data::Dumper;

use MediaWiki::DumpFile::Pages;

sub new {
	my ($class, @args) = @_;
	my $self = { queue => [] };
	my $mediawiki;
	
	$Carp::CarpLevel++;
	$mediawiki = MediaWiki::DumpFile::Pages->new(@args);
	$Carp::CarpLevel--;
	
	$self->{mediawiki} = $mediawiki;
	
	return bless($self, $class);
}

sub version {
	return $_[0]->{mediawiki}->version;
}

sub sitename {
	return $_[0]->{mediawiki}->sitename;
}

sub base {
	return $_[0]->{mediawiki}->base;
}

sub generator {
	return $_[0]->{mediawiki}->generator;
}

sub case {
	return $_[0]->{mediawiki}->case;
}

sub namespaces {
	my $cache = $_[0]->{cache}->{namespaces};
	
	if(defined($cache)) {
		return $cache;
	}
	
	my %namespaces = $_[0]->{mediawiki}->namespaces;
	my @temp;
	
	while(my ($key, $val) = each(%namespaces)) {
		push(@temp, [$key, $val]);
	}
	
	@temp = sort({$a->[0] <=> $b->[0]} @temp);
	
	$_[0]->{cache}->{namespaces} = \@temp;
	
	return \@temp;
}

sub namespaces_names {
	my ($self) = @_;
	my @result;
	
	return $self->{cache}->{namespaces_names} if defined $self->{cache}->{namespaces_names};
	
	foreach (@{ $_[0]->namespaces }) {
		push(@result, $_->[1]);
	}
	
	$self->{cache}->{namespaces_names} = \@result;
	
	return \@result;
}

sub current_byte {
	return $_[0]->{mediawiki}->current_byte;
}

sub size {
	return $_[0]->{mediawiki}->size;
}

sub get_category_anchor {
	my ($self) = @_;
	my $namespaces = $self->namespaces;
	my $cache = $self->{cache};
	my $ret = undef;
	
	if (defined($cache->{category_anchor})) {
		return $cache->{category_anchor};
	}

	foreach (@$namespaces) {
		my ($id, $name) = @$_;
		if ($id == 14) {
			$ret = $name;
		}
	}	
	
	$self->{cache}->{category_anchor} = $ret;
	
	return $ret;
}

sub next {
	my $self = $_[0];
	my $queue = $_[0]->{queue};
	my $next = shift(@$queue);
	my @results;

	return $next if defined $next;
	
	$next = $self->{mediawiki}->next;
	
	return undef unless defined $next;

	foreach ($next->revision) {
		push(@$queue, Parse::MediaWikiDump::page->new($next, $self->namespaces, $self->get_category_anchor, $_));
	}
	
	return shift(@$queue);
}

package #go away indexer! 
	Parse::MediaWikiDump::Pages;

use strict;
use warnings;

our @ISA = qw(Parse::MediaWikiDump::Revisions);

sub next {
	my $self = $_[0];
	my $next = $self->{mediawiki}->next;
	my $revision_count;
	
	return undef unless defined $next;
	
	$revision_count = scalar(@{[$next->revision]});
						#^^^^^ because scalar($next->revision) doesn't work
	
	if ($revision_count > 1) {
		die "only one revision per page is allowed\n";
	}

	return Parse::MediaWikiDump::page->new($next, $self->namespaces, $self->get_category_anchor);
}


package #go away indexer! 
	Parse::MediaWikiDump::page;

use strict;
use warnings;

our %REGEX_CACHE_CATEGORIES;

sub new {
	my ($class, $page, $namespaces, $category_anchor, $revision) = @_;
	my $self = {page => $page, namespaces => $namespaces, category_anchor => $category_anchor};
	
	$self->{revision} = $revision;
	
	return bless($self, $class);
}

sub _revision {
	if (defined($_[0]->{revision})) { return $_[0]->{revision}};
	
	return $_[0]->{page}->revision;
}

sub text {
	my $text = $_[0]->_revision->text;
	return \$text;
}

sub title {
	return $_[0]->{page}->title;
}

sub id {
	return $_[0]->{page}->id;
}

sub revision_id {
	return $_[0]->_revision->id;
}

sub username {
	return $_[0]->_revision->contributor->username;
}

sub userid {
	return $_[0]->_revision->contributor->id;
}

sub userip {
	return $_[0]->_revision->contributor->ip;
}

sub timestamp {
	return $_[0]->_revision->timestamp;
}

sub minor {
	return $_[0]->_revision->minor;
}

sub namespace {
	my ($self) = @_;
	my $title = $self->title;
	my $namespace = '';
	
	if (defined($self->{cache}->{namespace})) {
		return $self->{cache}->{namespace};
	}
	
	if ($title =~ m/^([^:]+):(.*)/o) {
		foreach (@{ $self->{namespaces} } ) {
			my ($num, $name) = @$_;
			if ($1 eq $name) {
				$namespace = $1;
				last;
			}
		}
	}

	$self->{cache}->{namespace} = $namespace;

	return $namespace;
}

sub redirect {
	my ($self) = @_;
	my $text = $self->text;
	my $ret;
	
	return $self->{cache}->{redirect} if defined $self->{cache}->{redirect};

	if ($$text =~ m/^#redirect\s*:?\s*\[\[([^\]]*)\]\]/io) {
		$ret = $1;
	} else {
		$ret = undef;
	}
	
	$self->{cache}->{redirect} = $ret;
	
	return $ret;
}

sub categories {
	my ($self) = @_;
	my $anchor = $$self{category_anchor};
	my $text = $self->text;
	my @cats;
	my $ret;
	
	return $self->{cache}->{categories} if defined $self->{cache}->{categories};
	
	if (! defined($REGEX_CACHE_CATEGORIES{$anchor})) {
		$REGEX_CACHE_CATEGORIES{$anchor} = qr/\[\[$anchor:\s*([^\]]+)\]\]/i;
	}
		
	while($$text =~ /$REGEX_CACHE_CATEGORIES{$anchor}/g) {
		my $buf = $1;
		
		#deal with the pipe trick
		$buf =~ s/\|.*$//;
		push(@cats, $buf);
	}

	if (scalar(@cats) == 0) {
		$ret = undef;
	} else {
		$ret = \@cats;
	}

	return $ret;
}


1;

__END__

=head1 NAME

MediaWiki::DumpFile::Compat - Compatibility with Parse::MediaWikiDump

=head1 SYNOPSIS

  use MediaWiki::DumpFile::Compat;

  $pmwd = Parse::MediaWikiDump->new;

  $pages = $pmwd->pages('pages-articles.xml');
  $revisions = $pmwd->revisions('pages-articles.xml');
  $links = $pmwd->links('links.sql');
  
=head1 ABOUT

This software suite provides the tools needed to process the contents of the XML page 
dump files and the SQL based links dump file from a Mediawiki instance. This is a compatibility 
layer between MediaWiki::Dumpfile and Parse::MediaWikiDump; 
instead of "use Parse::MediaWikiDump;" you "use MediaWiki::DumpFile::Compat;". The benefit of
using the new compatibility module is an increased processing speed - see the 
MediaWiki::DumpFile::Benchmarks documentation for benchmark results. 

=head1 MORE DOCUMENTATION

The original Parse::MediaWikiDump documentation is also available in this package; it has been updated
to include new features introduced by MediaWiki::DumpFile. You can find the documentation in the following
locations:

=over 4

=item MediaWiki::DumpFile::Compat::Pages

=item MediaWiki::DumpFile::Compat::Revisions

=item MediaWiki::DumpFile::Compat::page

=item MediaWiki::DumpFile::Compat::Links

=item MediaWiki::DumpFile::Compat::link

=back

=head1 USAGE

This module is a factory class that allows you to create instances of the individual 
parser objects. 

=over 4

=item $pmwd->pages

Returns a Parse::MediaWikiDump::Pages object capable of parsing an article XML dump file with one revision per each article.

=item $pmwd->revisions

Returns a Parse::MediaWikiDump::Revisions object capable of parsing an article XML dump file with multiple revisions per each article.

=item $pmwd->links

Returns a Parse::MediaWikiDump::Links object capable of parsing an article links SQL dump file.

=back

=head2 General

All parser creation invocations require a location of source data
to parse; this argument can be either a filename or a reference to an already
open filehandle. This entire software suite will die() upon errors in the file or if internal inconsistencies
have been detected. If this concerns you then you can wrap the portion of your code that uses these calls with eval().

=head1 COMPATIBILITY 

Any deviation of the behavior of MediaWiki::DumpFile::Compat from Parse::MediaWikiDump that is not 
listed below is a bug. Please report it so that this package can act as a near perfect standin for
the original. Compatibility is verified by using the existing Parse::MediaWikiDump test suite with the 
following adjustments:

=head2 Parse::MediaWikiDump::Pages

=over 4

=item

Parse::MediaWikiDump did not need to load all revisions of an article into memory when processing
dump files that contain more than one revision but this compatibility module does. The API does not
change but the memory requirements for parsing those dump files certainly do. It is, however, highly
unlikely that you will notice this as most of the documents with many revisions per article are so large
that Parse::MediaWikiDump would not have been able to parse them in any reasonable timeframe. 

=item 

The order of the results from namespaces() is now sorted by the namespace ID instead of being in document order

=back

=head2 Parse::MediaWikiDump::Links

=over 4

=item 

Order of values from next() is now in identical order as SQL file.

=back

=head1 BUGS

=over 4

=item

The value of current_byte() wraps at around 2 gigabytes of input XML; see http://rt.cpan.org/Public/Bug/Display.html?id=56843

=back

=head1 LIMITATIONS

=over 4

=item 

This compatibility layer is not yet well tested.

=back