use FindBin;
use lib "$FindBin::Bin/../lib";
use Pithub::Test;
use Test::Most;

BEGIN {
    use_ok('Pithub');
    use_ok('Pithub::Gists');
}

SKIP: {
    skip 'Set PITHUB_TEST_LIVE to true to run these tests', 1 unless $ENV{PITHUB_TEST_LIVE};

    my $p = Pithub->new;
    my $result = $p->request( GET => '/' );

    is $result->code,        200,  'HTTP status is 200';
    is $result->success,     1,    'Successful';
    is $result->raw_content, '{}', 'Empty JSON object';
    eq_or_diff $result->content, {}, 'Empty hashref';
}

# These tests may break very easily because data on Github can and will change, of course.
# And they also might fail once the ratelimit has been reached.
SKIP: {
    skip 'Set PITHUB_TEST_LIVE_DATA to true to run these tests', 1 unless $ENV{PITHUB_TEST_LIVE_DATA};

    my $p = Pithub->new;

    # Pagination + per_page
    {
        my $g = Pithub::Gists->new( per_page => 2 );

        my @seen = ();

        my $test = sub {
            my ( $row, $seen ) = @_;
            my $verb = $seen ? 'did' : 'did not';
            my $id = $row->{id};
            ok $id, "Pithub::Gists->list found gist id ${id}";
            is grep( $_ eq $id, @seen ), $seen, "Pithub::Gists->list we ${verb} see id ${id}";
            push @seen, $id;
        };

        my $result = $g->list( public => 1 );
        is $result->success, 1, 'Pithub::Gists->list successful';
        is $result->count,   2, 'The per_page setting was successful';

        foreach my $page ( 1 .. 2 ) {
            while ( my $row = $result->next ) {
                $test->( $row, 0 );
            }
            $result = $result->next_page unless $page == 2;
        }

        # Browse to the last page and see if we can get some gist id's there
        $result = $result->last_page;
        while ( my $row = $result->next ) {
            $test->( $row, 0 );
        }

        # Browse to the previous page and see if we can get some gist id's there
        $result = $result->prev_page;
        while ( my $row = $result->next ) {
            $test->( $row, 0 );
        }

        # Browse to the first page and see if we can get some gist id's there
        $result = $result->first_page;
        while ( my $row = $result->next ) {
            $test->( $row, 1 );    # we saw those gists already!
        }
    }
}

done_testing;

# TODO: implement tests for following methods:

# Pithub::GitData::Blobs->create

# Pithub::GitData::Commits->create

# Pithub::GitData::References->create
# Pithub::GitData::References->update

# Pithub::GitData::Tags->get
# Pithub::GitData::Tags->create

# Pithub::GitData::Trees->create

# Pithub::Issues::Events->get
# Pithub::Issues::Events->list

# Pithub::Orgs::Members->delete

# Pithub::PullRequests->merge

# Pithub::PullRequests::Comments->create
# Pithub::PullRequests::Comments->delete
# Pithub::PullRequests::Comments->get
# Pithub::PullRequests::Comments->list
# Pithub::PullRequests::Comments->update

# Pithub::Repos->teams
