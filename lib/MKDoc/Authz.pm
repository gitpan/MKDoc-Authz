package MKDoc::Authz;
use MKDoc::Authz::Group;
use strict;
use warnings;

our $VERSION = 0.1;


sub can_do
{
    my $self = shift;
    my $user = shift;
    $::MKD_USER and $user ||= $::MKD_USER->login();

    for my $group_name (MKDoc::Authz::Group->list())
    {
        my $group = MKDoc::Authz::Group->new ($group_name);
        $group->has_user ($user) || next;
        $group->can_do() && return 1;
    }
    
    return;
}


__END__


=head1 NAME

MKDoc::Authz - Authorization framework for MKDoc::Core


=head1 INSTALLATION

See L<MKDoc::Setup::Authz>.

Once you are done with the install, you will need to define some group
policies. A group policy is simply a configuration file which defines what can
and what can't be done for a given group. 

Group policies can be placed in <SITE_DIR>/resources/authz/ to set access
policies on a per-site basis or in <MKDOC_DIR>/resources/authz/ for a
server-wide policy.

Your <SITE_DIR>/resources/authz/ might look like:

  ./resources/authz/admin.conf
  ./resources/authz/content-writer.conf
  ./resources/authz/proof-reader.conf
  ./resources/authz/approver.conf
  ./resources/authz/public.conf

So in general, you want to attribute a set of permissions per 'task' which your
application can do. Then you want to associate each users with one or more
tasks. 

Group policies use the L<MKDoc::Control_List> module. You should probably
familiarize yourself with this module to work efficiently with L<MKDoc::Authz>.

Just like any other L<MKDoc::Core> resource, group policies inherit. See
L<MKDoc::Core::ResourceFinder> for more details on this.


=head1 INTERFACE

=head2 L<MKDoc::Authz::Plugin::Authenticate>

The default way which L<MKDoc::Authz> manages security is through a simple
L<MKDoc::Core> plugin, which has a very high priority (i.e. it gets executed
before any other plugin).

The nice way about using a plugin is that rather than sending an
*authorization* required page, we send an *authentication* required response
which prompts the user for his credentials.

This means that it's possible to have a very RESTful interface to your web
applications: simply set your policy to protect the appropriate 'POST'
operations and you're done - the user will be prompted for new credentials when
their permissions become insufficient.


=head2 L<MKDoc::Authz::Handler::Authenticate>

The other way of doing it is to install L<MKDoc::Authz::Handler::Authenticate>
as an authentication handler on your site.

However it's a bit of a pain since you need to use the mod_perl API all the
way: most of the environments variables are not set at this phase of the apache
request life cycle.

The default config files don't play well with the authentication handler
because they use L<MKDoc::Core::Request> which has no information about
PATH_INFO at the authorization stage.

But if you write your own config files, no problem...


=head2 Notes

All users ALWAYS belong to the group called 'public'. Even if the user is
'undef', it will belong to the group 'public'. By default, 'public' has a very
simple policy: return 'deny' all the time. Safe enough :-)

However you can change the 'public' policy by editing either
<SITE_DIR>/resources/authz/public.conf or
<MKDOC_DIR>/resources/authz/public.conf.

For example, this public.conf works well with L<MKDoc::Core> + L<MKDoc::Auth>.
Adapt to suit your needs...

  CONDITION always_true   "true"
  CONDITION is_resource   MKDoc::Core::Request->instance()->path_info() =~ m#^/\.resources/#
  CONDITION is_slash      MKDoc::Core::Request->instance()->path_info() eq '/'
  CONDITION is_signup     MKDoc::Core::Request->instance()->path_info() eq '/.signup.html'
  CONDITION is_login      MKDoc::Core::Request->instance()->path_info() eq '/.login.html'
  CONDITION is_confirm    MKDoc::Core::Request->instance()->path_info() =~ m#^/\~.*/\.confirm.html$#
  CONDITION is_edit       MKDoc::Core::Request->instance()->path_info() =~ m#^/\~.*/\.edit.html$#
  CONDITION is_remove     MKDoc::Core::Request->instance()->path_info() =~ m#^/\~.*/\.remove.html$#
  
  RET_VALUE allow         "allow"
  RET_VALUE deny          "deny"
  
  RULE    allow   WHEN is_resource
  RULE    allow   WHEN is_slash
  RULE    allow   WHEN is_signup
  RULE    allow   WHEN is_confirm
  RULE    allow   WHEN is_login
  RULE    allow   WHEN is_edit
  RULE    allow   WHEN is_remove
  RULE    deny    WHEN always_true

You can change the groups to which people belong by visiting the address
/~<user_name>/.groups.html, providing that you are logged in through some
authentication mechanism *and* provided that you have sufficient permissions
;-).


=head1 FUNCTIONALITY 

Installing this product on an L<MKDoc::Core> site will provide the following
services:


=head2 /~<user_login>/.groups.html

Changes the groups that this user belongs to. Of course, in order to access
this address, you need sufficient permissions yourself... The
L<MKDoc::Setup::Authz> module should sort out this little detail for you
though.

Of course if you remove yourself from the admin group, you're toasted. Your
only recourse is to log in your MySQL database and re-insert yourself in the
MKDoc_Authz_GroupItem table. 

(Note to self: maybe I should make it so that admin users cannot remove
themselves from the admin group...)


=head1 ADMINISTATION & SECURITY

The administration interface to L<MKDoc::Authz> is very crude, but this is the
price to pay in order to be completely authentication layer independant.

At some point in the future I plan to release L<MKDoc::Auth::Admin> which will
depend on L<MKDoc::Authz> for privileges management, L<MKDoc::Auth> for user
management, and integrates both of them together nicely.


=head1 AUTHOR

Copyright 2003 - MKDoc Holdings Ltd.

Author: Jean-Michel Hiver <jhiver@mkdoc.com>

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.


=head1 SEE ALSO

L<MKDoc::Auth>,
L<MKDoc::Core>

Help us open-source MKDoc. Join the mkdoc-modules mailing list:

  mkdoc-modules@lists.webarch.co.uk
