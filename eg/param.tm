% my ($x) = @_;
See t/01-template.t how to generate template.out from this template.

<%= $x %>

% for 1..$x {
    hello
% }

