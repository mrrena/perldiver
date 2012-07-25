package Module::Info;
use strict;
use Carp;
use File::Spec;
use Config;
require 5.004;

use vars qw($VERSION);
$VERSION = '0.12';


=head1 NAME

Module::Info - Information about Perl modules

=head1 SYNOPSIS

  use Module::Info;

  my $mod = Module::Info->new_from_file('Some/Module.pm');
  my $mod = Module::Info->new_from_module('Some::Module');
  my $mod = Module::Info->new_from_loaded('Some::Module');

  my @mods = Module::Info->all_installed('Some::Module');

  my $name    = $mod->name;
  my $version = $mod->version;
  my $dir     = $mod->inc_dir;
  my $file    = $mod->file;
  my $is_core = $mod->is_core;

  # Only available in perl 5.6.1 and up.
  # These do compile the module.
  my @packages = $mod->packages_inside;
  my @used     = $mod->modules_used;
  my @subs     = $mod->subroutines;
  my @isa      = $mod->superclasses;
  my @calls    = $mod->subroutines_called;

  # Check for constructs which make perl hard to predict.
  my @methods   = $mod->dynamic_method_calls;
  my @lines     = $mod->eval_string;    *UNIMPLEMENTED*
  my @lines     = $mod->gotos;          *UNIMPLEMENTED*
  my @controls  = $mod->exit_via_loop_control;      *UNIMPLEMENTED*
  my @unpredictables = $mod->has_unpredictables;    *UNIMPLEMENTED*

=head1 DESCRIPTION

Module::Info gives you information about Perl modules B<without
actually loading the module>.  It actually isn't specific to modules
and should work on any perl code.

=head1 METHODS

=head2 Constructors

There are a few ways to specify which module you want information for.
They all return Module::Info objects.

=over 4

=item new_from_file

  my $module = Module::Info->new_from_file('path/to/Some/Module.pm');

Given a file, it will interpret this as the module you want
information about.  You can also hand it a perl script.

If the file doesn't exist or isn't readable it will return false.

=cut

sub new_from_file {
    my($proto, $file) = @_;
    my($class) = ref $proto || $proto;

    return unless -r $file;

    my $self = {};
    $self->{file} = File::Spec->rel2abs($file);
    $self->{dir}  = '';
    $self->{name} = '';

    return bless $self, $class;
}

=item new_from_module

  my $module = Module::Info->new_from_module('Some::Module');
  my $module = Module::Info->new_from_module('Some::Module', @INC);

Given a module name, @INC will be searched and the first module found
used.  This is the same module that would be loaded if you just say
C<use Some::Module>.

If you give your own @INC, that will be used to search instead.

=cut

sub new_from_module {
    my($class, $module, @inc) = @_;
    return ($class->_find_all_installed($module, 1, @inc))[0];
}

=item new_from_loaded

  my $module = Module::Info->new_from_loaded('Some::Module');

Gets information about the currently loaded version of Some::Module.
If it isn't loaded, returns false.

=cut

sub new_from_loaded {
    my($class, $name) = @_;

    my $mod_file = join('/', split('::', $name)) . '.pm';
    my $filepath = $INC{$mod_file} || '';

    my $module = Module::Info->new_from_file($filepath);
    $module->{name} = $name;
    ($module->{dir} = $filepath) =~ s|/?$mod_file$||;
    $module->{dir} = File::Spec->rel2abs($module->{dir});

    return $module;
}

=item all_installed

  my @modules = Module::Info->all_installed('Some::Module');
  my @modules = Module::Info->all_installed('Some::Module', @INC);

Like new_from_module(), except I<all> modules in @INC will be
returned, in the order they are found.  Thus $modules[0] is the one
that would be loaded by C<use Some::Module>.

=cut

sub all_installed {
    my($class, $module, @inc) = @_;
    return $class->_find_all_installed($module, 0, @inc);
}

# Thieved from Module::InstalledVersion
sub _find_all_installed {
    my($proto, $name, $find_first_one, @inc) = @_;
    my($class) = ref $proto || $proto;

    @inc = @INC unless @inc;
    my $file = File::Spec->catfile(split /::/, $name) . '.pm';
    
    my @modules = ();
    DIR: foreach my $dir (@inc) {
        # Skip the new code ref in @INC feature.
        next if ref $dir;

        my $filename = File::Spec->catfile($dir, $file);
        if( -r $filename ) {
            my $module = $class->new_from_file($filename);
            $module->{dir} = File::Spec->rel2abs($dir);
            $module->{name} = $name;
            push @modules, $module;
            last DIR if $find_first_one;
        }
    }
              
    return @modules;
}


