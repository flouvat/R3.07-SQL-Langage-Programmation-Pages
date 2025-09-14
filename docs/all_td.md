---
layout: page
title: Liste des TD
permalink: /TD/
---



{% assign td_pages = site.pages | where_exp: "page", "page.path contains 'TD/' and not page.path contains 'TD/solutions/'" | sort: "title" %}
{% for TD in td_pages %}
    - [{{ TD.title }}]({{site.baseurl}}{{ TD.url }})
{% endfor %}


### Liste des Solutions

{% assign solution_pages = site.pages | where_exp: "page", "page.path contains 'TD/solutions/'" | sort: "title" %}
{% for solution in solution_pages %}
    - [{{ solution.title }}]({{site.baseurl}}{{ solution.url }})
{% endfor %}

