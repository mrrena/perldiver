#!/usr/bin/perl -X


# Note: This program currently cannot run with -T. The Module::Info module
# does not perform taint checking. However, all user input is taint-checked
# in Perl Diver.

use lib '.';
do 'perldiver.conf' or die "Can't load conf file $!";


BEGIN{
    $ENV{'PATH'} = '/bin:/usr/bin';
    delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };
}

use strict;
use CGI qw/ :standard /;
use CGI::Carp qw/ fatalsToBrowser /;
use File::Find;
use Config;
use Module::Info;
use Pod2::Html;
use Data::Dumper;
use File::Basename;


use vars qw/ $actions $vars $module_path @foundmods $types $defaults
             $main_page %escapes /;



my $ver  = sprintf "%d.%02d", '$Revision: 2.033 $ ' =~ /(\d+)\.(\d+)/;
my $dev  = 'ScriptSolutions.com';
my $prog = 'Perl Diver';
$| = 1;


##########
# Check user input on action. If it's not digits-only, just give them the
# main page.

#param( 'action' => '2000' ) unless param( 'action' );
param( 'action' => $vars->{ 'main_id' } ) unless param( 'action' );
param( 'action' ) =~ /^(\d+)$/;
param( 'action' => $1 );


##########
# If an action is present but not defined in $actions, just give them the main
# page.

if ( !exists $actions->{ param('action') } ) {
   param( 'action' => $vars->{ 'main_id' } );
}


##########
# Outputs most of the page information.

print
    header,
    start_html(
            -title => "$prog : $actions->{ param('action') }{ 'name' }",
            -style => { -code => $vars->{ 'style' } },
        ),
        _page_header(),
        _table_output( _navigation() ),
        _section_header(),
        _table_output( &{$actions->{ param( 'action' ) }{ 'subr' } } ),
        _page_footer();



###############
# Action. Environment variables.

sub environ_vars {

    my ( $c1, $c2 ) = ( 1, 1 );

    join ( "\n",
        map {
            Tr( { -class  => $c1++ % 3 ? ( $c2++ % 2 ? 'a1' : 'a2' ) : 'a3' },
                td( { -width => '35%', -class => 'label' }, $_ ),
                td( { -width => '65%', -class => 'value' }, $ENV{ $_ } )
            )
        } sort keys %ENV
    )
}



###############
# Action. Perl default values. Uses hohref $defaults from perldiver.conf

sub default_vals {

    my ( $c1, $c2 ) = ( 1, 1 );  # color incrementors

    Tr( { -class=> 'hl' },
        th( { -class => 'r label', -width => '30%' },
            'DESCRIPTION'
        ),
        th( { -class => 'label', -width => '15%' },
            'VARIABLE'
        ),
        th( { -class => 'l label', -width => '55%' },
            'RESULT'
        ),
    ) .
    join ( "\n",
        map{
            Tr( { -class  => $c1++ % 3 ? ( $c2++ % 2 ? 'a1' : 'a2' ) : 'a3' },
                th( { -class => 'r top label' }, $defaults->{ $_ }[0] ), # name
                td( { -class => 'c top value' }, $defaults->{ $_ }[1] ), # variable
                td( { -class => 'top value' }, $defaults->{ $_ }[2] ) # value
            )
        } sort { lc $a <=> lc $b } keys %$defaults
    )
}

###############
#  Action. Perl config summary. Uses Config.

sub config_summary {
    Tr( td( { -class => 'a2' }, pre( Config::myconfig() ) ) );
}

###############
#  Action. Perl full config. Uses Config.

