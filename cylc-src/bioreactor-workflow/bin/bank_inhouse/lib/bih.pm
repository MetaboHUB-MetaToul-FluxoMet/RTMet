package lib::bih ;

use strict;
use warnings ;
use Exporter ;
use Carp ;
use Math::BigFloat;

use LWP::Simple;
use LWP::UserAgent;
use URI::URL;
use SOAP::Lite;
use Encode;
use HTML::Template ;
#use Net::SSL ;
use Data::Dumper ;
#use REST::Client;	
use JSON;

use vars qw($VERSION @ISA @EXPORT %EXPORT_TAGS);

our $VERSION = "1.0";
our @ISA = qw(Exporter);
our @EXPORT = qw( db_pforest_get_clean_range map_pfjson_bankobject prepare_multi_masses_query );
our %EXPORT_TAGS = ( ALL => [qw( db_pforest_get_clean_range map_pfjson_bankobject prepare_multi_masses_query  )] );

=head1 NAME

My::Module - An example module

=head1 SYNOPSIS

    use My::Module;
    my $object = My::Module->new();
    print $object->as_string;

=head1 DESCRIPTION

This module does not really exist, it
was made for the sole purpose of
demonstrating how POD works.

=head1 METHODS

Methods are :

=head2 METHOD new

	## Description : new
	## Input : $self
	## Ouput : bless $self ;
	## Usage : new() ;

=cut

sub new {
    ## Variables
    my $self={};
    bless($self) ;
    return $self ;
}
### END of SUB
     
=head2 METHOD check_interval

	## Description : checks that the value is in the interval
	## Input : $value, $min, $max
	## Output : $message
	## Usage : $message= check_interval($value, $min, $max) ;
	
=cut
## START of SUB
sub check_interval {
	## Retrieve Values
    my $self = shift ;
    my ( $value, $min, $max ) = @_ ;
    
    my ( $message ) = undef ;
    if ( $min !~ m/^-?\d+\.?\d*$/ ) {
    	$message="the minimum '".$min."' isn't a valid number!";
    }
    elsif ( $max !~ m/^-?\d+\.?\d*$/ ) {
    	$message="the maximum '".$max."' isn't a valid number!";
    }
    elsif ( $value !~ m/^-?\d+\.?\d*$/ ) {
    	$message="'".$value."' isn't a valid number!";
    }
    elsif ( $value < $min ) {
    	$message="'".$value."' is below the minimum!";
    }
    elsif ( $value > $max ) {
    	$message="'".$value."' is greater than the maximum!";
    }
    else {
    	$message="OK" ;
    }
    return($message) ;
}
## END of SUB

=head2 METHOD format_manual_list_values

	## Description : extract a list of values and built identifiers
	## Input : $value, $sep
	## Output : \@values, \@ids
	## Usage : ($masses, $ids)= format_manual_list_values($mass, $sep) ;
	
