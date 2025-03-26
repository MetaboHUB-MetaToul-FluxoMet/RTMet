#! perl
use diagnostics;
use warnings;
no warnings qw/void/;
use strict;
no strict "refs" ;
use Test::More tests => 37 ;
use FindBin ;
use Data::Dumper ;

## Specific Modules
use lib $FindBin::Bin ;
my $binPath = $FindBin::Bin ;
use lib::bihTest qw( :ALL ) ;

## testing check_interval
print "\n-- test whether a value is in the interval defines\n\n" ;
#01
is ( check_interval_Test('test', '0', '1'), "'test' isn't a valid number!", 'Works with a value that is not a number');
#02
is ( check_interval_Test('', '0', '1'), "'' isn't a valid number!", 'Works with a value that is not a number');
#03
is ( check_interval_Test('-0.5', '-1', '0'), "OK", 'Works with a negative float');
#04
is ( check_interval_Test('-0.5', '0', '1'), "'-0.5' is below the minimum!", 'Works with a number below the minimum!');
#05
is ( check_interval_Test('2', '0', '1'), "'2' is greater than the maximum!", 'Works with a number greater than the maximum!');
print "\n--\n" ;

## testing format_manual_masses
print "\n-- Test format manual list of values lib for values (ex=> masses)\n\n" ;
#06
isa_ok( format_manual_list_values_Testvalues('562.0235', ' '), 'ARRAY' );
#07
is_deeply(format_manual_list_values_Testvalues('562.0235', ' '), [562.0235], 'Works with \'562.0235\' for mass');
#08
is_deeply(format_manual_list_values_Testvalues('562.0235 987.4568', ' '), [562.0235, 987.4568], 'Works with \'562.0235 987.4568\' for masses');
#09
is_deeply(format_manual_list_values_Testvalues('562.0235;987.4568', ';'), [562.0235, 987.4568], 'Works with \'562.0235;987.4568\' for masses');
print "\n--\n" ;

print "\n-- Test format manual list of values lib for ids\n\n" ;
#10
isa_ok( format_manual_list_values_Testids('562.0235', ' '), 'ARRAY' );
#11
is_deeply(format_manual_list_values_Testids('562.0235', ' '), ['value_1'], 'Works with \'562.0235\' for ids');
#12
is_deeply(format_manual_list_values_Testids('562.0235 987.4568', ' '), ['value_1', 'value_2'], 'Works with \'562.0235 987.4568\' for ids');
#13
is_deeply(format_manual_list_values_Testids('562.0235 987.4568 ', ' '), ['value_1', 'value_2'], 'Works with \'562.0235 987.4568 \' for ids');
#14
is_deeply(format_manual_list_values_Testids('562.0235 987.4568 52.0235 98.48 62.0235 987.68 152.05 8.48 562.0235', ' '), ['value_1', 'value_2','value_3', 'value_4','value_5', 'value_6','value_7', 'value_8', 'value_9'], 'Works with 9 masses for ids');
#15
is_deeply(format_manual_list_values_Testids('562.0235 987.4568 52.0235 98.48 62.0235 987.68 152.05 8.48 562.0235 987.4568', ' '), ['value_01', 'value_02','value_03', 'value_04','value_05', 'value_06','value_07', 'value_08', 'value_09', 'value_10'], 'Works with 10 masses for ids');
#16
is_deeply(format_manual_list_values_Testids('562.0235 987.4568 52.0235 98.48 62.0235 987.68 152.05 8.48 562.0235 987.4568 52.0235 98.48 62.0235 987.68 152.05 8.48', ' '), ['value_01', 'value_02','value_03', 'value_04','value_05', 'value_06','value_07', 'value_08', 'value_09', 'value_10', 'value_11', 'value_12', 'value_13', 'value_14', 'value_15', 'value_16'], 'Works with 16 masses for ids');
print "\n--\n" ;

## testing manage_mode
#print "\n-- Test manage_mode lib\n\n" ;
#09
#isa_ok( manage_mode_Testionization('positive,negative,neutral'), 'ARRAY' );
#10
#is_deeply(manage_mode_Testionization('positive,negative,neutral'), ['positive', 'negative', 'neutral'], 'Works with \'562.0235\' for ids');
#14
#isa_ok( format_manual_list_values_Testids('562.0235 987.4568'), 'ARRAY' );
#15
#is_deeply(format_manual_list_values_Testids('562.0235 987.4568'), ['mass_1', 'mass_2'], 'Works with \'562.0235 987.4568\' for ids');
#16
#is_deeply(format_manual_list_values_Testids('562.0235 987.4568 52.0235 98.48 62.0235 987.68 152.05 8.48 562.0235 987.4568 52.0235 98.48 62.0235 987.68 152.05 8.48'), ['mass_01', 'mass_02','mass_03', 'mass_04','mass_05', 'mass_06','mass_07', 'mass_08', 'mass_09', 'mass_10', 'mass_11', 'mass_12', 'mass_13', 'mass_14', 'mass_15', 'mass_16'], 'Works with 16 masses for ids');
#print "\n--\n" ;

## testing mz_delta_conversion
print "\n-- Test mz_delta_conversion lib\n\n" ;
#17
is ( mz_delta_conversion_Testmin(100, 'Da', 0.005), 99.995, 'Works with \'100, Da, 0.005\' for minimum');
#18
is ( mz_delta_conversion_Testmax(100, 'Da', 0.005), 100.0051, 'Works with \'100, Da, 0.005\' for maximum');
#19
is ( mz_delta_conversion_Testmin(500, 'Da', 0.005), 499.995, 'Works with \'500, Da, 0.005\' for minimum');
#20
is ( mz_delta_conversion_Testmax(500, 'Da', 0.005), 500.0051, 'Works with \'500, Da, 0.005\' for maximum');
#20.1
is ( mz_delta_conversion_Testmax(500.159989, 'Da', 0.005), 500.1649891, 'Works with \'500, Da, 0.005\' for maximum');

