#!/usr/bin/perl -w

use lib 'perl-modules';
use strict;
use utf8;
use diagnostics;
use MediaWiki::DumpFile;

binmode STDOUT, ':utf8';

my $mw = MediaWiki::DumpFile->new;

my $file = shift(@ARGV) or die "haj a spicificari un dump XML d'û wikizziunariu";

my $pages = $mw->fastpages($file);
my $title;
my $text;

while (($title, $text) = $pages->next) {
    next if $title =~ /:/;
    $text =~ s/(’|\&apos;)/'/gm;
    $text =~ s/\x{200E}//gm;
    $text =~ s/\{\{[^\}\n]*\}\}//gm;
    $text =~ s/\<ref.*\>[^\<]*\<\/ref\>//gmi;
    $text =~ s/\<references.*$//gmi;
    $text =~ s/^\#(REDIRECT|RINVIA).*//gmi;
    $text =~ s/^[!\|].*$//gm;
    $text =~ s/\[\[[\w\s"':\,\.\-\_\(\)\#]+\|([\w\s"'\,\.\-\_\(\)]+)\]\]/$1/g; # [[wikilinks|(alternate text grabbed)]]
    $text =~ s/\[\[([\w\s"':\,\.\-\_\(\)]+)\]\]/$1/g; # [[(wikilink grabbed)]]
    $text =~ s/^=.*//gm;
    #$text =~ s/\[\[(catigurìa|category):.*//gmi;
    $text =~ s/__TOC__//gmi;
    $text =~ s/\[http.* .*\]//gm;
    $text =~ s/\<br *\/\>//gm;
    $text =~ s/\[\[(|Catigurìa|Category|Image|File|Wikipedia|Mmàggini|Aiutu|Immagine)\:.*\]\]//gmi;
    

    foreach my $line (split /^/, $text) {
        chomp $line;
        #print $line, "\n" if $line =~ /^=/;
        # [[testo]] [[ŧesto|testo_ok]]
        #$line =~ s/^=.*//g;
        next if $line =~ /\[\[/;
        print $line, "\n" if $line;
    }
    #print $text, "\n" unless $title =~ /:/; # stampa sulu l'articuli d'û namespace principali
}
