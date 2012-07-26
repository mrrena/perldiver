# Perl Diver 2.33

*   [Name](#name)
*   [Description](#description)
*   [Get the Source](#get-the-source)
*   [Installation](#installation)
    *   [Files in this Distribution](#files-in-this-distribution)
*   [Sections](#sections)
    *   [Main](#main)
    *   [Environment Variables](#environment-variables)
    *   [Perl Default Values](#perl-default-values)
    *   [Perl Config - Summary](#perl-config---summary)
    *   [Perl Config - Full](#perl-config---full)
    *   [Installed Modules](#installed-modules)
        *   [View Module Details &amp; Documentation](#view-module-details--documentation)
            *   [Module Details](#module-details)
*   [Customizing Perl Diver](#customizing-perl-diver)
    *   [Changing Appearance](#changing-appearance)
    *   [Changing Urls](#changing-urls)
        *   [CPAN and Perl Documentation links](#cpan-and-perl-documentation-links)
        *   [Rename perldiver.pl](#rename-perldiverpl)
    *   [Default Settings](#default-settings)
    *   [Extending Perl Diver](#extending-perl-diver)
*   [Dependencies](#dependencies)
*   [Caveats](#caveats)
*   [License](#license)
*   [Changes](#changes)
*   [Support](#support)
*   [Credits &amp; Acknowledgements](#credits--acknowledgements)

# <a id="name"></a>Name

Perl Diver

# <a id="description"></a>Description

Perl Diver is a CGI program written in Perl that will help you find out what modules are installed on your server, server paths, perl configuration settings, etc.

# <a id="get-the-source"></a>Get the Source

Perl Diver source code available on GitHub @ [https://github.com/mrrena/perldiver][8]. Blog post with screenshot and how-tos on hiding Perl Diver from search engines using a *robots.txt* file and password protecting your perldiver directory using Apache's *htpasswd*: [Perl Diver 2.33: Download and Installation][9].

# <a id="installation"></a>Installation

If you have *git* access:

     # as ssh
     git clone git://github.com/mrrena/perldiver
     # as https
     git clone https://github.com/mrrena/perldiver

Otherwise, PerlDiver is installed simply by unzipping and uploading all files in the [distribution zip][10] into your cgi-bin directory. If you don't know where your cgi-bin directory is, please ask your system administrator. Be sure to upload all files in ASCII format.

After the files are uploaded, *perldiver.pl* needs to have execute permissions turned on. You can do this by running the command *chmod +x perldiver.pl* from your command line. If you don't have command line access to your web server, then there will probably be an equivalent function in your file transfer program (FTP).

## <a id="files-in-this-distribution"></a>Files in this Distribution

#### 1. perldiver.pl

The executable program.

#### 2. perldiver.conf

Configuration settings. Several sections in Perl Diver display information based on settings in this file. See [Customizing Perl Diver](#customizing-perl-diver) below for details.

#### 3. B/Utils.pm

A Perl module required by Module::Info.

#### 4. B/Module/Info.pm

A Perl module required by Module::Info.

#### 5. Module/Info.pm

A Perl module used to provide details about a module.

#### 6. Pod/Html2.pm

A modified version of Pod::Html.

# <a id="sections"></a>Sections

Perl Diver comes with a base set of sections to which you can add your own (covered in [Customizing Perl Diver](#customizing-perl-diver). These sections are described below.

## <a id="main"></a>Main

This section is the page that you see when you go to Perl Diver in your browser without any parameters. It shows you the paths to Perl, sendmail, operating system, etc. You can add or edit variables to this section (see [Customizing Perl Diver](#customizing-perl-diver)).

## <a id="environment-variables"></a>Environment Variables

In order to pass data about the information request from the server to the script, the server uses command line arguments as well as environment variables. These environment variables are set when the server executes the gateway program.

* Excerpted from ~~http://hoohoo.ncsa.uiuc.edu/cgi/env.html~~ [(Internet Archive Wayback Machine Link)][1]*

This section displays all environment variables that are available for your server.

## <a id="perl-default-values"></a>Perl Default Values

This section shows you some basic default values, such as a list of signal handlers supported by your server, various separators, debugging support, etc. You can add to this list by editing the Perl Defaults section of the configuration file. See [Customizing Perl Diver](#customizing-perl-diver) for details.

## <a id="perl-config---summary"></a>Perl Config - Summary

Displays a summary of the major perl configuration values.

## <a id="perl-config---full"></a>Perl Config - Full

All the information that was available to the Configure program at Perl build time (over 900 values). This section displays the entire perl configuration information in the form of the original config.sh shell variable assignment script.

All variables are linked to its description in Config.pm's documentation (using Perl Diver's [Module Details](#module-details) function).

## <a id="installed-modules"></a>Installed Modules

This section will list all modules that are included in the paths listed in @INC. Each module is linked to a page with more information about the module and its documentation (if any exist).

### <a id="view-module-details--documentation"></a>View Module Details &amp; Documentation

#### <a id="module-details"></a>Module Details

These details are extracted using the Module::Info module (found at [http://search.cpan.org/search][2]), which is included in the Perl Diver distribution. The documentation in this section is derived from the module.

1.  **Name**
    Just the name of the module.
2.  **Version Number, if any.**
    Divines the value of $VERSION. Module::Info uses the same method as [ExtUtils::MakeMaker][3] and all caveats therein apply.
3.  **Include Directory**
    Include directory in which this module was found.
4.  **File**
    The absolute path to the module.
5.  **Is Core**
    Shows you if this module is included in the Perl distribution.
    Note that this checks perl's installation directories (see the [Perl Config - Full](#perl-config---full) output for the directory listed in the installarchlib and installprivlib setting. It's possible that the module has been altered or upgraded from CPAN since the original Perl installation.

    A non-zero number states that it is a core module.

The following details are extracted by compiling the module and examining the optree code. The module will be compiled in a separate process so that it does not disturb the current program.

These details will only show if you have perl 5.6.1 *(or greater)* installed and requires the B::Utils module.

If you have perl 5.6.1 or higher and see all "None or Not Available" responses, check your error log. Module::Info may not be finding a required module to Run.

**Notes**: Currently doesn't spot package changes inside subroutines. Also, the following will currently not display if your server is running Win32.

1.  **Packages Inside**
    Looks for any explicit package declarations inside the module and returns a list. Useful for finding hidden classes and functionality (like Tie::StdHandle inside Tie::Handle).
    **Note**: Module::Info currently does not spot package changes inside subroutines.

2.  **Modules Used**
    Returns a list of all modules and files which may be use'd or require'd by this module.
    **Note**: These modules may be conditionally loaded, but Module::Info can't tell. It cannot find modules which might be used inside an eval.

3.  **Subroutines**
4.  **Superclasses**
5.  **Subroutines Called**
6.  **Dynamic Method Calls**

The remaining 2 options are to find the module and its documentation. See [Changing Urls](#changing-urls) for instructions on how to change the urls to which these links point.

# <a id="customizing-perl-diver"></a>Customizing Perl Diver

## <a id="changing-appearance"></a>Changing Appearance

All colors, fonts, and font sizes are controlled by a style sheet in *perldiver.conf*. Make style sheet changes to the style variable.

## <a id="changing-urls"></a>Changing Urls

### <a id="cpan-and-perl-documentation-links"></a>CPAN and Perl Documentation links

By default, CPAN modules link to [http://search.cpan.org][4] and Perl documentation links to [http://perldoc.perl.org][5]. You can change this to your favorite mirror by editing the perldoc\_base\_url and cpan\_base\_url variables in the **Other** section of *perldiver.conf*.

### <a id="rename-perldiverpl"></a>Rename perldiver.pl

By default, Perl Diver is named perldiver.pl. If you've changed this, be sure to change the script\_name variable in *perldiver.conf*'s **Other** section. It's recommended to not change the name of *perldiver.conf*, but if you do, open *perldiver.pl* and change the following line:

    do 'perldiver.conf' or die "Can't load conf file $!";

to reflect the new name/location of the configuration file.

## <a id="default-settings"></a>Default Settings

You can modify or add any piece of information that appears on the [Perl Default Values](#perl-default-values) page by editing the values in the "Perl Defaults" section. Add new data to the $defaults hashref using the format shown.

## <a id="extending-perl-diver"></a>Extending Perl Diver

Extending Perl Diver is easy, but not for the faint at heart. Simple follow the examples in *perldiver.conf* to build your own.

## <a id="item-Add-command-line-output"></a>Add command line output

    65 =  {
        'List Directory',
        sub { Tr( td( pre( `ls -la`) ) ) },
        'show' = 1,
        'Just a sample of extending Perl Diver with command output.'
    },

# <a id="dependencies"></a>Dependencies

PerlDiver requires the following modules to be installed.

#### <a id="item-CGI"></a>CGI

Standard module included in perl distribution.

#### <a id="item-File::A::AFind"></a>File::Find

Standard module included in perl distribution.

#### <a id="item-Config"></a>Config 

Module created when perl is installed.

#### <a id="item-Pod::A::AHtml2"></a>Pod::Html2 

Included with PerlDiver.

#### <a id="item-Module::A::AInfo"></a>Module::Info

Included with PerlDiver.

#### <a id="item-Pod2::A::AHtml"></a>Pod2::Html

A modified version of [Pod::Html][6] by Tom Christiansen. Included with PerlDiver. This should be considered extremely beta. It will not break PerlDiver, but may alter the output of the module documentation. Please report inconsistencies to ~~programmer@scriptsolutions.com~~.

# <a id="caveats"></a>Caveats

#### <a id="item-Module-details-is-not-supported-on-Win32-systems"></a>Module details is not supported on Win32 systems.

# <a id="license"></a>License

This script is free software; you are free to redistribute it and/or modify it under the same terms as Perl itself.

# <a id="changes"></a>Changes

2.032 - Added testing to module detail input. See ~~http://www.scriptsolutions.com/support/showflat.pl~~ [*(Internet Archive Wayback Machine Link)*][7] for details. (*20050916*)

2.031 - Told Pod2::Html to shut up already. (*20030420*)

2.03 - Removed most superfluous warnings in perldiver and Pod2::Html. (*20030419*)

2.02 - Modified Module::Info to remove warnings (*20030115*)

2.01 - Modified Pod::Html and included it as Pod2::Html (*20030103*)

2.00 - Overhaul from version 1.x (*20021216*)

# <a id="support"></a>Support

For support of this script please visit ~~http://scriptsolutions.com/support/~~

# <a id="credits--acknowledgements"></a>Credits &amp; Acknowledgements

Copyright 1997-2006, Creative Fundamentals, Inc. ~~http://creativefundamentals.com~~ dba ScriptSolutions ~~http://scriptsolutions.com~~)

 [1]: http://web.archive.org/web/20100123121442/http://hoohoo.ncsa.illinois.edu/cgi/env.html
 [2]: http://search.cpan.org/search?dist=Module-Info
 [3]: http://perldoc.perl.org/ExtUtils/MakeMaker.html
 [4]: http://search.cpan.org/
 [5]: http://perldoc.perl.org/
 [6]: http://perldoc.perl.org/Pod/Html.html
 [7]: http://web.archive.org/web/20061019231359/http://www.scriptsolutions.com/support/showflat.pl?Board=PDBugs&amp;Number=443
 [8]: https://github.com/mrrena/perldiver
 [9]: http://mrrena.blogspot.com/2012/05/perl-diver-233-download-and.html
 [10]: https://github.com/mrrena/perldiver/raw/master/perldiver2.33.zip
