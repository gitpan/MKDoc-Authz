package MKDoc::Authz::Group;
use MKDoc::Core::ResourceFinder;
use MKDoc::Authz::GroupItem;
use MKDoc::Control_List;
use warnings;
use strict;


sub new
{
    my $class = shift;
    my $name  = shift;
    my $file  = MKDoc::Core::ResourceFinder::rel2abs ("/authz/$name.conf") || return;
    return bless {
        name => $name,
        file => $file,
        ctrl => new MKDoc::Control_List ( file => $file ),
    }, $class;
}


sub list
{
    my @files = MKDoc::Core::ResourceFinder::list ("/authz");
    my @list  = map { s/\.conf$//; $_ } grep /\.conf$/, @files;
    return wantarray ? @list : \@list;
}


sub can_do
{
    my $self  = shift;
    my ($res) = $self->{ctrl}->process();
    $res || return;
    return ($res eq 'allow') ? 1 : 0;
}


sub has_user 
{
    my $self = shift;
    my $group_name = $self->{name};
    $group_name eq 'public' and return 1;

    my $user_login = shift || return;
    return MKDoc::Authz::GroupItem->load_from_user_login_and_group_name ($user_login, $group_name);
}


1;
