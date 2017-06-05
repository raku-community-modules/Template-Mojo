See t/02-complex.t how to generate complex.out from this template.

<h1><%= $:title %>

<ul>
% for $:pages.values -> $p {
  <li><a href="<%= $p<url> %>"><%= $p<title> %></a></li>
% }
</ul>


