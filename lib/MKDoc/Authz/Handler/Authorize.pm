package MKDoc::Authz::Handler::Authorize;
use Apache::Constants qw /:common/;
use MKDoc::Authz;
use strict;

sub handler
{
    my $r    = shift;
    my $user = $r->connection()->user();
    return MKDoc::Authz->can_do ($user) ? OK : FORBIDDEN;
}

1;