#21
is ( mz_delta_conversion_Testmin(100, 'ppm', 5), 99.9995, 'Works with \'100, ppm, 5\' for minimum');
#22
is ( mz_delta_conversion_Testmax(100, 'ppm', 5), 100.00051, 'Works with \'100, ppm, 5\' for maximum');
#23
is ( mz_delta_conversion_Testmin(500, 'ppm', 5), 499.9975, 'Works with \'500, ppm, 5\' for minimum');
#24
is ( mz_delta_conversion_Testmax(500, 'ppm', 5), 500.00251, 'Works with \'500, ppm, 5\' for maximum');
print "\n--\n" ;

## testing dichotomi_search
print "\n-- Test dichotomi_search lib\n\n" ;
#25
is ( dichotomi_search_Test(['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'], '0'), -1, 'Works with \'0\' smaller than the 1st element');
#26
is ( dichotomi_search_Test(['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'], '1'), 0, 'Works with \'1\' equal to the 1st element');
#27
is ( dichotomi_search_Test(['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'], '5'), 4, 'Works with \'5\' equal to the 4th element');
#28
is ( dichotomi_search_Test(['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'], '11'), 10, 'Works with \'11\' equal to the last (10th) element');
#29
is ( dichotomi_search_Test(['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'], '11.001'), 11, 'Works with \'11.001\' greater than the last (10th) element');
#30
is ( dichotomi_search_Test(['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'], '9.5'), 9, 'Works with \'9.5\' between the 9th and the 10th element return \'9\'(the index of the 10th)');
#31
is ( dichotomi_search_Test(['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'], '8.5'), 8, 'Works with \'8.5\' between the 8th and the 9th element return \'8\'(the index of the 9th)');
#32
is ( dichotomi_search_Test(['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'], '10.5'), 10, 'Works with \'10.5\' between the 10th and the 11th element return \'10\'(the index of the 11th)');
print "\n--\n" ;

## test of input bank parsing
#print "\n-- Test bank parsing\n\n" ;
#is_deeply ( parse_bank_interest_Test(
#	'/Users/fgiacomoni/Inra/labs/perl/galaxy_tools/tool-bank_inhouse/test_data/in_test2.tabular', 1),
#	{ '422.0849114' => [ [ 'C19H18O11', '422.0849114' ] ], '98.952389' => [ [ 'Halothane', '98.952389' ] ], '209.987659' => [ [ 'Bismuth', '209.987659' ] ], '18.0105647' => [ [ 'H2O', '18.0105647' ] ], '199.951068' => [ [ 'Picolinic acid', '199.951068' ] ], '535.3181236' => [ [ 'C18H45N7O11', '535.3181236' ] ] }, 
#	"Parsing a bank method works an return a well organized hash\n" ) ; 
#
#print "\n--\n" ;


## test of rest ws of PeakForest
#print "\n-- Test PeakForest WS\n\n" ;
#is_deeply ( db_pforest_get_clean_range_Test(
#	'https://rest.peakforest.org', '/spectra/lcms/peaks/get-range-clean', '190.0', '200.0', 'negative'),
# 	[{ 'cpds' => [ 186 ], 'thMass' => '195.0877', 'sp' => 25, 'ri' => '100', 'deltaPPM' => '0.245', 'composition' => 'C8H11N4O2', 'attribution' => '[M+H]+', 'mz' => '195.0875' }, { 'composition' => 'C9H9O5', 'attribution' => '[M-H]-', 'ri' => '100', 'deltaPPM' => '0.271', 'cpds' => [ 360 ], 'thMass' => '197.0456', 'sp' => 37, 'mz' => '197.0452' }, { 'composition' => 'C9H12NO4', 'attribution' => '[M+H]+', 'deltaPPM' => '-0.426098891623529', 'ri' => '100', 'thMass' => '198.0760844', 'sp' => 77, 'cpds' => [ 1841 ], 'mz' => '198.076' }, { 'mz' => '196.0614', 'composition' => 'C9H10NO4', 'attribution' => '[M-H]-', 'cpds' => [ 1841 ], 'thMass' => '196.0615311', 'sp' => 78, 'ri' => '100', 'deltaPPM' => '-0.668667633415113' }, { 'cpds' => [ 1841 ], 'thMass' => '198.0760844', 'sp' => 79, 'ri' => '100', 'deltaPPM' => '-0.426098891623529', 'composition' => 'C9H12NO4', 'attribution' => '[M+H]+', 'mz' => '198.076' }],
#	"PForest WS call works an return a clean range og mz between 190 and 200\n" ) ; 
#	
#print "\n--\n" ;

## test of rest ws of PeakForest
#print "\n-- Test PeakForest JSON Bank parsing\n\n" ;
#
#my ($bank, $headers) = map_pfjson_bankobject_Test([ { 'cpds' => [ 186 ], 'mz' => '195.0875' }, {'mz' => '198.076', 'cpds' => [ 190 ]} ]) ;
#is_deeply ( 
#	$bank, 
#	{ '198.076' => [ [ 190, '198.076' ] ], '195.0875' => [ [ 186, '195.0875' ] ] },
#	"Parsing json bank from PeakForest works an return a well organized hash for data\n" ) ;
#	
#is_deeply ( 
#	$headers, 
#	['id', 'mz'],
#	"Parsing json bank from PeakForest works an return a well organized array for headers\n" ) ;