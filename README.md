[![Actions Status](https://github.com/raku-community-modules/Template-Mojo/actions/workflows/test.yml/badge.svg)](https://github.com/raku-community-modules/Template-Mojo/actions)

TITLE
=====

class Template::Mojo

A templating system modeled after the Perl's [https://metacpan.org/module/Mojo::Template](https://metacpan.org/module/Mojo::Template)

SYNOPSIS
========

    my $tmpl = slurp 'eg/template.tm';

    my $t = Template::Mojo.new($tmpl);
    $t.render()

    my $ot = Template::Mojo.from-file('eg/template.tm');

EXAMPLES
========

Loop
----

### Template

    % for 1..3 {
        hello
    % }

### Code

    my $tmpl = slurp 'eg/template.tm';
    my $t = Template::Mojo.new($tmpl);
    $t.render()

### Output

    hello
    hello
    hello

Parameters
----------

### Template

    % my ($x) = @_;

    <%= $x %>

    % for 1..$x {
        hello
    % }

See, on the first row of the template we accept a parameter as if this was a generic function call. Then we use the veriable in two different ways.

### Code

The value to that subroutione can be passed in the render call:

    my $tmpl = slurp 'eg/template.tm';
    my $t = Template::Mojo.new($tmpl);
    $t.render(5)

### Output:

    5

        hello
        hello
        hello
        hello
        hello

Passing hash
------------

### Template

    % my ($x) = @_;

    Fname: <%= $x<fname> %>
    Lname: <%= $x<lname> %>

### Code

    my %params = (
      fname => 'Foo',
      lname => 'Bar',
    );

    my $tmpl = slurp 'eg/template.tm';
    my $t = Template::Mojo.new($tmpl);
    $t.render(%params)

### Output

    Fname: Foo
    Lname: Bar

Complex examples
----------------

### Template

    % my (%h) = @_;

    <h1><%= %h<title> %>

    <ul>
    % for %h<pages>.values -> $p {
      <li><a href="<%= $p<url> %>"><%= $p<title> %></a></li>
    % }
    </ul>

### Code

    my %params = (
       title => "Perl 6 Links",
       pages => [
          {
            "title" => "Rakudo",
            "url"   => "http://rakudo.org/",
          },
          {
            title   => 'Perl 6',
            url     => 'http://perl6.org/',
          }
       ],
    );

    my $tmpl = slurp 'eg/template.tm';
    my $t = Template::Mojo.new($tmpl);
    $t.render(%params)

### Output

    <h1>Perl 6 Links

    <ul>
      <li><a href="http://rakudo.org/">Rakudo</a></li>
      <li><a href="http://perl6.org/">Perl 6</a></li>
    </ul>

AUTHOR
======

Tadeusz “tadzik” Sośnierz"

COPYRIGHT AND LICENSE
=====================

Copyright 2012-2017 Tadeusz Sośnierz Copyright 2023 Raku Community

This library is free software; you can redistribute it and/or modify it under the MIT license.

Please see the LICENCE file in the distribution

CONTRIBUTORS
============

  * Andrew Egeler

  * Anthony Parsons

  * Carl Masak

  * Gabor Szabo

  * Moritz Lenz

  * Sterling Hanenkamp

  * Timo Paulssen

  * Tobias Leich

