#!perl

## script  : bank_inhouse.pl
#=============================================================================
#                              Included modules and versions
#=============================================================================
## Perl modules
use strict ;
use warnings ;
use Carp qw (cluck croak carp) ;

use Data::Dumper ;
use Getopt::Long ;
use POSIX ;
use List::Util qw( min max );
use FindBin ; ## Allows you to locate the directory of original perl script

## Specific Modules
use lib $FindBin::Bin ;
my $binPath = $FindBin::Bin ;
use lib::bih qw( :ALL ) ;

## PFEM Perl Modules
use lib::conf  qw( :ALL ) ;
use lib::csv  qw( :ALL ) ;

## Initialized values
my ( $help ) = ( undef ) ;
my ( $mass ) = ( undef ) ;
my ( $masses_file, $nbline_header, $col_mass ) = ( undef, undef, undef ) ;
my ( $col_rt, $manual_rt, $rt_delta, $mz_delta_type, $mz_delta, $rtdb ) = ( undef, undef, undef, undef, undef, undef ) ;
my ( $mode, $tissues, $bank_in, $bank_name, $col_mzdb) = ( undef, undef, undef, undef, undef ) ;
my ( $out_tab, $out_html, $out_xls, $out_json, $out_full ) = ( undef, undef, undef, undef, undef ) ;
my ($rest_mode) = ('no') ;

my ( $verbose ) = ( 2 ) ; ## verbose level is 3 for debugg

#=============================================================================
#                                Manage EXCEPTIONS
#=============================================================================

&GetOptions ( 	"h"					=> \$help,				# HELP
				"masse:s"			=> \$mass,				## option : one masse
				"input:s"			=> \$masses_file,		## option : path to the input
				"rest:s"			=> \$rest_mode,			## option : allow uses of peakforest rest service 
				"nbheader:i"		=> \$nbline_header,		## numbre of header line present in file
				"colrt:i"			=> \$col_rt,			## Column retention time for retrieve formula/masses list in tabular file
				"rt:s"				=> \$manual_rt,			## Retention time for manual masses list
				"rt_delta:f"		=> \$rt_delta,			## Delta for retention time
				"colmass:i"			=> \$col_mass,			## Column id for retrieve formula list in tabular file
				"mz_delta:s"		=> \$mz_delta_type,		## Delta type for masses
				"mass_delta:f"		=> \$mz_delta,			## Delta for masses
				"mode:s"			=> \$mode,				## Molecular species (positive/negative/neutral) 
				"tissues:s"			=> \$tissues,			## Restricted to certain characterization and localization (blood/plasma/urine/peptide) 
				"bank_in:s"			=> \$bank_in,			## option : path to a personal data bank
				"bank_name:s"		=> \$bank_name,			## option : name of the bank
				"mzdb:i"			=> \$col_mzdb,			## Column number in which is the masses of the personal data bank
				"rtdb:i"			=> \$rtdb,				## Column number in which is the retention time of the personal data bank
				"outputJson:s"		=> \$out_json,			## option : path to the ouput (results)
				"outputXls:s"		=> \$out_xls,			## option : path to the ouput (tabular : results )
				"outputTab:s"		=> \$out_tab,			## path to the ouput (tabular : input+results (1 col) )
				"outputView:s"		=> \$out_html,			## option : path to the results view (output2)
				"outputFull:s"		=> \$out_full,			## path to the ouput (tabular : input+results (x col) )
			) ;

#=============================================================================
#                                EXCEPTIONS
#=============================================================================
## if you put the option -help or -h function help is started
if ( defined $help ) { &help() ; }

#=============================================================================
#                                MAIN SCRIPT
#=============================================================================


