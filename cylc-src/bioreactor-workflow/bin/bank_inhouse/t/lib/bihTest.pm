package lib::bihTest ;

use diagnostics; # this gives you more debugging information
use warnings;    # this warns you of bad practices
use strict;      # this prevents silly errors
use Exporter ;
use Carp ;
use Data::Dumper ;

our $VERSION = "1.0";
our @ISA = qw(Exporter);
our @EXPORT = qw( map_pfjson_bankobject_Test parse_bank_interest_Test db_pforest_get_clean_range_Test check_interval_Test format_manual_list_values_Testvalues format_manual_list_values_Testids manage_mode_TestvalH manage_mode_Testionization mz_delta_conversion_Testmin mz_delta_conversion_Testmax dichotomi_search_Test );
our %EXPORT_TAGS = ( ALL => [qw( map_pfjson_bankobject_Test parse_bank_interest_Test db_pforest_get_clean_range_Test check_interval_Test format_manual_list_values_Testvalues format_manual_list_values_Testids manage_mode_TestvalH manage_mode_Testionization mz_delta_conversion_Testmin mz_delta_conversion_Testmax dichotomi_search_Test )] );

use lib '/Users/fgiacomoni/Inra/labs/perl/galaxy_tools/tool-bank_inhouse' ;
use lib::bih qw( :ALL ) ;
use lib::json qw( :ALL ) ;
use lib::csv qw( :ALL ) ;

sub check_interval_Test {
	my ( $value, $min, $max ) = @_ ;
	my $oBih = lib::bih->new() ;
	my ($message) = $oBih->check_interval($value, $min, $max) ;
	return($message) ;
}

sub format_manual_list_values_Testvalues {
	my ( $value, $sep ) = @_ ;
	my $oBih = lib::bih->new() ;
	my ($values, $ids) = $oBih->format_manual_list_values($value, $sep) ;
	return ($values) ;
}

sub format_manual_list_values_Testids {
	my ( $value, $sep ) = @_ ;
	my $oBih = lib::bih->new() ;
	my ($values, $ids) = $oBih->format_manual_list_values($value, $sep) ;
	return ($ids) ;
}

sub mz_delta_conversion_Testmin {
	my ( $mass, $delta_type, $mz_delta ) = @_ ;
	my $oBih = lib::bih->new() ;
	my ($min, $max) = $oBih->mz_delta_conversion(\$mass, \$delta_type, \$mz_delta) ;
	return($$min) ;
}

sub mz_delta_conversion_Testmax {
	my ( $mass, $delta_type, $mz_delta ) = @_ ;
	my $oBih = lib::bih->new() ;
	my ($min, $max) = $oBih->mz_delta_conversion(\$mass, \$delta_type, \$mz_delta) ;
	return($$max) ;
}

sub dichotomi_search_Test {
	my ( $tab, $search ) = @_ ;
	my $oBih = lib::bih->new() ;
	my ($position) = $oBih->dichotomi_search($tab, \$search) ;
	return($$position) ;
}

## SUB TEST for 
sub db_pforest_get_clean_range_Test {
    # get values
    my ( $host, $query, $min, $max, $mode ) = @_;
    my $json = undef ;
    
    my $oBih = lib::bih->new() ;
    $json = $oBih->db_pforest_get_clean_range($host, $query, $min, $max, $mode ) ;
    
    return($json) ;
}
## End SUB

## SUB TEST for 
sub parse_bank_interest_Test {
    # get values
    my ( $file, $col_interest ) = @_;
    
    my $ocsv_input  = lib::csv->new() ;
	my $ocsv = $ocsv_input->get_csv_object( "\t" ) ;
    
    my $oBih = lib::bih->new() ;
    my ($bank, $bank_header) = $oBih->parse_bank_interest($ocsv, \$file, $col_interest) ;
    
#    print Dumper $bank ;
    
    return($bank) ;
}
## End SUB


sub map_pfjson_bankobject_Test {
	# get values
    my ( $json ) = @_;
    
    my ($bank, $headers) = (undef, undef) ;
    
    my $oBih = lib::bih->new() ;
    ($bank, $headers) = $oBih->map_pfjson_bankobject($json) ;
#    print Dumper $headers ;
    return($bank, $headers) ;
}


1 ;