=back

=head2 Information without loading

The following methods get their information without actually compiling
the module.

=over 4

=item B<name>

  my $name = $module->name;
  $module->name($name);

Name of the module (ie. Some::Module).  

Module loaded using new_from_file() won't have this information in
which case you can set it yourself.

=cut

sub name {
    my($self) = shift;
    
    $self->{name} = shift if @_;
    return $self->{name};
}

=item B<version>

  my $version = $module->version;

Divines the value of $VERSION.  This uses the same method as
ExtUtils::MakeMaker and all caveats therein apply.

=cut

# Thieved from ExtUtils::MM_Unix 1.12603
sub version {
    my($self) = shift;

    my $parsefile = $self->file;

    open(MOD, $parsefile) or die $!;

    my $inpod = 0;
    my $result;
    while (<MOD>) {
        $inpod = /^=(?!cut)/ ? 1 : /^=cut/ ? 0 : $inpod;
        next if $inpod || /^\s*#/;

        chomp;
        next unless /([\$*])(([\w\:\']*)\bVERSION)\b.*\=/;
        my $eval = qq{
                      package Module::Info::_version;
                      no strict;

                      local $1$2;
                      \$$2=undef; do {
                          $_
                      }; \$$2
        };
        local $^W = 0;
        $result = eval($eval);
        warn "Could not eval '$eval' in $parsefile: $@" if $@;
        $result = "undef" unless defined $result;
        last;
    }
    close MOD;
    return $result;
}


=item B<inc_dir>

  my $dir = $module->inc_dir;

Include directory in which this module was found.  Module::Info
objects created with new_from_file() won't have this info.

=cut

sub inc_dir {
    my($self) = shift;

    return $self->{dir};
}

=item B<file>

  my $file = $module->file;

The absolute path to this module.

=cut

sub file {
    my($self) = shift;

    return $self->{file};
}

=item B<is_core>

  my $is_core = $module->is_core;

Checks if this module is the one distributed with Perl.

B<NOTE> This goes by what directory it's in.  It's possible that the
module has been altered or upgraded from CPAN since the original Perl
installation.

=cut

sub is_core {
    my($self) = shift;

    return scalar grep $self->{dir} eq File::Spec->canonpath($_), 
                           ($Config{installarchlib},
                            $Config{installprivlib});
}

=back

=head2 Information that requires loading.

B<WARNING!>  From here down reliability drops rapidly!

The following methods get their information by compiling the module
and examining the opcode tree.  The module will be compiled in a
seperate process so as not to disturb the current program.

They will only work on 5.6.1 and up and requires the B::Utils module.

=over 4

=item B<packages_inside>

  my @packages = $module->packages_inside;

Looks for any explicit C<package> declarations inside the module and
returns a list.  Useful for finding hidden classes and functionality
(like Tie::StdHandle inside Tie::Handle).

B<KNOWN BUG> Currently doesn't spot package changes inside subroutines.

=cut

sub packages_inside {
    my $self = shift;

    my @packs = $self->_call_B('packages');

    my %packs;
    @packs{@packs} = (1) x @packs;

    return keys %packs;
}

=item B<modules_used>

  my @used = $module->modules_used;

Returns a list of all modules and files which may be C<use>'d or
C<require>'d by this module.

B<NOTE> These modules may be conditionally loaded, can't tell.  Also
can't find modules which might be used inside an C<eval>.

=cut

sub modules_used {
    my($self) = shift;

    my $mod_file = $self->file;
    my @mods = $self->_call_B('modules_used');

    my @used_mods = ();
    push @used_mods, map { my($file) = /^use (\S+)/;  _file2mod($file); }
                     grep /^use \D/ && /at \Q$mod_file\E /, @mods;

    push @used_mods, map { my($file) = /^require bare (\S+)/;  _file2mod($file) }
                     grep /^require bare \D/ , @mods;

    push @used_mods, map { /^require not bare (\S+)/; $1 } 
                     grep /^require not bare \D/, @mods;

    my %used_mods = ();
    @used_mods{@used_mods} = (1) x @used_mods;
    return keys %used_mods;
}

sub _file2mod {
    my($mod) = shift;
    $mod =~ s/\.pm//;
    $mod =~ s|/|::|g;
    return $mod;
}


=item B<subroutines>

  my %subs = $module->subroutines;

Returns a hash of all subroutines defined inside this module and some
info about it.  The key is the *full* name of the subroutine
(ie. $subs{'Some::Module::foo'} rather than just $subs{'foo'}), value
is a hash ref with information about the subroutine like so:

    start   => line number of the first statement in the subroutine
    end     => line number of the last statement in the subroutine

Note that the line numbers may not be entirely accurate and will
change as perl's backend compiler improves.  They typically correspond
to the first and last I<run-time> statements in a subroutine.  For
example:

    sub foo {
        package Wibble;
        $foo = "bar";
        return $foo;
    }

Taking C<sub foo {> as line 1, Module::Info will report line 3 as the
start and line 4 as the end.  C<package Wibble;> is a compile-time
statement.  Again, this will change as perl changes.

Note this only catches simple C<sub foo {...}> subroutine
declarations.  Anonymous, autoloaded or eval'd subroutines are not
listed.

=cut

sub subroutines {
    my($self) = shift;

    my $mod_file = $self->file;
    my @subs = $self->_call_B('subroutines');
    return  map { /^(\S+) at \S+ from (\d+) to (\d+)/; 
                  ($1 => { start => $2, end => $3 }) } 
            grep /at \Q$mod_file\E /, @subs;
}

sub _call_B {
    my($self, $arg) = @_;

    my $mod_file = $self->file;
    my @out = `$^X "-MO=Module::Info,$arg" $mod_file 2>&1`;
    if( $? ) {
        my $exit = $? >> 8;
        warn join "\n", "B::Module::Info,$arg use failed with $exit saying: ",
                        @out;
        return;
    }

    @out = grep !/syntax OK$/, @out;
    chomp @out;
    return @out;
}


=item B<superclasses>

  my @isa = $module->superclasses;

Returns the value of @ISA for this $module.  Requires that
$module->name be set to work.

B<NOTE> superclasses() is currently cheating.  See L<CAVEATS> below.

=cut

sub superclasses {
    my $self = shift;

    my $mod_file = $self->file;
    my $mod_name = $self->name;
    unless( $mod_name ) {
        carp 'isa() requires $module->name to be set';
        return;
    }

    my @isa = `$^X -e "require q{$mod_file}; print join qq{\\n}, \@$mod_name\::ISA"`;
    chomp @isa;
    return @isa;
}

=item B<subroutines_called>

  my @calls = $module->subroutines_called;

Finds all the methods and functions which are called inside the
$module.

Returns a list of hashes.  Each hash represents a single function or
method call and has the keys:

    line        line number where this call originated
    class       class called on if its a class method
    type        function, symbolic function, object method, 
                class method, dynamic object method or 
                dynamic class method.
                (NOTE  This format will probably change)
    name        name of the function/method called if not dynamic


=cut

sub subroutines_called {
    my($self) = shift;

    my @subs = $self->_call_B('subs_called');
    my $mod_file = $self->file;

    @subs = grep /at \Q$mod_file\E line/, @subs;
    my @out = ();
    foreach (@subs) {
        my %info = ();
        ($info{type}) = /^(.+) call/;
        $info{type} = 'symbolic function' if /using symbolic ref/;
        ($info{'name'}) = /to (\S+)/;
        ($info{class})= /via (\S+)/;
        ($info{line}) = /line (\d+)/;
        push @out, \%info;
    }
    return @out;
}
    
=back

=head2 Information about Unpredictable Constructs

Unpredictable constructs are things that make a Perl program hard to
predict what its going to do without actually running it.  There's
nothing wrong with these constructs, but its nice to know where they
are when maintaining a piece of code.

=over 4

=item B<dynamic_method_calls>

  my @methods = $module->dynamic_method_calls;

Returns a list of dynamic method calls (ie. C<$obj->$method()>) used
by the $module.  @methods has the same format as the return value of
subroutines_called().

=cut

sub dynamic_method_calls {
    my($self) = shift;
    return grep $_->{type} =~ /dynamic/, $self->subroutines_called;
}

=back


=head1 AUTHOR

Michael G Schwern <schwern@pobox.com> with code from ExtUtils::MM_Unix, 
Module::InstalledVersion and lots of cargo-culting from B::Deparse.

=head1 THANKS

Many thanks to Simon Cozens and Robin Houston for letting me chew
their ears about B.

=head1 CAVEATS

Code refs in @INC are currently ignored.  If this bothers you submit a
patch.

superclasses() is cheating and just loading the module in a seperate
process and looking at @ISA.  I don't think its worth the trouble to
go through and parse the opcode tree as it still requires loading the
module and running all the BEGIN blocks.  Patches welcome.

I originally was going to call superclasses() isa() but then I
remembered that would be bad.

All the methods that require loading are really inefficient as they're
not caching anything.  I'll worry about efficiency later.

=cut

return 'Stepping on toes is what Schwerns do best!  *poing poing poing*';

