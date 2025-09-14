---
layout: page
title: Liste des TD
permalink: /TD/
---

{% assign td_pages = site.TD | where_exp: "page", "page.path contains 'TD/'" | sort: "title" %}
{% for TD in td_pages %}
  {% unless TD.path contains 'TD/solutions/' %}
    - [{{ TD.title }}]({{ site.baseurl }}{{ TD.url }})
  {% endunless %}
{% endfor %}

#### Solutions

{% assign solution_pages = site.TD | where_exp: "page", "page.path contains 'TD/solutions/'" | sort: "title" %}
{% for solution in solution_pages %}
  - [{{ solution.title }}]({{ site.baseurl }}{{ solution.url }})
{% endfor %}

