---
layout: page
title: Liste des TD
permalink: /TD/
---

{% for TD in site.TD %}

- [{{ TD.title }}]({{site.baseurl}}{{ TD.url }})

{% endfor %}