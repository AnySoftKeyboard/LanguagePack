package MediaWiki::DumpFile::Pages::Lib;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(_safe_text);

sub _safe_text {
	my ($data, $name) = @_;
	my $found = $data->get_elements($name);
	
	if (! defined($found)) {
		return '';
	}
	
	 return $found->text;
}

1;