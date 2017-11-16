#!/usr/bin/perl -w

# © 2017, David Paleino <david@cademiasiciliana.org>
#
# Permission to use, copy, modify, distribute, and sell this software
# and its documentation for any purpose is hereby granted without
# fee, provided that the above copyright notice appear in all copies
# and that both that copyright notice and this permission notice
# appear in supporting documentation, and that the name of the authors
# not be used in advertising or publicity pertaining to distribution of the
# software without specific, written prior permission.  The authors make no
# representations about the suitability of this software for any
# purpose.  It is provided "as is" without express or implied
# warranty.
#
# THE AUTHORS DISCLAIM ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
# INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN
# NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY SPECIAL, INDIRECT OR
# CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
# OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
# NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
# CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

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
