=head1 package MKDoc::Setup::Authz

Install L<MKDoc::Authz> on an L<MKDoc::Core> site.


=head1 REQUIREMENTS

=head2 MKDoc::Core

Make sure you have installed L<MKDoc::Core> on your system with at least one
L<MKDoc::Core> site.  Please refer to L<MKDoc::Core::Article::Install> for
details on how to do this.


=head2 MKDoc::SQL

L<MKDoc::Auth> use an SQL table to make its data persistent. You need to make
sure that you have installed L<MKDoc::SQL> on the website for which you want to
install L<MKDoc::Auth>.

See L<MKDoc::Setup::SQL> for more details.


=head1 Installing MKDoc::Authz

Once you are sure that L<MKDoc::Core> and L<MKDoc::SQL> have been properly
installed on your site, installation is trivial:

  source /path/to/site/mksetenv.sh
  perl -MMKDoc::Setup -e install_authz

That's it! The install script will create the SQL tables, register the
MKDoc::Authz plugins, and fiddle with apache config files as appropriate. Once
you are done you just need to restart apache.

=cut
package MKDoc::Setup::Authz;
use base qw /MKDoc::Setup/;
use MKDoc::Authz::GroupItem;
use MKDoc::Authz::Group;
use File::Touch;
use File::Spec;
use MKDoc::SQL;
use warnings;
use strict;


sub main::install_authz
{
    $ENV{MKDOC_DIR} || die "\$ENV{MKDOC_DIR} is not defined!";
    $ENV{SITE_DIR}  || die "\$ENV{SITE_DIR} is not defined!";
    -e "$ENV{SITE_DIR}/su/driver.pl" || die "$ENV{SITE_DIR}: MKDoc::SQL service does not seems to be installed.";
    
    MKDoc::SQL::Table->load_state ("$ENV{SITE_DIR}/su");
    MKDoc::Authz::GroupItem->sql_schema();
    MKDoc::SQL::Table->save_state ("$ENV{SITE_DIR}/su");
    print "Added SQL schema\n";

    __PACKAGE__->new()->install();
}


sub install
{
    my $self = shift;

    my $user_t = MKDoc::Authz::GroupItem->sql_table();
    eval { $user_t->create() };

    print "Attempting to create " . MKDoc::Authz::GroupItem->sql_name() . "\n";
    while ($@)
    {
        print "Could not create " . MKDoc::Authz::GroupItem->sql_name() . "\n";
        print "Error: $@\n\n";

        print "Would you like to:\n";
        print "T - Try again\n";
        print "I - Ignore and continue\n";
        print "E - Erase the existing table\n";
        
        my $answer = lc (<STDIN>);
        chomp ($answer);
       
        $answer eq 'i' and last;
        $answer eq 'e' and do {
            eval { $user_t->drop() }
        };

        $@ = undef;
        eval { $user_t->create() };
    }

    my @plugins = qw ( 
MKDoc::Authz::Plugin::Authorize
MKDoc::Authz::Plugin::UserEdit
    );

    for (@plugins) { _register_plugin ($_) } 

#    _register_httpd ("$ENV{SITE_DIR}/httpd/httpd-authorize.conf");
#    print "Registered MKDoc::Auth::Handler::AuthenticateOpt (Apache)\n";
#
#    _register_httpd ("$ENV{SITE_DIR}/httpd2/httpd-authorize.conf");
#    print "Registered MKDoc::Auth::Handler::AuthenticateOpt (Apache 2)\n";

    print "Please input the login of one user which has ALL the permissions [admin] ";
    my $admin_login = <STDIN>;
    chomp ($admin_login);

    $admin_login ||= 'admin';
    new MKDoc::Authz::GroupItem (user_login => $admin_login, group_name => 'admin');
    print "\nAdded '$admin_login' to group 'admin'\n\n";
}


sub _register_plugin
{
    my $plugin = shift;

    $plugin =~ /Authorize/ and do {
        File::Touch::touch ("$ENV{SITE_DIR}/plugin/00010_$plugin");
        print "Registered $plugin\n";
        return;
    };

    File::Touch::touch ("$ENV{SITE_DIR}/plugin/50000_$plugin");
    print "Registered $plugin\n";
}


sub _register_httpd
{
    my $file = shift;

    open FP, "<$file" or die "Cannot read $file";
    my $data = join '', <FP>;
    close FP;

    $data =~ /\# MKDoc::Authz/ and return;

    $data .= <<EOF;

# MKDoc::Authz
<Location />
  PerlAccessHandler MKDoc::Authz::Handler::Authorize
</Location>
EOF

    open FP, ">$file" or die "Cannot write $file";
    print FP $data;
    close FP;
}


1;
