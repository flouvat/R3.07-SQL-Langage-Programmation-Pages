---
layout: page
title: Liste des TD
permalink: /TD/
---


{% for TD in site.TD %}

- [{{ TD.title }}]({{site.baseurl}}{{ TD.url }})

{% endfor %}

Solutions :

{% for TD in site.TD.solutions %}

- [{{ TD.title }}]({{site.baseurl}}{{ TD.url }})

{% endfor %}