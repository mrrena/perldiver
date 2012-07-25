#!/usr/bin/perl -X


# Note: This program currently cannot run with -T.  The Module::Info module
# does not perform taint checking.  However, all user input is taint-checked
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
# Check user input on action.  If it's not digits-only, just give them the
# main page.

#param( 'action' => '2000' ) unless param( 'action' );
param( 'action' => $vars->{ 'main_id' } ) unless param( 'action' );
param( 'action' ) =~ /^(\d+)$/;
param( 'action' => $1 );



##########
# A little cheat to create perldiver's doc page.

if ( param( 'action' ) == '06291969' ){
    my $file = pod2html(
            "--infile=$vars->{'script_name'}",
            "--htmlroot=$vars->{'perldoc_base_url'}",
            "--quiet"
    );
    open( DOCS, '>perldiver.html' ) or die "Can't open perldiver.html for writing $!";
    print DOCS $file;
    close DOCS or die "Can't close docs $!";

    print header, 'done';
    exit;
}



##########
# If an action is present but not defined in $actions , just give them the main
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
        p(),
        _table_output( &{$actions->{ param( 'action' ) }{ 'subr' } } ),
        _page_footer();



###############
# Action.  Environment variables.

sub environ_vars {

    my ( $c1, $c2 ) = ( 1, 1 );

    join ( "\n",
        map {
            Tr( { -class  => $c1++ % 3 ? ( $c2++ % 2 ? 'a1' : 'a2' ) : 'a3' },
                td( { -width => '35%', -class => 'label' }, $_ ),
                td( { -width => '65%', -class => 'value' },
                    '<tt>' . $ENV{ $_ } . '</tt>' )
            )
        } sort keys %ENV
    )
}



###############
# Action.  Perl default values.  Uses hohref $defaults from perldiver.conf

sub default_vals {

    my ( $c1, $c2 ) = ( 1, 1 );  # color incrementors

    Tr( { -class=> 'hl' },
        th( { -class => 'label', -width => '30%', -align => 'right' },
            'DESCRIPTION'
        ),
        th( { -class => 'label', -width => '15%' },
            'VARIABLE'
        ),
        th( { -class => 'label', -width => '55%', -align => 'left' },
            'RESULT'
        ),
    ) .
    join ( "\n",
        map{
            Tr( { -class  => $c1++ % 3 ? ( $c2++ % 2 ? 'a1' : 'a2' ) : 'a3' },
                th( { -valign => 'top', -align => 'right', -class => 'label' },
                    $defaults->{ $_ }[0] # name
                ),
                td( { -valign => 'top', -align => 'center' },
                    '<tt>' . $defaults->{ $_ }[1] . '</tt>' # variable
                ),
                td( { -valign => 'top' },
                    '<tt>' . $defaults->{ $_ }[2] . '</tt>' # value
                ),
            )
        } sort { lc $a <=> lc $b } keys %$defaults
    )
}

###############
#  Action.  Perl config summary.  Uses Config.

sub config_summary {
    Tr( td( { -class => 'a2' }, pre( Config::myconfig() ) ) );
}

###############
#  Action.  Perl full config.  Uses Config.

