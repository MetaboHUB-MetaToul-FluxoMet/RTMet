package lib::json ;

use strict;
use warnings ;
use Exporter ;
use Carp ;

use Data::Dumper ;

## dedicate lib
use JSON qw( );

use vars qw($VERSION @ISA @EXPORT %EXPORT_TAGS);

our $VERSION = "1.0";
our @ISA = qw(Exporter);
our @EXPORT = qw(decode_json_file);
our %EXPORT_TAGS = ( ALL => [qw(decode_json_file)] );

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
     
=head2 METHOD decode_json_file

	## Description : decode a json file and return a json perl object
	## Input : $ref_file
	## Output : $ojson
	## Usage : my ( $ojson ) = decode_json_file( $file ) ;
	
=cut
## START of SUB
sub decode_json_file {
	## Retrieve Values
    my $self = shift ;
    my ( $ref_file ) = @_ ;
    
    my $ojson = undef ;
    
    if ( ( defined $ref_file ) and ( -e $$ref_file ) ) {
    	my $filename = $$ref_file ;
    	my $json_text = do {
			open( my $json_fh, "<:encoding(UTF-8)", $filename) or die("Can't open \$filename\": $!\n");
			local $/;
			<$json_fh>
		};
		
		my $json = JSON->new;
		$ojson = $json->decode($json_text);
    }
    else {
    	croak "Can't decode any file : it doesn't exist or defined\n" ;
    }
    return(\$ojson) ;
}
## END of SUB

=head2 METHOD decode_json_stdout

	## Description : decode a perl unicode string and return a json perl object
	## Input : $stdout
	## Output : $perl_scalar
	## Usage : my ( $perl_scalar ) = decode_json_stdout( $stdout ) ;
	
=cut
## START of SUB
sub decode_json_stdout {
	## Retrieve Values
    my $self = shift ;
    my ( $stdout ) = @_ ;
    
    my $perl_scalar = undef ;
    if ( defined $stdout ) {
    	my $string = $$stdout ;
#    	$string =~ s/\\/\\\\/g ; ## bug patched : jsons are clean now
    	    	
    	$perl_scalar = JSON->new->decode($string) ;
    }
    else {
    	croak "Can't decode any string : it doesn't defined\n" ;
    }
    return(\$perl_scalar) ;
}
## END of SUB

1 ;


__END__

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc XXX.pm

=head1 Exports

=over 4

=item :ALL is ...

=back

=head1 AUTHOR

Franck Giacomoni E<lt>franck.giacomoni@clermont.inra.frE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 VERSION

version 1 : xx / xx / 201x

version 2 : ??

=cut