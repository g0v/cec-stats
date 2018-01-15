#!/usr/bin/env perl

=encoding utf8

=head1 USAGE

perl bin/convert.pl data/第09屆立法委員選舉（區域）候選人得票數.html > data/第09屆立法委員選舉（區域） 候選人得票數.csv

=cut

use v5.18;
use strict;

use HTML::TableExtract;
use Text::CSV;
use File::Slurp qw'read_file write_file';

sub convert_one {
    my ($html_file_name, $csv_file_name) = @_;

    my $html = read_file($html_file_name, { binmode => ":utf8" });

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

    my $csv_content = "";
    my $csv = Text::CSV->new({ binary => 1 });
    for my $row (@rows) {
        $csv->combine(@$row);
        $csv_content .= $csv->string . "\n";
    }

    write_file( $csv_file_name, { binmode => ":utf8" }, \$csv_content );
}

for my $html_file_name (<data/*.html>) {
    my $csv_file_name = $html_file_name =~ s/\.html$/.csv/r;
    say "$html_file_name => $csv_file_name";
    convert_one($html_file_name, $csv_file_name);
}