sub config_full {

    my ( $c1, $c2, $output, $letter ) = ( 1, 1, '', '' ); # color incrementors

    for ( sort{ lc $a cmp lc $b } split( /\n/, Config::config_sh() ) ){

        my ( $var, $val ) = split /=/;
        $letter = substr( $var, 0, 1 );

        $val =~ s/["'](.*)\1/$1/g;

        $output .=
            Tr( { -class  => $c1++ % 3 ? ( $c2++ % 2 ? 'a1' : 'a2' ) : 'a3' },
                td( { -class => 'label' },
                    a( { -href => "$vars->{'script_name'}?action=2010&module=Config#$letter",
                         -target => 'pcddet'
                       },
                        $var
                    )
                ),
                td( { -class => 'value' }, '<tt>' . $val . '</tt>')
            )
    }

    return $output;
}



###############
# Action.  Finds installed mods.

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

        # Pull basename out to match package line.  A little workaround
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
# Action.  Main page.  General defaults.  Uses hohref $main_page from
# perldiver.conf

sub main {

    my ( $c1, $c2 ) = ( 1, 1 ); # color incrementors

    join ( "\n",
        map{
            Tr( { -class  => $c1++ % 3 ? ( $c2++ % 2 ? 'a1' : 'a2' ) : 'a3' },
               td( { -class => 'label', -valign => 'top' },
                   $main_page->{ $_ }{ 'desc' }
               ),
               td( { -class => 'value' },
                   $main_page->{ $_ }{ 'val' }
               )
            )
        } sort { $a <=> $b } keys %$main_page
    )
}



##########
# Sub-action.  Accessible from Installed Modules page.  Uses Module::Info


sub module_detail {

    my $module = param( 'module' );
        $module =~ s/[^A-Za-z0-9:_]/ /g;

    if ( $module =~ /^([-\:\w.]+)$/ ) {
        $module = $1;
    }
    else {
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
                         ),
              },
        1010 => {
                'name' => 'Documentation',
                'val' => a( {
                            -target => '_blank',
                            -href => "$vars->{'perldoc_base_url'}/$perldocmodpage"
                            },
                            $module
                         ),
              },
    };


    # sets a global (ugh) to call Pod::Html when this sub is done.  Can't
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
        }
        elsif( $@ ){
            $response = "perl 5.6.1 is required to view this data."
        }
        else {
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

#    }


    my ( $c1, $c2 ) = ( 1, 1 ); # color incrementors

    join ( "\n",
        map{
            Tr( { -class  => $c1++ % 3 ? ( $c2++ % 2 ? 'a1' : 'a2' ) : 'a3' },
                td( { -class => 'label', -valign => 'top' }, $mod_info->{ $_ }{ 'name' } ),
                td( { -class => 'value' }, $mod_info->{ $_ }{ 'val' } ),
            )
        } sort { $a <=> $b } keys %$mod_info
    )
}



