package MKDoc::Authz::Plugin::Authorize;
use MKDoc::Authz;
use base qw/MKDoc::Core::Plugin/;
use strict;
use warnings;


sub activate
{
    my $self = shift;
    my $user = $ENV{REMOTE_USER};
    return not MKDoc::Authz->can_do ($user);
}


sub http_get
{
    my $self = shift;
    my $rsp = $self->response();
    $rsp->Status ("401 Authorization Required");
    $rsp->WWW_Authenticate ('Basic realm="MKDoc/Auth"');
    return $self->SUPER::http_get (@_);
}


1;
