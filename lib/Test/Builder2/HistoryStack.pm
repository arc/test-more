package Test::Builder2::HistoryStack;

use Carp;
use Test::Builder2::Mouse;

with 'Test::Builder2::Singleton';

=head1 NAME

Test::Builder2::HistoryStack - Manage the history of test results

=head1 SYNOPSIS

    use Test::Builder2::HistoryStack;

    # This is a shared singleton object
    my $history = Test::Builder2::HistoryStack->singleton;
    my $result  = Test::Builder2::Result->new_result( pass => 1 );

    $history->add_test_history( $result );
    $history->is_passing;

=head1 DESCRIPTION

This object stores and manages the history of test results.

=head1 METHODS

=head2 Constructors

=head3 singleton

    my $history = Test::Builder2::HistoryStack->singleton;
    Test::Builder2::HistoryStack->singleton($history);

Gets/sets the shared instance of the history object.

Test::Builder2::HistoryStack is a singleton.  singleton() will return the same
object every time so all users can have a shared history.  If you want
your own history, call create() instead.

=head3 create

    my $history = Test::Builder2::HistoryStack->create;

Creates a new, unique History object with its own Counter.

=head2 Accessors

Unless otherwise stated, these are all accessor methods of the form:

    my $value = $history->method;       # get
    $history->method($value);           # set


=head2 Results

=head3 results

Return an arrya of all results stored.

    # The result of test #4.
    my $result = $history->results->[3];

=cut

has _results => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[Test::Builder2::Result::Base]',
    lazy    => 1,
    default => sub {[]},
    handles => { add_test_history => 'push',
                 add_result       => 'push',
                 add_results      => 'push',
                 result_count     => 'count',
                 results          => 'elements',
               },
);

=head2 add_test_history, add_result, and add_results

Add a result object to the end stack, 

=head2 result_count

Get the count of results stored in the stack. 

NOTE: This could be diffrent from the number of tests that have been
seen, to get that count use test_count.

=head3 has_results

Returns true if we have stored results, false otherwise.

=cut

sub has_results { shift->result_count > 0 }



=head2 Statistics

=cut

# %statistic_mapping: 
# attribute_name => code_ref that defines how to increment attribute_name
#
# this is used both as a list of attributes to create as well as by 
# _update_statistics to increment the attribute. 
# code_ref will be handed a single result object that was to be added
# to the results stack.

my %statistic_mapping = (
    pass_count => sub{ shift->is_pass ? 1 : 0 },
    fail_count => sub{ shift->is_fail ? 1 : 0 },
    todo_count => sub{ shift->is_todo ? 1 : 0 },
    skip_count => sub{ shift->is_skip ? 1 : 0 },
    test_count => sub{ 1 },
);

has $_ => (
    is => 'rw',
    isa => 'Test::Builder2::Positive_Int',
    default => 0,
) for keys %statistic_mapping;

sub _update_statistics {
    my $self = shift;
    for my $attr ( keys %statistic_mapping ) {
        for my $result (@_) {
            $self->$attr( $self->$attr + $statistic_mapping{$attr}->($result) );
        }
    }
}

before [qw{add_test_history add_result add_results}] => sub{
    my $self = shift;
    $self->_update_statistics(@_);
};

=head3 test_count

A count of the number of tests that have been added to results. This
value is not guaranteed to be the same as results_count if you have
altered the results_stack. This is a static counter of the number of
tests that have been seen, not the number of results stored.

=head3 pass_count

A count of the number of passed tests have been added to results.

=head3 fail_count

A count of the number of failed tests have been added to results.

=head3 todo_count

A count of the number of TODO tests have been added to results.

=head3 skip_count

A count of the number of SKIP tests have been added to results.

=head3 is_passing

Returns true if we have not yet seen a failing test.

=cut

sub is_passing { shift->fail_count == 0 }


no Test::Builder2::Mouse;
1;








__END__
!!!!!!! DON"T YET KNOW IF I NEED ANY OF THIS FROM HISTORY !!!!!!!


# splice() isn't implemented for (thread) shared arrays and its likely
# the History object will be shared in a threaded environment
sub _overlay {
    my( $orig, $overlay, $from ) = @_;

    my $to = $from + (@$overlay || 0) - 1;
    @{$orig}[$from..$to] = @$overlay;

    return;
}


=head3 summary

    my @summary = $history->results;

Returns a list of true/false values for each test result indicating if
it passed or failed.

=cut

sub summary {
    my $self = shift;

    return map { $_->is_fail ? 0 : 1 } @{ $self->results };
}

