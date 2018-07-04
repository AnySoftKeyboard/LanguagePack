package MediaWiki::DumpFile::SQL;

our $VERSION = '0.2.2';

use strict;
use warnings;
use Data::Dumper;
use Carp qw(croak);
use Scalar::Util qw(reftype);

use IO::Uncompress::AnyUncompress qw($AnyUncompressError);

#public methods
sub new {
	my ($class, $file) = @_;
	my $self = { };
	
	if (! defined($file)) {
		croak "must specify a filename or open filehandle";
	}
		
	bless($self, $class);
	
	$self->{buffer} = [];
	$self->{file} = $file;
	$self->{fh} = undef;
	$self->{table_name} = undef;
	$self->{schema} = undef;
	$self->{type_map} = undef;
	$self->{table_statement} = undef;
	
	$self->create_type_map;
	$self->open_file;
	$self->parse_table;
	
	return $self;
}

sub next {
	my ($self) = @_;
	my $buffer = $self->{buffer};
	my $next;
	
	while(! defined($next = shift(@$buffer))) {
		if (! $self->parse_more) {
			return undef;
		}
	}
	
	return $next;
}

sub table_name {
	my ($self) = @_;
	return $self->{table_name};
}

sub table_statement {
	my ($self) = @_;
	return $self->{table_statement};
}

sub schema {
	my ($self) = @_;
	return @{$self->{schema}};
}

#private methods
sub open_file {
	my ($self) = @_;
	my $file = $self->{file};
	my $type = reftype($file);
	my $fh;
	
	$self->{fh} = $fh = IO::Uncompress::AnyUncompress->new($file);
	my $line = <$fh>;
	
	if ($line !~ m/^-- MySQL dump/) {
		die "expected MySQL dump file";
	}
	
	return;
}

sub parse_table {
	my ($self) = @_;
	my $fh = $self->{fh};
	my $found = 0;
	my $table;
	my $table_statement;
	my @cols;
	
	#find the CREATE TABLE line and get the table name
	while(<$fh>) {
		if (m/^CREATE TABLE `([^`]+)` \(/) {
			$table = $1;
			$table_statement = $_;
			
			last;
		}
	}
	
	die "expected CREATE TABLE" unless defined($table);
	
	while(<$fh>) {
		$table_statement .= $_;

		if (m/^\)/) {
			last;
		} elsif (m/^\s+`([^`]+)` (\w+)/) {
			#this regex ^^^^ matches column names and types
			push(@cols, [$1, $2]);
		}
	}
	
	if (! scalar(@cols)) {
		die "Could not find columns for $table";
	}

	$self->{table_name} = $table;
	$self->{schema} = \@cols;
	$self->{table_statement} = $table_statement;
	
	return 1;
}

#returns false at EOF or true if more data was parsed
sub parse_more {
	my ($self) = @_;
	my $fh = $self->{fh};
	my $insert;
	
	if (! defined($fh)) {
		return 0;
	}
	
	while(1) {
		$insert = <$fh>;
		
		if (! defined($insert)) {
			close($fh) or die "could not close: $!";
			$self->{fh} = undef;
			
			return 0;
		}
		
		if ($insert =~ m/^INSERT INTO/) {
			$self->parse($insert);
			return 1;
		} 
	}
}

#this parses a complete INSERT line into the individual
#components
sub parse {
	my ($self, $string) = @_;
	my $buffer = $self->{buffer};
	my $compiled = $self->compile_config;  
	my $found = 0;
	
	$_ = $string;
	
	#check the table name
	m/^INSERT INTO `(.*?)` VALUES /g or die "expected header";
	if ($self->{table_name} ne $1) {
		die "table name mismatch: $1";
	}
		
	while(1) {		
		my %new;
		my $depth = 0;
		
		#apply the various regular expressions to the
		#string in order
		foreach my $handler (@$compiled) {
			my ($col, $cb) = @$handler;
			my $ret;
			
			$depth++;
			
			#these callbacks also use $_
			eval { $ret = &$cb };
			
			if ($@) {
				die "parse error pos:" . pos() . " depth:$depth error: $@";
			}
			
			#column names starting with # are part of the parser, not user data
			if ($col !~ m/^#/) {
				$new{$col} = $ret;
			}
		}
		
		push(@$buffer, \%new);
		$found++;

		if (m/\G, ?/gc) {
			#^^^^ match the delimiter between rows
			next;
		} elsif (m/\G;$/gc) {
			#^^^^ match end of statement
			last;
		} else {
			die "expected delimter or end of statement. pos:" . pos;
		}
	}
	
	return $found;
}

#functions for the parsing engine

