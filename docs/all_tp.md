---
layout: page
title: Liste des TP
permalink: /TP/
---

{% for TP in site.TP %}

- [{{ TP.title }}]({{site.baseurl}}{{ TP.url }})

{% endfor %}