## ****** match_mass environnemnt : ****** ##
# version December 2014 M Landi / M Petera / JF Martin

## --- PERL compilator / libraries : --- ##
$ perl -v
This is perl, v5.10.1 (*) built for x86_64-linux-thread-multi
--

# libs CORE PERL : 
use strict ;
use warnings ;
use Carp qw (cluck croak carp) ;
use Data::Dumper ;
use Getopt::Long ;
use POSIX ;
use List::Util qw( min max );
use FindBin ;

# libs CPAN PERL : 
use Math::BigFloat;
use LWP::Simple;
use LWP::UserAgent;
use URI::URL;
use SOAP::Lite;
use Encode;
use HTML::Template ;
use Net::SSL ;
use Data::Dumper ;
use REST::Client;	
use JSON;

# libs pfem PERL : libs are now integrated
use lib::conf  qw( :ALL ) ;
use lib::csv  qw( :ALL ) ;
use lib::json  qw( :ALL ) ;

## --- R bin and Packages : --- ##
NA

## --- Binary dependencies --- ##
Uses a local database : "inhouse.tsv" in some cases
"create_inhouse_bank.pl" : allows to recreate "inhouse.tsv"
--

## --- Config : --- ##
Edit the following lines in the config file : conf_pf.ini
with  your personal token used to manage and allow Pforest access / the WS PeakForest url
PF_GLOBAL_TOKEN
PF_WS_URL=https://rest.peakforest.org
PF_REST_QUERY_CLEAN_RANGE=/spectra/lcms/peaks/get-range-clean

--

## --- XML HELP PART --- ##
one image : 
bank_inhouse.png
--

## --- DATASETS --- ##
No data set ! waiting for galaxy pages
--

## --- ??? COMMENTS ??? --- ##
Uses a local database : "inhouse.tsv" in some cases
"create_inhouse_bank.pl" : allows to recreate "inhouse.tsv"
--