#maps between MySQL types and our types
sub create_type_map {
	my ($self) = @_;
	
	$self->{type_map} = {
		int => 'int',
		tinyint => 'int',
		bigint => 'int',
		
		char => 'varchar',
		varchar => 'varchar',
		enum => 'varchar',
		
		double => 'float',
		
		timestamp => 'int',
		
		blob => 'varchar',
		mediumblob => 'varchar',
		mediumtext => 'varchar',
		tinyblob => 'varchar',
		varbinary => 'varchar',
		
	};
	
	return 1;
}

#convert the schema into a list of callbacks
#that match the schema and extract data from it
sub compile_config {
	my ($self) = @_;
	my $schema = $self->{schema};
	my @handlers;
	
	push(@handlers, ['#start', new_start_data()]);

	foreach (@$schema) {
		my ($name, $type) = @$_;

		my $oldtype = $type;
		$type = $self->{type_map}->{lc($type)};
		
		if (! defined($type)) {
			die "type map failed for $oldtype";
		}

		if ($type eq 'int') {
			push(@handlers, [$name, new_int()], ['#delim', new_delim()]);
		} elsif ($type eq 'varchar') {
			push(@handlers, [$name, new_varchar()], ['#delim', new_delim()]);
		} elsif($type eq 'float') {
			push(@handlers, [$name, new_float()], ['#delim', new_delim()]);
		} else {
			die "unknown type: $type";
		}
	}	
	
	pop(@handlers); #gets rid of that extra delimiter
	push(@handlers, ['#end', new_end_data()]);
	
	return \@handlers;
}

sub unescape {
	my ($input) = @_;
	
	if ($input eq '\\\\') {
		return '\\';
	} elsif ($input eq "\\'") {
		return("'");
	} elsif ($input eq '\\"') {
		return '"';
	} elsif ($input eq '\\n') {
		return "\n";
	} elsif ($input eq '\\t') {
		return "\t";
	} else {
		die "can not unescape $input";
	}
}


#functions that create callbacks that match and extract
#data from INSERT lines

#it is critical that these regular expressions use the /gc option
#or the parser will stop functioning as soon as a regex with
#out those options is encountered and debugging becomes
#almost impossible

sub new_int {
	return sub {
		m/\GNULL/gc and return undef;
		m/\G(-?[\d]+)/gc or die "expected int"; return $1;
	};
}

sub new_float {
	return sub {
		m/\GNULL/gc and return undef;
		m/\G(-?[\d]+(?:\.[\d]+(e-?[\d]+)?)?)/gc or die "expected float"; return $1;
	}
}

sub new_varchar {
	return sub {
		my $data;
		
		m/\GNULL/gc and return undef;

		#does not handle very long strings; crashes perl 5.8.9 causes 5.10.1 to error out	
		#m/\G'((\\.|[^'])*)'/gc or die "expected varchar"; 
		#thanks somni!
		m/'((?:[^\\']*(?:\\.[^\\']*)*))'/gc or die "expected varchar"; 
		$data = $1;
		$data =~ s/(\\.)/unescape($1)/e;
		
		return $data;
	}
}

sub new_delim {
	return sub { 
		m/\G, ?/gc or die "expected delimiter"; return undef; 
	};
}

sub new_start_data {	
	return sub {
		m/\G\(/gc or die "expected start of data set"; return undef; 
	};
}

sub new_end_data {
	return sub {
		m/\G\)/gc or die "expected end of data set"; return undef;
	}
}

1;

__END__

=head1 NAME

MediaWiki::DumpFile::SQL - Process SQL dump files from a MediaWiki instance

=head1 SYNOPSIS

  use MediaWiki::DumpFile::SQL;
  
  $sql = MediaWiki::DumpFile::SQL->new('dumpfile.sql');
  #many compression formats are supported
  $sql = MediaWiki::DumpFile::SQL->new('dumpfile.sql.gz');
  $sql = MediaWiki::DumpFile::SQL->new('dumpfile.sql.bz2');
  $sql = MediaWiki::DumpFile::SQL->new(\*FH);
  
  @schema = $sql->schema;
  $name = $sql->table_name;
  
  while(defined($row = $sql->next)) {
  	#do something with the data from the row
  }

=head1 FUNCTIONS

=head2 new

This is the constructor for this package. It is called with a single parameter: the location of
a MediaWiki SQL dump file or a reference to an already open file handle. 

Only the definition and data for the B<first> table in a SQL dump file is processed.

=head2 next

Returns a hash reference where the key is the column name from the table and the value of the hash is
the value for that column and row. Returns undef when there is no more data available. 

=head2 table_name

Returns a string of the table name that was discovered in the dump file. 

=head2 table_statement

Returns a string of the unparsed CREATE TABLE statement straight from the
dump file. 

=head2 schema

Returns a list that represents the table schema as it was parsed by this module. Each item in the list
is a reference to an array with two elements. The first element is the name of the row and the second
element is the MySQL datatype associated with the row. The list is in an identical order as the definitions
in the CREATE TABLE statement. 

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