print "The bank_inhouse program is launched as:\n";
print "./bank_inhouse.pl " ;
print "--h "  if (defined $help) ;
print "--masse $mass " if (defined $mass) ;
print "--input $masses_file " if (defined $masses_file) ;
print "--rest $rest_mode " if (defined $rest_mode) ;
print "--nbheader $nbline_header " if (defined $nbline_header) ;
print "--colrt $col_rt " if (defined $col_rt) ;
print "--rt $manual_rt " if (defined $manual_rt) ;
print "--rt_delta $rt_delta " if (defined $rt_delta) ;
print "--colmass $col_mass " if (defined $col_mass) ;
print "--mz_delta $mz_delta_type " if (defined $mz_delta_type) ;
print "--mass_delta $mz_delta " if (defined $mz_delta) ;
print "--mode $mode " if (defined $mode) ;
print "--tissues $tissues " if (defined $tissues) ;
print "--bank_in $bank_in " if (defined $bank_in) ;
print "--bank_name $bank_name " if (defined $bank_name) ;
print "--mzdb $col_mzdb " if (defined $col_mzdb) ;
print "--rtdb $rtdb " if (defined $rtdb) ;
print "--outputJson $out_json " if (defined $out_json) ;
print "--outputXls $out_xls " if (defined $out_xls) ;
print "--outputTab $out_tab " if (defined $out_tab) ;
print "--outputView $out_html " if (defined $out_html) ;
print "--outputFull $out_full " if (defined $out_full) ;
print "\n" ;