=cut
## START of SUB
sub format_manual_list_values {
	## Retrieve Values
    my $self = shift ;
    my ( $value, $sep ) = @_ ;
    
    my ( @values, @ids ) = ( (), () ) ;
    
    if ( ( defined $value ) and ( $value ne "" ) and ( defined $sep ) ) {
    	@values = split($sep, $value);
		my $nb = 1+int(log($#values+1)/log(10));
		my $sf = '%0'.$nb.'s';
		for (my $i=1 ; $i<=$#values+1 ; $i++){
			my $id = sprintf($sf, $i) ;
			push (@ids,"value_".$id );
		}
    }
    else {
    	croak "No value list found \n" ;
    }
    return(\@values, \@ids) ;
}
## END of SUB

=head2 METHOD parse_bank_interest

	## Description : parse csv object and return a two-dimensional array in a hash by grouping information according to the interest value as key.
	## Input : $csv, \$file, $col_interest
	## Output : \%bank_interest, \$head
	## Usage : my ( $bank_interest, $head ) = parse_bank_interest ( $csv, $file, $col_interest ) ;
	
=cut
## START of SUB
sub parse_bank_interest {
	## Retrieve Values
    my $self = shift ;
    my ( $csv, $file, $col_interest ) = @_ ;
    
    my $bank_interest = () ;
    my $oBih = new() ;

	open my $fh, "<:encoding(utf8)", $$file or die "Can't open csv file $$file: $!";
	
	my $head = $csv->getline( $fh );
	my $nb_line = 1 ;	## for error messages
	
	while ( my $row = $csv->getline( $fh ) ) {
	    $nb_line++ ;
		if ($#$head != $#$row) {	croak "Not the same number of columns over the file of the interest bank! See the line: $nb_line in your input bank file!\n" ;	}
		## it would be more general to do the following masse check out this function - commented - No interest to do this here - FG 13/11/18
#		my ($MZmessage) = $oBih->check_interval($$row[$col_interest], 0, 10000) ; 
#		if ($MZmessage ne 'OK') {	$col_interest++;	croak "There is at least one row (See the line : $nb_line) where in the column $col_interest : $MZmessage\n" ;	} #/!\ col_interest++ to print to user a not-table (@) value.
		
	    push (@{$bank_interest->{$$row[$col_interest]}}, $row ) ;
	}
#	print Dumper $bank_interest; exit;
	$csv->eof or $csv->error_diag();
	close $fh;
    return($bank_interest, $head) ;
}
## END of SUB

=head2 METHOD mz_delta_conversion

	## Description : returns the minimum and maximum mass according to the delta
	## Input : \$mass, \$delta_type, \$mz_delta
	## Output : \$min, \$max
	## Usage : ($min, $max)= mz_delta_conversion($mass, $delta_type, $mz_delta) ;
	
=cut
## START of SUB
sub mz_delta_conversion {
	## Retrieve Values
    my $self = shift ;
    my ( $mass, $delta_type, $mz_delta ) = @_ ;
    my ( $computedDeltaMz, $min, $max ) = ( 0, undef, undef ) ;
    
    if 		($$delta_type eq 'ppm')		{	$computedDeltaMz = ($$mz_delta * 10**-6 * $$mass); }
	elsif 	($$delta_type eq 'Da')		{	$computedDeltaMz = $$mz_delta ; }
	else {	croak "The masses delta type '$$delta_type' isn't a valid type !\n" ;	}
    
    
    # Determine the number of decimals of the mz and of the delta (adding 0.1 if mz = 100 or 0.01 if mz = 100.1 )
    my @decimalMzPart = split (/\./, $$mass) ;
    my @decimalDeltaPart = split (/\./, $computedDeltaMz) ;
    
    my ($decimalMzPart, $decimalDeltaPart, $decimalLength, $nbDecimalMz, $nbDecimalDelta) = (0, 0, 0, 0, 0) ;
    
    if ($#decimalMzPart+1 == 1) 	{	$decimalMzPart = 0 ; }
    else 							{ 	$decimalMzPart = $decimalMzPart[1] ; }
    
    if ($#decimalDeltaPart+1 == 1) 	{	$decimalDeltaPart = 0 ; }
    else 							{ 	$decimalDeltaPart = $decimalDeltaPart[1] ; }
    
    if ( ($decimalMzPart == 0 ) and ($decimalDeltaPart == 0 ) ) {
    	$decimalLength = 1 ;
    }
    else {
    	$nbDecimalMz = length ($decimalMzPart)+1 ;
   		$nbDecimalDelta = length ($decimalDeltaPart)+1 ;
    
    	if ( $nbDecimalMz >= $nbDecimalDelta ) { $decimalLength = $nbDecimalMz ; }
    	if ( $nbDecimalDelta >= $nbDecimalMz ) { $decimalLength = $nbDecimalDelta ; }
    }
    
    my $deltaAdjustment = sprintf ("0."."%.$decimalLength"."d", 1 ) ;
    
#    print "$$mass: $decimalMzPart -> $nbDecimalMz, $$mz_delta: $decimalDeltaPart -> $nbDecimalDelta ==> $deltaAdjustment \n " ;
    
	$min = $$mass - $computedDeltaMz ;
	$max = $$mass + $computedDeltaMz + $deltaAdjustment ; ## it's to included the maximum value in the search
	
    return(\$min, \$max) ;
}
## END of SUB

=head2 METHOD dichotomi_search

	## Description : returns the index of the position or the interval value
	##               does not work if there are duplicates in the table
	## Input : \@tab, \$search
	## Output : \$index
	## Usage : ($index)= dichotomi_search($mass, $sep) ;
	
=cut
## START of SUB
sub dichotomi_search {
	## Retrieve Values
    my $self = shift ;
    my ( $tab, $search ) = @_ ;
    my ($sup, $inf, $demi) = (scalar(@{$tab})-1, 0, 0);
    
    while(1) {
		$demi = int(($sup + $inf)/2);
		if($sup < $inf)  { 
			if($inf==0){	$demi=-1;	}	elsif($sup==scalar(@{$tab})-1){	$demi=scalar(@{$tab});	} ## to distinguish items off limits
			last;
		}
		elsif ( ($$search == $$tab[$demi]) ) { last; }
		elsif ( ($$search > $$tab[$demi-1]) && ($$search < @$tab[$demi]) ) { last; }
		elsif($$search < $$tab[$demi]) { $sup = $demi - 1; next; }
		else { $inf = $demi + 1; next; }
	}
	
    return(\$demi) ;
}
## END of SUB

=head2 METHOD extract_sub_mz_lists

	## Description : extract a couples of sublist from a long mz list (more than $HMDB_LIMITS)
	## Input : $HMDB_LIMITS, $masses
	## Output : $sublists
	## Usage : my ( $sublists ) = extract_sub_mz_lists( $HMDB_LIMITS, $masses ) ;
	
=cut
## START of SUB
sub extract_sub_mz_lists {
	## Retrieve Values
    my $self = shift ;
    my ( $masses, $HMDB_LIMITS ) = @_ ;
    
    my ( @sublists, @sublist ) = ( (), () ) ;
    my $nb_mz = 0 ;
    my $nb_total_mzs = scalar(@{$masses}) ;
    
    for ( my $current_pos = 0 ; $current_pos < $nb_total_mzs ; $current_pos++ ) {
    	
    	if ( $nb_mz < $HMDB_LIMITS ) {
    		if ( $masses->[$current_pos] ) { 	push (@sublist, $masses->[$current_pos]) ; $nb_mz++ ;	} # build sub list
    	} 
    	elsif ( $nb_mz == $HMDB_LIMITS ) {
    		my @tmp = @sublist ; push (@sublists, \@tmp) ; @sublist = () ;	$nb_mz = 0 ;
    		$current_pos-- ;
    	}
    	if ($current_pos == $nb_total_mzs-1) { 	my @tmp = @sublist ; push (@sublists, \@tmp) ; }
	}
    return(\@sublists) ;
}
## END of SUB


=head2 METHOD set_html_tbody_object

	## Description : initializes and build the tbody object (perl array) need to html template
	## Input : $nb_pages, $nb_items_per_page
	## Output : $tbody_object
	## Usage : my ( $tbody_object ) = set_html_tbody_object($nb_pages, $nb_items_per_page) ;
	
=cut
## START of SUB
sub set_html_tbody_object {
	my $self = shift ;
    my ( $nb_pages, $nb_items_per_page ) = @_ ;

	my ( @tbody_object ) = ( ) ;
	
	for ( my $i = 1 ; $i <= $nb_pages ; $i++ ) {
	    
	    my %pages = ( 
	    	# tbody feature
	    	PAGE_NB => $i,
	    	MASSES => [], ## end MASSES
	    ) ; ## end TBODY N
	    push (@tbody_object, \%pages) ;
	}
    return(\@tbody_object) ;
}
## END of SUB

=head2 METHOD add_mz_to_tbody_object

	## Description : initializes and build the mz object (perl array) need to html template
	## Input : $tbody_object, $nb_items_per_page, $mz_list
	## Output : $tbody_object
	## Usage : my ( $tbody_object ) = add_mz_to_tbody_object( $tbody_object, $nb_items_per_page, $mz_list ) ;
	
=cut
## START of SUB
sub add_mz_to_tbody_object {
	my $self = shift ;
    my ( $tbody_object, $nb_items_per_page, $mz_list, $ids_list ) = @_ ;

	my ( $current_page, $mz_index ) = ( 0, 0 ) ;
	
	foreach my $page ( @{$tbody_object} ) {
		
		my @colors = ('white', 'green') ;
		my ( $current_index, , $icolor ) = ( 0, 0 ) ;
		
		for ( my $i = 1 ; $i <= $nb_items_per_page ; $i++ ) {
			# 
			if ( $current_index > $nb_items_per_page ) { ## manage exact mz per html page
				$current_index = 0 ; 
				last ; ##
			}
			else {
				$current_index++ ;
				if ( $icolor > 1 ) { $icolor = 0 ; }
				
				if ( exists $mz_list->[$mz_index]  ) {
					
					my %mz = (
						# mass feature
						MASSES_ID_QUERY => $ids_list->[$mz_index],
						MASSES_MZ_QUERY => $mz_list->[$mz_index],
						MZ_COLOR => $colors[$icolor],
						MASSES_NB => $mz_index+1,
						ENTRIES => [] ,
					) ;
					push ( @{ $tbody_object->[$current_page]{MASSES} }, \%mz ) ;
					# Html attr for mass
					$icolor++ ;
				}
			}
			$mz_index++ ;
		} ## foreach mz

		$current_page++ ;
	}
    return($tbody_object) ;
}
## END of SUB

=head2 METHOD add_entries_to_tbody_object

	## Description : initializes and build the mz object (perl array) need to html template
	## Input : $tbody_object, $nb_items_per_page, $mz_list, $entries
	## Output : $tbody_object
	## Usage : my ( $tbody_object ) = add_entries_to_tbody_object( $tbody_object, $nb_items_per_page, $mz_list, $entries ) ;
	
=cut
## START of SUB
sub add_entries_to_tbody_object {
	## Retrieve Values
    my $self = shift ;
    my ( $tbody_object, $nb_items_per_page, $mz_list, $entries ) = @_ ;
    
    my $index_page = 0 ;
    my $index_mz_continous = 0 ;
    
    foreach my $page (@{$tbody_object}) {
    	
    	my $index_mz = 0 ;
    	
    	foreach my $mz (@{ $tbody_object->[$index_page]{MASSES} }) {
    		
    		my $index_entry = 0 ;
    		
    		my @anti_redondant = ('N/A') ;
    		my $check_rebond = 0 ;
    		
    		foreach my $entry (@{ $entries->[$index_mz_continous] }) {
    			
    			## dispo anti doublons des entries
    			foreach my $rebond (@anti_redondant) {
    				if ( $rebond eq $entries->[$index_mz_continous][$index_entry]{ENTRY_ENTRY_ID} ) {	$check_rebond = 1 ; last ; }
    			}
    			
    			if ( $check_rebond == 0 ) {
    				
    				 push ( @anti_redondant, $entries->[$index_mz_continous][$index_entry]{ENTRY_ENTRY_ID} ) ;
    				
    				my %entry = (
		    			ENTRY_COLOR => $tbody_object->[$index_page]{MASSES}[$index_mz]{MZ_COLOR},
		   				ENTRY_ENTRY_ID => $entries->[$index_mz_continous][$index_entry]{ENTRY_ENTRY_ID},
		   				ENTRY_ENTRY_ID2 => $entries->[$index_mz_continous][$index_entry]{ENTRY_ENTRY_ID},
						ENTRY_FORMULA => $entries->[$index_mz_continous][$index_entry]{ENTRY_FORMULA},
						ENTRY_CPD_MZ => $entries->[$index_mz_continous][$index_entry]{ENTRY_CPD_MZ},
						ENTRY_ADDUCT => $entries->[$index_mz_continous][$index_entry]{ENTRY_ADDUCT},
						ENTRY_ADDUCT_TYPE => $entries->[$index_mz_continous][$index_entry]{ENTRY_ADDUCT_TYPE},
						ENTRY_ADDUCT_MZ => $entries->[$index_mz_continous][$index_entry]{ENTRY_ADDUCT_MZ},
						ENTRY_DELTA => $entries->[$index_mz_continous][$index_entry]{ENTRY_DELTA},   			
		    		) ;
		    		
	    			push ( @{ $tbody_object->[$index_page]{MASSES}[$index_mz]{ENTRIES} }, \%entry) ;
    			}
    			$check_rebond = 0 ; ## reinit double control
    			$index_entry++ ;	
    		}
    		$index_mz ++ ;
    		$index_mz_continous ++ ;
    	}
    	$index_page++ ;
    }
    return($tbody_object) ;
}
## END of SUB

=head2 METHOD write_html_skel

	## Description : prepare and write the html output file
	## Input : $html_file_name, $html_object, $html_template
	## Output : $html_file_name
	## Usage : my ( $html_file_name ) = write_html_skel( $html_file_name, $html_object ) ;
	
=cut
## START of SUB
sub write_html_skel {
	## Retrieve Values
    my $self = shift ;
    my ( $html_file_name,  $html_object, $pages , $search_condition, $html_template, $js_path, $css_path ) = @_ ;
    
    my $html_file = $$html_file_name ;
    
    if ( defined $html_file ) {
		open ( HTML, ">$html_file" ) or die "Can't create the output file $html_file " ;
		
		if (-e $html_template) {
			my $ohtml = HTML::Template->new(filename => $html_template);
			$ohtml->param(  JS_GALAXY_PATH => $js_path, CSS_GALAXY_PATH => $css_path  ) ;
			$ohtml->param(  CONDITIONS => $search_condition  ) ;
			$ohtml->param(  PAGES_NB => $pages  ) ;
			$ohtml->param(  PAGES => $html_object  ) ;
			print HTML $ohtml->output ;
		}
		else {
			croak "Can't fill any html output : No template available ($html_template)\n" ;
		}
		
		close (HTML) ;
    }
    else {
    	croak "No output file name available to write HTML file\n" ;
    }
    return(\$html_file) ;
}
## END of SUB

=head2 METHOD set_bih_matrix_object

	## Description : build the bih_row under its ref form
	## Input : $header, $init_mzs, $col_mzdb, $results, $rts, $col_rtdb, $bank_head, $sep
	## Output : $hmdb_matrix
	## Usage : my ( $hmdb_matrix ) = set_bih_matrix_object( $header, $init_mzs, $col_mzdb, $results, $rts, $col_rtdb, $bank_head, $sep ) ;
	
=cut
## START of SUB
sub set_bih_matrix_object {
	## Retrieve Values
    my $self = shift ;
    my ( $header, $init_mzs, $col_mzdb, $results, $rts, $col_rtdb, $bank_head, $sep ) = @_ ;
    
    my @bih_matrix = () ;
    
    if ( defined $header ) {
    	my @headers = () ;
    	push @headers, $header ;
    	push @bih_matrix, \@headers ;
    }
    
    my $index_mz = 0 ;
    $col_mzdb -= 1;     $col_rtdb -= 1; ## conversion in array number
    
    foreach my $mz ( @{$init_mzs} ) {
    	
    	my $index_entries = 0 ;
    	my @clusters = () ;
    	my $cluster_col = undef ;
    	
    	foreach my $entry (@{ $results->[$index_mz] }) {
    		
    		my $format_float = Math::BigFloat->new($entry->[$col_mzdb]);	## requires "use Math::BigFloat;"
			my $delta_mz = abs( $format_float-$mz );	## management problem on small float
			# manage final pipe
			if ($index_entries == 0){	$cluster_col .= $delta_mz.$sep.$entry->[$col_mzdb].$sep ;	} ## Managing multiple results transition pipes "|"
			else{	$cluster_col .= '|'.$delta_mz.$sep.$entry->[$col_mzdb].$sep ;	}
			
			if  ( ( defined $rts ) and ( $rts ne "" ) ) {
				my $rt = $rts->[$index_mz] ;
				my $format_float_rt = Math::BigFloat->new($entry->[$col_rtdb]);	## requires "use Math::BigFloat;"
				my $delta_rt = abs( $format_float_rt-$rt );	## management problem on small float
				$cluster_col .= $delta_rt.$sep.$entry->[$col_rtdb].$sep;
			}
    		for (my $i=0; $i<=$#$entry; $i++){
    			
    			if ($entry->[$i]) {
    				if ($entry->[$i] ne '') {
    					if($i == $#$entry){	$cluster_col .= $entry->[$i];	} ## Managing multiple results transition "#"
    					else {	$cluster_col .= $entry->[$i].$sep;	}
    				}
    				else {
    					if($i == $#$entry){	$cluster_col .= 'NA';	} ## Managing multiple results transition "#"
    					else {	$cluster_col .= 'NA'.$sep;	}
    				}
    			}
    			else {
    				$cluster_col .= 'NA'.$sep;
    			}
    			
#    			if($i == $#$entry){	$cluster_col .= $entry->[$i];	} ## Managing multiple results transition "#"
#    			else {	$cluster_col .= $entry->[$i].$sep;	}
    		}
    		$index_entries++ ;
    	}
    	if ( !defined $cluster_col ) { $cluster_col = 'No_match_in_bank' ; }
    	
	    ## $cluster_col like METLIN data display model but the "::" have been modified (#) for ease of Excel reading
	   	## entry1=VAR1::VAR2::VAR3::VAR4|entry2=VAR1::VAR2::VAR3::VAR4|...
    	push (@clusters, $cluster_col) ;
    	push (@bih_matrix, \@clusters) ;
    	$index_mz++ ;
    }
    return(\@bih_matrix) ;
}
## END of SUB

=head2 METHOD add_bih_matrix_to_input_matrix

	## Description : build a full matrix (input + lm column)
	## Input : $input_matrix_object, $lm_matrix_object, $nb_header
	## Output : $output_matrix_object
	## Usage : my ( $output_matrix_object ) = add_bih_matrix_to_input_matrix( $input_matrix_object, $lm_matrix_object, $nb_header ) ;
	
=cut
## START of SUB
sub add_bih_matrix_to_input_matrix {
	## Retrieve Values
    my $self = shift ;
    my ( $input_matrix_object, $lm_matrix_object, $nb_header ) = @_ ;
    
    my @output_matrix_object = () ;
    my $index_row = 0 ;
    my $line = 0 ;
    
    foreach my $row ( @{$input_matrix_object} ) {
    	my @init_row = @{$row} ;
    	$line++;
    	
    	if ( ( defined $nb_header ) and ( $line <= $nb_header) ) {
    		push (@output_matrix_object, \@init_row) ;
    		next ;
    	}
    	
    	if ( $lm_matrix_object->[$index_row] ) {
    		my $dim = scalar(@{$lm_matrix_object->[$index_row]}) ;
    		
    		if ($dim > 1) { warn "the add method can't manage more than one column\n" ;}
    		if (defined $lm_matrix_object->[$index_row][$dim-1]) {
    			my $lm_col =  $lm_matrix_object->[$index_row][$dim-1] ;
   		 		push (@init_row, $lm_col) ;
    		}
    		
	    	$index_row++ ;
    	}
    	push (@output_matrix_object, \@init_row) ;
    }
    return(\@output_matrix_object) ;
}
## END of SUB

=head2 METHOD write_csv_skel

	## Description : prepare and write csv output file
	## Input : $csv_file, $rows
	## Output : $csv_file
	## Usage : my ( $csv_file ) = write_csv_skel( $csv_file, $rows ) ;
	
=cut
## START of SUB
sub write_csv_skel {
	## Retrieve Values
    my $self = shift ;
    my ( $csv_file, $rows ) = @_ ;
    
    my $ocsv = lib::csv::new() ;
	my $csv = $ocsv->get_csv_object("\t") ;
	$ocsv->write_csv_from_arrays($csv, $$csv_file, $rows) ;
    
    return($csv_file) ;
}
## END of SUB


=head2 METHOD write_full_excel_like

	## Description : allows to print a tsv file
	## Input : $input_matrix_object, $sep, $masses, $mz_delta_type, $mz_delta, $col_mzdb, $rts, $rt_delta, $col_rtdb, $results, $file, $nb_header, $bank_head, $bank_name
	## Output : N/A
	## Usage : write_full_excel_like( $input_matrix_object, $sep, $masses, $mz_delta_type, $mz_delta, $col_mzdb, $rts, $rt_delta, $col_rtdb, $results, $file, $nb_header, $bank_head, $bank_name ) ;
	
=cut
## START of SUB
sub write_full_excel_like {
	## Retrieve Values
    my $self = shift ;
    my ( $input_matrix_object, $sep, $masses, $mz_delta_type, $mz_delta, $col_mzdb, $rts, $rt_delta, $col_rtdb, $results, $file, $nb_header, $bank_head, $bank_name ) = @_ ;
    
    open(CSV, '>:utf8', $file) or die "Cant' create the file $file\n" ;
    
    my $line = 0 ;
    my $index_mz = 0 ;
    $col_mzdb -= 1;     $col_rtdb -= 1; ## conversion in array number
    
    foreach my $row ( @{$input_matrix_object} ) {
    	my $join_row = join($sep, @$row);
    	
    	if ( defined $nb_header ){
    		$line++;
    		if ( $line < $nb_header ) {	print CSV $join_row."\n";	next ;	}
    		elsif ( $line == $nb_header ){
    			my $head = join("_".$bank_name.$sep, @$bank_head);
    			print CSV $join_row.$sep.$head."_".$bank_name."\n";
    			next ;
    		}
    	}
    	
    	my $mass = $masses->[$index_mz] ;
    	my $results4mass = $results->[$index_mz];
    	
    	if ( ref($results4mass) eq 'ARRAY' and defined $results4mass and $results4mass ne [] and $#$results4mass>=0) { ## an requested id has a result in the list of array $results.
    		foreach my $entry (@{$results->[$index_mz]}) {
    			print CSV $join_row."\t";
    			my $format_float = Math::BigFloat->new($entry->[$col_mzdb]);	## requires "use Math::BigFloat;"
				my $delta_mass = abs( $format_float-$mass );	## management problem on small float
				print CSV $delta_mass."\t".$entry->[$col_mzdb];
				
				if  ( ( defined $rts ) and ( $rts ne "" ) ) {
	    			my $rt = $rts->[$index_mz] ;
	    			my $format_float_rt = Math::BigFloat->new($entry->[$col_rtdb]);	## requires "use Math::BigFloat;"
					my $delta_rt = abs( $format_float_rt-$rt );	## management problem on small float
	    			print CSV "\t".$rt."\t".$delta_rt."\t".$entry->[$col_rtdb];
				}
    			for (my $i=0; $i<=$#$entry; $i++){	
    				if ($entry->[$i]) {
						if ($entry->[$i] ne '' ) 	{	print CSV "\t".$entry->[$i]; }
						else 						{	print CSV "\tNA";  }
					}
					else {
						print CSV "\tNA";
					}	
    			}
    			print CSV "\n";
    		}
    	}
    	else {
    		print CSV $join_row."\tNo_match_in_bank";
    		for (my $i=0; $i<$#$bank_head; $i++){	print CSV "\tNA";	}
    		print CSV "\n";
    	}
    	$index_mz++ ;
    }
   	close(CSV) ;
    return() ;
}
## END of SUB


=head2 METHOD write_excel_like_mass

	## Description : allows to print a tsv file if retention time is required
	## Input : $masses, $ids, $mz_delta_type, $mz_delta, $col_mzdb, $rts, $rt_delta, $col_rtdb, $results, $file, $bank_head
	## Output : N/A
	## Usage : write_excel_like_mass( $masses, $ids, $mz_delta_type, $mz_delta, $col_mzdb, $rts, $rt_delta, $col_rtdb, $results, $file, $bank_head ) ;
=cut
## START of SUB
sub write_excel_like_mass {
	## Retrieve Values
    my $self = shift ;
    my ( $masses, $mz_delta_type, $mz_delta, $col_mzdb, $rts, $rt_delta, $col_rtdb, $results, $file, $out_head ) = @_ ;
    
    open(CSV, '>:utf8', $file) or die "Cant' create the file $file\n" ;
    
    my $index_mz = 0 ;	my @bank_head = @$out_head;
    $col_mzdb -= 1; ## conversion in array number
    if  ( ( defined $rts ) and ( $rts ne "" ) ) {
	    splice (@bank_head, 2, 0, "RtQuery");
	    $col_rtdb -= 1; ## conversion in array number
    }
    my $head = join("\t", @bank_head);
    print CSV "MzQuery\t".$head."\n" ;
    
    foreach my $mass (@{$masses}) {
    	my $results4mass = $results->[$index_mz];
    	
    	if ( ref($results4mass) eq 'ARRAY' and defined $results4mass and $results4mass ne [] and $#$results4mass>=0) { ## an requested id has a result in the list of array $results.
    		foreach my $entry (@{$results->[$index_mz]}) {
    			print CSV $mass."\t";
    			my $format_float = Math::BigFloat->new($entry->[$col_mzdb]);	## requires "use Math::BigFloat;"
				my $delta_mass = abs( $format_float-$mass );	## management problem on small float
				print CSV $delta_mass."\t".$entry->[$col_mzdb];
				
				if  ( ( defined $rts ) and ( $rts ne "" ) ) {
	    			my $rt = $rts->[$index_mz] ;
	    			my $format_float_rt = Math::BigFloat->new($entry->[$col_rtdb]);	## requires "use Math::BigFloat;"
					my $delta_rt = abs( $format_float_rt-$rt );	## management problem on small float
	    			print CSV "\t".$rt."\t".$delta_rt."\t".$entry->[$col_rtdb];
				}
				# fill th ematrix with all values
				for ( my $i=0; $i<=$#$entry; $i++ ) {
					if ($entry->[$i]) {
						if ($entry->[$i] ne '' ) 	{	print CSV "\t".$entry->[$i]; }
						else 						{	print CSV "\tNA";  }
					}
					else {
						print CSV "\tNA";
					}
				}
    			print CSV "\n";
    		}
    	}
    	#No matching result
    	else {
    		print CSV $mass."\tNo_match_in_bank\t";
    		for (my $i=0; $i<$#bank_head-1; $i++){	print CSV "\tNA";	}
    		print CSV "\n";
    	}
    	$index_mz++ ;
    }
   	close(CSV) ;
    return() ;
}
## END of SUB


=head2 METHOD db_pforest_get_clean_range

	## Description : get a clean range of mass from PeakForest and REST
	## Input : $ws_host, $query, $max
	## Output : $json
	## Usage : $json = db_pforest_get_clean_range( $ws_host, $query, $max ) ;
=cut
## START of SUB


#sub db_pforest_get_clean_range {
#    my $self = shift;
#    my ( $ws_host, $query, $min, $max, $mode) = @_;
#    my $json = undef ;
#	# init
##	my $ws_url = "https://rest.peakforest.org/search/compounds/monoisotopicmass/59.048/0.02";
#
#	$ENV{HTTPS_VERSION} = 3;
#	#$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0 ;
#
#	my $headers = {Accept => 'application/json', Authorization => 'Basic '};
#	my $client = REST::Client->new({
#         host    => $ws_host,
##         cert    => '/path/to/ssl.crt',
##         key     => '/path/to/ssl.key',
##         ca      => '/path/to/ca.file',
#         timeout => 100,
#     });
#    my $complete_query = $query.'/'.$min.'/'.$max ;
#    
#    if (defined $mode) {
#    	$complete_query = $complete_query.'?mode='.$mode ; 
#    }
#    
#    
#    print $complete_query."\n" ;
#    $client->GET($complete_query , $headers);
#	$json = from_json ($client->responseContent()) ;
#
#	return ($json) ;   
#}

=head2 METHOD map_pfjson_bankobject

	## Description : map PForest json with the original BiH Bank object
	## Input : $json
	## Output : $complete_bank, $bank_head
	## Usage : ($complete_bank, $bank_heads) = map_pfjson_bankobject( json ) ;
=cut
## START of SUB
sub map_pfjson_bankobject {
	my $self = shift;
    my ( $json ) = @_;
    
    my ( %complete_bank ) = () ;
    my ( @bank_head ) = ('id', 'mz')  ;
    
    foreach my $cpd (@$json) {
    	$complete_bank{$cpd->{'mz'}} = [] ;
    	my @tmp = @{$cpd->{'cpds'}} ;
    	
    	push ( @tmp, $cpd->{'mz'} ) ;
    	push ( @{ $complete_bank{$cpd->{'mz'} } }, \@tmp ) ;

    }
    return (\%complete_bank, \@bank_head) ;
}
## END of SUB

1 ;


__END__

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc bih.pm

=head1 Exports

=over 4

=item :ALL is prepare_multi_masses_query

=back

=head1 AUTHOR

Marion Landi E<lt>marion.landi@clermont.inra.frE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 VERSION

version 1 : 19 / 11 / 2014

=cut