##########
# Sub-Action.  Displayed on module detail page.  Must be called after header
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
                         ),
              },
        1010 => {
                'name' => 'Documentation',
                'val' => a( {
                            -target => '_blank',
                            -href => "$vars->{'perldoc_base_url'}/$perldocmodpage"
                            },
                            $module
                         ),
              },
        1020 => {
                'name' => 'Module Details',
                'val' => a( {
                            -href => "$vars->{'script_name'}?action=2020&module=" . pd_uri_escape( $module )
                            },
                            $module
                         ),
              },
    };

    my ( $c1, $c2 ) = ( 1, 1 ); # color incrementors

    my $file = $mod->file;

    my $details = join ( "\n",

        map{
            Tr( { -class  => $c1++ % 3 ? ( $c2++ % 2 ? 'a1' : 'a2' ) : 'a3' },
                td( { -class => 'label', -valign => 'top' }, $mod_info->{ $_ }{ 'name' } ),
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

    p() .
    _table_output(
        Tr( { -class => 'hl' },
            th(
                span( { -class => 'heading'},
                    $actions->{ param( 'action' ) }{ 'name' }
                )
            )
        ) .
        Tr(
            td(
                { -align => 'center' },
                $actions->{ param( 'action' ) }{ 'desc' }
            )
        )
    )
}


##########
# Private. Outputs formatted table.  Expects any number of table rows

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
# Private.  Outputs navigation bar.

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
# Private.  Page Header

sub _page_header{

    div( { -class => 'progname' }, "$prog $ver" );

}



##########
# Private.  Page Footer

sub _page_footer{

    p() .
    _table_output(
        Tr( { -class => 'hl' },
            th( { -class => 'copyr' },
                "$prog brought to you by " .
                strike( { -href => 'http://scriptsolutions.com' }, $dev ) .
                ' &copy; 1997-2003. ' .
                a( {-href => 'https://github.com/mrrena/perldiver' },
                    ' ' . ( localtime( time ) )[5] + 1900 .
                    ' source code' ) . '.'
            )
        )
    ) .
    end_html;
}


##########
# Action.  Outputs embedded pod.

sub help_extend{

    return
        Tr(
            td( { -class => 'c' },
                '<br /><br /><b>Source code @ ' .
                a({ -href => 'https://github.com/mrrena/perldiver' },
                'https://github.com/mrrena/perldiver') .
                ' or as a ' .
               a({-href =>
                'https://github.com/mrrena/perldiver/raw/master/perldiver2.33.zip' },
                'zip file'),
                 ' (updated 2012).</b><br /><br />'
            ),
        ),
        Tr(

            td(
                pod2html(
                    "--infile=$vars->{'script_name'}",
                    "--htmlroot=$vars->{'perldoc_base_url'}",
                    "--title=PerlDiver Documentation",
                    "--quiet",
                )
            )
        );
}


__END__

=head1 Name

Perl Diver

=head1 Description

Perl Diver is a CGI program written in Perl that will help you find out what
modules are installed on your server, server paths, perl configuration settings,
etc.

=head1 Installation

PerlDiver is installed simply by unzipping and uploading all files in the
distribution into your cgi-bin directory. If you don't know where your cgi-bin
directory is, please ask your system administrator.  Be sure to upload all files
in ASCII format.

After the files are uploaded, perldiver.cgi needs to have execute permissions
turned on.  You can do this by running the command C<chmod +x perldiver.cgi>
from your command line. If you don't have command line access to your web
server, then there will probably be an equivalent function in your file transfer
program.


=head2 Files in this Distribution

=over

=item 1 perldiver.cgi

The executable program.

=item 2 perldiver.conf

Configuration settings.  Several sections in Perl Diver
display information based on settings in this file.  See L<Customizing Perl
Diver> below for details.

=item 3 B/Utils.pm

A Perl module required by Module::Info.

=item 4 B/Module/Info.pm

A Perl module required by Module::Info.

=item 5 Module/Info.pm

A Perl module used to provide details about a module.

=item 6 Pod/Html2.pm

A modified version of Pod::Html.

=back

=head1 Sections

Perl Diver comes with a base set of sections to which you can add your own
(covered in L<Customizing Perl Diver>).  These sections are described below.

=head2 Main

This section is the page that you see when you go to Perl Diver in your browser
without any parameters.  It shows you the paths to Perl, sendmail, operating
system, etc.  You can add or edit variables to this section (see L<Customizing
Perl Diver>).

=head2 Environment Variables

In order to pass data about the information request from the server to the
script, the server uses command line arguments as well as environment variables.
These environment variables are set when the server executes the gateway program.

- I< Excerpted from L<http://hoohoo.ncsa.uiuc.edu/cgi/env.html>>

This section displays all environment variables that are available for your
server.

=head2 Perl Default Values

This section shows you some basic default values, such as a list of signal
handlers supported by your server, various separators, debugging support, etc.
You can add to this list by editing the Perl Defaults section of the
configuration file.  See L<Customizing Perl Diver> for details.

=head2 Perl Config - Summary

Displays a summary of the major perl configuration values.

=head2 Perl Config - Full

All the information that was available to the Configure program at Perl build
time (over 900 values). This section displays the entire perl configuration
information in the form of the original config.sh shell variable assignment
script.

All variables are linked to its description in Config.pm's documentation
(using Perl Diver's L<Module Details> function).


=head2 Installed Modules

This section will list all modules that are included in the paths listed in
C<@INC>.  Each module is linked to a page with more information about the module
and its documentation (if any exist).

=head3 View Module Details & Documentation

=head4 Module Details

These details are extracted using the Module::Info module
(found at L<http://search.cpan.org/search?dist=Module-Info>), which is included
in the Perl Diver distribution.  The documentation in this section is derived
from the module.

=over

=item 1 Name

Just the name of the module.

=item 2 Version Number, if any.

Divines the value of C<$VERSION>.  Module::Info uses the same method as
L<ExtUtils::MakeMaker|ExtUtils::MakeMaker> and all caveats therein apply.

=item 3 Include Directory

Include directory in which this module was found.

=item 4 File

The absolute path to the module.

=item 5 Is Core

Shows you if this module is included in the Perl distribution.

Note that this checks perl's installation directories (see the
L<Perl Config - Full> output for the directory listed in the C<installarchlib>
and C<installprivlib> setting. It's possible that the module has been altered or
upgraded from CPAN since the original Perl installation.

A non-zero number states that it is a core module.

=back

The following details are extracted by compiling the module and examining the
optree code. The module will be compiled in a separate process so that it does
not disturb the current program.

These details will only show if you have perl 5.6.1 I<(or greater)> installed
and requires the B::Utils module.

If you have perl 5.6.1 or higher and see all "None or Not Available" responses,
check your error log.  Module::Info may not be finding a required module to
Run.

B<Notes>: Currently doesn't spot package changes inside subroutines.  Also, the
following will currently not display if your server is running Win32.

=over

=item 1 Packages Inside

Looks for any explicit C<package> declarations inside the module and returns a
list.  Useful for finding hidden classes and functionality (like Tie::StdHandle
inside Tie::Handle).

B<Note>: Module::Info currently does not spot package changes inside subroutines.

=item 2 Modules Used

Returns a list of all modules and files which may be C<use>'d or C<require>'d
by this module.

B<Note>: These modules may be conditionally loaded, but Module::Info can't tell.
It cannot find modules which might be used inside an C<eval>.

=item 3 Subroutines


=item 4 Superclasses

=item 5 Subroutines Called

=item 6 Dynamic Method Calls

=back

The remaining 2 options are to find the module and its documentation.  See
L<Changing Urls> for instructions on how to change the urls these links point
to.



=head1 Customizing Perl Diver

=head2 Changing Appearance

All colors, fonts, and font sizes are controlled by a style sheet in
perldiver.conf.  Make style sheet changes to the 'style' variable.

=head2 Changing Urls

=head3 CPAN and Perl Documentation links

By default, CPAN modules link to L<http://search.cpan.org> and Perl
documentation links to L<http://perldoc.com>.  You can change this to your
favorite mirror by editing the C<'perldoc_base_url'> and C<'cpan_base_url'>
variables in the "Other" section of perldiver.conf.

=head3 Rename perldiver.cgi

By default, Perl Diver is named perldiver.cgi.  If you've changed this, be sure
to change the C<'script_name'> variable in perldiver.conf's "Other" section.
It's recommended to not change the name of perldiver.conf, but if you do, open
perldiver.cgi and change the following line:

C<do 'perldiver.conf' or die "Can't load conf file $!";>

to reflect the new name/location of the configuration file.
=back

=head2 Default Settings

You can modify or add any piece of information that appears on the
L<Perl Default Values> page by editing the values in the "Perl Defaults"
section.  Add new data to the C<$defaults> hashref using the format shown.


=head2 Extending Perl Diver

Extending Perl Diver is easy, but not for the faint at heart.  Simple
follow the examples in perldiver.conf to build your own.

=head3 Samples

=over

=item Add command line output

    65 =>  {
        'name' => 'List Directory',
        'subr' => sub { Tr( td( pre( `ls -la`) ) ) },
        'show' => 1,
        'desc' => 'Just a sample of extending Perl Diver with command output.'
    },


=back


=head1 Dependencies

PerlDiver requires the following modules to be installed.

=over

=item CGI

Standard module included in perl distribution.

=item File::Find

Standard module included in perl distribution.

=item Config

Module created when perl is installed.

=item Pod::Html2

Included with PerlDiver.

=item Module::Info

Included with PerlDiver.

=item Pod2::Html

A modified version of L<Pod::Html|Pod::Html> by Tom Christiansen.
Included with PerlDiver.  This should be considered extremely beta.  It will not
break PerlDiver, but may alter the output of the module documentation.  Please
report inconsistencies to programmer@scriptsolutions.com.

=back



=head1 Caveats

=over

=item Module details is not supported on Win32 systems.

=back


=head1 License

This script is free software; you are free to redistribute it and/or modify it
under the same terms as Perl itself.


=head1 Changes

2.033 - Corrected bug introduced by v2.032. I<20051217>)

2.032 - Added testing to module detail input. See L<http://www.scriptsolutions.com/support/showflat.pl?Board=PDBugs&Number=443> for details. (I<20050916>)

2.031 - Told Pod2::Html to shut up already. (I<20030420>)

2.03 - Removed most superfluous warnings in perldiver and Pod2::Html. (I<20030419>)

2.02 - Modified Module::Info to remove warnings (I<20030115>)

2.01 - Modified Pod::Html and included it as Pod2::Html (I<20030103>)

2.00 - Overhaul from version 1.x (I<20021216>)


=head1 Support

For support of this script please visit L<http://scriptsolutions.com/support/>


=head1 Credits & Acknowledgements



=head1 Copyright

Copyright 1997-2003, TNS Group, Inc.
(I<L<http://www.tnsgroup.com>>) dba ScriptSolutions
(I<L<http://scriptsolutions.com>>)


=cut