## -------------- Conf file ------------------------ :
my ( $CONF, $PF_CONF ) = ( undef, undef ) ;
foreach my $conf ( <$binPath/*.cfg> ) {
	my $oConf = lib::conf::new() ;
	$CONF = $oConf->as_conf($conf) ;
}

## PForest dedicated conf
if ((defined $rest_mode ) and ( $rest_mode eq "yes" )) {
	foreach my $ini ( <$binPath/*.ini> ) {
		my $oConf = lib::conf::new() ;
		$PF_CONF = $oConf->as_conf($ini) ;
	}
}

## --------------- Global parameters ---------------- :
my ( $masses, $rt, $results, $header_choice ) = ( undef, undef, undef, undef, undef ) ; ##############
my ( $complete_rows, $nb_pages_for_html_out ) = ( undef, 1 ) ;

my $oBih = lib::bih::new() ;

## --------------- retrieve input data -------------- :

## manage manual mass(es)
if ( ( defined $mass ) and ( $mass ne "" ) ) {
	$mass =~ tr/,/./ ;
	@$masses = split(' ', $mass);
	if  ( ( defined $manual_rt ) and ( $manual_rt ne "" ) ) {
		$manual_rt =~ tr/,/./ ;
		@$rt = split(' ', $manual_rt) ;
		if  ( $#$rt != $#$masses) {	croak "You have not given the same number of masses and retention time\n" ;	}
	}
} ## END IF

## manage csv file containing list of masses
elsif ( ( defined $masses_file ) and ( $masses_file ne "" ) and ( -e $masses_file ) ) {
	## parse all csv for later : output csv build
	my $ocsv_input  = lib::csv->new() ;
	my $complete_csv = $ocsv_input->get_csv_object( "\t" ) ;
	$complete_rows = $ocsv_input->parse_csv_object($complete_csv, \$masses_file) ;
	
	## parse csv ids and masses
	my $ocsv = lib::csv->new() ;
	my $csv = $ocsv->get_csv_object( "\t" ) ;
	
	if ( ( defined $nbline_header ) and ( $nbline_header > 0 ) ) { $header_choice = 'yes' ; }
	else{ $header_choice = 'no' ; }
	
	## retrieve mz values on csv
	$masses = $ocsv->get_value_from_csv_multi_header( $csv, $masses_file, $col_mass, $header_choice, $nbline_header ) ; 
	
	## retrieve rt values on csv
	if  ( ( defined $col_rt ) and ( $col_rt ne "" ) ) {
		$rt = $ocsv->get_value_from_csv_multi_header( $csv, $masses_file, $col_rt, $header_choice, $nbline_header ) ; ## retrieve rt values on csv
	}
}

# --------------- retrieve personal data bank input -------------- :

my ($complete_bank, $bank_head) = (undef, undef) ;

## check up $bank_in and parse
if ( ( defined $bank_in ) and ( $bank_in ne '' ) and ( -e $bank_in ) and ( defined $col_mzdb ) and ( $col_mzdb ne '' ) ) {
	## parse csv bank_in
	my $ocsv_input  = lib::csv->new() ;
	my $complete_csv = $ocsv_input->get_csv_object( "\t" ) ;
	($complete_bank, $bank_head)= $oBih->parse_bank_interest($complete_csv, \$bank_in, $col_mzdb-1) ;
}
## manage rest service of PeakForest and set $masses and $rt with given databases
elsif  ( ( defined $rest_mode ) and ( $rest_mode eq "yes" ) ) {
	$bank_name = "PeakForest";
	if ( ( $PF_CONF->{PF_GLOBAL_TOKEN} ne "" ) and ( $PF_CONF->{PF_WS_URL} ne "" ) ) {
		## init
		my $opfws = lib::bih::new() ;
		## get min and max values of user query
		my ($min, $max) = (0, 0) ;
			
		if ( ( defined $masses ) and ( scalar (@{$masses}) > 0 ) ) {
			$min = min @{$masses} ;
			$max = max @{$masses} ;

			my ( $min_delta, undef ) = $opfws->mz_delta_conversion(\$min, \$mz_delta_type, \$mz_delta) ;
			my ( undef, $max_delta ) = $opfws->mz_delta_conversion(\$max, \$mz_delta_type, \$mz_delta) ;

			## get clean range database json from PForest WS : 
			my $pf_json = $opfws->db_pforest_get_clean_range($PF_CONF->{PF_WS_URL}, $PF_CONF->{PF_REST_QUERY_CLEAN_RANGE}, $$min_delta, $$max_delta, $mode) ;
			if (defined $pf_json) {
				($complete_bank, $bank_head) = $opfws->map_pfjson_bankobject($pf_json) ;
			}
		} ## End IF
		else {
			croak "Fatal error : your mass list is empty\n" ;
		}
	} ## End IF PForest param
	else {	croak "Can't work : missing a PForest REST paramater\n" ;	}
} ## End ELSIF PForest
elsif ( ( defined $CONF->{'INHOUSE_BANK'} ) and ( $CONF->{'INHOUSE_BANK'} ne '' ) ) {
	
	$col_mzdb = $CONF->{'INHOUSE_BANK_MZ_COLUMN'} ;
	$bank_name = $CONF->{'INHOUSE_BANK_NAME'} ;
	my $html_file = $binPath.'/'.$CONF->{'INHOUSE_BANK'} ;
	
	if  ( (defined $col_rt) or (defined $manual_rt) or (defined $rt_delta) ) {	croak "No retention time in the internal bank, please use your own bank\n" ;	}
	
	if ( -e $html_file ) {
		## parse all csv for later : output csv build
		my $ocsv_input  = lib::csv->new() ;
		my $complete_csv = $ocsv_input->get_csv_object( "\t" ) ;
		($complete_bank, $bank_head)= $oBih->parse_bank_interest($complete_csv, \$html_file, $col_mzdb-1) ;
	}
	else {	croak "Can't work : no local inhouse bank name '$html_file'\n" ;	}
}
else {	croak "Can't work : missing an inhouse bank\n" ;	}

## ---------------- launch queries -------------------- :

my $ionization = undef ;
my $characterization = undef ;
my $valH = undef ;
my $bank = undef ;
my $search_condition = undef ;

#($valH, $ionization)= $oBih->manage_mode($mode, $CONF->{'PROTON_MZ'}, $CONF->{'ELECTRON_MZ'}) ;

######### Manage Tissues ##############################################################################
#if ( ( !defined $tissues ) or ( $tissues eq '' ) or ( $tissues eq 'none' ) ) {
#	$characterization = ['None'];
#} else {	@{$characterization} = split(",", $tissues);	}
######### End #########################################################################################

#if ( (@$ionization = (['None'])) and (@$characterization = (['None']))) {	$bank = $complete_bank;	}
#else  {	$bank = FILTER LA BANK;	}
$bank = $complete_bank;
$valH = 0 ;

#if ( ( defined $mz_delta ) and ( $mz_delta > 0 ) and ( defined $ionization ) and ( defined $characterization ) and ( defined $masses ) and ( defined $ids ) and ( defined $bank ) ) {
#	$search_condition = "Search params : Molecular specie = $mode / delta = $mz_delta / characterization and localization = $tissues \n bank file = $bank_in" ;

if ( ( defined $mz_delta ) and ( $mz_delta >= 0 ) and ( defined $masses ) and ( defined $bank ) ) {
	## prepare masses list and execute query
	$results = [] ;
	if ($mz_delta != 0){
		my @sort_masses_bank = sort { $a <=> $b } keys(%$bank);
		
		my $compt_masses = 0;
		foreach my $mz (@$masses) {
			$compt_masses++;
			my ($MZmessage) = $oBih->check_interval($mz, $CONF->{'BANK_MZ_MIN'}, $CONF->{'BANK_MZ_MAX'}) ;
			if ( $MZmessage eq 'OK' ){
				my ( $min, $max ) = $oBih->mz_delta_conversion(\$mz, \$mz_delta_type, \$mz_delta) ;
				
				my ($marj_inf) = $oBih->dichotomi_search(\@sort_masses_bank, $min) ;
				my ($marj_sup) = $oBih->dichotomi_search(\@sort_masses_bank, $max) ;
				
				my $result = [];
				if($$marj_inf != $$marj_sup){
					if ($$marj_inf == -1){	$$marj_inf=0;	}
					for (my $i=$$marj_inf; $i<$$marj_sup; $i++){
						my $bank_tmp = $$bank{$sort_masses_bank[$i]};
						if  ( ( defined $rt ) and ( $rt ne "" ) ) {
							my ($RTmessage) = $oBih->check_interval($$rt[$compt_masses-1], $CONF->{'BANK_RT_MIN'}, $CONF->{'BANK_RT_MAX'}) ;
							if ( $RTmessage eq 'OK' ){
								my $bank_rt = [];
								for(my $nb_rt=0; $nb_rt<=$#$bank_tmp; $nb_rt++){
									my ($RTbank) = $oBih->check_interval($bank_tmp->[$nb_rt]->[$rtdb-1], $CONF->{'BANK_RT_MIN'}, $CONF->{'BANK_RT_MAX'}) ;
									my ($RTsearch) = $oBih->check_interval($bank_tmp->[$nb_rt]->[$rtdb-1], $$rt[$compt_masses-1]-$rt_delta, $$rt[$compt_masses-1]+$rt_delta) ;
									if ( ($RTbank eq 'OK') and ($RTsearch eq 'OK') ){
										push (@$result, $bank_tmp->[$nb_rt]) ;
									}
									elsif ($RTbank ne 'OK'){	croak "At least one retention time in bank is not valid : $RTbank\n" ;	}
								}
							}
							else {	croak "The $compt_masses th analyzed retention time : $RTmessage\n" ;	}
						}
						else {	push (@$result, @$bank_tmp) ;	}
					}
				}
				else{	$result = [];	}
				push (@$results, [@$result]) ;
			}
			else {	croak "The $compt_masses th value : $MZmessage\n" ;	}
			print Dumper $results if ($verbose>2) ;
		} ## End FOREACH MZ queried
	} ## End IF
	else{
		my $result = [];
		my $compt_masses = 0;
		foreach my $mz (@$masses) {
			$compt_masses++;
			my ($MZmessage) = $oBih->check_interval($mz, $CONF->{'BANK_MZ_MIN'}, $CONF->{'BANK_MZ_MAX'}) ;
			if ( $MZmessage eq 'OK' ){
				if ($$bank{$mz}){
					my $bank_tmp = $$bank{$mz};
					if  ( ( defined $rt ) and ( $rt ne "" ) ) {
						my ($RTmessage) = $oBih->check_interval($$rt[$compt_masses-1], $CONF->{'BANK_RT_MIN'}, $CONF->{'BANK_RT_MAX'}) ;
						if ( $RTmessage eq 'OK' ){my $bank_rt = [];
							for(my $nb_rt=0; $nb_rt<=$#$bank_tmp; $nb_rt++){
								my ($RTbank) = $oBih->check_interval($bank_tmp->[$nb_rt]->[$rtdb-1], $CONF->{'BANK_RT_MIN'}, $CONF->{'BANK_RT_MAX'}) ;
								my ($RTsearch) = $oBih->check_interval($bank_tmp->[$nb_rt]->[$rtdb-1], $$rt[$compt_masses-1]-$rt_delta, $$rt[$compt_masses-1]+$rt_delta) ;
								if ( ($RTbank eq 'OK') and ($RTsearch eq 'OK') ){
									push (@$bank_rt, $bank_tmp->[$nb_rt]) ;
								}
								elsif ($RTbank ne 'OK'){	croak "At least one retention time in bank is not valid : $RTbank\n" ;	}
							}
							if ($#$bank_rt>=0){		## If there is at least one result
								push (@$result, $bank_rt) ;
							}	## else $bank_rt = [] as defined
						}
						else {	croak "The $compt_masses th analyzed retention time : $RTmessage\n" ;	}
					}
					else {	push (@$result, [$bank_tmp]) ;	}
				}
				else {	push (@$result, [] ) ;	}
			}
			else {	croak "The $compt_masses th mass : $MZmessage\n" ;	}
		}
		$results = [@$results, @$result] ;
	}
}
else {
	croak "Can't work : missing paramaters (list of ids, masses, delta, ionization, characterization or inhouse_bank)\n" ;
} ## end ELSE


if  ( ( defined $rt ) and ( $rt ne "" ) ) {	unshift (@$bank_head, ("MzDelta_Query-Bank(".$mz_delta.$mz_delta_type.")", "MzBank", "RtQuery", "RtDelta_Query-Bank(".$rt_delta."min.)", "RtBank")) ;	}
else {	unshift (@$bank_head, ("MzDelta_Query-Bank(".$mz_delta.$mz_delta_type.")", "MzBank")) ;	}


## -------------- Produce JSON output ------------------ :
if ( ( defined $out_json ) and ( defined $results ) ) {
	open(JSON, '>:utf8', "$out_json") or die "Cant' create the json file\n" ;
	print JSON Dumper $results;
	close(JSON) ;
} ## END IF
else {
	#croak "Can't create a json output for Massbank : no result found or your output file is not defined\n" ;
}

## -------------- Produce HTML output ------------------ :

#if ( ( defined $out_html ) and ( defined $results ) ) {
#	## Uses N mz and theirs entries per page (see config file).
#	# how many pages you need with your input mz list?
#	$nb_pages_for_html_out = ceil( scalar(@{$masses} ) / $CONF->{HTML_ENTRIES_PER_PAGE} )  ;
#	
#	my $oHtml = lib::bih::new() ;
#	my ($tbody_object) = $oHtml->set_html_tbody_object( $nb_pages_for_html_out, $CONF->{HTML_ENTRIES_PER_PAGE} ) ;
#	($tbody_object) = $oHtml->add_mz_to_tbody_object($tbody_object, $CONF->{HTML_ENTRIES_PER_PAGE}, $masses, $ids) ;
#	($tbody_object) = $oHtml->add_entries_to_tbody_object($tbody_object, $CONF->{HTML_ENTRIES_PER_PAGE}, $masses, $results) ;
#	print Dumper $tbody_object;exit;
#	my $output_html = $oHtml->write_html_skel(\$out_html, $tbody_object, $nb_pages_for_html_out, $search_condition, $CONF->{'HTML_TEMPLATE'}, $CONF->{'JS_GALAXY_PATH'}, $CONF->{'CSS_GALAXY_PATH'}) ;
#	
#} ## END IF
#else {	croak "Can't create a HTML output for HMDB : no result found or your output file is not defined\n" ;	}

## -------------- Produce XLS like output ------------------ :
if ( ( defined $out_xls ) and ( defined $results ) ) {
	my $oxls = lib::bih::new() ;
	$oxls->write_excel_like_mass($masses, $mz_delta_type, $mz_delta, $col_mzdb, $rt, $rt_delta, $rtdb, $results, $out_xls, $bank_head) ;
} ## END IF
else {	croak "Can't create a tabular output for BiH (like xls): no result found or your output file is not defined\n" ;	}

## -------------- Produce CSV output ------------------ :
if (defined $results) {
	if ( defined $masses_file ) {	# produce a csv based on METLIN format
		if ( defined $out_tab ) {
			my $sep = "#";
			my $ocsv = lib::bih::new() ;
			my $lm_matrix = undef ;
			if ( ( $header_choice eq 'yes' ) and ( defined $nbline_header ) and ( $nbline_header > 0 )) {
				my $header = join("$sep", @$bank_head);
				my $out_head = "BiH_".$bank_name."_(".$header.")";
				$lm_matrix = $ocsv->set_bih_matrix_object($out_head, $masses, $col_mzdb, $results, $rt, $rtdb, $bank_head, $sep ) ;
				$lm_matrix = $ocsv->add_bih_matrix_to_input_matrix($complete_rows, $lm_matrix, $nbline_header-1) ;
			}
			elsif ( ( $header_choice eq 'no' ) or ( $nbline_header <= 0 )) {
				$lm_matrix = $ocsv->set_bih_matrix_object(undef, $masses, $col_mzdb, $results, $rt, $rtdb, $bank_head, $sep ) ;
				$lm_matrix = $ocsv->add_bih_matrix_to_input_matrix($complete_rows, $lm_matrix, 0) ;
			}
			else {	croak "The number of header line is not identifiable\n" ;	}
			$ocsv->write_csv_skel(\$out_tab, $lm_matrix) ;
		}
		else {	croak "Can't create a tabular output for BiH : your output file is not defined\n" ;	}
	}
	elsif (defined $mass) { } ## no csv output for manual masses
	else {	croak "the input format is not identifiable or your output file is not defined\n" ;	}
} ## END IF
else {	croak "Can't create a tabular output for BiH : no result found\n" ;	}

## -------------- Produce Full output ------------------ :
if (defined $results) {
	if ( defined $masses_file ) {
		if ( defined $out_full ) {
			my $sep = "\t";
			my $ofull = lib::bih::new() ;
			if ( ( $header_choice eq 'yes' ) and ( defined $nbline_header ) and ( $nbline_header > 0 )) {
				$ofull->write_full_excel_like($complete_rows, $sep, $masses, $mz_delta_type, $mz_delta, $col_mzdb, $rt, $rt_delta, $rtdb, $results, $out_full, $nbline_header, $bank_head, "BiH_$bank_name") ;
			}
			elsif ( ( $header_choice eq 'no' ) or ( $nbline_header <= 0 )) {
				$ofull->write_full_excel_like($complete_rows, $sep, $masses, $mz_delta_type, $mz_delta, $col_mzdb, $rt, $rt_delta, $rtdb, $results, $out_full, 0, undef, undef) ;
			}
			else {	croak "The number of header line is not identifiable\n" ;	}
		}
	}
	elsif (defined $mass) { } ## no csv output for manual masses
	else {	croak "the input format is not identifiable or your output file is not defined\n" ;	}
} ## END IF
else {	croak "Can't create a full output for BiH : no result found\n" ;	}


#====================================================================================
# Help subroutine called with -h option
# number of arguments : 0
# Argument(s)        :
# Return           : 1
#====================================================================================
sub help {
	print STDERR "
bank_inhouse

# bank_inhouse is a script to query a in house bank (file) using chemical mass and return a list of common names.
# Input : mass or list of masses
# Author : Marion LANDI and Franck Giacomoni (as maintainers)
# Email : franck.giacomoni\@inra.fr
# Version : 1.2.1
# Created : 15/10/2014
# Updated : 24/01/2019
USAGE :		 
		bank_inhouse.pl -masse [mass]
		 		-tolerance [Delta of mass (Da)] -mode [Ionization type: positive/negative/neutral] 
		 		-tissues [Restricted to certain tissues] -- optionnal
		 		-bank_in [file for in personal house bank] -- optionnal
		 		-outputTab [output file tabular format] -outputView [output file html format]
				-verbose
		OR				
		bank_inhouse.pl -input [path to list of masses file]
			-nbHeader [nb of lines of headers : 0-n] -colId [Ids colunm number in input file] -colmass [masses col] -colrt [RT col]
 			-tolerance [Delta of mass (Da)] -mode [molecular type: positive/negative/neutral]
 			-bank_in [file for in house bank]
 			-tissues [Restricted to certain tissues] 
 			-outputTab [output file tabular format] -outputView [output file html format]
		 				
		OR 
		bank_inhouse.pl	-masse [mass]
				-rest [get the PeakForest ref db : yes|no]
				-mz_delta [Delta type for mass (Da or PPM)] -mass_delta [Delta for mass (Da or PPM)] -mode [molecular type: positive/negative/neutral]
		 		-outputXls [output xls format]
		 		
		Others output formats: 		
		 		-outputJson [output json format]  -outputFull [output format is input+res]
		";
	exit(1);
}

## END of script - M Landi 

__END__

=head1 NAME

 bank_inhouse.pl -- script for

=head1 USAGE

 bank_inhouse.pl -precursors -arg1 [-arg2] 
 or bank_inhouse.pl -help

=head1 SYNOPSIS

This script manage ... 

=head1 DESCRIPTION

This main program is a ...

=over 4

=item B<function01>

=item B<function02>

=back

=head1 AUTHOR

Marion LANDI E<lt>marion.landi@clermont.inra.frE<gt>
Frank Giacomoni E<lt>franck.giacomoni@inra.frE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 VERSION

version 1.1.1 : 15 / 10 / 2014

version 1.1.2 : 21 / 11 / 2014

version 1.1.3 : 13 / 11 / 2018

version 1.2.0 : 12 / 12 / 2018

version 1.2.1 : 24 / 01 / 2019 - new version with no more rest methods


=cut
