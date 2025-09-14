---
layout: page
title: Liste des TD
permalink: /TD/
---

{% assign sorted_TD = site.TD | sort: "title" %}
{% for TD in sorted_TD %}

- [{{ TD.title }}]({{site.baseurl}}{{ TD.url }})

{% endfor %}