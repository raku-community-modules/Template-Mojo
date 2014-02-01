% my (%h) = @_;
See t/02-complex.t how to generate complex.out from this template.

<h1><%= %h<title> %>

<ul>
% for %h<pages>.values -> $p {
  <li><a href="<%= $p<url> %>"><%= $p<title> %></a></li>
% }
</ul>


