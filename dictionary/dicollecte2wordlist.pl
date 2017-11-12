use strict;
use utf8;

use open qw/:std :utf8/;

our $LETTERS_OK=qr((?i)(?:(?![×Þß÷þø])[-a-zÀ-ÿœŒ ]));

my %Flexions=();
my %lemmes=();
my %letters=();

my @columns=();
my ($nbLines, $nbEntries)=(0,0);
my %nbFiltered=();
while (my $line=<>) {
	chomp $line; $nbLines++;
	# the header line
	if ($line=~m/^id\t/) {
		@columns=split /\t/, $line;
		next;
	}
	# skip comment before header line
	next if (!@columns);
	$nbEntries++;
	my %entry=();
	@entry{@columns} = split /\t/, $line;
	# filter entry by 'Indice de fréquence'
	if ($entry{'Indice de fréquence'} < 1) {
		$nbFiltered{'Indice de fréquence'}++;
		next;
	}
	# filter entry by 'Sous-dictionnaire'
	if ($entry{'Sous-dictionnaire'}!~m/[*MC]/) {
		$nbFiltered{'Sous-dictionnaire'}++;
		next;
	}
	my $flexion = $entry{Flexion};
	$flexion=~s/_/ /g;
	my @fletters = (split //, $flexion);
	if (my @bad=(grep !/$LETTERS_OK/, @fletters)) {
		$nbFiltered{badLetter}++;
		$nbFiltered{$bad[0]}++;
		next;
	}
	foreach my $l (@fletters) { $letters{$l}++;}
	$Flexions{$flexion} = [] if (!defined $Flexions{$flexion});
	push @{$Flexions{$flexion}}, \%entry;
	$lemmes{$entry{Lemme}}++;
}

print STDERR "Read $nbLines lines, $nbEntries entries => ",scalar keys %Flexions," flexions (for ",(scalar keys %lemmes)," distinct lemas)\n";
print STDERR "Filtered: ",join(" ", map {$_.":".$nbFiltered{$_}} keys %nbFiltered),"\n";
my $il=0;
foreach my $l (sort {$letters{$b}<=>$letters{$a}} keys %letters) {
	print STDERR " $l:$letters{$l},";
	print STDERR "\n" if ((++$il % 10) == 0)
}
print STDERR "\n";

# merge flexions
my %Flexions_freq=();
while (my ($flexion, $entries) = each %Flexions) {
	my $freq = 0;
	foreach my $entry (@{$entries}) {
		$freq+=$entry->{'Fréquence'};
	}
	# convert frequency into [1-255]
	$Flexions_freq{$flexion}= ($freq > 1.) ? 255	# frequence > 1 (!) => 255
		: ($freq < 1.0e-10) ? 1 # low frequencies => 1 
		: 3 + (25 * (10 + log($freq)/log(10))); # logarithmic repartition between [3-253]
}


# Print the <wordlist>
print '<?xml version="1.0" encoding="UTF-8"?>',"\n";
print '<wordlist>',"\n";
foreach my $flexion (sort {$Flexions_freq{$b}<=>$Flexions_freq{$a}} keys %Flexions_freq) {
	print "\t<w f=\"",int($Flexions_freq{$flexion}),"\">$flexion</w>\n";
}
print '</wordlist>',"\n";
