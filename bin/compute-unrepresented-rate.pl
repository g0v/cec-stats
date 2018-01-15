#!/usr/bin/env perl

=encoding utf8

=head1 Unrepresented Rate

The definition of "Unrepresented Rate" used in this program

    Unrepresented rate  := p(unrepresented votes)

    Unrepresented votes := count(votes to candidates who lost)

When unrepresented rate is 0, all voters are "represented" in the goverment machine.  When
unrepresented rate is 100, no voters are represented. (Not likely a case, assuming the voting system
is fair and no once cheats.)

This program compute the Unrepresented votes and rate for:

- per area
- per admin. division (county or city)
- total (the whole nation)

=cut

use v5.26;
use strict;
use warnings;
use autodie;
use Text::CSV;

sub compute_one {
    my ($csv_file) = @_;
    my $result = {
        area => {},
        total => {}
    };
    my $csv_reader = Text::CSV->new({ binary => 1 });

    # Columns:
    # 0:"地區",1:"姓名",2:"號次",3:"性別",4:"出生年次",5:"推薦政黨",6:"得票數",7:"得票率",8:"當選註記",9:"是否現任"
    open my $fh, "<:utf8", $csv_file;

    # skip first row, which is the column names.
    $_ = $csv_reader->getline($fh);

    while (my $row = $csv_reader->getline($fh)) {
        my $votes = $row->[6];
        my $is_elected = $row->[8];

        # say "<$votes> => <$is_elected>";

        $result->{total}{votes} += $votes;
        $result->{area}{$row->[0]}{votes} += $votes;

        unless ($is_elected) {
            $result->{total}{unrepresented_votes} += $votes;
            $result->{area}{$row->[0]}{unrepresented_votes} += $votes;
        }
        $result->{total}{unrepresented_votes} //= 0;
        $result->{area}{$row->[0]}{unrepresented_votes} //= 0;
    }
    close($fh);

    return $result;
}

for my $csv_file (sort <data/*.csv>) {
    my $stats_csv_file = $csv_file =~ s{^data/}{stats/UnrepresentedRate_}r;

    my $result = compute_one($csv_file);

    my @area_rate;
    for my $area (keys %{$result->{area}}) {
        my $area_result = $result->{area}{$area};
        push @area_rate, [
            $area,
            ($area_result->{unrepresented_votes} / $area_result->{votes}),
        ];
    }

    my $csv_writer = Text::CSV->new({ binary => 1 });
    open( my $stats_csv_fh, ">:utf8", $stats_csv_file );

    my sub csv_print {
        $csv_writer->print($stats_csv_fh, [@_]);
        print $stats_csv_fh "\n";
    };

    csv_print("Area", "Unrepresented Rate", "Unrepresented Votes", "Votes");

    csv_print(
        "(Total)",
        sprintf('%.4f', $result->{total}{unrepresented_votes} / $result->{total}{votes}),
        $result->{total}{unrepresented_votes},
        $result->{total}{votes}
    );

    for (sort { $b->[1] <=> $a->[1] } @area_rate)  {
        my ($area, $area_p) = @$_;
        my $area_result = $result->{area}{$area};
        csv_print($area, sprintf('%.4f', $area_p), $area_result->{unrepresented_votes}, $area_result->{votes});
    }
}
