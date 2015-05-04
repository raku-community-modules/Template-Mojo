<% my &block = begin %>
Hello <%= $^name %>!
<% end %>

% for 'World', 'Bob', 'Larry', 'Fred', 'George' {
%= block($^name)
% }
