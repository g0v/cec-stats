#!/usr/bin/env perl

=encoding utf8

=head1 USAGE

perl bin/convert.pl data/第09屆立法委員選舉（區域）候選人得票數.html > data/第09屆立法委員選舉（區域） 候選人得票數.csv

=cut

use v5.18;
use strict;

use HTML::TableExtract;
use Text::CSV;
use File::Slurp 'read_file';

my $html = read_file($ARGV[0], { binmode => ":utf8" });

my $extractor = HTML::TableExtract->new();
$extractor->parse($html);

my @rows;
for my $table ($extractor->tables) {
    my $span;
    for my $row ($table->rows) {
        @$row = map { s/^\s+//; s/\s+$//; $_ } @$row;
        if ($row->[0]) {
            $span = $row->[0];
        } else {
            $row->[0] = $span;
        }
        push @rows, $row;
    }
}

binmode STDOUT, ":utf8";
my $csv = Text::CSV->new({ binary => 1 });
for my $row (@rows) {
    $csv->combine(@$row);
    say $csv->string;
}
