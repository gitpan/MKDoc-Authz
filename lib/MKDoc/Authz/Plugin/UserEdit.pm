package MKDoc::Authz::Plugin::UserEdit;
use MKDoc::Authz::Group;
use MKDoc::Authz::GroupItem;
use strict;
use warnings;
use base qw /MKDoc::Core::Plugin/;


sub activate
{
    my $self   = shift;
    return $self->user_login();
}


sub uri_hint
{
    return $ENV{MKD__AUTHZ_EDIT_URI_HINT} || 'groups.html';
}


sub uri
{
    my $self  = shift;
    my $args  = { @_ };

    # attempts to get the login from the arguments
    my $login = delete $args->{user_login};

    # if unsuccessful, try to get the login from
    # the current location
    $login ||= $self->user_login();

    # if unsuccessful, try to get the login from
    # the current user
    $login ||= $::MKD_USER->login() if ($::MKD_USER);
    
    # if unsuccessful, return nothing
    $login ||= do {
        warn $self . '::login() - could not find matching login';
        return;
    };
    
    # lie about what the location() is so that we get the right URI
    my $req = $self->request()->clone();
    
    local *location;
    *location = sub { "/~$login/." . $self->uri_hint() };
    
    return $self->SUPER::uri ( %{$args} );
}


sub user_login 
{
    my $self  = shift || return;
    my $req   = $self->request();
    my $path  = $req->path_info();
    my $hint  = quotemeta ($self->uri_hint());

    my ($login) = $path =~ /^\/~(.*)\/\.$hint$/;
    return $login;
}


sub http_post
{
    my $self = shift;
    my $req  = $self->request();
    my $user_login = $self->user_login();

    MKDoc::Authz::GroupItem->delete_from_user_login ($user_login);

    for ($req->param())
    {
        MKDoc::Authz::GroupItem->new (
            user_login => $user_login,
            group_name => $_,
        );
    }

    return $self->http_get();
}


sub list_groups
{
    my $self = shift;
    my $user_login = $self->user_login();
    my @groups = map {
        {
            name    => $_,
            label   => $_,
            checked => MKDoc::Authz::GroupItem->load_from_user_login_and_group_name ($user_login, $_) ?
                       'checked' : undef,
        }
    } grep !/^public$/, MKDoc::Authz::Group->list();

    return wantarray ? @groups : \@groups;
}


1;
