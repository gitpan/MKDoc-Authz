#!/usr/bin/perl
use lib qw (lib ../lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::Authz::Group;
use MKDoc::Core::Request;
ok (1);
exit (0) unless (-e 'test/su/driver.pl');

$ENV{SITE_DIR} = 'test';

our @ERRORS = ();

$MKDoc::Core::Error::CALLBACK = sub {
    push @ERRORS, shift;
};

my $public = new MKDoc::Authz::Group ('public');
ok ($public->isa ('MKDoc::Authz::Group'));
is ($public->{file} => 'lib/MKDoc/resources/authz/public.conf');
is ($public->{name} => 'public');
ok ($public->{ctrl});
ok ($public->{ctrl}->isa ('MKDoc::Control_List'));

{
    local $::MKD_Request = MKDoc::Core::Request->instance()->clone();
    $::MKD_Request->path_info ('/');
    is ($public->can_do() => 1);
}

{
    local $::MKD_Request = MKDoc::Core::Request->instance()->clone();
    $::MKD_Request->path_info ('/foo/');
    is ($public->can_do() => 0);
}


my $admin = new MKDoc::Authz::Group ('admin');
ok ($admin->isa ('MKDoc::Authz::Group'));
is ($admin->{file} => 'lib/MKDoc/resources/authz/admin.conf');
is ($admin->{name} => 'admin');
ok ($admin->{ctrl});
ok ($admin->{ctrl}->isa ('MKDoc::Control_List'));

{
    local $::MKD_Request = MKDoc::Core::Request->instance()->clone();
    $::MKD_Request->path_info ('/');
    is ($admin->can_do() => 1);
}

{
    local $::MKD_Request = MKDoc::Core::Request->instance()->clone();
    $::MKD_Request->path_info ('/foo/');
    is ($admin->can_do() => 1);
}

__END__
