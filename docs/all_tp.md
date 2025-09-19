---
layout: page
title: Liste des TP
permalink: /TP/
---


{% assign tp_pages = site.TP | where_exp: "page", "page.path contains 'TP/'" | sort: "title" %}
{% for TP in tp_pages %}
  {% unless TP.path contains 'TP/solutions/' %}

- [{{ TP.title }}]({{ site.baseurl }}{{ TP.url }})
  
  {% endunless %}
{% endfor %}

#### Solutions

{% assign solution_pages = site.TP | where_exp: "page", "page.path contains 'TP/solutions/'" | sort: "title" %}
{% for solution in solution_pages %}

- [{{ solution.title }}]({{ site.baseurl }}{{ solution.url }})
  
{% endfor %}