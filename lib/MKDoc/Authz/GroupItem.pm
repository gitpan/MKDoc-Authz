package MKDoc::Authz::GroupItem;
use MKDoc::Core::Error;
use MKDoc::SQL;
use warnings;
use strict;


sub sql_table
{
    my $class = shift;
    my $name  = $class->sql_name(); 
    return MKDoc::SQL::Table->table ($name);
}


sub sql_name { return 'MKDoc_Authz_GroupItem' }


sub sql_schema
{
    my $class = shift;
    new MKDoc::SQL::Table (
        bless_into => 'MKDoc::Authz::GroupItem',
        name       => $class->sql_name(), 
        pk         => [ qw /ID/ ],
        ai         => 1,
        unique     => { assoc => [ qw /User_Login Group_Name/ ] },
        cols       => [
            { name => 'ID',         type => new MKDoc::SQL::Type::Int  ( not_null => 1 )               },
            { name => 'User_Login', type => new MKDoc::SQL::Type::Char ( size => 250, not_null => 1 )  },
            { name => 'Group_Name', type => new MKDoc::SQL::Type::Char ( size => 250, not_null => 1 )  },
        ],
    );
}


sub validate
{
    my $self = shift;
    return $self->_validate_id()         &
           $self->_validate_user_login() &
           $self->_validate_group_name();
}


sub _validate_id
{
    my $self = shift;
    
    # if the object is new, there must be no ID
    $self->{'.new'} and do {
        delete $self->{ID};
        return 1;
    };
    
    # if the object is not new, there must be an ID
    # and this ID must exist in the database.
    my $id = $self->id() || do {
        new MKDoc::Core::Error 'auth/user/id/undefined';
        return 0;
    };

    $self->load ($id) || do {
        new MKDoc::Core::Error 'auth/user/id/no_match';
        return 0;
    };

    return 1;
}


sub _validate_user_login
{
    my $self = shift;
    my $login = $self->user_login() || do {
        new MKDoc::Core::Error 'auth/user/user_login/empty';
        return 0;
    };

    return 1;
}


sub _validate_group_name
{
    my $self = shift;
    my $group = $self->group_name() || do {
        new MKDoc::Core::Error 'auth/user/group_name/empty';
        return 0;
    };

    return 1;
}


sub new
{
    my $class = shift;
    my %args  = @_;

    my $self  = bless {}, $class;
    foreach my $key (%args)
    {
        my $met = "set_$key";
        $self->can ($met) and $self->$met ( $args{$key} );
    }

    $self->{'.new'} = 1;
    return $self->save;
}


sub list
{
    my $class   = shift;
    my $group_t = $class->sql_table();
    my $query   = $group_t->search();
    my @res     = $query->fetch_all();
    return wantarray ? @res : \@res;
}


sub load
{
    my $class  = shift || return;
    my $id     = shift || return;
    my $group_t = $class->sql_table();
    return $group_t->get ( ID => $id );
}


sub find_from_user_login
{
    my $class = shift || return;
    my $user_login = shift || return;
    my $group_t = $class->sql_table();
    my @res = $group_t->search ( User_Login => $user_login )->fetch_all();
    return @res;
}


sub delete_from_user_login
{
    my $class = shift || return;
    my $user_login = shift || return;
    my $group_t = $class->sql_table();
    $group_t->delete ( User_Login => $user_login );
}


sub find_from_group_name
{
    my $class = shift || return;
    my $group_name = shift || return;
    my $group_t = $class->sql_table();
    my @res = $group_t->search ( Group_Name => $group_name )->fetch_all();
    return @res;
}


sub load_from_user_login_and_group_name
{
    my $class = shift || return;
    my $user_login = shift || return;
    my $group_name = shift || return;
    my $group_t = $class->sql_table();
    return $group_t->get (User_Login => $user_login, Group_Name => $group_name);
}


sub save
{
    my $self = shift;
    $self->validate() || return;
    $self->{'.new'} ? $self->_insert() : $self->_modify();
    
    return $self;
}


sub _insert
{
    my $self   = shift;
    my $group_t = $self->sql_table();
    delete $self->{'.new'};
    $group_t->insert ($self);
}


sub _modify
{
    my $self   = shift;
    my $group_t = $self->sql_table();
    delete $self->{'.new'};
    $group_t->modify ($self);
}


sub delete
{
    my $self   = shift;
    my $group_t = $self->sql_table();
    $group_t->delete (ID => $self->id());
}


sub id
{
    my $self = shift;
    return $self->{ID};
}


sub user_login
{
    my $self = shift;
    return $self->{User_Login};
}


sub set_user_login
{
    my $self = shift;
    $self->{User_Login} = shift;
}


sub group_name
{
    my $self = shift;
    return $self->{Group_Name};
}


sub set_group_name
{
    my $self = shift;
    $self->{Group_Name} = shift;
}


1;


__END__