sub config_full {

    my ( $c1, $c2, $output, $letter ) = ( 1, 1, '', '' ); # color incrementors

    for ( sort{ lc $a cmp lc $b } split( /\n/, Config::config_sh() ) ){

        my ( $var, $val ) = split /=/;
        $letter = substr( $var, 0, 1 );

        $val =~ s/["'](.*)\1/$1/g;

        $output .=
            Tr( { -class  => $c1++ % 3 ? ( $c2++ % 2 ? 'a1' : 'a2' ) : 'a3' },
                td( { -class => 'label' },
                    a( { -href => "$vars->{'script_name'}?action=2010&module=Config#$letter" },
                        $var
                    )
                ),
                td( { -class => 'value' }, $val )
            )
    }

    return $output;
}



###############
# Action. Finds installed mods.

sub installed_mods {

    my ( $third, $modcount, $mods, %found ) = ( 0, 0, '' );


    find( { wanted => \&wanted, untaint => 1 }, @INC );

    ++$found{ $_ } foreach @foundmods;


    @foundmods = sort { lc $a cmp lc $b } keys( %found );
    $modcount  = @foundmods;

    $third = int( @foundmods / 3 );

    my ( $c1, $c2 ) = ( 1, 0 ); # counter incrementor

    $mods = Tr(
                th( { -colspan => '3', -class => 'hl' },
                    "$modcount modules found."
                )
            );

    for ( 0 .. $third ) {

        # many thanks to Dave Cross (dave@dave.org.uk) for the code that
        # accurately splits the output across 3 columns.

        my $col1 = $foundmods[ $_ ] || '';
        my $col2 = $foundmods[ $_ + $third + 1 ] || '';
        my $col3 = $foundmods[ $_ + 2 + ( 2 * $third ) ] || '';



        $mods .=
                Tr( { -class => 'mono' },
                    td( { -width => '33%', -class  => 'a2' },
                        a( { -href =>
                            "$vars->{'script_name'}?action=2010&module="
                            . pd_uri_escape( $col1 )
                            },
                            $col1
                        )
                    ),

                    td( { -width => '33%', -class  => 'a3' },
                        a( { -href =>
                            "$vars->{'script_name'}?action=2010&module="
                            . pd_uri_escape( $col2 )
                            },
                            $col2
                        )
                    ),
                    td( { -width => '34%', -class  => 'a1' },
                        a( { -href =>
                            "$vars->{'script_name'}?action=2010&module="
                            . pd_uri_escape( $col3 )
                            },
                            $col3
                        )
                    )
                )
    }
    return $mods;
}




# borrowed from URI::Escape
sub pd_uri_escape {

    for (0..255) {
        $escapes{ chr( $_ ) } = sprintf( "%%%02X", $_ );
    }

    my ( $text ) = @_;
    return undef unless defined $text;
    $text =~ s/([^A-Za-z0-9\-_.!~*'()])/$escapes{$1}/g;
    $text;

}

##########
# Private sub used by File::Find

sub wanted {

    if ( $File::Find::name =~ /\.pm$/ ){

        # Pull basename out to match package line. A little workaround
        # for modules whose docs contain sample code that includes package
        # declarations (e.g. DBD::mysql has "package MY" in code sample ).

        my $base = basename( $File::Find::name, ('.pm') );

        no warnings;
        open( MODFILE, $File::Find::name ) || return;

        while( <MODFILE> ){

            if ( /^ *package +(\S*?$base\S*?);/) {
                push ( @foundmods, $1 );
                last;
            }
        }
        close MODFILE;
        use warnings;
    }
}



###############
# Action. Main page. General defaults. Uses hohref $main_page from
# perldiver.conf

sub main {

    my ( $c1, $c2 ) = ( 1, 1 ); # color incrementors

    join ( "\n",
        map{
            Tr( { -class  => $c1++ % 3 ? ( $c2++ % 2 ? 'a1' : 'a2' ) : 'a3' },
               td( { -class => 'top label' }, $main_page->{ $_ }{ 'desc' } ),
               td( { -class => 'value' }, $main_page->{ $_ }{ 'val' } )
            )
        } sort { $a <=> $b } keys %$main_page
    )
}



##########
# Sub-action. Accessible from Installed Modules page. Uses Module::Info


sub module_detail {

    my $module = param( 'module' );
        $module =~ s/[^A-Za-z0-9:_]/ /g;

    if ( $module =~ /^([-\:\w.]+)$/ ) {
        $module = $1;
    } else {
        return Tr( th ( "Bad module name: $module" ) );
    }

    my $mod = Module::Info->new_from_module( $module );

    my ( $perldocmodpage, $output ) = ( "$module.html", '' );

    $perldocmodpage =~ s|::|/|g;

    my $mod_info = {
        10 => {
                'name' => 'Name',
                'val'  => $mod->name
              },
        20 => {
                'name' => 'Version',
                'val'  => $mod->version
              },
        30 => {
                'name' => 'Located at',
                'val' => $mod->inc_dir
              },
        40 => {
                'name' => 'File',
                'val' => $mod->file
              },
        50 => {
                'name' => 'Is Core',
                'val' => $mod->is_core  ? 'Yes' : 'No'
              },
        1000 => {
                'name' => 'Search CPAN for this module',
                'val' => a( {
                            -target => '_blank',
                            -href => $vars->{'cpan_base_url'} . pd_uri_escape( $module )
                            },
                            $module
                         )
              },
        1010 => {
                'name' => 'Documentation',
                'val' => a( {
                            -target => '_blank',
                            -href => "$vars->{'perldoc_base_url'}/$perldocmodpage"
                            },
                            $module
                         )
              }
    };


    # sets a global (ugh) to call Pod::Html when this sub is done. Can't
    # invoke Pod::Html from here because it immediately prints output.

    $module_path = $mod_info->{ '40' }{ 'val' };


    # Module::Info routines that require 5.6.1 or above

    eval "require 5.6.1";


#####
#

        my %subs = $mod->subroutines;

        $Data::Dumper::Terse = 1;          # don't output names where feasible
        $Data::Dumper::Indent = 1;

        my $response = '';

        if ( $^O =~ /mswin/i ){
            $response = 'This feature is currently not supported on Windows'
        } elsif( $@ ){
            $response = "perl 5.6.1 is required to view this data."
        } else {
            $response = 'None or Not Available'
        }

        $mod_info->{ '100' }{ 'name' } = 'Packages Inside';
        $mod_info->{ '100' }{ 'val'  } = $mod->packages_inside ? pre( Dumper( $mod->packages_inside ) ) : $response;

        $mod_info->{ '110' }{ 'name' } = 'Modules Used';
        $mod_info->{ '110' }{ 'val'  } = $mod->modules_used ? pre( Dumper( $mod->modules_used ) ) : $response;

        $mod_info->{ '120' }{ 'name' } = 'Subroutines';
        $mod_info->{ '120' }{ 'val'  } = keys %subs ? pre( Dumper( %subs ) ) : $response;

        $mod_info->{ '130' }{ 'name' } = 'Superclasses';
        $mod_info->{ '130' }{ 'val'  } = $mod->superclasses ? pre( Dumper( $mod->superclasses ) ) : $response;

        $mod_info->{ '140' }{ 'name' } = 'Subroutines Called';
        $mod_info->{ '140' }{ 'val'  } = $mod->subroutines_called ? pre( Dumper( $mod->subroutines_called ) ) : $response;

        $mod_info->{ '150' }{ 'name' } = 'Dynamic Method Calls';
        $mod_info->{ '150' }{ 'val'  } = $mod->dynamic_method_calls ? pre( Dumper( $mod->dynamic_method_calls ) ) : $response;



    my ( $c1, $c2 ) = ( 1, 1 ); # color incrementors

    join ( "\n",
        map{
            Tr( { -class  => $c1++ % 3 ? ( $c2++ % 2 ? 'a1' : 'a2' ) : 'a3' },
                td( { -class => 'label top' }, $mod_info->{ $_ }{ 'name' } ),
                td( { -class => 'value' }, $mod_info->{ $_ }{ 'val' } ),
            )
        } sort { $a <=> $b } keys %$mod_info
    )
}



##########
# Sub-Action. Displayed on module detail page. Must be called after header
# and module_detail because Pod::Html immediately prints to stdout.

sub module_pod {
#    param( 'module' => s/[^A-Za-z0-9]|://g );
    my $module = param( 'module' );
    $module =~ s/[^A-Za-z0-9:_]/ /g;

    my $mod = Module::Info->new_from_module( $module );

    my ( $perldocmodpage, $output ) = ( "$module.html", '' );

    $perldocmodpage =~ s|::|/|g;

    my $mod_info = {
        10 => {
                'name' => 'Name',
                'val'  => $mod->name
              },
        20 => {
                'name' => 'Version',
                'val'  => $mod->version
              },
        30 => {
                'name' => 'Located at',
                'val' => $mod->inc_dir
              },
        40 => {
                'name' => 'File',
                'val' => $mod->file
              },
        50 => {
                'name' => 'Is Core',
                'val' => $mod->is_core  ? 'Yes' : 'No'
              },
        1000 => {
                'name' => 'Search CPAN for this module',
                'val' => a( {
                            -target => '_blank',
                            -href => $vars->{'cpan_base_url'} . pd_uri_escape( $module )
                            },
                            $module
                         )
              },
        1010 => {
                'name' => 'Documentation',
                'val' => a( {
                            -target => '_blank',
                            -href => "$vars->{'perldoc_base_url'}/$perldocmodpage"
                            },
                            $module
                         )
              },
        1020 => {
                'name' => 'Module Details',
                'val' => a( {
                            -href => "$vars->{'script_name'}?action=2020&module=" . pd_uri_escape( $module )
                            },
                            $module
                         )
              }
    };

    my ( $c1, $c2 ) = ( 1, 1 ); # color incrementors

    my $file = $mod->file;

    my $details = join ( "\n",

        map{
            Tr( { -class  => $c1++ % 3 ? ( $c2++ % 2 ? 'a1' : 'a2' ) : 'a3' },
                td( { -class => 'label top' }, $mod_info->{ $_ }{ 'name' } ),
                td( { -class => 'value' }, $mod_info->{ $_ }{ 'val' } ),
            )
        } sort { $a <=> $b } keys %$mod_info

    );

    return
        Tr(
            td( { -class=> 'c1'},
                h1( $module )
            )
        ) .
        $details .
        Tr(
            td( { -colspan => 2 },
                pod2html( "--infile=$file", "--htmlroot=$vars->{'perldoc_base_url'}" )
            )
        );
}




##########
# Private. Just outputs the page header and description

sub _section_header{

    _table_output(
        Tr( { -class => 'hl' },
            th(
                span( { -class => 'heading'},
                    $actions->{ param( 'action' ) }{ 'name' }
                )
            )
        ),
        Tr(
            td(
                { -class => 'c' },
                $actions->{ param( 'action' ) }{ 'desc' }
            )
        )
    )
}


##########
# Private. Outputs formatted table. Expects any number of table rows

sub _table_output{

    table( {  -class => 'border-black', -cellspacing => '0' },
        Tr(
            td(
                table( { -class => 'background-white', -cellspacing => '0' },
                    @_
                )
            )
        )
    )
}


##########
# Private. Outputs navigation bar.

sub _navigation {

    my ( $c1, $c2 ) = ( 1, 1 ); # color incrementors
    my @showkeys = ();


    # build navigation bar using only keys that are defined to be shown.

    for my $key ( keys %$actions ){
        push @showkeys, $key if $actions->{ $key }{ 'show' } == 1;
    }

    Tr(
        map {
            th( { -class  => $c1++ % 3 ? ( $c2++ % 2 ? 'a1' : 'a2' ) : 'a3'},

                # create link to action unless it's the current action

                $_ == param( 'action' ) ?
                    $actions->{ $_ }{ 'name' }
                      :
                    a( { -href => "$vars->{ 'script_httppath' }$vars->{ 'script_name' }?action=$_" },
                        $actions->{ $_ }{ 'name' }
                    )
            )
        } sort { $a <=> $b } @showkeys
    )
}



##########
# Private. Page Header

sub _page_header{

    div( { -class => 'progname' }, "$prog $ver" );

}



##########
# Private. Page Footer

sub _page_footer{

    _table_output(
        Tr( { -class => 'hl' },
            th( { -class => 'copyr' },
                strike(
                    "$prog brought to you by <span>$dev</span> &copy;
                    1997-2006."
                ),
                a( {-href => 'https://github.com/mrrena/perldiver' },
                    ' ' . ( localtime( time ) )[5] + 1900 .
                    ' source code' ) . '.'
            )
        )
    ) .
    end_html;
}


##########
# Action. Outputs embedded pod.

sub help_extend{

    return
        Tr(
            td( { -class => 'c' },
                '<b>Source code @ ' .
                a({ -href => 'https://github.com/mrrena/perldiver' },
                'https://github.com/mrrena/perldiver') .
                ' or as a ' .
               a({-href =>
                'https://github.com/mrrena/perldiver/raw/master/perldiver.zip' },
                'zip file'),
                 ' (updated 2012).</b>'
            )
        ),
        Tr(
            td(
                &fetch_readme
            )
        );
}

sub fetch_readme{
    my $file = 'README.html';
    my $document = do {
        local $/ = undef;
        open my $fh, "<", $file
            or die "could not open $file: $!";
        return <$fh>;
    };
}
