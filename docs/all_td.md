---
layout: page
title: Liste des TD
permalink: /TD/
---


<ul>
  {% assign td_pages = site.pages | where_exp: "page", "page.path contains 'TD/' and not page.path contains 'TD/solutions/'" | sort: "title" %}
  {% for page in td_pages %}
    <li><a href="{{ site.baseurl }}{{ page.url }}">{{ page.title }}</a></li>
  {% endfor %}
</ul>

<h2>Liste des Solutions</h2>
<ul>
  {% assign solution_pages = site.pages | where_exp: "page", "page.path contains 'TD/solutions/'" | sort: "title" %}
  {% for page in solution_pages %}
    <li><a href="{{ site.baseurl }}{{ page.url }}">{{ page.title }}</a></li>
  {% endfor %}
</ul>
